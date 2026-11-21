import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../app/controller.dart';
import '../app/strings.dart';
import '../core/widgets.dart';
import '../data/config_generator.dart';
import '../data/platform_services.dart';
import '../domain/models.dart';
import 'installation.dart';
import 'workshop.dart';

class WizardScreen extends StatefulWidget {
  const WizardScreen({super.key});
  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  static const steps = [
    'stepPrepare',
    'stepInstall',
    'stepBasics',
    'stepWorld',
    'stepCaves',
    'stepMods',
    'stepNetwork',
    'stepReview',
    'stepLaunch',
  ];
  final name = TextEditingController(),
      description = TextEditingController(),
      password = TextEditingController(),
      players = TextEditingController(text: '6'),
      token = TextEditingController();
  final form = GlobalKey<FormState>();
  int step = 0;
  bool caves = true, pvp = false, pause = true, obscure = true, saving = false;
  String mode = 'survival',
      worldSize = 'default',
      id = ServerProfile.newId(),
      secret = ServerProfile.randomKey();
  String? root;
  List<ModSpec> mods = [];
  Map<int, bool>? ports;
  Timer? debounce;
  late LauncherController controller;
  @override
  void initState() {
    super.initState();
    controller = context.read<LauncherController>();
    final saved = controller.preferences.getString('wizardDraft');
    if (saved != null) {
      try {
        final j = jsonDecode(saved);
        name.text = j['name'] ?? '';
        description.text = j['description'] ?? '';
        players.text = j['slots'] ?? '6';
        mode = j['mode'] ?? 'survival';
        caves = j['caves'] ?? true;
        pvp = j['pvp'] ?? false;
        pause = j['pause'] ?? true;
        worldSize = j['worldSize'] ?? 'default';
        root = j['root'];
        mods = (j['mods'] as List? ?? [])
            .map((m) => ModSpec.fromJson(m))
            .toList();
      } catch (_) {
        /* A malformed draft must never prevent opening setup. */
      }
    }
    for (final field in [name, description, players]) {
      field.addListener(_saveDraft);
    }
  }

