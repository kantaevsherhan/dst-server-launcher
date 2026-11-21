import 'dart:io';

import 'package:path/path.dart' as path;

import '../domain/models.dart';
import '../domain/services.dart';

enum TargetPlatformOS {
  windows('Windows'),
  linux('Linux');

  const TargetPlatformOS(this.label);
  final String label;
  static TargetPlatformOS get host => Platform.isWindows ? windows : linux;
}

class LocalSteamLocator implements SteamLocator {
  static String binary(String root, {bool? windows}) => path.join(
    root,
    'bin64',
    'dontstarve_dedicated_server_nullrenderer_x64${(windows ?? Platform.isWindows) ? '.exe' : ''}',
  );
  static List<String> libraries(String text) =>
      RegExp(r'"path"\s*"([^"\r\n]+)"')
          .allMatches(text)
          .map((m) => m[1]!.replaceAll(r'\\', r'\'))
          .toList();
  static String? installFolder(String manifest) =>
      RegExp(r'"installdir"\s*"([^"\r\n]+)"').firstMatch(manifest)?[1];

  @override
  Future<Installation> locate({String? manual}) async {
    final roots = <String>{};
    String? steam, steamCmd, server, build;
    final notes = <String>[];
    if (Platform.isWindows) {
      for (final key in [
        r'HKCU\Software\Valve\Steam',
        r'HKLM\SOFTWARE\WOW6432Node\Valve\Steam',
      ]) {
        final r = await Process.run('reg.exe', [
          'query',
          key,
          '/v',
          key.startsWith('HKCU') ? 'SteamPath' : 'InstallPath',
        ]);
        final match = RegExp(r'REG_SZ\s+(.+)').firstMatch(r.stdout.toString());
        if (match != null) roots.add(match[1]!.trim());
      }
      for (final env in ['ProgramFiles(x86)', 'ProgramFiles']) {
        final v = Platform.environment[env];
        if (v != null) roots.add(path.join(v, 'Steam'));
      }
    } else {
      final home = Platform.environment['HOME'] ?? '';
      roots.addAll([
        path.join(home, '.steam', 'steam'),
        path.join(home, '.local', 'share', 'Steam'),
      ]);
      for (final cmd in [
        '/usr/games/steamcmd',
        '/usr/bin/steamcmd',
        path.join(home, '.local', 'bin', 'steamcmd'),
        path.join(
          home,
          '.local',
          'share',
          'dst-launcher',
          'steamcmd',
          'steamcmd.sh',
        ),
      ]) {
        if (await File(cmd).exists()) steamCmd = cmd;
      }
      final candidate = path.join(home, 'games', 'dst-dedicated');
      if (manual == null && await File(binary(candidate)).exists()) {
        server = candidate;
      }
    }
    if (manual != null && manual.isNotEmpty) {
      if (await File(binary(manual)).exists()) {
        server = path.normalize(manual);
      } else {
        notes.add(
          'bin64/dontstarve_dedicated_server_nullrenderer_x64${Platform.isWindows ? '.exe' : ''}',
        );
      }
      roots
        ..clear()
        ..add(manual);
    }
    final librariesFound = <String>{...roots};
    for (final root in roots) {
      final exe = path.join(
        root,
        Platform.isWindows ? 'steam.exe' : 'steam.sh',
      );
      if (await File(exe).exists()) steam = exe;
      final vdf = File(path.join(root, 'steamapps', 'libraryfolders.vdf'));
      if (await vdf.exists()) {
        librariesFound.addAll(libraries(await vdf.readAsString()));
      }
    }
    for (final root in librariesFound) {
      final manifest = File(
        path.join(root, 'steamapps', 'appmanifest_343050.acf'),
      );
      if (!await manifest.exists()) continue;
      final text = await manifest.readAsString();
      final folder = installFolder(text);
      if (folder == null ||
          folder.contains('/') ||
          folder.contains('\\') ||
          folder == '..') {
        continue;
      }
      final candidate = path.join(root, 'steamapps', 'common', folder);
      if (await File(binary(candidate)).exists()) {
        if (server != null && !path.equals(server, candidate)) continue;
        server = candidate;
        build = RegExp(r'"buildid"\s*"([0-9]+)"').firstMatch(text)?[1];
      }
    }
    return Installation(
      steam: steam,
      steamCmd: steamCmd,
      server: server,
      build: build,
      notes: notes,
    );
  }
}

class LinuxCommands implements ServerInstaller {
  static const distributions = [
    'Ubuntu',
    'Debian',
    'Linux Mint',
    'Manjaro',
    'Fedora',
  ];
  static String distribution(String osRelease) {
    final id = RegExp(
      r'^ID=["\x27]?([^"\x27\r\n]+)',
      multiLine: true,
    ).firstMatch(osRelease)?[1]?.toLowerCase();
    return switch (id) {
      'debian' => 'Debian',
      'linuxmint' => 'Linux Mint',
      'manjaro' || 'arch' => 'Manjaro',
      'fedora' => 'Fedora',
      _ => 'Ubuntu',
    };
  }

  static String dependencies(String distro) => switch (distro) {
    'Fedora' =>
      'sudo dnf install glibc.i686 libstdc++.i686 libcurl.i686 curl tar gzip',
    'Manjaro' => '# Enable [multilib] in /etc/pacman.conf first.\nsudo pacman -Syu --needed lib32-gcc-libs lib32-libcurl curl tar gzip',
    _ => 'sudo dpkg --add-architecture i386\nsudo apt-get update\nsudo apt-get install lib32gcc-s1 lib32stdc++6 libcurl4:i386 curl ca-certificates tar',
  };
  static String quote(String text) {
    if (text.contains('\u0000') || text.contains('\n') || text.contains('\r')) {
      throw const FormatException('Invalid path');
    }
    return "'${text.replaceAll("'", "'\"'\"'")}'";
  }

