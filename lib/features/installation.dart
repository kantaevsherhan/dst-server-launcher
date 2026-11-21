import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../app/controller.dart';
import '../app/strings.dart';
import '../core/widgets.dart';
import '../data/platform_services.dart';

class InstallationScreen extends StatelessWidget {
  const InstallationScreen({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitle(context.t('installation'), context.t('installHelp')),
        TargetSystemPicker(controller: context.watch<LauncherController>()),
        const SizedBox(height: 24),
        const InstallationPanel(),
      ],
    ),
  );
}

class TargetSystemPicker extends StatelessWidget {
  const TargetSystemPicker({required this.controller, super.key});
  final LauncherController controller;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(context.t('os'), style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      SegmentedButton<TargetPlatformOS>(
        selectedIcon: Icon(PhosphorIcons.check(), size: 16),
        segments: [
          for (final os in TargetPlatformOS.values)
            ButtonSegment(
              value: os,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    os == TargetPlatformOS.windows
                        ? PhosphorIcons.windowsLogo
                        : PhosphorIcons.linuxLogo,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(os.label),
                ],
              ),
            ),
        ],
        selected: {controller.targetSystem},
        onSelectionChanged: (values) =>
            guard(context, () => controller.setTargetSystem(values.single)),
      ),
    ],
  );
}

class InstallationPanel extends StatefulWidget {
  const InstallationPanel({super.key});
  @override
  State<InstallationPanel> createState() => _InstallationPanelState();
}

class _InstallationPanelState extends State<InstallationPanel> {
  String distro = 'Ubuntu';
  final pathController = TextEditingController(
    text: Platform.isLinux
        ? '${Platform.environment['HOME'] ?? '/home/user'}/games/dst-dedicated'
        : '/home/user/games/dst-dedicated',
  );
  @override
  void initState() {
    super.initState();
    if (Platform.isLinux) {
      final file = File('/etc/os-release');
      if (file.existsSync()) {
        distro = LinuxCommands.distribution(file.readAsStringSync());
      }
    }
  }

  @override
  void dispose() {
    pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LauncherController>();
    final install = controller.installation;
    final linux = controller.targetSystem == TargetPlatformOS.linux;
    final destination = pathController.text;
    final validPath =
        destination.startsWith('/') &&
        destination.trim() != '/' &&
        !RegExp(r'[\x00-\x1f\x7f]').hasMatch(destination);
    final script = linux && validPath
        ? LinuxCommands().linuxScript(destination, distro: distro)
        : null;
    final transfer = context
        .t('transferInstructions')
        .replaceAll('{os}', controller.targetSystem.label);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.localTarget) ...[
          Panel(
            child: Column(
              children: [
                _DetectionRow(
                  icon: PhosphorIcons.steamLogo(),
                  title: context.t('steamClient'),
                  value: install.steam,
                  busy: controller.busy,
                ),
                const Divider(height: 32),
                _DetectionRow(
                  icon: PhosphorIcons.desktopTower(),
                  title: context.t('dedicatedServer'),
                  value: install.server,
                  busy: controller.busy,
                ),
                if (install.build != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('${context.t('build')}: ${install.build}'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => guard(
                  context,
                  () => openExternal('steam://install/343050'),
                ),
                icon: Icon(PhosphorIcons.steamLogo(), size: 20),
                label: Text(context.t('steamInstall')),
              ),
              OutlinedButton.icon(
                onPressed: controller.busy
                    ? null
                    : () => guard(context, () => controller.detect()),
                icon: Icon(PhosphorIcons.arrowsClockwise(), size: 18),
                label: Text(context.t(controller.busy ? 'busy' : 'refresh')),
              ),
              OutlinedButton.icon(
                onPressed: () => guard(context, () async {
                  final folder = await selectDirectory();
                  if (folder != null) {
                    await controller.detect(manual: folder);
                    if (controller.installation.server == null) {
                      throw StateError(
                        controller.installation.notes.join('\n'),
                      );
                    }
                  }
                }),
                icon: Icon(PhosphorIcons.folderOpen(), size: 18),
                label: Text(context.t('manualPath')),
              ),
              TextButton(
                onPressed: () => guard(
                  context,
                  () => openExternal('https://store.steampowered.com/about/'),
                ),
                child: Text(context.t('steamDownload')),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InlineHelp(context.t('installHelp')),
          if (install.steam == null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(context.t('steamUnavailable')),
            ),
        ] else ...[
          InlineHelp(transfer),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => guard(context, () async {
              await FilePicker.saveFile(
                dialogTitle: context.t('saveGuide'),
                fileName: 'DST-${controller.targetSystem.label}.txt',
                bytes: Uint8List.fromList(utf8.encode(transfer)),
              );
            }),
            icon: Icon(PhosphorIcons.fileArrowDown()),
            label: Text(context.t('saveGuide')),
          ),
        ],
        if (linux) ...[
          const SizedBox(height: 24),
          ExpansionTile(
            initiallyExpanded: true,
            tilePadding: EdgeInsets.zero,
            title: Text(
              context.t('linuxCommands'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: const Text(
              'Debian · Ubuntu · Linux Mint · Manjaro · Fedora',
            ),
            children: [
              const SizedBox(height: 16),
              InlineHelp(context.t('linuxHelp')),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: distro,
                decoration: InputDecoration(labelText: context.t('distro')),
                items: LinuxCommands.distributions
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => distro = v!),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: pathController,
                decoration: InputDecoration(
                  labelText: context.t('serverPath'),
                  errorText: validPath ? null : context.t('linuxPathError'),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              CommandBlock(LinuxCommands.dependencies(distro)),
              const SizedBox(height: 16),
              if (script != null) CommandBlock(script),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: script == null
                    ? null
                    : () => guard(context, () async {
                        await FilePicker.saveFile(
                          dialogTitle: context.t('saveScript'),
                          fileName: 'install.sh',
                          bytes: Uint8List.fromList(utf8.encode(script)),
                        );
                      }),
                icon: Icon(PhosphorIcons.fileArrowDown()),
                label: Text(context.t('saveScript')),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ],
    );
  }
}

class _DetectionRow extends StatelessWidget {
  const _DetectionRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.busy,
  });
  final IconData icon;
  final String title;
  final String? value;
  final bool busy;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (value != null) ...[
              const SizedBox(height: 6),
              SelectableText(
                value!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      const SizedBox(width: 12),
      busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : StatusChip(
              context.t(value == null ? 'notInstalled' : 'installed'),
              active: value != null,
            ),
    ],
  );
}
