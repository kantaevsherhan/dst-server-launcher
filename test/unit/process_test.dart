import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:dst_server_launcher/data/local_repository.dart';
import 'package:dst_server_launcher/data/platform_services.dart';
import 'package:dst_server_launcher/data/process_supervisor.dart';
import 'package:dst_server_launcher/domain/models.dart';

class FakeDstProcess implements Process {
  final output = StreamController<List<int>>();
  final errors = StreamController<List<int>>();
  final input = StreamController<List<int>>();
  final completion = Completer<int>();
  final List<String> commands = [];
  late final sink = IOSink(input.sink);
  bool graceful = true, killed = false;
  FakeDstProcess() {
    input.stream.transform(utf8.decoder).listen((text) {
      commands.add(text);
      if (graceful && text.contains('c_shutdown(true)')) exit(0);
    });
  }
  void line(String text) => output.add(utf8.encode('$text\n'));
  void exit(int code) {
    if (!completion.isCompleted) {
      completion.complete(code);
      unawaited(output.close());
      unawaited(errors.close());
      unawaited(input.close());
    }
  }

  @override
  int get pid => 999999;
  @override
  Stream<List<int>> get stdout => output.stream;
  @override
  Stream<List<int>> get stderr => errors.stream;
  @override
  IOSink get stdin => sink;
  @override
  Future<int> get exitCode => completion.future;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    exit(-1);
    return true;
  }
}

void main() {
  late Directory temp;
  late LocalProfileRepository repo;
  late ServerProfile profile;
  late ProcessSupervisor supervisor;
  late List<FakeDstProcess> spawned;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('dst-process-');
    repo = LocalProfileRepository(Directory(p.join(temp.path, 'app')));
    profile = ServerProfile(
      id: 'dst_process',
      name: 'Test',
      installDir: p.join(temp.path, 'server'),
      storageRoot: p.join(temp.path, 'klei'),
      secret: 'shardSecret',
      portBase: 43000,
    );
    final exe = File(LocalSteamLocator.binary(profile.installDir));
    await exe.parent.create(recursive: true);
    await exe.writeAsString('fixture');
    await repo.create(profile, 'privateToken');
    spawned = [];
    supervisor = ProcessSupervisor(
      repo,
      stopTimeout: const Duration(milliseconds: 30),
      spawn: (exe, args, cwd) async {
        expect(
          args,
          containsAll([
            '-cluster',
            profile.id,
            '-shard',
            '-persistent_storage_root',
          ]),
        );
        expect(cwd, p.join(profile.installDir, 'bin64'));
        final fake = FakeDstProcess();
        spawned.add(fake);
        return fake;
      },
    );
  });
  tearDown(() async {
    for (final fake in spawned) {
      fake.exit(0);
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    supervisor.dispose();
    if (await temp.exists()) await temp.delete(recursive: true);
  });
  test('Two shards start but readiness waits for real log output; duplicate blocked', () async {
    await supervisor.start(profile);
    expect(spawned.length, 2);
    expect(supervisor.state(profile, 'Master'), ShardState.starting);
    await expectLater(supervisor.start(profile), throwsStateError);
    spawned.first.line('Sim paused');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(supervisor.state(profile, 'Master'), ShardState.running);
    expect(await supervisor.stop(profile), isTrue);
    expect(
      spawned.every(
        (v) => v.commands.any((s) => s.contains('c_shutdown(true)')),
      ),
      isTrue,
    );
  });
  test('A slow shard can confirm readiness after the timeout', () async {
    supervisor.dispose();
    supervisor = ProcessSupervisor(
      repo,
      readyTimeout: const Duration(milliseconds: 10),
      spawn: (_, _, _) async {
        final fake = FakeDstProcess();
        spawned.add(fake);
        return fake;
      },
    );
    await supervisor.start(profile);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(supervisor.state(profile, 'Master'), ShardState.attention);
    spawned.first.line('Server registered');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(supervisor.state(profile, 'Master'), ShardState.running);
  });
  test('Save and restart operate on both owned shards', () async {
    await supervisor.start(profile);
    await supervisor.saveWorld(profile);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      spawned.every((p) => p.commands.any((s) => s.contains('c_save()'))),
      isTrue,
    );
    expect(await supervisor.stop(profile), isTrue);
    await supervisor.start(profile);
    expect(spawned.length, 4);
    expect(supervisor.active(profile), isTrue);
  });

  test('Crash is not reported as running', () async {
    await supervisor.start(profile);
    spawned.first.exit(1);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(supervisor.state(profile, 'Master'), ShardState.crashed);
  });
  test('Shutdown timeout never automatically force kills', () async {
    await supervisor.start(profile);
    for (final fake in spawned) {
      fake.graceful = false;
    }
    expect(await supervisor.stop(profile), isFalse);
    expect(spawned.any((v) => v.killed), isFalse);
    await supervisor.forceStop(profile);
    expect(spawned.every((v) => v.killed), isTrue);
  });
  test('Klei token and cluster password/key are masked in console', () async {
    await supervisor.start(profile);
    spawned.first.line('privateToken shardSecret cluster_token=anotherToken');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final text = supervisor.logs[profile.id]!.map((v) => v.message).join();
    expect(text, isNot(contains('privateToken')));
    expect(text, isNot(contains('shardSecret')));
    expect(text, isNot(contains('anotherToken')));
  });
  test('Without token no process starts', () async {
    await File(p.join(clusterDirectory(profile), 'cluster_token.txt')).delete();
    await expectLater(
      supervisor.start(profile),
      throwsA(isA<FileSystemException>()),
    );
    expect(spawned, isEmpty);
  });
  test(
    'Start is blocked while a backup or restore holds the profile',
    () async {
      supervisor.maintenance.add(profile.id);
      await expectLater(supervisor.start(profile), throwsStateError);
      expect(spawned, isEmpty);
      supervisor.maintenance.clear();
    },
  );
}
