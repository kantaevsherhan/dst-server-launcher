import 'package:flutter/material.dart';

import '../app/strings.dart';

import 'package:provider/provider.dart';

import '../app/controller.dart';
import '../data/world_icons.dart';
import '../core/launcher_dialog.dart';
import '../domain/world_catalog.dart';

class WorldSettingsButton extends StatelessWidget {
  const WorldSettingsButton({
    super.key,
    required this.caves,
    required this.values,
    required this.onChanged,
    this.enabled = true,
  });
  final bool caves, enabled;
  final Map<String, String> values;
  final Future<void> Function(Map<String, String>) onChanged;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    icon: Icon(caves ? Icons.terrain : Icons.forest),
    label: Text(context.t(caves ? 'caveSettings' : 'surfaceSettings')),
    onPressed: !enabled
        ? null
        : () async {
            final result = await showDialog<Map<String, String>>(
              context: context,
              builder: (_) => _WorldSettings(caves: caves, initial: values),
            );
            if (result != null) await onChanged(result);
          },
  );
}

class _WorldSettings extends StatefulWidget {
  const _WorldSettings({required this.caves, required this.initial});
  final bool caves;
  final Map<String, String> initial;
  @override
  State<_WorldSettings> createState() => _WorldSettingsState();
}

class _WorldSettingsState extends State<_WorldSettings> {
  SettingsIcons iconsByName = {};
  @override
  void initState() {
    super.initState();
    worldIcons(context.read<LauncherController>().installation.server)
        .then((v) {
          if (mounted) setState(() => iconsByName = v);
        });
  }

  late final values = Map<String, String>.of(widget.initial);
  bool generation = false;
  String query = '', group = '';
  static const icons = {
    'resources': Icons.grass,
    'animals': Icons.pets,
    'monsters': Icons.bug_report,
    'giants': Icons.whatshot,
    'misc': Icons.terrain,
    'global': Icons.public,
    'survivors': Icons.groups,
    'events': Icons.event,
    'lunar_mutations': Icons.dark_mode,
  };
  String groupLabel(String group) => 'group_$group';
  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode == 'ru' ? 1 : 0;
    final rows = worldRows
        .where(
          (r) =>
              r[5] == (widget.caves ? 'cave' : 'forest') &&
              r[3] == (generation ? 'WORLDGEN' : 'WORLDSETTINGS'),
        )
        .toList();
    final groups = rows.map((r) => r[4]).toSet();
    final filtered =
        rows
            .where(
              (r) =>
                  (group.isEmpty || group == r[4]) &&
                  ('${r[lang + 1]} ${r[0]}'.toLowerCase().contains(query)),
            )
            .toList()
          ..sort((a, b) => a[lang + 1].compareTo(b[lang + 1]));
    return LauncherDialog(
      title: Text(context.t(widget.caves ? 'caveSettings' : 'surfaceSettings')),
      content: SizedBox(
        width: 700,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final gen in [false, true])
                  ChoiceChip(
                    label: Text(
                      context.t(gen ? 'worldGeneration' : 'worldRules'),
                    ),
                    selected: gen == generation,
                    onSelected: (_) => setState(() {
                      generation = gen;
                      group = '';
                    }),
                  ),
              ],
            ),
            if (generation)
              Text(
                context.t('newTerrainOnly'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: context.t('searchOptions'),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (v) =>
                        setState(() => query = v.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(generation),
                    isExpanded: true,
                    initialValue: group,
                    decoration: InputDecoration(
                      labelText: context.t('category'),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(context.t('allCategories')),
                      ),
                      for (final g in groups)
                        DropdownMenuItem(
                          value: g,
                          child: Text(context.t(groupLabel(g))),
                        ),
                    ],
                    onChanged: (v) => setState(() => group = v ?? ''),
                  ),
                ),
              ],
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text(context.t('noModResults')))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final r = filtered[i],
                            key = r[0],
                            choices = worldChoices[r[6]]!;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              if (iconsByName['${generation ? 'worldgen' : 'worldsettings'}/${r[7]}']
                                  case final bytes?)
                                Image.memory(
                                  bytes,
                                  width: 32,
                                  height: 32,
                                  excludeFromSemantics: true,
                                )
                              else
                                Icon(icons[r[4]] ?? Icons.tune, size: 24),
                              const SizedBox(width: 10),
                              Expanded(child: Text(r[lang + 1])),
                              const SizedBox(width: 8),
                              Flexible(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: values[key] ?? '',
                                  items: [
                                    DropdownMenuItem(
                                      value: '',
                                      child: Text(context.t('usePreset')),
                                    ),
                                    for (final e in choices.entries)
                                      DropdownMenuItem(
                                        value: e.key,
                                        child: Text(
                                          e.value[lang],
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                  onChanged: (v) => setState(() {
                                    if (v == null || v.isEmpty) {
                                      values.remove(key);
                                    } else {
                                      values[key] = v;
                                    }
                                  }),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, values),
          child: Text(context.t('applyOptions')),
        ),
      ],
    );
  }
}
