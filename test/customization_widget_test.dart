import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dst_server_launcher/app/controller.dart';
import 'package:dst_server_launcher/app/strings.dart';
import 'package:dst_server_launcher/app/theme.dart';
import 'package:dst_server_launcher/data/local_repository.dart';
import 'package:dst_server_launcher/features/world_settings.dart';
import 'package:dst_server_launcher/features/mod_catalog.dart';

Future<void> mount(
  WidgetTester tester,
  LauncherController c,
  Widget child,
) async {
  tester.view.physicalSize = const Size(900, 650);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: c,
      child: MaterialApp(
        theme: launcherTheme(),
        localizationsDelegates: const [AppStrings.delegate],
        home: Scaffold(body: child),
      ),
    ),
  );
}

Future<LauncherController> controller() async {
  SharedPreferences.setMockInitialValues({'language': 'en'});
  return LauncherController(
    LocalProfileRepository(Directory.systemTemp),
    await SharedPreferences.getInstance(),
  );
}

void main() {
  testWidgets(
    'Cave terrain search edits cave-only vegetation and saves the override',
    (t) async {
      final c = await controller();
      Map<String, String>? saved;
      await mount(
        t,
        c,
        WorldSettingsButton(
          caves: true,
          values: const {},
          onChanged: (v) async {
            saved = v;
          },
        ),
      );
      await t.tap(find.text('Cave settings'));
      await t.pumpAndSettle();
      await t.tap(find.text('Generation'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'mushtree');
      await t.pumpAndSettle();
      final selector = find.byType(DropdownButton<String>).last;
      await t.tap(selector);
      await t.pumpAndSettle();
      await t.tap(find.text('More').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(saved, containsPair('mushtree', 'often'));
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('Catalog marks selected mods immediately and stays open', (
    t,
  ) async {
    final c = await controller();
    var count = 0;
    c.workshop.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          h.resolve(
            Response(
              requestOptions: o,
              data: o.method == 'GET'
                  ? '<a href="/sharedfiles/filedetails/?id=123">Example</a>'
                  : {
                      'response': {
                        'publishedfiledetails': [
                          {
                            'publishedfileid': '123',
                            'title': 'Test item',
                            'result': 1,
                            'consumer_app_id': 322330,
                          },
                        ],
                      },
                    },
            ),
          );
        },
      ),
    );
    await mount(
      t,
      c,
      Builder(
        builder: (ctx) => TextButton(
          onPressed: () => browseMods(
            ctx,
            select: true,
            added: {},
            onAdd: (m) async {
              count++;
            },
          ),
          child: const Text('Browse'),
        ),
      ),
    );
    await t.tap(find.text('Browse'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Add mod'));
    await t.pumpAndSettle();
    expect(count, 1);
    expect(find.text('Added'), findsOneWidget);
    expect(find.text('Test item'), findsOneWidget);
    expect(find.byTooltip('Add mod'), findsNothing);
  });
}
