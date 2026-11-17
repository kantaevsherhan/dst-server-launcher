import 'dart:convert';
import 'dart:math';

enum ShardState { stopped, starting, running, stopping, crashed, attention }

class ModSpec {
  const ModSpec({
    required this.id,
    required this.title,
    this.master = true,
    this.caves = true,
    this.collection = false,
    this.preview,
  });
  final String id, title;
  final bool master, caves, collection;
  final String? preview;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'master': master,
    'caves': caves,
    'collection': collection,
    'preview': preview,
  };
  factory ModSpec.fromJson(Map<String, dynamic> j) => ModSpec(
    id: j['id'],
    title: j['title'],
    master: j['master'] ?? true,
    caves: j['caves'] ?? true,
    collection: j['collection'] ?? false,
    preview: j['preview'],
  );
  ModSpec enabled({bool? master, bool? caves}) => ModSpec(
    id: id,
    title: title,
    master: master ?? this.master,
    caves: caves ?? this.caves,
    collection: collection,
    preview: preview,
  );
}

class ServerProfile {
  const ServerProfile({
    required this.id,
    required this.name,
    required this.installDir,
    required this.storageRoot,
    required this.secret,
    required this.portBase,
    this.description = '',
    this.password = '',
    this.slots = 6,
    this.mode = 'survival',
    this.caves = true,
    this.pvp = false,
    this.pause = true,
    this.worldSize = 'default',
    this.mods = const [],
  });
  final String id,
      name,
      description,
      password,
      installDir,
      storageRoot,
      mode,
      worldSize,
      secret;
  final int slots, portBase;
  final bool caves, pvp, pause;
  final List<ModSpec> mods;
  List<String> get shards => ['Master', if (caves) 'Caves'];
  List<int> get ports => [
    portBase,
    portBase + 2,
    portBase + 3,
    if (caves) ...[portBase + 1, portBase + 4, portBase + 5],
    portBase + 6,
  ];
  void validate() {
    if (!RegExp(r'^dst_[a-z0-9_]+$').hasMatch(id)) {
      throw const FormatException('Invalid cluster ID');
    }
    if (name.trim().isEmpty || name.length > 80 || _control.hasMatch(name)) {
      throw const FormatException('Invalid name');
    }
    if (_control.hasMatch(description) || _control.hasMatch(password)) {
      throw const FormatException('Multiline INI value');
    }
    if (slots < 1 || slots > 64) throw const FormatException('Players: 1–64');
    if (!['survival', 'endless', 'wilderness'].contains(mode)) {
      throw const FormatException('Invalid game mode');
    }
    if (!['default', 'small', 'medium', 'large', 'huge'].contains(worldSize)) {
      throw const FormatException('Invalid world size');
    }
    if (portBase < 1024 || portBase + 6 > 65535) {
      throw const FormatException('Invalid UDP range');
    }
    if (secret.isEmpty || !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(secret)) {
      throw const FormatException('Invalid shard key');
    }
    for (final m in mods) {
      if (!RegExp(r'^[1-9][0-9]{0,19}$').hasMatch(m.id)) {
        throw const FormatException('Invalid Workshop ID');
      }
    }
  }

  static final _control = RegExp(r'[\x00-\x1f\x7f]');
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'password': password,
    'installDir': installDir,
    'storageRoot': storageRoot,
    'secret': secret,
    'slots': slots,
    'portBase': portBase,
    'mode': mode,
    'caves': caves,
    'pvp': pvp,
    'pause': pause,
    'worldSize': worldSize,
    'mods': mods.map((m) => m.toJson()).toList(),
  };
  factory ServerProfile.fromJson(Map<String, dynamic> j) => ServerProfile(
    id: j['id'],
    name: j['name'],
    description: j['description'] ?? '',
    password: j['password'] ?? '',
    installDir: j['installDir'],
    storageRoot: j['storageRoot'],
    secret: j['secret'],
    portBase: j['portBase'],
    slots: j['slots'] ?? 6,
    mode: j['mode'] ?? 'survival',
    caves: j['caves'] ?? true,
    pvp: j['pvp'] ?? false,
    pause: j['pause'] ?? true,
    worldSize: j['worldSize'] ?? 'default',
    mods: (j['mods'] as List? ?? [])
        .map((m) => ModSpec.fromJson(Map<String, dynamic>.from(m)))
        .toList(),
  );
  ServerProfile withMods(List<ModSpec> value) => ServerProfile.fromJson({
    ...toJson(),
    'mods': value.map((m) => m.toJson()).toList(),
  });
  static String randomKey() => base64Url
      .encode(List.generate(24, (_) => Random.secure().nextInt(256)))
      .replaceAll(RegExp('[^a-zA-Z0-9]'), '');
  static String newId() =>
      'dst_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}_${randomKey().substring(0, 6).toLowerCase()}';
}

class Installation {
  const Installation({
    this.steam,
    this.steamCmd,
    this.server,
    this.build,
    this.notes = const [],
  });
  final String? steam, steamCmd, server, build;
  final List<String> notes;
}

class LogLine {
  LogLine(this.shard, this.message, {DateTime? time})
    : time = time ?? DateTime.now();
  final String shard, message;
  final DateTime time;
  bool get error => RegExp(
    r'error|failed|crash|exception',
    caseSensitive: false,
  ).hasMatch(message);
}
