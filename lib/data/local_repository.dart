import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../domain/models.dart';
import '../domain/services.dart';
import 'config_generator.dart';

Future<void> atomicWrite(File file, String content) async {
  await file.parent.create(recursive: true);
  final temp = File('${file.path}.tmp');
  await temp.writeAsString(content, flush: true);
  // Windows cannot rename over an existing target. Keep a recoverable journal.
  final previous = File('${file.path}.previous');
  if (!await file.exists() && await previous.exists()) {
    await previous.rename(file.path);
  }
  if (await previous.exists()) await previous.delete();
  if (await file.exists()) await file.rename(previous.path);
  try {
    await temp.rename(file.path);
  } catch (_) {
    if (await previous.exists()) await previous.rename(file.path);
    rethrow;
  }
  if (await previous.exists()) await previous.delete();
}

Future<void> privateFile(File file) async {
  final result = Platform.isWindows
      ? await Process.run('icacls.exe', [
          file.path,
          '/inheritance:r',
          '/grant:r',
          '${Platform.environment['USERDOMAIN']}\\${Platform.environment['USERNAME']}:(F)',
        ])
      : await Process.run('chmod', ['600', file.path]);
  if (result.exitCode != 0) {
    throw const FileSystemException(
      'Could not restrict secret file permissions',
    );
  }
}

String clusterDirectory(ServerProfile profile) =>
    p.join(profile.storageRoot, 'DoNotStarveTogether', profile.id);

class LocalProfileRepository implements ClusterConfigRepository {
  LocalProfileRepository(this.appDir);
  final Directory appDir;
  final generator = ClusterConfigGenerator();
  @override
  Future<List<ServerProfile>> load() async {
    var file = File(p.join(appDir.path, 'profiles.json'));
    if (!await file.exists() && await File('${file.path}.previous').exists()) {
      file = File('${file.path}.previous');
    }
    if (!await file.exists()) return [];
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    if (json['version'] != 1) {
      throw const FormatException('Unsupported profile database version');
    }
    return (json['profiles'] as List)
        .map((j) => ServerProfile.fromJson(j))
        .toList();
  }

  @override
  Future<void> save(List<ServerProfile> profiles) async {
    final file = File(p.join(appDir.path, 'profiles.json'));
    await atomicWrite(
      file,
      const JsonEncoder.withIndent('  ').convert({
        'version': 1,
        'profiles': profiles.map((v) => v.toJson()).toList(),
      }),
    );
    await privateFile(file);
  }

  @override
  Map<String, String> preview(ServerProfile profile) =>
      generator.generate(profile);
  @override
  Future<void> create(ServerProfile profile, String token) async {
    profile.validate();
    if (token.trim().isEmpty || RegExp(r'[\r\n\x00]').hasMatch(token)) {
      throw const FormatException('Invalid Klei token');
    }
    if (!p.isAbsolute(profile.storageRoot) ||
        !p.isAbsolute(profile.installDir)) {
      throw const FormatException('Absolute paths required');
    }
    final dir = Directory(clusterDirectory(profile));
    if (await dir.exists()) {
      throw const FileSystemException('Cluster already exists');
    }
    final staging = Directory('${dir.path}.staging');
    if (await staging.exists()) {
      throw const FileSystemException(
        'Incomplete cluster exists; inspect staging folder',
      );
    }
    await staging.create(recursive: true);
    for (final entry in preview(profile).entries) {
      await atomicWrite(File(p.join(staging.path, entry.key)), entry.value);
    }
    final tokenFile = File(p.join(staging.path, 'cluster_token.txt'));
    await tokenFile.writeAsString(token.trim(), flush: true);
    await privateFile(tokenFile);
    await staging.rename(dir.path);
  }

