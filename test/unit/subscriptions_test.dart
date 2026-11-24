import 'dart:io';

import 'package:dst_server_launcher/data/steam_subscriptions.dart';
import 'package:dst_server_launcher/data/windows_game_path.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('dst-workshop-');
  });
  tearDown(() => root.delete(recursive: true));
  test(
    'Subscriptions are specific to the account and game, even before download',
    () async {
      Future<void> seed(String user, String app, String records) async {
        final file = File(
          p.join(
            root.path,
            'userdata',
            user,
            'ugc',
            '${app}_subscriptions.vdf',
          ),
        );
        await file.parent.create(recursive: true);
        await file.writeAsString(
          '"subscribedfiles" { "appid" "$app" $records }',
        );
      }

      await seed(
        '12',
        '322330',
        '"0" { "publishedfileid" "351" } "1" { "publishedfileid" "351" }',
      );
      await seed('13', '322330', '"0" { "publishedfileid" "714" }');
      await seed('14', '570', '"0" { "publishedfileid" "999" }');
      final accounts = await SteamSubscriptions.accounts(
        roots: [root.path, root.path],
      );
      expect(accounts.map((a) => a.account), ['12', '13']);
      expect(await accounts[0].ids(), ['351']);
      expect(await accounts[1].ids(), ['714']);
    },
  );
  test('Windows game receives an ASCII alias of the existing Unicode folder or an explicit error', () async {
    final folder = await Directory(p.join(root.path, 'Мир')).create();
    if (!Platform.isWindows) {
      expect(gameStoragePath(folder.path), folder.path);
      return;
    }
    try {
      final alias = gameStoragePath(folder.path);
      expect(alias.codeUnits.every((u) => u < 128), isTrue);
      expect(await FileSystemEntity.identical(alias, folder.path), isTrue);
    } on FileSystemException catch (e) {
      expect(e.message, contains('ASCII storage path'));
    }
  });
}