  void _saveDraft() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), _persistDraft);
  }

  void _persistDraft() {
    unawaited(
      controller.preferences.setString(
        'wizardDraft',
        jsonEncode({
          'name': name.text,
          'description': description.text,
          'slots': players.text,
          'mode': mode,
          'caves': caves,
          'pvp': pvp,
          'pause': pause,
          'worldSize': worldSize,
          'root': root,
          'mods': mods.map((m) => m.toJson()).toList(),
        }),
      ),
    );
  }

  @override
  void dispose() {
    if (debounce?.isActive == true && step < 8) _persistDraft();
    debounce?.cancel();
    for (final c in [name, description, password, players, token]) {
      c.dispose();
    }
    super.dispose();
  }

  ServerProfile get profile => ServerProfile(
    id: id,
    name: name.text.trim(),
    description: description.text.trim(),
    password: password.text,
    slots: int.tryParse(players.text) ?? 6,
    installDir: controller.installation.server ?? '',
    storageRoot: root ?? controller.storageRoot,
    secret: secret,
    portBase: controller.nextPort(),
    mode: mode,
    caves: caves,
    pvp: pvp,
    pause: pause,
    worldSize: worldSize,
    mods: mods,
  );
  String? singleLine(String? value, {bool required = false}) {
    if (required && (value == null || value.trim().isEmpty)) {
      return context.t('required');
    }
    if (RegExp(r'[\x00-\x1f\x7f]').hasMatch(value ?? '')) {
      return context.t('invalidText');
    }
    return null;
  }

  Future<void> advance() async {
    if (step == 1 && !controller.localTarget) {
      context.go('/');
      return;
    }
    if (step == 1 && controller.installation.server == null) {
      await guard(
        context,
        () async => throw StateError(context.t('needInstall')),
      );
      return;
    }
    if (step == 2 && !form.currentState!.validate()) return;
    if (step == 6 &&
        (token.text.trim().isEmpty ||
            RegExp(r'[\r\n\x00]').hasMatch(token.text))) {
      await guard(
        context,
        () async => throw StateError(context.t('needToken')),
      );
      return;
    }
    if (step == 7) {
      setState(() => saving = true);
      final portBusyText = context.t('portBusy');
      await guard(context, () async {
        final checks = await LocalPortInspector().inspect(profile.ports);
        if (checks.values.contains(false)) {
          throw StateError(
            '$portBusyText: ${checks.entries.where((e) => !e.value).map((e) => e.key).join(', ')}',
          );
        }
        await controller.create(profile, token.text);
        debounce?.cancel();
        token.clear();
        if (mounted) setState(() => step = 8);
      });
      if (mounted) setState(() => saving = false);
    } else if (step == 8) {
      context.go('/server/$id');
    } else {
      setState(() => step++);
      _saveDraft();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LauncherController>();
    final scheme = Theme.of(context).colorScheme;
    final count = c.localTarget ? steps.length : 2;
    final progress = '${context.t('stepOf')} ${step + 1} / $count';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: scheme.surfaceContainer,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Row(
            children: [
              Image.asset(
                'assets/images/tent.png',
                width: 36,
                height: 36,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.t('setupTitle'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Semantics(liveRegion: true, child: Text(progress)),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: (step + 1) / count,
          minHeight: 3,
          semanticsLabel: progress,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rail =
                  constraints.maxWidth >= 960 &&
                  MediaQuery.textScalerOf(context).scale(14) < 22;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (rail) ...[
                    SizedBox(
                      width: 208,
                      child: Material(
                        color: scheme.surfaceContainer,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          children: [
                            for (var i = 0; i < count; i++)
                              ListTile(
                                dense: true,
                                selected: i == step,
                                selectedTileColor:
                                    scheme.surfaceContainerHighest,
                                leading: i < step
                                    ? Icon(PhosphorIcons.check(), size: 16)
                                    : Text('${i + 1}'),
                                title: Text(context.t(steps[i])),
                                onTap: i < step && step < 8 && !saving
                                    ? () => setState(() => step = i)
                                    : null,
                                enabled: i <= step,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      key: ValueKey(step),
                      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 880),
                          child: SizedBox(
                            width: double.infinity,
                            child: _content(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const Divider(height: 1),
        Container(
          color: scheme.surfaceContainer,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 12,
            overflowSpacing: 8,
            children: [
              if (step < 8)
                TextButton(
                  onPressed: saving ? null : () => context.go('/'),
                  child: Text(context.t('cancel')),
                ),
              if (step > 0 && step < 8)
                OutlinedButton(
                  onPressed: saving ? null : () => setState(() => step--),
                  child: Text(context.t('back')),
                ),
              FilledButton(
                onPressed: saving ? null : advance,
                child: Text(
                  context.t(
                    saving
                        ? 'creating'
                        : !c.localTarget && step == 1
                        ? 'finishGuide'
                        : step == 7
                        ? 'finishReview'
                        : step == 8
                        ? 'openManagement'
                        : 'next',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heading(String title, String body, {Widget? child}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(context.t(title), style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      Text(
        context.t(body),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 24),
      ?child,
    ],
  );
  Widget _content() => switch (step) {
    0 => _heading(
      'prepareTitle',
      'prepareBody',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TargetSystemPicker(controller: controller),
          const SizedBox(height: 12),
          Text(
            context.t(
              controller.localTarget ? 'localTargetHelp' : 'otherTargetHelp',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.t('requirements'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(context.t('requirementsBody')),
          if (controller.localTarget) ...[
            const SizedBox(height: 24),
            Text(
              context.t('storagePath'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(root ?? controller.storageRoot),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => guard(context, () async {
                    final folder = await selectDirectory();
                    if (folder != null) {
                      if (!mounted) return;
                      setState(() => root = folder);
                      _saveDraft();
                    }
                  }),
                  icon: Icon(PhosphorIcons.folderOpen()),
                  label: Text(context.t('browse')),
                ),
                OutlinedButton(
                  onPressed: () => guard(context, () async {
                    final dir = Directory(root ?? controller.storageRoot);
                    await dir.create(recursive: true);
                    final probe = File(
                      '${dir.path}${Platform.pathSeparator}.launcher-write-${DateTime.now().microsecondsSinceEpoch}',
                    );
                    await probe.writeAsString('check');
                    await probe.delete();
                  }, success: context.t('writable')),
                  child: Text(context.t('checkStorage')),
                ),
              ],
            ),
            const SizedBox(height: 20),
            InlineHelp(context.t('diskHint')),
          ],
        ],
      ),
    ),
    1 => _heading(
      controller.localTarget ? 'installTitle' : 'targetInstallTitle',
      'installHelp',
      child: const InstallationPanel(),
    ),
    2 => _heading(
      'basicsTitle',
      'readyHint',
      child: Form(
        key: form,
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['friendsPreset', 'beginnerPreset', 'hardPreset']
                  .map(
                    (v) => ActionChip(
                      label: Text(context.t(v)),
                      onPressed: () {
                        setState(() {
                          mode = v == 'beginnerPreset' ? 'endless' : 'survival';
                          players.text = v == 'hardPreset' ? '4' : '6';
                          pvp = false;
                        });
                        _saveDraft();
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: name,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: context.t('name'),
                hintText: context.t('nameHint'),
              ),
              validator: (v) => singleLine(v, required: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: description,
              maxLength: 256,
              decoration: InputDecoration(labelText: context.t('description')),
              validator: singleLine,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: password,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: context.t('password'),
                suffixIcon: IconButton(
                  tooltip: context.t('showPassword'),
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(
                    obscure ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
                  ),
                ),
              ),
              validator: singleLine,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: players,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: context.t('players')),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < 1 || n > 64
                    ? context.t('invalidPlayers')
                    : null;
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: mode,
              decoration: InputDecoration(labelText: context.t('mode')),
              items: ['survival', 'endless', 'wilderness']
                  .map(
                    (v) =>
                        DropdownMenuItem(value: v, child: Text(context.t(v))),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => mode = v!);
                _saveDraft();
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.t('pvp')),
              value: pvp,
              onChanged: (v) {
                setState(() => pvp = v);
                _saveDraft();
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.t('pause')),
              value: pause,
              onChanged: (v) {
                setState(() => pause = v);
                _saveDraft();
              },
            ),
          ],
        ),
      ),
    ),
    3 => _heading(
      'worldTitle',
      'worldHelp',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Panel(
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.treeEvergreen(),
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    context.t('worldPreset'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: worldSize,
            decoration: InputDecoration(labelText: context.t('worldSize')),
            items: ['default', 'small', 'medium', 'large', 'huge']
                .map(
                  (v) => DropdownMenuItem(value: v, child: Text(context.t(v))),
                )
                .toList(),
            onChanged: (v) {
              setState(() => worldSize = v!);
              _saveDraft();
            },
          ),
        ],
      ),
    ),
    4 => _heading(
      'cavesTitle',
      'cavesBody',
      child: Panel(
        child: Column(
          children: [
            Icon(
              PhosphorIcons.mountains(),
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text(context.t('enableCaves')),
              subtitle: Text(context.t('cavePreset')),
              value: caves,
              onChanged: (v) {
                setState(() {
                  caves = v;
                  ports = null;
                });
                _saveDraft();
              },
            ),
          ],
        ),
      ),
    ),
    5 => _heading(
      'modsTitle',
      'modsHelp',
      child: ModEditor(
        mods: mods,
        onChanged: (value) async {
          setState(() => mods = value);
          _saveDraft();
        },
      ),
    ),
    6 => _heading(
      'tokenTitle',
      'tokenHelp',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: token,
            obscureText: obscure,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: context.t('token'),
              suffixIcon: IconButton(
                tooltip: context.t('showPassword'),
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(PhosphorIcons.eye()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => guard(
              context,
              () => openExternal(
                'https://accounts.klei.com/account/game/servers?game=DontStarveTogether',
              ),
            ),
            icon: Icon(PhosphorIcons.arrowSquareOut(), size: 18),
            label: Text(context.t('getToken')),
          ),
          SectionLabel(context.t('network')),
          InlineHelp(context.t('networkHelp')),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => guard(context, () async {
              final values = await LocalPortInspector().inspect(profile.ports);
              if (mounted) setState(() => ports = values);
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
                    (e) => StatusChip(
                      '${e.key} UDP · ${context.t(e.value ? 'portFree' : 'portBusy')}',
                      active: e.value,
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 16),
          Text(context.t('externalUnknown')),
        ],
      ),
    ),
    7 => _heading(
      'reviewTitle',
      'reviewHelp',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/crow.png',
                  height: 64,
                  excludeFromSemantics: true,
                ),
                const SizedBox(height: 8),
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  '${context.t('slots')}: ${profile.slots}  ·  ${context.t(profile.mode)}',
                ),
                const SizedBox(height: 12),
                Text(
                  '${context.t('caves')}: ${context.t(caves ? 'enabled' : 'disabled')}  ·  ${context.t('mods')}: ${mods.length}',
                ),
                const SizedBox(height: 12),
                SelectableText(profile.storageRoot),
                const SizedBox(height: 16),
                StatusChip(
                  context.t(token.text.isEmpty ? 'tokenMissing' : 'tokenAdded'),
                  active: token.text.isNotEmpty,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ExpansionTile(
            title: Text(context.t('previewFiles')),
            children: [
              for (final entry
                  in ClusterConfigGenerator().generate(profile).entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key),
                      const SizedBox(height: 8),
                      CommandBlock(
                        entry.key == 'cluster.ini'
                            ? entry.value
                                  .replaceAll(profile.secret, '[redacted]')
                                  .replaceAll(
                                    RegExp(
                                      r'^cluster_password =.*$',
                                      multiLine: true,
                                    ),
                                    'cluster_password = [redacted]',
                                  )
                            : entry.value,
                      ),
                    ],
                  ),
                ),
              Text('mods/dedicated_server_mods_setup.lua'),
              CommandBlock(ClusterConfigGenerator().workshopSetup(mods)),
            ],
          ),
        ],
      ),
    ),
    _ => _heading(
      'launchTitle',
      'launchHelp',
      child: Panel(
        child: Column(
          children: [
            Image.asset(
              'assets/images/fire.png',
              height: 84,
              excludeFromSemantics: true,
            ),
            const SizedBox(height: 24),
            Text(name.text, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            InlineHelp(context.t('serverHelp')),
          ],
        ),
      ),
    ),
  };
}
