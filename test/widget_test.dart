import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dst_server_launcher/app/app.dart';
import 'package:dst_server_launcher/domain/models.dart';
import 'package:dst_server_launcher/app/controller.dart';
import 'package:dst_server_launcher/data/local_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final size in [
    const Size(1440, 1000),
    const Size(1050, 800),
    const Size(900, 700),
  ]) {
    testWidgets('First-run dashboard and wizard fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      SharedPreferences.setMockInitialValues({});
      final temp = Directory.systemTemp.createTempSync('dst-ui-');
      final c = LauncherController(
        LocalProfileRepository(temp),
        await SharedPreferences.getInstance(),
      );
      await tester.pumpWidget(
        LauncherApp(controller: c, windowControls: false),
      );
      await tester.pumpAndSettle();
      expect(find.text('Мастер установки сервера'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Создать сервер'));
      await tester.pumpAndSettle();
      expect(find.text('Параметры установки'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Далее'));
      await tester.pumpAndSettle();
      expect(find.text('Найдём выделенный сервер'), findsOneWidget);
      await tester.tap(find.text('Далее'));
      await tester.pumpAndSettle();
      expect(find.text('Не удалось выполнить действие'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      c.supervisor.dispose();
      c.dispose();
      temp.deleteSync(recursive: true);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
  testWidgets(
    'Other OS offers transferable instructions without local actions',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({'language': 'en'});
      final prefs = await SharedPreferences.getInstance();
      final controller = LauncherController(
        LocalProfileRepository(Directory.systemTemp),
        prefs,
      );
      final other = Platform.isWindows ? 'Linux' : 'Windows';
      await tester.pumpWidget(
        LauncherApp(controller: controller, windowControls: false),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(other));
      await tester.pumpAndSettle();
      expect(prefs.getString('targetSystem'), other.toLowerCase());
      await tester.tap(find.text('Create server'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 / 2'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Save instructions'), findsOneWidget);
      expect(find.text('Install through Steam'), findsNothing);
      expect(
        find.text('Debian · Ubuntu · Linux Mint · Manjaro · Fedora'),
        Platform.isWindows ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(find.text('Server setup wizard'), findsOneWidget);
      expect(controller.profiles, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.supervisor.dispose();
      controller.dispose();
    },
  );

  testWidgets(
    'Local wizard validates basics and token and reaches config review',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({'language': 'en'});
      final prefs = await SharedPreferences.getInstance();
      final c = LauncherController(
        LocalProfileRepository(Directory.systemTemp),
        prefs,
      )..installation = Installation(server: Directory.systemTemp.path);
      await tester.pumpWidget(
        LauncherApp(controller: c, windowControls: false),
      );
      await tester.pumpAndSettle();
      Future<void> press(String label) async {
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
      }

      await press('Create server');
      await press('Next');
      await press('Next');
      await press('Next');
      expect(find.text('Step 3 / 9'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Test camp');
      await press('Next');
      await press('Next');
      await press('Next');
      await press('Next');
      expect(find.text('Step 7 / 9'), findsOneWidget);
      await press('Next');
      await press('Close');
      await tester.enterText(find.byType(TextField).first, 'fixtureToken');
      await press('Next');
      expect(find.text('Step 8 / 9'), findsOneWidget);
      expect(find.text('Test camp'), findsOneWidget);
      expect(find.textContaining('fixtureToken'), findsNothing);
      await press('Cancel');
      expect(c.profiles, isEmpty);
      expect(prefs.getString('wizardDraft'), isNot(contains('fixtureToken')));
      await tester.pumpWidget(const SizedBox.shrink());
      c.supervisor.dispose();
      c.dispose();
    },
  );

  testWidgets('English and large text remain readable', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(1050, 850);
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues({
      'language': 'en',
      'theme': 'light',
    });
    final temp = Directory.systemTemp.createTempSync('dst-ui-en-');
    final c = LauncherController(
      LocalProfileRepository(temp),
      await SharedPreferences.getInstance(),
    );
    await tester.pumpWidget(LauncherApp(controller: c, windowControls: false));
    await tester.pumpAndSettle();
    expect(find.text('Server setup wizard'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    c.supervisor.dispose();
    c.dispose();
    temp.deleteSync(recursive: true);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
