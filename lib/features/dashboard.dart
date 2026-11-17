import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../app/controller.dart';
import '../app/strings.dart';
import '../app/theme.dart';
import '../core/widgets.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageTitle(
            context.t('myServers'),
            context.t('homeSubtitle'),
            action: OutlinedButton.icon(
              onPressed: () => _import(context),
              icon: Icon(PhosphorIcons.folderOpen(), size: 18),
              label: Text(context.t('importServer')),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/expedition.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Tokens.background.withValues(alpha: .92),
                          Tokens.background.withValues(alpha: .55),
                          Tokens.background.withValues(alpha: .05),
                        ],
                        stops: const [0, .52, 1],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 540,
                      minHeight: 280,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.t('expedition'),
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 2.5,
                            color: Tokens.green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.t('heroTitle'),
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(color: Tokens.ink),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.t('heroBody'),
                          style: const TextStyle(
                            color: Tokens.ink,
                            fontSize: 13,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => context.go('/create'),
                          icon: Icon(PhosphorIcons.plus(), size: 18),
                          label: Text(context.t('createServer')),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (controller.error != null) ...[
            InlineHelp(
              '${context.t('actionFailed')}\n${controller.error}',
              warning: true,
            ),
            const SizedBox(height: 24),
          ],
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Text(
                '${context.t('myServers')}  ·  ${controller.profiles.length}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              StatusChip(context.t('heroTag'), active: true),
            ],
          ),
          const SizedBox(height: 16),
          if (controller.profiles.isEmpty)
            Panel(
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      PhosphorIcons.treeEvergreen(),
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('emptyTitle'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.t('emptyBody'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    tooltip: context.t('emptyAction'),
                    onPressed: () => context.go('/create'),
                    icon: Icon(PhosphorIcons.arrowUpRight()),
                  ),
                ],
              ),
            ),
          for (final profile in controller.profiles)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ServerCard(profile: profile),
            ),
          if (controller.profiles.isEmpty) ...[
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, c) {
                final items = [
                  (
                    PhosphorIcons.globeHemisphereWest(),
                    'benefitWorld',
                    'benefitWorldBody',
                  ),
                  (
                    PhosphorIcons.puzzlePiece(),
                    'benefitMods',
                    'benefitModsBody',
                  ),
                  (
                    PhosphorIcons.slidersHorizontal(),
                    'benefitControl',
                    'benefitControlBody',
                  ),
                ];
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: items
                      .map(
                        (v) => SizedBox(
                          width: c.maxWidth < 800
                              ? c.maxWidth
                              : (c.maxWidth - 48) / 3,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                v.$1,
                                size: 24,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.t(v.$2),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      context.t(v.$3),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
          const SizedBox(height: 32),
          Text(
            context.t('unofficial'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
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
                  'assets/images/expedition.png',
                  width: 88,
                  height: 80,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
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
