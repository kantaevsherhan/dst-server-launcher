import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../domain/models.dart';
import '../domain/services.dart';
import 'local_repository.dart';
import 'platform_services.dart';
import 'windows_game_path.dart';

typedef SpawnProcess = Future<Process> Function(
  String executable,
  List<String> arguments,
  String workingDirectory,
);

class ProcessSupervisor extends ChangeNotifier implements DstProcessController {
  ProcessSupervisor(
    this.repository, {
    SpawnProcess? spawn,
    this.stopTimeout = const Duration(seconds: 30),
    this.readyTimeout = const Duration(seconds: 90),
  }) : spawn = spawn ?? _spawn;
  static Future<Process> _spawn(
    String exe,
    List<String> args,
    String workingDirectory,
  ) => Process.start(
    exe,
    args,
    workingDirectory: workingDirectory,
    runInShell: false,
  );
  final SpawnProcess spawn;
  final Duration stopTimeout, readyTimeout;
  final LocalProfileRepository repository;
  final Map<String, Process> _processes = {};
  final Map<String, ShardState> states = {};
  final Map<String, DateTime> started = {};
  final Map<String, List<LogLine>> logs = {};
  final Map<String, List<String>> _secrets = {};
  final Set<String> _locked = {};
  final Set<String> maintenance = {};
  final Map<String, Timer> _readinessTimers = {};
  final Map<String, Future<void>> _logQueues = {};
  bool _disposed = false;
  bool installing = false;
  Future<void> _journalQueue = Future.value();
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final timer in _readinessTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  bool active(ServerProfile profile) =>
      _locked.contains(profile.id) ||
      profile.shards.any(
        (s) => [
          ShardState.starting,
          ShardState.running,
          ShardState.stopping,
          ShardState.attention,
        ].contains(state(profile, s)),
      );
  ShardState state(ServerProfile profile, String shard) =>
      states['${profile.id}/$shard'] ?? ShardState.stopped;
  String redact(String id, String message) {
    var value = message.replaceAll(
      RegExp(r'cluster_token\s*[:=]\s*\S+', caseSensitive: false),
      'cluster_token=[redacted]',
    );
    for (final secret in _secrets[id] ?? <String>[]) {
      if (secret.isNotEmpty) value = value.replaceAll(secret, '[redacted]');
    }
    return value;
  }

  void _log(ServerProfile profile, String shard, String message) {
    final clean = redact(profile.id, message);
    final list = logs.putIfAbsent(profile.id, () => []);
    list.add(LogLine(shard, clean));
    if (list.length > 3000) list.removeRange(0, list.length - 3000);
    final f = File(p.join(repository.appDir.path, 'logs', '${profile.id}.log'));
    _logQueues[profile.id] = (_logQueues[profile.id] ?? Future.value()).then(
      (_) =>
          _append(f, '[${DateTime.now().toIso8601String()}][$shard] $clean\n'),
    );
    notifyListeners();
  }

  Future<void> _append(File file, String text) async {
    try {
      await file.parent.create(recursive: true);
      if (await file.exists() && await file.length() > 4 * 1024 * 1024) {
        final rotated = File(
          '${file.path}.${DateTime.now().microsecondsSinceEpoch}',
        );
        await file.rename(rotated.path);
      }
      await file.writeAsString(text, mode: FileMode.append);
    } on FileSystemException {
      /* Console remains available when disk logging fails. */
    }
  }

