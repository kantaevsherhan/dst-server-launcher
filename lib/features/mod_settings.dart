import 'dart:convert';

import 'package:flutter/material.dart';

import '../app/strings.dart';
import '../core/launcher_dialog.dart';
import '../data/mod_settings.dart';
import '../domain/models.dart';

Future<Map<String, Object>?> editModOptions(
  BuildContext context,
  ModSpec mod,
  String? dir,
) => showDialog<Map<String, Object>>(
  context: context,
  builder: (_) => _Options(mod: mod, dir: dir),
);

class _Options extends StatefulWidget {
  const _Options({required this.mod, required this.dir});
  final ModSpec mod;
  final String? dir;
  @override
  State<_Options> createState() => _OptionsState();
}

class _OptionsState extends State<_Options> {
  late final future = loadModOptions(widget.mod.id, widget.dir);
  late final values = Map<String, Object>.from(widget.mod.options);
  final name = TextEditingController(), data = TextEditingController();
  String type = 'string';
  String? error;
  @override
  void dispose() {
    name.dispose();
    data.dispose();
    super.dispose();
  }

  void add() {
    final key = name.text.trim();
    Object? v = data.text;
    if (type == 'number') v = num.tryParse(data.text);
    if (type == 'bool') v = bool.tryParse(data.text.trim());
    if (key.isEmpty ||
        key.length > 256 ||
        v == null ||
        v is num && !v.isFinite) {
      setState(() => error = context.t('invalidOption'));
      return;
    }
    setState(() {
      values[key] = v!;
      error = null;
      name.clear();
      data.clear();
    });
  }

  @override
  Widget build(BuildContext context) => LauncherDialog(
    title: Text(widget.mod.title),
    content: SizedBox(
      width: 620,
      height: 430,
      child: FutureBuilder<List<ModOption>>(
        future: future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final schema = snap.data ?? [];
          return ListView(
            children: [
              if (schema.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(ctx.t('dynamicModOptions')),
                ),
              for (final opt in schema)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(opt.label),
                  subtitle: Text(opt.key),
                  trailing: SizedBox(
                    width: 200,
                    child: DropdownButton<Object>(
                      isExpanded: true,
                      value: opt.choices.containsKey(values[opt.key])
                          ? values[opt.key]
                          : null,
                      hint: Text(
                        opt.choices[opt.initial] ?? ctx.t('usePreset'),
                      ),
                      items: [
                        for (final e in opt.choices.entries)
                          DropdownMenuItem(
                            value: e.key,
                            child: Text(
                              e.value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => values[opt.key] = v!),
                    ),
                  ),
                ),
              if (values.isNotEmpty)
                for (final e in values.entries)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${e.key} = ${jsonEncode(e.value)}'),
                    trailing: IconButton(
                      tooltip: ctx.t('resetOption'),
                      icon: const Icon(Icons.undo),
                      onPressed: () => setState(() => values.remove(e.key)),
                    ),
                  ),
              ExpansionTile(
                title: Text(ctx.t('manualOption')),
                children: [
                  TextField(
                    controller: name,
                    decoration: InputDecoration(labelText: ctx.t('optionKey')),
                  ),
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: type,
                        items: [
                          for (final t in ['string', 'number', 'bool'])
                            DropdownMenuItem(
                              value: t,
                              child: Text(
                                ctx.t(switch (t) {
                                  'number' => 'type_number',
                                  'bool' => 'type_bool',
                                  _ => 'type_string',
                                }),
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => type = v!),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: data,
                          decoration: InputDecoration(
                            labelText: ctx.t('optionValue'),
                            errorText: error,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: ctx.t('addMod'),
                        onPressed: add,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
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
