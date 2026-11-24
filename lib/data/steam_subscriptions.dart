import 'dart:io';

import 'package:path/path.dart' as p;

import 'platform_services.dart';

class SteamSubscriptions {
  const SteamSubscriptions(this.account, this.file);
  final String account;
  final File file;

  static Future<List<SteamSubscriptions>> accounts({
    Iterable<String>? roots,
  }) async {
    final accounts = <String, SteamSubscriptions>{};
    for (final root in roots ?? await LocalSteamLocator.steamRoots()) {
      final users = Directory(p.join(root, 'userdata'));
      if (!await users.exists()) continue;
      await for (final dir in users.list(followLinks: false)) {
        final id = p.basename(dir.path);
        if (dir is! Directory || !RegExp(r'^[1-9]\d*$').hasMatch(id)) continue;
        final file = File(p.join(dir.path, 'ugc', '322330_subscriptions.vdf'));
        if (await file.exists()) {
          accounts.putIfAbsent(id, () => SteamSubscriptions(id, file));
        }
      }
    }
    return accounts.values.toList()
      ..sort((a, b) => a.account.compareTo(b.account));
  }

  Future<List<String>> ids() async {
    final text = await file.readAsString();
    if (!RegExp(r'"appid"\s*"322330"').hasMatch(text)) {
      throw const FormatException('Invalid DST subscription file');
    }
    return RegExp(r'"publishedfileid"\s*"([1-9][0-9]{0,19})"')
        .allMatches(text)
        .map((m) => m[1]!)
        .toSet()
        .toList();
  }
}
