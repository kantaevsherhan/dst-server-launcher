import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/ink_frame.dart';
import '../app/controller.dart';
import '../app/strings.dart';
import '../core/widgets.dart';
import 'installation.dart';
import 'woodland_atmosphere.dart';
import '../domain/models.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  Future<void> _import(BuildContext context) async {
    final controller = context.read<LauncherController>();
    if (!await confirm(
          context,
          context.t('importTitle'),
          context.t('importHelp'),
        ) ||
        !context.mounted) {
      return;
    }
    await guard(context, () async {
      final value = await selectDirectory();
      if (value != null) await controller.importCluster(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LauncherController>();
    final empty = controller.profiles.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1152),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (empty) ...[
                      ExcludeSemantics(
                        child: AspectRatio(
                          aspectRatio: 3,
                          child: InkFrame(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  'assets/images/expedition.png',
                                  fit: BoxFit.cover,
                                ),
                                const FractionallySizedBox(
                                  alignment: Alignment(.08, .65),
                                  heightFactor: .83,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _Survivor('wilson'),
                                      SizedBox(width: 16),
                                      _Survivor('willow'),
                                    ],
                                  ),
                                ),
                                const WoodlandAtmosphere(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        context.t(empty ? 'welcomeTitle' : 'myServers'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(context.t(empty ? 'welcomeBody' : 'serverListHelp')),
                    if (controller.error != null)
                      InlineHelp(controller.error!, warning: true),
                    const SizedBox(height: 12),
                    if (empty) ...[
                      TargetSystemPicker(controller: controller),
                      const SizedBox(height: 8),
                      Text(
                        context.t(
                          controller.localTarget
                              ? 'localTargetHelp'
                              : 'otherTargetHelp',
                        ),
                      ),
                    ],
                    for (final profile in controller.profiles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ServerCard(profile: profile),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _import(context),
                icon: Icon(PhosphorIcons.folderOpen(), size: 18),
                label: Text(context.t('importServer')),
              ),
              FilledButton.icon(
                onPressed: () => context.go('/create'),
                icon: Icon(PhosphorIcons.arrowRight(), size: 18),
                label: Text(context.t('createServer')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Survivor extends StatelessWidget {
  const _Survivor(this.name);
  final String name;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/$name.png',
    height: double.infinity,
    fit: BoxFit.contain,
  );
}

class ServerCard extends StatelessWidget {
  const ServerCard({required this.profile, super.key});
  final ServerProfile profile;
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LauncherController>();
    final state = controller.supervisor.state(profile, 'Master');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/server/${profile.id}'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/tent.png',
                  width: 88,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${profile.slots} ${context.t('slots').toLowerCase()}  ·  ${context.t(profile.mode)}  ·  ${profile.mods.length} ${context.t('mods').toLowerCase()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              StatusChip(
                context.t(state.name),
                active: state == ShardState.running,
              ),
              const SizedBox(width: 8),
              Icon(PhosphorIcons.caretRight(), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
