import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:dst_server_launcher/data/local_repository.dart';
import 'package:dst_server_launcher/data/platform_services.dart';
import 'package:dst_server_launcher/domain/models.dart';

void main() {
  late Directory temp;
  late LocalProfileRepository repo;
  late ServerProfile profile;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('dst repo кириллица ');
    repo = LocalProfileRepository(Directory(p.join(temp.path, 'app')));
    profile = ServerProfile(
      id: 'dst_test',
      name: 'Мир друзей',
      password: 'secretPass',
      installDir: p.join(temp.path, 'server'),
      storageRoot: p.join(temp.path, 'klei'),
      secret: 'secretShardKey',
      portBase: 32000,
    );
  });
  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });
  test(
    'Create cluster atomically; token is not in JSON or export preview',
    () async {
      await repo.create(profile, 'testKleiToken');
      await repo.save([profile]);
      expect(
        await File(p.join(clusterDirectory(profile), 'cluster_token.txt'))
            .readAsString(),
        'testKleiToken',
      );
      expect(
        await File(p.join(repo.appDir.path, 'profiles.json')).readAsString(),
        isNot(contains('testKleiToken')),
      );
      expect((await repo.load()).single.name, 'Мир друзей');
      expect(repo.preview(profile).keys, isNot(contains('cluster_token.txt')));
      await expectLater(
        repo.create(profile, 'otherToken'),
        throwsA(isA<FileSystemException>()),
      );
    },
  );
  test('Recover profile journal after interrupted rename', () async {
    await repo.save([profile]);
    final file = File(p.join(repo.appDir.path, 'profiles.json'));
    await file.rename('${file.path}.previous');
    expect((await repo.load()).single.id, profile.id);
  });
  test('Backups exclude token/password/key and preserve current identity on restore', () async {
    await repo.create(profile, 'testKleiToken');
    final save = File(
      p.join(clusterDirectory(profile), 'Master', 'save', 'session'),
    );
    await save.parent.create(recursive: true);
    await save.writeAsString('first-world');
    final backups = ZipBackupService(repo.appDir);
    final zip = await backups.create(profile);
    final archive = ZipDecoder().decodeBytes(await File(zip).readAsBytes());
    expect(archive.findFile('cluster_token.txt'), isNull);
    final cluster = utf8.decode(
      archive.findFile('cluster.ini')!.content as List<int>,
    );
    expect(cluster, isNot(contains('secretPass')));
    expect(cluster, isNot(contains('secretShardKey')));
    await save.writeAsString('second-world');
    expect(
      await backups.previewRestore(profile, zip),
      contains('Master/save/session'),
    );
    await backups.restore(profile, zip);
    expect(await save.readAsString(), 'first-world');
    expect(
      await File(p.join(clusterDirectory(profile), 'cluster_token.txt'))
          .readAsString(),
      'testKleiToken',
    );
    expect(
      await File(p.join(clusterDirectory(profile), 'cluster.ini'))
          .readAsString(),
      contains('secretPass'),
    );
    expect((await backups.list(profile)).length, 2);
  });
  for (final name in [
    '../escape',
    '/absolute',
    r'C:\escape',
    r'Master\..\escape',
  ]) {
    test('Reject ZIP traversal: $name', () async {
      final archive = Archive()
        ..addFile(ArchiveFile(name, 4, utf8.encode('evil')))
        ..addFile(ArchiveFile('cluster.ini', 0, <int>[]))
        ..addFile(ArchiveFile('launcher-backup.json', 2, utf8.encode('{}')));
      final file = File(p.join(temp.path, 'malicious.zip'));
      await file.writeAsBytes(ZipEncoder().encode(archive));
      await expectLater(
        ZipBackupService(repo.appDir).previewRestore(profile, file.path),
        throwsFormatException,
      );
      expect(await File(p.join(temp.path, 'escape')).exists(), isFalse);
    });
  }
  test('Corrupt ZIP is rejected before existing world changes', () async {
    await repo.create(profile, 'testKleiToken');
    final file = File(p.join(temp.path, 'corrupt.zip'));
    await file.writeAsString('not an archive');
    await expectLater(
      ZipBackupService(repo.appDir).restore(profile, file.path),
      throwsA(anything),
    );
    expect(
      await File(p.join(clusterDirectory(profile), 'cluster.ini')).exists(),
      isTrue,
    );
  });
  test('Mod synchronization preserves foreign Steam install entries', () async {
    await repo.create(profile, 'testKleiToken');
    final setup = File(
      p.join(profile.installDir, 'mods', 'dedicated_server_mods_setup.lua'),
    );
    await setup.parent.create(recursive: true);
    await setup.writeAsString('ServerModSetup("999")\n-- user content\n');
    final updated = profile.withMods([const ModSpec(id: '123', title: 'Test')]);
    await repo.syncMods(updated);
    await repo.syncMods(updated);
    final text = await setup.readAsString();
    expect(text, contains('ServerModSetup("999")'));
    expect('ServerModSetup("123")'.allMatches(text).length, 1);
  });
  test(
    'Steam library needs Dedicated Server manifest, not game manifest',
    () async {
      final root = Directory(p.join(temp.path, 'steam'));
      final server = Directory(
        p.join(root.path, 'steamapps', 'common', 'DST Server'),
      );
      await Directory(p.join(server.path, 'bin64')).create(recursive: true);
      await File(LocalSteamLocator.binary(server.path))
          .writeAsString('fixture');
      final manifest = File(
        p.join(root.path, 'steamapps', 'appmanifest_322330.acf'),
      );
      await manifest.writeAsString('"installdir" "DST Server"');
      expect(
        (await LocalSteamLocator().locate(manual: root.path)).server,
        isNull,
      );
      await manifest.rename(
        p.join(root.path, 'steamapps', 'appmanifest_343050.acf'),
      );
      expect(
        (await LocalSteamLocator().locate(manual: root.path)).server,
        server.path,
      );
    },
  );
  test('Manifest path traversal is ignored', () async {
    final manifest = File(
      p.join(temp.path, 'steamapps', 'appmanifest_343050.acf'),
    );
    await manifest.parent.create(recursive: true);
    await manifest.writeAsString('"installdir" "../escape"');
    expect(
      (await LocalSteamLocator().locate(manual: temp.path)).server,
      isNull,
    );
  });
  test('A running profile cannot be archived', () async {
    await repo.create(profile, 'testKleiToken');
    final backups = ZipBackupService(repo.appDir, active: (_) => true);
    await expectLater(backups.create(profile), throwsStateError);
    expect(await backups.list(profile), isEmpty);
  });
  test(
    'Imported manual mod overrides are never overwritten on launch',
    () async {
      await repo.create(profile, 'testKleiToken');
      final imported = ServerProfile.fromJson({
        ...profile.toJson(),
        'manageMods': false,
      });
      final file = File(
        p.join(clusterDirectory(profile), 'Master', 'modoverrides.lua'),
      );
      await file.writeAsString(
        'return { ["workshop-123"] = { enabled = true, configuration_options = { custom = 7 } } }',
      );
      await repo.syncMods(imported);
      expect(await file.readAsString(), contains('custom = 7'));
    },
  );
  test('Import copies saves and keeps PvP and pause settings', () async {
    final original = ServerProfile.fromJson({
      ...profile.toJson(),
      'pvp': true,
      'pause': false,
    });
    await repo.create(original, 'fixture-token');
    final source = clusterDirectory(original);
    final save = File(p.join(source, 'Master', 'save', 'world'));
    await save.parent.create(recursive: true);
    await save.writeAsString('world fixture');
    final copy = await repo.importCluster(
      source,
      profile.installDir,
      p.join(temp.path, 'copy'),
      34000,
    );
    expect(copy.pvp, isTrue);
    expect(copy.pause, isFalse);
    expect(copy.id, isNot(original.id));
    expect(
      await File(p.join(clusterDirectory(copy), 'Master', 'save', 'world'))
          .readAsString(),
      'world fixture',
    );
    expect(await save.readAsString(), 'world fixture');
  });
  test('Import rejects destination nested inside the source', () async {
    await repo.create(profile, 'testKleiToken');
    final source = clusterDirectory(profile);
    await expectLater(
      repo.importCluster(source, profile.installDir, source, 34000),
      throwsA(isA<FileSystemException>()),
    );
  });
}
