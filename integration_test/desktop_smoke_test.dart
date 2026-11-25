import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dst_server_launcher/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Desktop opens and renders localized dashboard', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    expect(find.text('DST Server Launcher'), findsOneWidget);
    expect(tester.takeException(), isNull);
    if (Platform.isWindows) {
      await windowManager.close();
      for (var i = 0; i < 30 && await windowManager.isVisible(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(await windowManager.isVisible(), isFalse);
      expect(await trayManager.getBounds(), isNotNull);
      await windowManager.show();
      await windowManager.focus();
      expect(await windowManager.isVisible(), isTrue);
    }
  });
}
