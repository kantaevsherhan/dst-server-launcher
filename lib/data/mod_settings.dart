import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'platform_services.dart';

class ModOption {
  const ModOption(this.key, this.label, this.choices, this.initial);
  final String key, label;
  final Map<Object, String> choices;
  final Object? initial;
}

// Read declarative modinfo tables only. Never run Workshop Lua.
class _Tables {
  final List<String> tokens;
  final named = <String, Object>{};
  int pos = 0;
  String get next => pos < tokens.length ? tokens[pos] : '';
  bool take(String token) {
    if (next != token) return false;
    pos++;
    return true;
  }

  _Tables(String source)
    : tokens =
          RegExp(
                r'''--\[(=*)\[[\s\S]*?\]\1\]|--[^\n]*|"(?:\\[\s\S]|[^"\\])*"|'(?:\\[\s\S]|[^'\\])*'|[A-Za-z_]\w*|-?(?:\d+\.\d+|\d+)|[^\s]''',
              )
              .allMatches(source)
              .map((m) => m[0]!)
              .where((t) => !t.startsWith('--'))
              .toList();

  Object? value(int depth) {
    if (depth > 24 || next.isEmpty) {
      throw const FormatException('Invalid option table');
    }
    if (take('{')) return table(depth + 1);
    final t = tokens[pos++];
    if (t.startsWith('"') || t.startsWith("'")) {
      return t
          .substring(1, t.length - 1)
          .replaceAllMapped(
            RegExp(r'''\\([\\'"nrt])'''),
            (m) => const {'n': '\n', 'r': '\r', 't': '\t'}[m[1]] ?? m[1]!,
          );
    }
    if (t == 'true' || t == 'false') return t == 'true';
    return num.tryParse(t) ?? named[t];
  }

  Map<Object, Object> table(int depth) {
    final result = <Object, Object>{};
    int index = 1;
    while (next.isNotEmpty && !take('}')) {
      if (take(',') || take(';')) continue;
      Object key = index++;
      if (pos + 1 < tokens.length && tokens[pos + 1] == '=') {
        key = tokens[pos];
        pos += 2;
        index--;
      }
      final start = pos;
      Object? v = value(depth);
      if (![',', ';', '}'].contains(next)) {
        v = null;
        pos = start;
        int nested = 0;
        while (next.isNotEmpty) {
          if (nested == 0 && [',', ';', '}'].contains(next)) break;
          final token = tokens[pos++];
          if (['{', '[', '('].contains(token)) nested++;
          if (['}', ']', ')'].contains(token)) nested--;
        }
      }
      if (v != null) result[key] = v;
    }
    return result;
  }

  List<ModOption> parse() {
    Map? config;
    while (pos + 2 < tokens.length) {
      final name = tokens[pos++];
      if (tokens[pos] != '=' || tokens[pos + 1] != '{') continue;
      pos += 2;
      final t = table(0);
      named[name] = t;
      if (name == 'configuration_options') config = t;
    }
    final options = <ModOption>[];
    for (final row in config?.values ?? []) {
      if (row is! Map || row['name'] is! String || row['options'] is! Map) {
        continue;
      }
      final choices = <Object, String>{};
      for (final opt in (row['options'] as Map).values) {
        if (opt is! Map) continue;
        final data = opt['data'];
        if (data is String || data is num || data is bool) {
          choices[data] = opt['description']?.toString() ?? data.toString();
        }
      }
      final key = row['name'] as String;
      if (choices.isNotEmpty && key.isNotEmpty) {
        options.add(
          ModOption(
            key,
            row['label']?.toString() ?? key,
            choices,
            row['default'],
          ),
        );
      }
    }
    return options;
  }
}

List<ModOption> parseModOptions(String text) => _Tables(text).parse();

Future<List<ModOption>> loadModOptions(String id, String? installDir) async {
  if (!RegExp(r'^[1-9]\d{0,19}$').hasMatch(id)) {
    throw const FormatException('Invalid Workshop ID');
  }
  final roots = await LocalSteamLocator.steamRoots();
  final libraries = {...roots};
  for (final root in roots) {
    final manifest = File(p.join(root, 'steamapps', 'libraryfolders.vdf'));
    if (await manifest.exists()) {
      libraries.addAll(
        LocalSteamLocator.libraries(await manifest.readAsString()),
      );
    }
  }
  final candidates = [
    if (installDir != null) p.join(installDir, 'mods', 'workshop-$id'),
    if (installDir != null)
      p.join(installDir, 'ugc_mods', 'content', '322330', id),
    for (final root in libraries) ...[
      p.join(root, 'steamapps', 'workshop', 'content', '322330', id),
      p.join(
        root,
        'steamapps',
        'common',
        "Don't Starve Together",
        'mods',
        'workshop-$id',
      ),
    ],
  ];
  for (final dir in candidates) {
    final file = File(p.join(dir, 'modinfo.lua'));
    if (!await file.exists() || await file.length() > 2 * 1024 * 1024) continue;
    final result = parseModOptions(
      utf8.decode(await file.readAsBytes(), allowMalformed: true),
    );
    if (result.isNotEmpty) return result;
  }
  return [];
}
