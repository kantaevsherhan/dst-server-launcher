import '../domain/models.dart';

class ClusterConfigGenerator {
  Map<String, String> generate(ServerProfile p) {
    p.validate();
    final result = <String, String>{
      'cluster.ini':
          '''[GAMEPLAY]
game_mode = ${p.mode}
max_players = ${p.slots}
pvp = ${p.pvp}
pause_when_empty = ${p.pause}

[NETWORK]
cluster_name = ${p.name}
cluster_description = ${p.description}
cluster_password = ${p.password}
cluster_intention = cooperative
lan_only_cluster = false
offline_cluster = false

[MISC]
console_enabled = true

[SHARD]
shard_enabled = ${p.caves}
bind_ip = 127.0.0.1
master_ip = 127.0.0.1
master_port = ${p.portBase + 6}
cluster_key = ${p.secret}
''',
    };
    for (final shard in p.shards) {
      final master = shard == 'Master';
      result['$shard/server.ini'] =
          '''[NETWORK]
server_port = ${p.portBase + (master ? 0 : 1)}

[SHARD]
is_master = $master
name = $shard
id = ${master ? 1 : 2}

[STEAM]
master_server_port = ${p.portBase + (master ? 2 : 4)}
authentication_port = ${p.portBase + (master ? 3 : 5)}
''';
      result['$shard/worldgenoverride.lua'] =
          '''return {
  override_enabled = true,
  preset = "${master ? 'SURVIVAL_TOGETHER' : 'DST_CAVE'}",
  overrides = { world_size = "${p.worldSize == 'large' ? 'default' : p.worldSize}" },
}
''';
      result['$shard/modoverrides.lua'] =
          'return {\n${p.mods.where((m) => !m.collection && (master ? m.master : m.caves)).map((m) => '  ["workshop-${m.id}"] = { enabled = true, configuration_options = {} },').join('\n')}\n}\n';
    }
    return result;
  }

  String workshopSetup(List<ModSpec> mods) =>
      '${mods.map((m) => '${m.collection ? 'ServerModCollectionSetup' : 'ServerModSetup'}("${m.id}")').toSet().join('\n')}\n';
}
