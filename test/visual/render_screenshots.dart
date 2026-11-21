import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dst_server_launcher/app/app.dart';
import 'package:dst_server_launcher/app/controller.dart';
import 'package:dst_server_launcher/data/local_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final entry in {
      'Neucha': 'assets/fonts/Neucha.ttf',
      'Inter': 'assets/fonts/Inter.ttf',
      'Manrope': 'assets/fonts/Manrope.ttf',
      'packages/phosphor_flutter/PhosphorRegular':
          'packages/phosphor_flutter/lib/fonts/Phosphor.ttf',
      'packages/phosphor_flutter/PhosphorBold':
          'packages/phosphor_flutter/lib/fonts/Phosphor-Bold.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });
  for (final (width, dark) in [
    (1440.0, false),
    (900.0, false),
    (1100.0, true),
  ]) {
    final suffix = dark ? 'dark' : width.toInt().toString();
    testWidgets('Render real Flutter layouts at $width', (tester) async {
      tester.view.physicalSize = Size(width, width == 900 ? 700 : 780);
      tester.view.devicePixelRatio = 1;
      SharedPreferences.setMockInitialValues({
        'theme': dark ? 'dark' : 'light',
      });
      final dir = Directory(
        Platform.isWindows
            ? r'C:\DST Launcher\Data'
            : '/home/player/.local/share/dst-launcher',
      );
      final controller = LauncherController(
        LocalProfileRepository(dir),
        await SharedPreferences.getInstance(),
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: LauncherApp(controller: controller, windowControls: false),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(Scaffold).first);
        for (final asset in ['expedition', 'wilson', 'willow', 'tent']) {
          await precacheImage(AssetImage('assets/images/$asset.png'), context);
        }
      });
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('../../docs/screenshots/dashboard-$suffix.png'),
      );
      await tester.tap(find.text('Создать сервер'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(Scaffold).first);
        for (final asset in ['expedition', 'wilson', 'willow', 'tent']) {
          await precacheImage(AssetImage('assets/images/$asset.png'), context);
        }
      });
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('../../docs/screenshots/wizard-$suffix.png'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.supervisor.dispose();
      controller.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
}
