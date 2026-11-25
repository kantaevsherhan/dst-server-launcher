import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/controller.dart';
import '../app/strings.dart';
import '../core/icons.dart';
import '../core/launcher_dialog.dart';
import '../core/widgets.dart';
import '../data/workshop_service.dart';
import '../data/steam_subscriptions.dart';
import '../domain/models.dart';

Future<ModSpec?> browseMods(
  BuildContext context, {
  bool select = false,
  Map<String, String>? added,
  Future<void> Function(ModSpec)? onAdd,
  bool subscriptions = false,
}) => showDialog<ModSpec>(
  context: context,
  builder: (_) => _Catalog(
    select: select,
    onAdd: onAdd,
    added:
        added ??
        {
          for (final p in context.read<LauncherController>().profiles)
            for (final m in p.mods) m.id: p.name,
        },
    subscriptions: subscriptions,
    repository: context.read<LauncherController>().workshop,
  ),
);

Future<void> showMod(BuildContext context, WorkshopEntry entry) =>
    showDialog<void>(
      context: context,
      builder: (ctx) => LauncherDialog(
        title: Text(entry.mod.title),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.mod.preview != null)
                  Image.network(
                    entry.mod.preview!,
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                const SizedBox(height: 12),
                SelectableText('Workshop ${entry.mod.id}'),
                const SizedBox(height: 12),
                SelectableText(
                  entry.description.isEmpty
                      ? ctx.t('noModDescription')
                      : entry.description,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.t('close')),
          ),
        ],
      ),
    );

class _Catalog extends StatefulWidget {
  const _Catalog({
    required this.repository,
    required this.select,
    required this.added,
    this.onAdd,
    required this.subscriptions,
  });
  final SteamWorkshopRepository repository;
  final bool select, subscriptions;
  final Map<String, String> added;
  final Future<void> Function(ModSpec)? onAdd;
  @override
  State<_Catalog> createState() => _CatalogState();
}

class _CatalogState extends State<_Catalog> {
  late final added = Map<String, String>.of(widget.added);
  bool adding = false;
  final input = TextEditingController();
  int page = 1;
  String search = '';
  List<SteamSubscriptions> accounts = [];
  SteamSubscriptions? account;
  late Future<List<WorkshopEntry>> results = fetch();

  Future<List<WorkshopEntry>> fetch() async {
    if (!widget.subscriptions) return widget.repository.browse(search, page);
    accounts = await SteamSubscriptions.accounts();
    if (accounts.length == 1) account = accounts.single;
    if (account == null) return [];
    return widget.repository.subscriptions(await account!.ids());
  }

  void load(String query, int number) => setState(() {
    search = query.trim();
    page = number;
    results = fetch();
  });
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LauncherDialog(
    title: Text(
      context.t(widget.subscriptions ? 'mySubscriptions' : 'modCatalog'),
    ),
    content: SizedBox(
      width: 660,
      height: 450,
      child: Column(
        children: [
          if (widget.subscriptions)
            TextField(
              controller: input,
              decoration: InputDecoration(labelText: context.t('findMod')),
              onChanged: (v) => setState(() => search = v.trim()),
            )
          else
            TextField(
              controller: input,
              onSubmitted: (q) => load(q, 1),
              decoration: InputDecoration(
                labelText: context.t('findMod'),
                suffixIcon: IconButton(
                  tooltip: context.t('findMod'),
                  onPressed: () => load(input.text, 1),
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<WorkshopEntry>>(
              future: results,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ctx.t('catalogUnavailable')),
                        TextButton(
                          onPressed: () => load(search, page),
                          child: Text(ctx.t('refresh')),
                        ),
                      ],
                    ),
                  );
                }
                final entries = (snapshot.data ?? [])
                    .where(
                      (e) =>
                          !widget.subscriptions ||
                          e.mod.title.toLowerCase().contains(
                            search.toLowerCase(),
                          ) ||
                          e.mod.id.contains(search),
                    )
                    .toList();
                return Column(
                  children: [
                    if (widget.subscriptions && accounts.length > 1)
                      DropdownButton<String>(
                        isExpanded: true,
                        value: account?.account,
                        hint: Text(ctx.t('chooseSteamAccount')),
                        items: [
                          for (final a in accounts)
                            DropdownMenuItem(
                              value: a.account,
                              child: Text('Steam · ${a.account}'),
                            ),
                        ],
                        onChanged: (id) {
                          account = accounts.firstWhere((a) => a.account == id);
                          load(search, 1);
                        },
                      ),
                    Expanded(
                      child: entries.isEmpty
                          ? Center(
                              child: Text(
                                ctx.t(
                                  widget.subscriptions && accounts.isEmpty
                                      ? 'noLocalSubscriptions'
                                      : 'noModResults',
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: entries.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final entry = entries[i], mod = entry.mod;
                                return ListTile(
                                  title: Text(mod.title),
                                  subtitle: Text(
                                    entry.selectable
                                        ? 'Workshop ${mod.id}'
                                        : ctx.t(
                                            entry.clientOnly
                                                ? 'clientOnlyMod'
                                                : 'unselectableMod',
                                          ),
                                  ),
                                  leading: mod.preview == null
                                      ? Icon(PhosphorIcons.puzzlePiece())
                                      : Image.network(
                                          mod.preview!,
                                          width: 52,
                                          height: 52,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              Icon(PhosphorIcons.puzzlePiece()),
                                        ),
                                  onTap: () => showMod(ctx, entry),
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  trailing: added.containsKey(mod.id)
                                      ? Tooltip(
                                          message:
                                              '${ctx.t('alreadyAdded')} ${added[mod.id]}',
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.check, size: 18),
                                              const SizedBox(width: 4),
                                              Text(ctx.t('alreadyAdded')),
                                            ],
                                          ),
                                        )
                                      : widget.select
                                      ? IconButton(
                                          tooltip: ctx.t('addMod'),
                                          icon: Icon(PhosphorIcons.plus()),
                                          onPressed: entry.selectable && !adding
                                              ? () async {
                                                  if (widget.onAdd == null) {
                                                    Navigator.pop(ctx, mod);
                                                    return;
                                                  }
                                                  setState(() => adding = true);
                                                  await guard(ctx, () async {
                                                    await widget.onAdd!(mod);
                                                    if (mounted) {
                                                      setState(
                                                        () =>
                                                            added[mod.id] = '',
                                                      );
                                                    }
                                                  });
                                                  if (mounted) {
                                                    setState(
                                                      () => adding = false,
                                                    );
                                                  }
                                                }
                                              : null,
                                        )
                                      : null,
                                );
                              },
                            ),
                    ),
                    if (widget.subscriptions)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => load(search, 1),
                          icon: const Icon(Icons.refresh),
                          label: Text(ctx.t('refresh')),
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: ctx.t('back'),
                            onPressed: page > 1
                                ? () => load(search, page - 1)
                                : null,
                            icon: Icon(PhosphorIcons.arrowLeft()),
                          ),
                          Text('$page'),
                          IconButton(
                            tooltip: ctx.t('next'),
                            onPressed: entries.isEmpty
                                ? null
                                : () => load(search, page + 1),
                            icon: Icon(PhosphorIcons.arrowRight()),
                          ),
                        ],
                      ),
                  ],
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
        child: Text(context.t('close')),
      ),
    ],
  );
}