  List<String> arguments(ServerProfile profile, String shard) => [
    '-console',
    '-persistent_storage_root',
    gameStoragePath(profile.storageRoot),
    '-conf_dir',
    'DoNotStarveTogether',
    '-cluster',
    profile.id,
    '-shard',
    shard,
    '-monitor_parent_process',
    pid.toString(),
  ];
  @override
  Future<void> start(ServerProfile profile) async {
    if (installing) throw StateError('SteamCMD installation in progress');
    if (maintenance.contains(profile.id)) {
      throw StateError('A backup or restore is in progress');
    }
    if (active(profile) || !_locked.add(profile.id)) {
      throw StateError('Server is already active');
    }
    try {
      profile.validate();
      final exe = LocalSteamLocator.binary(profile.installDir);
      if (!await File(exe).exists()) {
        throw const FileSystemException(
          'DST Dedicated Server binary not found',
        );
      }
      final tokenFile = File(
        p.join(clusterDirectory(profile), 'cluster_token.txt'),
      );
      if (!await tokenFile.exists() ||
          (await tokenFile.readAsString()).trim().isEmpty) {
        throw const FileSystemException('Klei cluster token is missing');
      }
      final token = (await tokenFile.readAsString()).trim();
      _secrets[profile.id] = [token, profile.password, profile.secret];
      final ports = await LocalPortInspector().inspect(profile.ports);
      if (ports.values.contains(false)) {
        throw StateError(
          'UDP ports occupied: ${ports.entries.where((e) => !e.value).map((e) => e.key).join(', ')}',
        );
      }
      await repository.syncMods(profile);
      for (final shard in profile.shards) {
        final key = '${profile.id}/$shard';
        states[key] = ShardState.starting;
        notifyListeners();
        final process = await spawn(
          exe,
          arguments(profile, shard),
          p.dirname(exe),
        );
        _processes[key] = process;
        started[key] = DateTime.now();
        _log(profile, shard, 'PID ${process.pid}');
        void consume(String line) {
          _log(profile, shard, line);
          if ((states[key] == ShardState.starting ||
                  states[key] == ShardState.attention) &&
              RegExp(
                r'Sim (un)?paused|Server registered|DST initialized',
                caseSensitive: false,
              ).hasMatch(line)) {
            _readinessTimers.remove(key)?.cancel();
            states[key] = ShardState.running;
            notifyListeners();
          }
        }

        process.stdout
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter())
            .listen(
              consume,
              onError: (Object _) => _log(profile, shard, 'stdout unavailable'),
            );
        process.stderr
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter())
            .listen(
              consume,
              onError: (Object _) => _log(profile, shard, 'stderr unavailable'),
            );
        unawaited(
          process.exitCode.then((code) async {
            _processes.remove(key);
            _readinessTimers.remove(key)?.cancel();
            final expected = states[key] == ShardState.stopping;
            states[key] = expected || code == 0
                ? ShardState.stopped
                : ShardState.crashed;
            _log(profile, shard, 'Exit: $code');
            await _journal();
          }),
        );
        _readinessTimers[key] = Timer(readyTimeout, () {
          if (states[key] == ShardState.starting) {
            states[key] = ShardState.attention;
            _log(
              profile,
              shard,
              'Readiness not confirmed after 90s. Check token, mods, network and shard logs.',
            );
          }
        });
      }
      await _journal();
    } catch (_) {
      // Roll back a partial Master/Caves start; never silently force-kill.
      for (final shard in profile.shards) {
        final key = '${profile.id}/$shard';
        final process = _processes[key];
        if (process != null) {
          states[key] = ShardState.stopping;
          process.stdin.writeln('c_shutdown(true)');
          await process.stdin.flush();
        } else {
          states[key] = ShardState.stopped;
        }
      }
      notifyListeners();
      rethrow;
    } finally {
      _locked.remove(profile.id);
    }
  }

  Future<void> _journal() {
    final snapshot = jsonEncode({
      for (final e in _processes.entries) e.key: e.value.pid,
    });
    final task = _journalQueue.then(
      (_) => atomicWrite(
        File(p.join(repository.appDir.path, 'processes.json')),
        snapshot,
      ),
    );
    _journalQueue = task.catchError((Object _) {});
    return task;
  }

  Future<void> reconcile(List<ServerProfile> profiles) async {
    final file = File(p.join(repository.appDir.path, 'processes.json'));
    if (!await file.exists()) return;
    final entries = Map<String, dynamic>.from(
      jsonDecode(await file.readAsString()),
    );
    for (final profile in profiles) {
      for (final shard in profile.shards) {
        final key = '${profile.id}/$shard';
        final value = entries[key];
        if (value is! int || value <= 0) continue;
        String command = '';
        if (Platform.isWindows) {
          final r = await Process.run('powershell.exe', [
            '-NoProfile',
            '-NonInteractive',
            '-Command',
            '(Get-CimInstance Win32_Process -Filter "ProcessId = $value").CommandLine',
          ]);
          if (r.exitCode == 0) command = r.stdout.toString();
        } else {
          final proc = File('/proc/$value/cmdline');
          if (await proc.exists()) command = await proc.readAsString();
        }
        if (command.contains(profile.id) &&
            command.contains('dontstarve_dedicated_server') &&
            command.contains(shard)) {
          states[key] = ShardState.attention;
          _log(
            profile,
            shard,
            'Existing PID $value detected. Console cannot be reattached. Stop it in the OS before starting here.',
          );
        }
      }
    }
    notifyListeners();
  }

  @override
  Future<bool> stop(ServerProfile profile) async {
    final owned = <Process>[];
    for (final shard in profile.shards) {
      final key = '${profile.id}/$shard';
      final process = _processes[key];
      if (process == null) {
        if (state(profile, shard) == ShardState.attention) {
          throw StateError(
            'Existing external process: stop it in the OS, then restart the launcher',
          );
        }
        continue;
      }
      states[key] = ShardState.stopping;
      owned.add(process);
      process.stdin.writeln('c_shutdown(true)');
      await process.stdin.flush();
    }
    notifyListeners();
    try {
      await Future.wait(owned.map((process) => process.exitCode))
          .timeout(stopTimeout);
      await flushLogs();
      return true;
    } on TimeoutException {
      return false;
    }
  }

  Future<void> flushLogs() async {
    await _journalQueue;
    await Future.wait(_logQueues.values.toList());
  }

  @override
  Future<void> forceStop(ServerProfile profile) async {
    for (final shard in profile.shards) {
      final process = _processes['${profile.id}/$shard'];
      if (process != null) process.kill(ProcessSignal.sigkill);
    }
  }

  Future<void> saveWorld(ServerProfile profile) async {
    for (final shard in profile.shards) {
      final process = _processes['${profile.id}/$shard'];
      if (process != null) {
        process.stdin.writeln('c_save()');
        await process.stdin.flush();
      }
    }
  }
}
