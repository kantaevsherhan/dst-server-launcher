import 'models.dart';

abstract interface class SteamLocator {
  Future<Installation> locate({String? manual});
}

abstract interface class ClusterConfigRepository {
  Future<List<ServerProfile>> load();
  Future<void> save(List<ServerProfile> profiles);
  Future<void> create(ServerProfile profile, String token);
  Map<String, String> preview(ServerProfile profile);
}

abstract interface class WorkshopRepository {
  Future<List<ModSpec>> resolve(String input);
}

abstract interface class PortInspector {
  Future<Map<int, bool>> inspect(List<int> ports);
}

abstract interface class BackupService {
  Future<String> create(ServerProfile profile);
  Future<List<String>> list(ServerProfile profile);
  Future<List<String>> previewRestore(ServerProfile profile, String path);
  Future<void> restore(ServerProfile profile, String path);
}

abstract interface class ServerInstaller {
  String linuxScript(String path);
}

abstract interface class DstProcessController {
  Future<void> start(ServerProfile profile);
  Future<bool> stop(ServerProfile profile);
  Future<void> forceStop(ServerProfile profile);
}