  @override
  String linuxScript(String destination, {String distro = 'Ubuntu'}) =>
      '''#!/usr/bin/env bash
set -euo pipefail
# $distro: run these dependency commands yourself after reviewing.
${dependencies(distro).split('\n').map((line) => '# $line').join('\n')}
# Official Valve SteamCMD, installed in your account. No sudo below.
STEAMCMD_DIR="\$HOME/.local/share/dst-launcher/steamcmd"
mkdir -p -- "\$STEAMCMD_DIR"
if ! command -v steamcmd >/dev/null && [ ! -f "\$STEAMCMD_DIR/steamcmd.sh" ]; then
  curl --fail --location --proto '=https' --tlsv1.2 https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz -o "\$STEAMCMD_DIR/steamcmd.tar.gz"
  tar -xzf "\$STEAMCMD_DIR/steamcmd.tar.gz" -C "\$STEAMCMD_DIR"
fi
if command -v steamcmd >/dev/null; then STEAMCMD_BIN="\$(command -v steamcmd)"; else STEAMCMD_BIN="\$STEAMCMD_DIR/steamcmd.sh"; fi
mkdir -p -- ${quote(destination)}
"\$STEAMCMD_BIN" +force_install_dir ${quote(destination)} +login anonymous +app_update 343050 validate +quit
test -x ${quote(path.posix.join(destination, 'bin64/dontstarve_dedicated_server_nullrenderer_x64'))}
ldd ${quote(path.posix.join(destination, 'bin64/dontstarve_dedicated_server_nullrenderer_x64'))}
''';
}

class LocalPortInspector implements PortInspector {
  @override
  Future<Map<int, bool>> inspect(List<int> ports) async {
    final result = <int, bool>{};
    for (final port in ports) {
      RawDatagramSocket? socket;
      try {
        socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
        result[port] = true;
      } on SocketException {
        result[port] = false;
      } finally {
        socket?.close();
      }
    }
    return result;
  }
}
