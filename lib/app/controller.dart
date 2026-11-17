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
  String? error;
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
      installation = await locator.locate(
        manual: preferences.getString('installDir'),
      );
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

  Future<void> detect({String? manual}) async {
    busy = true;
    notifyListeners();
    try {
      installation = await locator.locate(
        manual: manual ?? preferences.getString('installDir'),
      );
      if (manual != null && installation.server != null) {
        await preferences.setString('installDir', installation.server!);
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
        'version': '0.1.0',
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
