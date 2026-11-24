import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local_repository.dart';
import '../data/platform_services.dart';
import '../data/process_supervisor.dart';
import '../data/workshop_service.dart';
import '../domain/models.dart';

class LauncherController extends ChangeNotifier {
  LauncherController(this.repository, this.preferences)
    : supervisor = ProcessSupervisor(repository) {
    supervisor.addListener(notifyListeners);
  }
  final LocalProfileRepository repository;
  final SharedPreferences preferences;
  final ProcessSupervisor supervisor;
  late final ZipBackupService backups = ZipBackupService(
    repository.appDir,
    active: supervisor.active,
    maintenance: supervisor.maintenance,
  );
  final workshop = SteamWorkshopRepository();
  final locator = LocalSteamLocator();
  List<ServerProfile> profiles = [];
  Installation installation = const Installation();
  bool busy = false;
  bool get installing => supervisor.installing;
  String installOutput = '';

  Future<void> installLinux(String destination, String script) async {
    if (!Platform.isLinux ||
        installing ||
        profiles.any(supervisor.active) ||
        supervisor.maintenance.isNotEmpty) {
      throw StateError(
        'Stop active worlds and wait for any installation or maintenance to finish.',
      );
    }
    supervisor.installing = true;
    installOutput = '';
    notifyListeners();
    try {
      final process = await Process.start('/bin/bash', [
        '-s',
      ], runInShell: false);
      Future<void> drain(Stream<List<int>> stream) async {
        await for (final chunk in stream.transform(
          const Utf8Decoder(allowMalformed: true),
        )) {
          final text = installOutput + chunk;
          installOutput = text.length > 3000
              ? text.substring(text.length - 3000)
              : text;
          notifyListeners();
        }
      }

      final streams = Future.wait([
        drain(process.stdout),
        drain(process.stderr),
      ]);
      process.stdin.add(utf8.encode(script));
      await process.stdin.close();
      final code = await process.exitCode;
      await streams;
      if (code != 0) {
        throw StateError(
          'SteamCMD installer exited with code $code.\n$installOutput',
        );
      }
      await detect(manual: destination);
    } finally {
      supervisor.installing = false;
      notifyListeners();
    }
  }

  String? error;
  TargetPlatformOS get targetSystem =>
      TargetPlatformOS.values.asNameMap()[preferences.getString(
        'targetSystem',
      )] ??
      TargetPlatformOS.host;

  bool get localTarget => targetSystem == TargetPlatformOS.host;

  Future<void> setTargetSystem(TargetPlatformOS value) async {
    await preferences.setString('targetSystem', value.name);
    notifyListeners();
  }

  String get language => preferences.getString('language') ?? 'ru';
  ThemeMode get themeMode => preferences.getString('theme') == 'light'
      ? ThemeMode.light
      : ThemeMode.dark;
  String get storageRoot =>
      preferences.getString('storageRoot') ??
      p.join(repository.appDir.path, 'Klei');
  Future<void> initialize() async {
    try {
      profiles = await repository.load();
      await supervisor.reconcile(profiles);
      installation = await _locatePreferred();
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    await preferences.setString('language', value);
    notifyListeners();
  }

  Future<void> setTheme(String value) async {
    await preferences.setString('theme', value);
    notifyListeners();
  }

  Future<void> setStorageRoot(String value) async {
    await preferences.setString('storageRoot', value);
    notifyListeners();
  }

  Future<Installation> _locatePreferred() async {
    final automatic = await locator.locate();
    final saved = preferences.getString('installDir');
    if (saved == null) return automatic;
    final preferred = await locator.locate(manual: saved);
    if (preferred.server == null) return automatic;
    return Installation(
      steam: automatic.steam,
      steamCmd: automatic.steamCmd,
      server: preferred.server,
      build: preferred.build,
      notes: preferred.notes,
    );
  }

  Future<void> detect({String? manual}) async {
    busy = true;
    notifyListeners();
    try {
      if (manual == null) {
        installation = await _locatePreferred();
      } else {
        final selected = await locator.locate(manual: manual);
        if (selected.server == null) {
          throw FormatException(selected.notes.join('\n'));
        }
        await preferences.setString('installDir', selected.server!);
        installation = Installation(
          steam: installation.steam ?? selected.steam,
          steamCmd: installation.steamCmd ?? selected.steamCmd,
          server: selected.server,
          build: selected.build,
        );
      }
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  int nextPort() {
    var candidate = 10999;
    final used = profiles.expand((e) => e.ports).toSet();
    while (List.generate(7, (i) => candidate + i).any(used.contains)) {
      candidate += 10;
    }
    return candidate;
  }

  Future<void> create(ServerProfile profile, String token) async {
    await repository.create(profile, token);
    final next = [...profiles, profile];
    await repository.save(next);
    profiles = next;
    await preferences.remove('wizardDraft');
    notifyListeners();
  }

  Future<void> updateMods(ServerProfile profile, List<ModSpec> mods) async {
    if (!profile.manageMods || supervisor.maintenance.contains(profile.id)) {
      throw StateError(
        'Imported mod configuration is preserved; use manual files or create a GUI-managed profile',
      );
    }
    if (supervisor.active(profile)) {
      throw StateError('Stop both shards before changing mods');
    }
    final updated = profile.withMods(mods);
    await repository.syncMods(updated);
    final next = profiles.map((v) => v.id == updated.id ? updated : v).toList();
    await repository.save(next);
    profiles = next;
    notifyListeners();
  }

  Future<void> importCluster(String path) async {
    if (installation.server == null) {
      throw StateError('Select DST Dedicated Server installation first');
    }
    final profile = await repository.importCluster(
      path,
      installation.server!,
      storageRoot,
      nextPort(),
    );
    final next = [...profiles, profile];
    await repository.save(next);
    profiles = next;
    notifyListeners();
  }

  Future<String> diagnostics() async {
    final file = File(
      p.join(
        repository.appDir.path,
        'diagnostics-${DateTime.now().millisecondsSinceEpoch}.json',
      ),
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'version': '0.2.1',
        'os': Platform.operatingSystem,
        'steamDetected': installation.steam != null,
        'serverDetected': installation.server != null,
        'build': installation.build,
        'profiles': profiles
            .map(
              (v) => {
                'id': v.id,
                'slots': v.slots,
                'caves': v.caves,
                'modCount': v.mods.length,
                'ports': v.ports,
                'states': {
                  for (final s in v.shards) s: supervisor.state(v, s).name,
                },
              },
            )
            .toList(),
        'externalReachability': 'not_verified',
      }),
    );
    return file.path;
  }
}
