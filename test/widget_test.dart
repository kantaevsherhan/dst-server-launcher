import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dst_server_launcher/app/app.dart';
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
      expect(find.text('Большой мир.\nВаша компания.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Создать сервер'));
      await tester.pumpAndSettle();
      expect(find.text('Начнём с самого необходимого'), findsOneWidget);
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
  testWidgets('English and large text remain readable', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
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
    expect(find.text('A big world.\nYour favourite people.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    c.supervisor.dispose();
    c.dispose();
    temp.deleteSync(recursive: true);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