  Future<void> syncMods(ServerProfile profile) async {
    for (final entry
        in generator
            .generate(profile)
            .entries
            .where((e) => e.key.endsWith('modoverrides.lua'))) {
      final file = File(p.join(clusterDirectory(profile), entry.key));
      if (await file.exists()) await file.copy('${file.path}.bak');
      await atomicWrite(file, entry.value);
    }
    final setup = File(
      p.join(profile.installDir, 'mods', 'dedicated_server_mods_setup.lua'),
    );
    final old = await setup.exists() ? await setup.readAsString() : '';
    final additions = generator
        .workshopSetup(profile.mods)
        .split('\n')
        .where((line) => line.isNotEmpty && !old.contains(line))
        .join('\n');
    if (additions.isNotEmpty) {
      if (await setup.exists()) {
        await setup.copy('${setup.path}.launcher-backup');
      }
      await atomicWrite(
        setup,
        '$old\n-- Added by DST Server Launcher; existing entries preserved\n$additions\n',
      );
    }
  }

  Future<ServerProfile> importCluster(
    String source,
    String installDir,
    String storageRoot,
    int portBase,
  ) async {
    final dir = Directory(source);
    if (!await File(p.join(source, 'cluster.ini')).exists()) {
      throw const FormatException('cluster.ini not found');
    }
    final ini = await File(p.join(source, 'cluster.ini')).readAsString();
    String? value(String key) => RegExp(
      '^${RegExp.escape(key)}\\s*=\\s*(.*)\$',
      multiLine: true,
    ).firstMatch(ini)?[1]?.trim();
    final profile = ServerProfile(
      id: ServerProfile.newId(),
      name: value('cluster_name') ?? p.basename(source),
      description: value('cluster_description') ?? '',
      password: value('cluster_password') ?? '',
      installDir: installDir,
      storageRoot: storageRoot,
      secret: ServerProfile.randomKey(),
      portBase: portBase,
      slots: int.tryParse(value('max_players') ?? '') ?? 6,
      caves: await Directory(p.join(source, 'Caves')).exists(),
      mode: value('game_mode') ?? 'survival',
    );
    profile.validate();
    final target = Directory(clusterDirectory(profile));
    await target.create(recursive: true);
    // Preserve saves and custom overrides; reject symlinks, never mutate source.
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is Link) {
        throw const FormatException('Symlinks are not imported');
      }
      final relative = p.relative(entity.path, from: source);
      if (entity is Directory) {
        await Directory(p.join(target.path, relative)).create(recursive: true);
      }
      if (entity is File) {
        final f = File(p.join(target.path, relative));
        await f.parent.create(recursive: true);
        await entity.copy(f.path);
      }
    }
    // New identity and ports prevent collision with original. Preserve world files.
    for (final entry
        in generator
            .generate(profile)
            .entries
            .where((e) => e.key.endsWith('.ini'))) {
      await atomicWrite(File(p.join(target.path, entry.key)), entry.value);
    }
    final token = File(p.join(target.path, 'cluster_token.txt'));
    if (await token.exists()) await privateFile(token);
    return profile;
  }
}

