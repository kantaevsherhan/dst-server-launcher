import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dst_server_launcher/domain/models.dart';
import 'package:dst_server_launcher/data/config_generator.dart';
import 'package:dst_server_launcher/data/platform_services.dart';
import 'package:dst_server_launcher/data/workshop_service.dart';

ServerProfile fixture({
  bool caves = true,
  List<ModSpec> mods = const [],
  int port = 10999,
}) => ServerProfile(
  id: 'dst_fixture',
  name: 'Лесная компания',
  description: 'Friends',
  installDir: '/tmp/server',
  storageRoot: '/tmp/klei',
  secret: 'abcdef123',
  portBase: port,
  caves: caves,
  mods: mods,
);

void main() {
  test('Master and Caves have distinct official ports and presets', () {
    final profile = fixture();
    final files = ClusterConfigGenerator().generate(profile);
    expect(files['cluster.ini'], contains('shard_enabled = true'));
    expect(files['Master/server.ini'], contains('server_port = 10999'));
    expect(files['Caves/server.ini'], contains('server_port = 11000'));
    expect(files['Caves/server.ini'], contains('is_master = false'));
    expect(files['Caves/worldgenoverride.lua'], contains('DST_CAVE'));
    expect(profile.ports.toSet().length, profile.ports.length);
    expect(files.keys.any((v) => v.contains('token')), isFalse);
  });
  test('Large UI size uses the actual engine identifier default', () {
    final profile = ServerProfile.fromJson({
      ...fixture().toJson(),
      'worldSize': 'large',
    });
    expect(
      ClusterConfigGenerator().generate(profile)['Master/worldgenoverride.lua'],
      contains('world_size = "default"'),
    );
  });
  test('No caves means one shard and no Caves files', () {
    final files = ClusterConfigGenerator().generate(fixture(caves: false));
    expect(files.keys.any((v) => v.startsWith('Caves/')), isFalse);
    expect(files['cluster.ini'], contains('shard_enabled = false'));
  });
  test('Download and shard enablement are independent', () {
    final profile = fixture(
      mods: [const ModSpec(id: '123', title: 'Mod', caves: false)],
    );
    final gen = ClusterConfigGenerator();
    final files = gen.generate(profile);
    expect(gen.workshopSetup(profile.mods), contains('ServerModSetup("123")'));
    expect(files['Master/modoverrides.lua'], contains('["workshop-123"]'));
    expect(files['Caves/modoverrides.lua'], isNot(contains('workshop-123')));
  });
  for (final field in [
    'id',
    'name',
    'description',
    'password',
    'mode',
    'worldSize',
    'secret',
  ]) {
    test('Reject untrusted $field', () {
      final j = fixture().toJson();
      j[field] = field == 'id' ? '../escape' : 'invalid\nvalue';
      expect(() => ServerProfile.fromJson(j).validate(), throwsFormatException);
    });
  }
  for (final slots in [0, 65, -1]) {
    test('Reject invalid slots $slots', () {
      expect(
        () =>
            ServerProfile.fromJson({...fixture().toJson(), 'slots': slots})
                .validate(),
        throwsFormatException,
      );
    });
  }
  test('Cluster IDs are safe, unique, and independent of display name', () {
    final ids = List.generate(100, (_) => ServerProfile.newId());
    expect(ids.toSet().length, 100);
    expect(ids.every((v) => RegExp(r'^dst_[a-z0-9_]+$').hasMatch(v)), isTrue);
  });
  for (final input in [
    '12345',
    'https://steamcommunity.com/sharedfiles/filedetails/?id=12345&searchtext=foo',
  ]) {
    test(
      'Parse Workshop $input',
      () => expect(SteamWorkshopRepository.parseId(input), '12345'),
    );
  }
  for (final input in [
    '0',
    '-1',
    'abc',
    'https://evil.com/?id=123',
    'https://steamcommunity.com.evil.com/sharedfiles/filedetails/?id=123',
    'http://steamcommunity.com/sharedfiles/filedetails/?id=123',
    'https://steamcommunity.com/sharedfiles/filedetails/?id=abc',
  ]) {
    test(
      'Reject Workshop $input',
      () => expect(
        () => SteamWorkshopRepository.parseId(input),
        throwsFormatException,
      ),
    );
  }
  for (final distro in LinuxCommands.distributions) {
    test('Generate safe official SteamCMD script for $distro', () {
      final script = LinuxCommands(
        File('scripts/linux/install-dst-server.sh').readAsStringSync(),
      ).linuxScript("/home/друзья/server's world", distro: distro);
      expect(script, contains("'\"'\"'"));
      expect(script, contains('+app_update 343050 validate'));
      expect(
        script.split('\n').any((line) => line.startsWith('sudo ')),
        isFalse,
      );
      expect(script, contains('steamcdn-a.akamaihd.net'));
    });
  }
  test('Detect the requested Linux families', () {
    expect(LinuxCommands.distribution('ID=debian\n'), 'Debian');
    expect(LinuxCommands.distribution('ID="linuxmint"\n'), 'Linux Mint');
    expect(LinuxCommands.distribution('ID=manjaro\n'), 'Manjaro');
    expect(LinuxCommands.distribution('ID=fedora\n'), 'Fedora');
  });
  test(
    'Reject newline in shell path',
    () =>
        expect(() => LinuxCommands.quote('/tmp/a\nrm'), throwsFormatException),
  );
  test('VDF multiple libraries support escaped Windows paths', () {
    expect(
      LocalSteamLocator.libraries(
        r'"path" "C:\\Program Files (x86)\\Steam" "path" "D:\\Игры\\SteamLibrary"',
      ),
      [r'C:\Program Files (x86)\Steam', r'D:\Игры\SteamLibrary'],
    );
    expect(
      LocalSteamLocator.installFolder('"installdir" "DST Server"'),
      'DST Server',
    );
  });
  test('RU/EN ARB keys match and UI keys exist', () {
    final ru = jsonDecode(File('l10n/app_ru.arb').readAsStringSync()) as Map;
    final en = jsonDecode(File('l10n/app_en.arb').readAsStringSync()) as Map;
    expect(ru.keys.toSet(), en.keys.toSet());
    for (final f
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((v) => v.path.endsWith('.dart'))) {
      for (final m in RegExp(
        r"\.t\('([^']+)'\)",
      ).allMatches(f.readAsStringSync())) {
        expect(ru.containsKey(m[1]), isTrue, reason: '${f.path}: ${m[1]}');
      }
    }
  });
}
