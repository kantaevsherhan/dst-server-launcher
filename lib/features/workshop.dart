import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../app/controller.dart';
import '../app/strings.dart';
import '../core/widgets.dart';
import '../domain/models.dart';

class WorkshopScreen extends StatelessWidget {
  const WorkshopScreen({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitle(context.t('workshop'), context.t('modsTitle')),
        InlineHelp(context.t('modsHelp')),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => guard(
            context,
            () =>
                openExternal('https://steamcommunity.com/app/322330/workshop/'),
          ),
          icon: Icon(PhosphorIcons.arrowSquareOut()),
          label: Text(context.t('openWorkshop')),
        ),
        const SizedBox(height: 24),
        for (final profile in context.watch<LauncherController>().profiles)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ModEditor(
                    mods: profile.mods,
                    onChanged: (mods) => context
                        .read<LauncherController>()
                        .updateMods(profile, mods),
                    lockMessage: profile.manageMods
                        ? 'stopFirst'
                        : 'importedModsHelp',
                    locked:
                        !profile.manageMods ||
                        context.read<LauncherController>().supervisor.active(
                          profile,
                        ),
                  ),
                ],
              ),
            ),
          ),
        if (context.watch<LauncherController>().profiles.isEmpty)
          InlineHelp(context.t('emptyBody')),
      ],
    ),
  );
}

class ModEditor extends StatefulWidget {
  const ModEditor({
    required this.mods,
    required this.onChanged,
    this.locked = false,
    this.lockMessage = 'stopFirst',
    super.key,
  });
  final List<ModSpec> mods;
  final Future<void> Function(List<ModSpec>) onChanged;
  final bool locked;
  final String lockMessage;
  @override
  State<ModEditor> createState() => _ModEditorState();
}

class _ModEditorState extends State<ModEditor> {
  final input = TextEditingController();
  bool loading = false;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> add() async {
    setState(() => loading = true);
    await guard(context, () async {
      final values = await context.read<LauncherController>().workshop.resolve(
        input.text,
      );
      final map = {
        for (final m in widget.mods) m.id: m,
        for (final m in values) m.id: m,
      };
      await widget.onChanged(map.values.toList());
      input.clear();
    });
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InlineHelp(
        context.t(widget.locked ? widget.lockMessage : 'modDownloadNote'),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: input,
        enabled: !widget.locked && !loading,
        decoration: InputDecoration(
          labelText: context.t('workshopInput'),
          hintText: 'https://steamcommunity.com/sharedfiles/filedetails/?id=…',
        ),
        onSubmitted: (_) {
          if (!widget.locked && !loading) add();
        },
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: widget.locked || loading ? null : add,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(PhosphorIcons.plus(), size: 18),
            label: Text(context.t(loading ? 'busy' : 'addMod')),
          ),
          TextButton.icon(
            onPressed: () => guard(
              context,
              () => openExternal(
                'https://steamcommunity.com/app/322330/workshop/',
              ),
            ),
            icon: Icon(PhosphorIcons.arrowSquareOut(), size: 18),
            label: Text(context.t('openWorkshop')),
          ),
        ],
      ),
      const SizedBox(height: 24),
      if (widget.mods.isEmpty)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(context.t('noMods')),
        ),
      for (final mod in widget.mods)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Panel(
            padding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (mod.preview != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            mod.preview!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Icon(PhosphorIcons.puzzlePiece(), size: 36),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mod.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Workshop ${mod.id}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: context.t('openWorkshop'),
                      onPressed: () => guard(
                        context,
                        () => openExternal(
                          'https://steamcommunity.com/sharedfiles/filedetails/?id=${mod.id}',
                        ),
                      ),
                      icon: Icon(PhosphorIcons.arrowSquareOut()),
                    ),
                    IconButton(
                      tooltip: context.t('remove'),
                      onPressed: widget.locked
                          ? null
                          : () async {
                              if (await confirm(
                                    context,
                                    context.t('removeModTitle'),
                                    context.t('removeModBody'),
                                  ) &&
                                  context.mounted) {
                                await guard(
                                  context,
                                  () => widget.onChanged(
                                    widget.mods
                                        .where((m) => m.id != mod.id)
                                        .toList(),
                                  ),
                                );
                              }
                            },
                      icon: Icon(PhosphorIcons.trash()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  children: [
                    FilterChip(
                      label: Text(context.t('master')),
                      selected: mod.master,
                      onSelected: widget.locked
                          ? null
                          : (v) => guard(
                              context,
                              () => widget.onChanged(
                                widget.mods
                                    .map(
                                      (m) => m.id == mod.id
                                          ? m.enabled(master: v)
                                          : m,
                                    )
                                    .toList(),
                              ),
                            ),
                    ),
                    FilterChip(
                      label: Text(context.t('caves')),
                      selected: mod.caves,
                      onSelected: widget.locked
                          ? null
                          : (v) => guard(
                              context,
                              () => widget.onChanged(
                                widget.mods
                                    .map(
                                      (m) => m.id == mod.id
                                          ? m.enabled(caves: v)
                                          : m,
                                    )
                                    .toList(),
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  context.t('modOptionsUnavailable'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