class ZipBackupService implements BackupService {
  ZipBackupService(this.root);
  final Directory root;
  Directory _dir(ServerProfile profile) =>
      Directory(p.join(root.path, 'backups', profile.id));
  @override
  Future<String> create(ServerProfile profile) async {
    final archive = Archive();
    final cluster = Directory(clusterDirectory(profile));
    await for (final entity in cluster.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final relative = p
          .relative(entity.path, from: cluster.path)
          .replaceAll('\\', '/');
      if (p.basename(relative) == 'cluster_token.txt' ||
          relative.endsWith('.tmp') ||
          relative.endsWith('.previous') ||
          relative.endsWith('.bak') ||
          relative.endsWith('_log.txt') ||
          relative.endsWith('.log')) {
        continue;
      }
      // Password and shard key are secrets too; never export them.
      var bytes = await entity.readAsBytes();
      if (relative == 'cluster.ini') {
        bytes = utf8.encode(
          utf8
              .decode(bytes)
              .replaceAllMapped(
                RegExp(
                  r'^(cluster_password|cluster_key)\s*=.*$',
                  multiLine: true,
                ),
                (m) => '${m[1]} =',
              ),
        );
      }
      archive.addFile(ArchiveFile(relative, bytes.length, bytes));
    }
    final metadata = utf8.encode(
      jsonEncode({
        'format': 1,
        'created': DateTime.now().toUtc().toIso8601String(),
        'cluster': profile.id,
        'secrets': false,
      }),
    );
    archive.addFile(
      ArchiveFile('launcher-backup.json', metadata.length, metadata),
    );
    final dir = _dir(profile);
    await dir.create(recursive: true);
    final file = File(
      p.join(dir.path, '${DateTime.now().microsecondsSinceEpoch}.zip'),
    );
    final bytes = await Isolate.run(() => ZipEncoder().encode(archive));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<List<String>> list(ServerProfile profile) async {
    final dir = _dir(profile);
    if (!await dir.exists()) return [];
    return (await dir
          .list()
          .where((e) => e is File && e.path.endsWith('.zip'))
          .map((e) => e.path)
          .toList())
      ..sort((a, b) => b.compareTo(a));
  }

  Future<Archive> _read(String file) async {
    if (await File(file).length() > 512 * 1024 * 1024) {
      throw const FormatException('Archive exceeds 512 MiB');
    }
    final archive = ZipDecoder().decodeBytes(
      await File(file).readAsBytes(),
      verify: true,
    );
    var total = 0;
    for (final entry in archive) {
      total += entry.size;
      if (total > 2 * 1024 * 1024 * 1024) {
        throw const FormatException('Expanded archive exceeds 2 GiB');
      }
      final name = entry.name.replaceAll('\\', '/');
      if (name.startsWith('/') ||
          name.split('/').contains('..') ||
          name.contains(':') ||
          entry.isSymbolicLink) {
        throw const FormatException('Unsafe archive path');
      }
      if (name == 'cluster_token.txt') {
        throw const FormatException('Archive contains a secret token');
      }
    }
    if (archive.findFile('launcher-backup.json') == null ||
        archive.findFile('cluster.ini') == null) {
      throw const FormatException('Not a launcher backup');
    }
    return archive;
  }

  @override
  Future<List<String>> previewRestore(
    ServerProfile profile,
    String path,
  ) async =>
      (await _read(path)).files
          .where((e) => e.isFile && e.name != 'launcher-backup.json')
          .map((e) => e.name)
          .toList();
  @override
  Future<void> restore(ServerProfile profile, String file) async {
    final archive = await _read(file);
    // Validate fully before making the safety snapshot or changing any data.
    await create(profile);
    final current = Directory(clusterDirectory(profile));
    final stage = Directory(
      '${current.path}.restore_${DateTime.now().microsecondsSinceEpoch}',
    );
    await stage.create(recursive: true);
    for (final entry in archive) {
      if (!entry.isFile ||
          entry.name == 'launcher-backup.json' ||
          entry.name == 'cluster.ini') {
        continue;
      }
      final dest = File(p.join(stage.path, entry.name));
      await dest.parent.create(recursive: true);
      await dest.writeAsBytes(entry.content as List<int>);
    }
    // Keep current identity, network settings and secrets. Restore world data.
    for (final name in ['cluster.ini', 'cluster_token.txt']) {
      final src = File(p.join(current.path, name));
      if (await src.exists()) await src.copy(p.join(stage.path, name));
    }
    for (final shard in profile.shards) {
      final src = File(p.join(current.path, shard, 'server.ini'));
      if (await src.exists()) {
        await Directory(p.join(stage.path, shard)).create(recursive: true);
        await src.copy(p.join(stage.path, shard, 'server.ini'));
      }
    }
    final token = File(p.join(stage.path, 'cluster_token.txt'));
    if (await token.exists()) await privateFile(token);
    final previous =
        '${current.path}.before_restore_${DateTime.now().microsecondsSinceEpoch}';
    await current.rename(previous);
    try {
      await stage.rename(current.path);
    } catch (_) {
      await Directory(previous).rename(current.path);
      rethrow;
    }
  }
}
