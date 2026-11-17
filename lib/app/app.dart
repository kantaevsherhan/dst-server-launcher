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
                color: scheme.surfaceContainer,
                child: WindowCaption(
                  brightness: Theme.of(context).brightness,
                  title: const Text(
                    'DST Server Launcher',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 1140;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: compact ? 84 : 236,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          border: Border(
                            right: BorderSide(
                              color: scheme.outline.withValues(alpha: .35),
                            ),
                          ),
                        ),
                        child: Material(
                          color: scheme.surfaceContainer,
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 16 : 24,
                                  vertical: 32,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        PhosphorIcons.campfire(
                                          PhosphorIconsStyle.bold,
                                        ),
                                        color: scheme.onPrimary,
                                        size: 25,
                                      ),
                                    ),
                                    if (!compact) ...[
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'DST',
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 23,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                            Text(
                                              'SERVER LAUNCHER',
                                              style: TextStyle(
                                                fontSize: 9,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              for (final entry in entries)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  child: Tooltip(
                                    message: context.t(entry.$2),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: compact ? 16 : 14,
                                      ),
                                      minLeadingWidth: 20,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      selected:
                                          widget.path == entry.$3 ||
                                          entry.$3 == '/' &&
                                              (widget.path.startsWith(
                                                    '/server',
                                                  ) ||
                                                  widget.path == '/create'),
                                      selectedColor: scheme.primary,
                                      selectedTileColor: scheme.primary
                                          .withValues(alpha: .1),
                                      leading: Icon(entry.$1, size: 21),
                                      title: compact
                                          ? null
                                          : Text(
                                              context.t(entry.$2),
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                      onTap: () => context.go(entry.$3),
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: compact
                                    ? IconButton(
                                        tooltip: context.t('docs'),
                                        onPressed: () => guard(
                                          context,
                                          () => openExternal(
                                            context.t('documentationUrl'),
                                          ),
                                        ),
                                        icon: Icon(PhosphorIcons.bookOpen()),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Divider(),
                                          TextButton.icon(
                                            onPressed: () => guard(
                                              context,
                                              () => openExternal(
                                                context.t('documentationUrl'),
                                              ),
                                            ),
                                            icon: Icon(
                                              PhosphorIcons.bookOpen(),
                                              size: 18,
                                            ),
                                            label: Text(context.t('docs')),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            context.t('desktopNote'),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                          const Text(
                                            'v0.1.0',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: scheme.outline.withValues(alpha: .3),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    context.t('localOnly'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  const Spacer(),
                                  Icon(
                                    PhosphorIcons.desktopTower(),
                                    size: 16,
                                    color: scheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      context
                                                  .watch<LauncherController>()
                                                  .installation
                                                  .server ==
                                              null
                                          ? context.t('notInstalled')
                                          : context.t('dedicatedServer'),
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: widget.child),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
