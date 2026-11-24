import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';

import 'package:window_manager/window_manager.dart';

import '../core/widgets.dart';
import '../features/dashboard.dart';
import '../features/installation.dart';
import '../features/settings.dart';
import '../features/wizard.dart';
import '../features/server_detail.dart';
import '../features/workshop.dart';
import 'controller.dart';
import 'strings.dart';
import 'theme.dart';

class LauncherApp extends StatefulWidget {
  const LauncherApp({
    required this.controller,
    this.windowControls = true,
    super.key,
  });
  final LauncherController controller;
  final bool windowControls;
  @override
  State<LauncherApp> createState() => _LauncherAppState();
}

class _LauncherAppState extends State<LauncherApp> {
  late final router = GoRouter(
    initialLocation: '/',
    overridePlatformDefaultLocation: true,
    routes: [
      ShellRoute(
        builder: (context, state, child) => LauncherShell(
          path: state.uri.path,
          windowControls: widget.windowControls,
          child: child,
        ),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
          GoRoute(path: '/create', builder: (_, _) => const WizardScreen()),
          GoRoute(
            path: '/install',
            builder: (_, _) => const InstallationScreen(),
          ),
          GoRoute(path: '/workshop', builder: (_, _) => const WorkshopScreen()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
          GoRoute(
            path: '/server/:id',
            builder: (_, state) =>
                ServerDetailScreen(id: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: widget.controller,
    child: Consumer<LauncherController>(
      builder: (context, controller, _) => MaterialApp.router(
        title: 'DST Server Launcher',
        debugShowCheckedModeBanner: false,
        theme: launcherTheme(Brightness.light),
        darkTheme: launcherTheme(Brightness.dark),
        themeMode: controller.themeMode,
        locale: Locale(controller.language),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
}

class LauncherShell extends StatefulWidget {
  const LauncherShell({
    required this.path,
    required this.child,
    required this.windowControls,
    super.key,
  });
  final String path;
  final Widget child;
  final bool windowControls;
  @override
  State<LauncherShell> createState() => _LauncherShellState();
}

class _LauncherShellState extends State<LauncherShell> with WindowListener {
  bool _closing = false;
  @override
  void initState() {
    super.initState();
    if (widget.windowControls) windowManager.addListener(this);
  }

  @override
  void dispose() {
    if (widget.windowControls) windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    if (_closing) return;
    _closing = true;
    final controller = context.read<LauncherController>();
    try {
      final active = controller.profiles
          .where(controller.supervisor.active)
          .toList();
      if (active.isEmpty) {
        await windowManager.destroy();
        return;
      }
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.t('closeQuestion')),
          content: Text(ctx.t('closeBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.t('cancel')),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 'background'),
              child: Text(ctx.t('keepRunning')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'stop'),
              child: Text(ctx.t('stopAndExit')),
            ),
          ],
        ),
      );
      if (action == 'background') {
        await windowManager.minimize();
      }
      if (action == 'stop' && mounted) {
        final timeoutText = context.t('stopTimeout');
        await guard(context, () async {
          for (final profile in active) {
            if (!await controller.supervisor.stop(profile)) {
              throw StateError(timeoutText);
            }
          }
          await windowManager.destroy();
        });
      }
    } finally {
      _closing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = [
      (PhosphorIcons.squaresFour(), 'myServers', '/'),
      (PhosphorIcons.puzzlePiece(), 'workshop', '/workshop'),
      (PhosphorIcons.downloadSimple(), 'installation', '/install'),
      (PhosphorIcons.gearSix(), 'settings', '/settings'),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (widget.windowControls)
              Container(
                height: 40,
                color: scheme.surfaceContainer,
                child: WindowCaption(
                  brightness: Theme.of(context).brightness,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/launcher-logo.png',
                        width: 24,
                        height: 24,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'DST Server Launcher',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.path != '/create')
              Material(
                color: scheme.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final entry in entries)
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    backgroundColor:
                                        widget.path == entry.$3 ||
                                            entry.$3 == '/' &&
                                                widget.path.startsWith(
                                                  '/server/',
                                                )
                                        ? scheme.surfaceContainerHighest
                                        : null,
                                    foregroundColor: scheme.onSurface,
                                  ),
                                  onPressed: () => context.go(entry.$3),
                                  icon: Icon(entry.$1, size: 18),
                                  label: Text(context.t(entry.$2)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: context.t('docs'),
                        icon: Icon(PhosphorIcons.bookOpen()),
                        onPressed: () => guard(
                          context,
                          () => openExternal(context.t('documentationUrl')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.path != '/create') const Divider(height: 1),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}
