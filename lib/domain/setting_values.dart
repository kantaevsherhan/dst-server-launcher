import 'world_catalog.dart';

String luaValue(Object value) {
  if (value is bool || value is num && value.isFinite) return value.toString();
  if (value is String && value.length <= 4096) {
    final quoted = value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAllMapped(
          RegExp(r'[\x00-\x1f\x7f]'),
          (m) => '\\${m[0]!.codeUnitAt(0).toString().padLeft(3, '0')}',
        );
    return '"$quoted"';
  }
  throw const FormatException('Unsupported Lua option value');
}

void validateWorld(Map<String, String> overrides, String location) {
  final valid = {
    for (final r in worldRows)
      if (r[5] == location) r[0]: worldChoices[r[6]]!,
  };
  for (final e in overrides.entries) {
    if (valid[e.key]?.containsKey(e.value) != true) {
      throw FormatException('Invalid world setting: ${e.key}');
    }
  }
}
