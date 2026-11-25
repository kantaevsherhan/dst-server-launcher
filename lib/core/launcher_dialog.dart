import 'package:flutter/material.dart';

/// Compact beveled frame shared by the Workshop and settings editors.
class LauncherDialog extends StatelessWidget {
  const LauncherDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });
  final Widget title, content;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      actionsPadding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      titleTextStyle: theme.textTheme.titleLarge,
      title: title,
      content: content,
      actions: actions,
    );
  }
}
