import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../app/controller.dart';
import '../app/strings.dart';
import '../core/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.watch<LauncherController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitle(
            context.t('settings'),
            context.t('settingsSubtitle'),
            action: Image.asset(
              'assets/images/gear.png',
              height: 56,
              excludeFromSemantics: true,
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('appearance'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ChoiceChip(
                      label: Text(context.t('dark')),
                      selected: c.themeMode == ThemeMode.dark,
                      onSelected: (_) =>
                          guard(context, () => c.setTheme('dark')),
                    ),
                    ChoiceChip(
                      label: Text(context.t('light')),
                      selected: c.themeMode == ThemeMode.light,
                      onSelected: (_) =>
                          guard(context, () => c.setTheme('light')),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  key: ValueKey(c.language),
                  initialValue: c.language,
                  decoration: InputDecoration(labelText: context.t('language')),
                  items: const [
                    DropdownMenuItem(value: 'ru', child: Text('Русский')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (v) => guard(context, () => c.setLanguage(v!)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('storagePath'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SelectableText(c.storageRoot),
                const SizedBox(height: 16),
                Text(context.t('storageHelp')),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => guard(context, () async {
                    final path = await selectDirectory();
                    if (path != null) await c.setStorageRoot(path);
                  }),
                  icon: Icon(PhosphorIcons.folderOpen()),
                  label: Text(context.t('browse')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('closePolicy'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(context.t('closeHelp')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('diagnostics'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(context.t('diagnosticsHelp')),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => guard(context, () async {
                    final title = context.t('diagnostics');
                    final generated = await c.diagnostics();
                    await FilePicker.saveFile(
                      fileName: 'dst-diagnostics.json',
                      dialogTitle: title,
                      bytes: await File(generated).readAsBytes(),
                    );
                  }),
                  icon: Icon(PhosphorIcons.fileArrowDown()),
                  label: Text(context.t('diagnostics')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.t('unofficial'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
