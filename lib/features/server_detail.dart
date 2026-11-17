import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../app/controller.dart';
import '../app/strings.dart';
import '../core/widgets.dart';
import '../data/local_repository.dart';
import '../data/platform_services.dart';
import '../domain/models.dart';
import 'workshop.dart';

class ServerDetailScreen extends StatefulWidget {
  const ServerDetailScreen({required this.id, super.key});
  final String id;
  @override
  State<ServerDetailScreen> createState() => _ServerDetailScreenState();
}

class _ServerDetailScreenState extends State<ServerDetailScreen> {
  int tab = 0;
  bool busy = false;
  Map<int, bool>? ports;
  Future<void> action(Future<void> Function() task) async {
    setState(() => busy = true);
    await guard(context, task);
    if (mounted) setState(() => busy = false);
  }

  Future<void> stop(LauncherController c, ServerProfile profile) async {
    if (!await c.supervisor.stop(profile) && mounted) {
      if (await confirm(
        context,
        context.t('stopTimeout'),
        context.t('forceWarning'),
      )) {
        await c.supervisor.forceStop(profile);
      } else {
        throw StateError(
          'Shutdown is still pending. Inspect console before retrying.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LauncherController>();
    final matches = c.profiles.where((v) => v.id == widget.id);
    if (matches.isEmpty) return Center(child: Text(context.t('emptyBody')));
    final profile = matches.first;
    final active = c.supervisor.active(profile);
    final tabs = [
      'overview',
      'world',
      'mods',
      'playersTab',
      'console',
      'network',
      'files',
      'backups',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitle(
            profile.name,
            context.t('detailSubtitle'),
            action: StatusChip(
              context.t(c.supervisor.state(profile, 'Master').name),
              active:
                  c.supervisor.state(profile, 'Master') == ShardState.running,
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: busy || active
                    ? null
                    : () => action(() => c.supervisor.start(profile)),
                icon: Icon(PhosphorIcons.play(), size: 18),
                label: Text(context.t(busy ? 'busy' : 'start')),
              ),
              OutlinedButton.icon(
                onPressed: busy || !active
                    ? null
                    : () => action(() => stop(c, profile)),
                icon: Icon(PhosphorIcons.stop(), size: 18),
                label: Text(context.t('stop')),
              ),
              OutlinedButton.icon(
                onPressed: busy || !active
                    ? null
                    : () => action(() async {
                        await stop(c, profile);
                        if (!context.mounted) return;
                        if (c.supervisor.active(profile)) {
                          throw StateError(context.t('stopFirst'));
                        }
                        await c.supervisor.start(profile);
                      }),
                icon: Icon(PhosphorIcons.arrowsClockwise(), size: 18),
                label: Text(context.t('restart')),
              ),
              TextButton.icon(
                onPressed: () =>
                    guard(context, () => openFolder(clusterDirectory(profile))),
                icon: Icon(PhosphorIcons.folderOpen(), size: 18),
                label: Text(context.t('openFolder')),
              ),
              TextButton.icon(
                onPressed: () => Clipboard.setData(
                  ClipboardData(
                    text: '${profile.name}\n${context.t('inviteNote')}',
                  ),
                ),
                icon: Icon(PhosphorIcons.copy(), size: 18),
                label: Text(context.t('invite')),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < tabs.length; i++)
                ChoiceChip(
                  label: Text(context.t(tabs[i])),
                  selected: i == tab,
                  onSelected: (_) => setState(() => tab = i),
                ),
            ],
          ),
          const SizedBox(height: 24),
          switch (tab) {
            0 => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: profile.shards.map((shard) {
                      final state = c.supervisor.state(profile, shard);
                      final start =
                          c.supervisor.started['${profile.id}/$shard'];
                      return SizedBox(
                        width: constraints.maxWidth < 650
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 16) / 2,
                        child: Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    shard == 'Master'
                                        ? PhosphorIcons.treeEvergreen()
                                        : PhosphorIcons.mountains(),
                                    size: 30,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      context.t(
                                        shard == 'Master' ? 'master' : 'caves',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              StatusChip(
                                context.t(state.name),
                                active: state == ShardState.running,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                start == null ||
                                        state == ShardState.stopped ||
                                        state == ShardState.crashed
                                    ? '—'
                                    : '${context.t('uptime')}: ${DateTime.now().difference(start).inMinutes} min',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                InlineHelp(context.t('serverHelp')),
                const SizedBox(height: 20),
                Text(
                  '${context.t('slots')}: ${profile.slots} · ${context.t(profile.mode)} · ${context.t('mods')}: ${profile.mods.length}',
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: !active || busy
                          ? null
                          : () => action(() => c.supervisor.saveWorld(profile)),
                      icon: Icon(PhosphorIcons.floppyDisk()),
                      label: Text(context.t('saveWorld')),
                    ),
                    OutlinedButton.icon(
                      onPressed: active
                          ? null
                          : () => guard(context, () async {
                              await showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(ctx.t('updateServer')),
                                  content: Text(ctx.t('updateHelp')),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text(ctx.t('close')),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        guard(
                                          context,
                                          () =>
                                              openExternal('steam://nav/tools'),
                                        );
                                      },
                                      child: Text(ctx.t('openSteam')),
                                    ),
                                  ],
                                ),
                              );
                            }),
                      icon: Icon(PhosphorIcons.downloadSimple()),
                      label: Text(context.t('updateServer')),
                    ),
                  ],
                ),
              ],
            ),
            1 => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InlineHelp(context.t('generationReadOnly'), warning: true),
                const SizedBox(height: 24),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('worldSummary'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      Text(context.t('worldPreset')),
                      const SizedBox(height: 12),
                      Text(
                        '${context.t('worldSize')}: ${context.t(profile.worldSize)}',
                      ),
                      const SizedBox(height: 12),
                      if (profile.caves) Text(context.t('cavePreset')),
                    ],
                  ),
                ),
              ],
            ),
            2 => ModEditor(
              mods: profile.mods,
              locked: active,
              onChanged: (mods) => c.updateMods(profile, mods),
            ),
            3 => InlineHelp(context.t('playersUnknown')),
            4 => ConsoleLogView(lines: c.supervisor.logs[profile.id] ?? []),
            5 => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InlineHelp(context.t('networkHelp')),
                const SizedBox(height: 20),
                Text(
                  context.t('externalUnknown'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(profile.ports.map((v) => '$v UDP').join(' · ')),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => action(() async {
                    final checked = await LocalPortInspector().inspect(
                      profile.ports,
                    );
                    if (mounted) setState(() => ports = checked);
                  }),
                  icon: Icon(PhosphorIcons.plugsConnected()),
                  label: Text(context.t('checkPorts')),
                ),
                const SizedBox(height: 16),
                if (ports != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ports!.entries
                        .map(
                          (v) => StatusChip(
                            '${v.key}: ${context.t(v.value ? 'portFree' : 'portBusy')}',
                            active: v.value,
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 20),
                Text(context.t('portCheckHint')),
                const SizedBox(height: 16),
                InlineHelp(context.t('networkFirewall')),
              ],
            ),
            6 => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InlineHelp(context.t('manualEdits')),
                const SizedBox(height: 20),
                for (final name in c.repository.preview(profile).keys)
                  ExpansionTile(
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    children: [
                      FutureBuilder<String>(
                        future: File(p.join(clusterDirectory(profile), name))
                            .readAsString(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text(context.t('actionFailed'));
                          }
                          if (!snapshot.hasData) {
                            return const LinearProgressIndicator();
                          }
                          var value = snapshot.data!.replaceAll(
                            profile.secret,
                            '[redacted]',
                          );
                          if (profile.password.isNotEmpty) {
                            value = value.replaceAll(
                              profile.password,
                              '[redacted]',
                            );
                          }
                          return CommandBlock(value);
                        },
                      ),
                    ],
                  ),
              ],
            ),
            _ => _backups(c, profile, active),
          },
        ],
      ),
    );
  }

  Widget _backups(
    LauncherController c,
    ServerProfile profile,
    bool active,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InlineHelp(context.t('backupHelp')),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: busy || active
            ? null
            : () => action(() async {
                await c.backups.create(profile);
                if (mounted) setState(() {});
              }),
        icon: Icon(PhosphorIcons.archive()),
        label: Text(context.t(active ? 'stopFirst' : 'backupCreate')),
      ),
      const SizedBox(height: 24),
      FutureBuilder<List<String>>(
        future: c.backups.list(profile),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return InlineHelp(context.t('actionFailed'), warning: true);
          }
          if (!snapshot.hasData) return const LinearProgressIndicator();
          if (snapshot.data!.isEmpty) return Text(context.t('noBackups'));
          return Column(
            children: snapshot.data!
                .map(
                  (file) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Panel(
                      padding: 16,
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIcons.archive(),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              DateTime.fromMicrosecondsSinceEpoch(
                                int.parse(p.basenameWithoutExtension(file)),
                              ).toLocal().toString().split('.').first,
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: active || busy
                                ? null
                                : () => action(() async {
                                    final names = await c.backups
                                        .previewRestore(profile, file);
                                    if (!context.mounted) return;
                                    if (await confirm(
                                      context,
                                      context.t('restoreTitle'),
                                      '${context.t('restoreHelp')}\n\n${names.take(16).join('\n')}${names.length > 16 ? '\n…' : ''}',
                                    )) {
                                      await c.backups.restore(profile, file);
                                    }
                                  }),
                            child: Text(context.t('restore')),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
}

class ConsoleLogView extends StatefulWidget {
  const ConsoleLogView({required this.lines, super.key});
  final List<LogLine> lines;
  @override
  State<ConsoleLogView> createState() => _ConsoleLogViewState();
}

class _ConsoleLogViewState extends State<ConsoleLogView> {
  String query = '', filter = 'all';
  bool follow = true;
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.lines
        .where(
          (v) =>
              v.message.toLowerCase().contains(query.toLowerCase()) &&
              (filter == 'all' ||
                  filter == 'errors' && v.error ||
                  filter == v.shard),
        )
        .toList();
    if (follow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
      });
    }
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: context.t('searchLogs'),
            prefixIcon: Icon(PhosphorIcons.magnifyingGlass()),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in ['all', 'Master', 'Caves', 'errors'])
              ChoiceChip(
                label: Text(
                  context.t(
                    item == 'Master'
                        ? 'master'
                        : item == 'Caves'
                        ? 'caves'
                        : item,
                  ),
                ),
                selected: filter == item,
                onSelected: (_) => setState(() => filter = item),
              ),
            FilterChip(
              label: Text(context.t('autoScroll')),
              selected: follow,
              onSelected: (v) => setState(() => follow = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Panel(
          padding: 12,
          child: SizedBox(
            height: 360,
            child: lines.isEmpty
                ? Center(
                    child: Text(
                      context.t(
                        widget.lines.isEmpty ? 'noLogs' : 'filteredEmpty',
                      ),
                    ),
                  )
                : SelectionArea(
                    child: ListView.builder(
                      controller: scroll,
                      itemCount: lines.length,
                      itemBuilder: (context, index) {
                        final line = lines[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            '${line.time.toLocal().toIso8601String().substring(11, 19)} [${line.shard}] ${line.message}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              height: 1.6,
                              color: line.error
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
