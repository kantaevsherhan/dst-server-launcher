import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'icons.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

import '../app/strings.dart';

Future<String?> selectDirectory() async =>
    (await FilePicker.pickDirectory())?.toFilePath();

Future<void> openExternal(String address) async {
  if (!await launchUrl(
    Uri.parse(address),
    mode: LaunchMode.externalApplication,
  )) {
    throw StateError('Cannot open $address');
  }
}

Future<void> openFolder(String value) async {
  final result = await Process.run(
    Platform.isWindows ? 'explorer.exe' : 'xdg-open',
    [value],
  );
  if (result.exitCode != 0 && !Platform.isWindows) {
    throw const FileSystemException('Could not open folder');
  }
}

Future<void> guard(
  BuildContext context,
  Future<void> Function() task, {
  String? success,
}) async {
  try {
    await task();
    if (context.mounted && success != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    }
  } catch (e) {
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.t('actionFailed')),
          content: SingleChildScrollView(
            child: SelectableText('${ctx.t('retryHelp')}\n\n$e'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.t('close')),
            ),
          ],
        ),
      );
    }
  }
}

Future<bool> confirm(BuildContext context, String title, String body) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.t('confirm')),
          ),
        ],
      ),
    ) ??
    false;

class PageTitle extends StatelessWidget {
  const PageTitle(this.title, this.subtitle, {this.action, super.key});
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: LayoutBuilder(
      builder: (context, c) {
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
        if (c.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text,
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: text),
            if (action != null) ...[const SizedBox(width: 24), action!],
          ],
        );
      },
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({required this.child, this.padding = 24, super.key});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: EdgeInsets.all(padding), child: child),
  );
}

class InlineHelp extends StatelessWidget {
  const InlineHelp(this.text, {this.warning = false, super.key});
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          warning ? PhosphorIcons.warning() : PhosphorIcons.info(),
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.text, {this.active = false, super.key});
  final String text;
  final bool active;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? scheme.primary.withValues(alpha: .12)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? PhosphorIcons.checkCircle() : PhosphorIcons.circleDashed(),
            size: 14,
            color: active ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: active ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommandBlock extends StatelessWidget {
  const CommandBlock(this.command, {super.key});
  final String command;
  @override
  Widget build(BuildContext context) => Panel(
    padding: 16,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(PhosphorIcons.terminalWindow(), size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(context.t('commandPreview'))),
            IconButton(
              tooltip: context.t('copy'),
              onPressed: () => Clipboard.setData(ClipboardData(text: command)),
              icon: Icon(PhosphorIcons.copy()),
            ),
          ],
        ),
        const Divider(),
        SelectableText(
          command,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.7,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    ),
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 16),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}
