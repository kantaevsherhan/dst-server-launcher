import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'app/controller.dart';
import 'data/local_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isWindows && !Platform.isLinux) {
    throw UnsupportedError('Windows and Linux x64 only');
  }
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    size: Size(1100, 780),
    minimumSize: Size(900, 650),
    center: true,
    title: 'DST Server Launcher',
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  await windowManager.setPreventClose(true);
  final directory = await getApplicationSupportDirectory();
  final controller = LauncherController(
    LocalProfileRepository(directory),
    await SharedPreferences.getInstance(),
  );
  runApp(LauncherApp(controller: controller));
  unawaited(controller.initialize());
}
