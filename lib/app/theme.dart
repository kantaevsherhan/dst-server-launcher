import 'package:flutter/material.dart';

abstract final class Tokens {
  static const background = Color(0xff292d2a);
  static const panel = Color(0xff333933);
  static const raised = Color(0xff41483f);
  static const green = Color(0xffb4c6a8);
  static const amber = Color(0xffe3b46c);
  static const ink = Color(0xfff6f1e8);
  static const muted = Color(0xffc8cabe);
  static const line = Color(0xff738173);
  static const danger = Color(0xffffb4ab);
  static const radius = 6.0;
  static const gap = 24.0;
}

ThemeData launcherTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Tokens.green,
        brightness: brightness,
      ).copyWith(
        primary: dark ? Tokens.green : const Color(0xff506954),
        onPrimary: dark ? Tokens.background : Colors.white,
        surface: dark ? Tokens.background : const Color(0xfffbf8f0),
        onSurface: dark ? Tokens.ink : const Color(0xff343b34),
        onSurfaceVariant: dark ? Tokens.muted : const Color(0xff586357),
        surfaceContainer: dark ? Tokens.panel : const Color(0xfff3efe5),
        surfaceContainerHighest: dark ? Tokens.raised : const Color(0xffe4eadb),
        outline: dark ? Tokens.line : const Color(0xff76806f),
        error: dark ? Tokens.danger : const Color(0xffa32f28),
      );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'Inter',
    brightness: brightness,
  );
  const paperEdge = BeveledRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(8),
      topRight: Radius.circular(3),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(9),
    ),
  );
  const buttonType = TextStyle(
    fontFamily: 'Neucha',
    fontSize: 20,
    height: 1.15,
  );
  return base.copyWith(
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: paperEdge,
        minimumSize: const Size(48, 48),
        textStyle: buttonType,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: paperEdge,
        textStyle: buttonType,
        minimumSize: const Size(56, 48),
        selectedBackgroundColor: scheme.surfaceContainerHighest,
        selectedForegroundColor: scheme.onSurface,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: paperEdge,
      labelStyle: buttonType.copyWith(fontSize: 18),
    ),

    textTheme: base.textTheme.copyWith(
      displaySmall: TextStyle(
        fontFamily: 'Neucha',
        fontSize: 40,
        height: 1.12,
        fontWeight: FontWeight.w600,
        letterSpacing: -1,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Neucha',
        fontSize: 36,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Neucha',
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Neucha',
        fontSize: 21,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        height: 1.55,
        color: scheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        height: 1.5,
        color: scheme.onSurfaceVariant,
      ),
    ),
    dividerColor: scheme.outline.withValues(alpha: .4),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainer,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.radius),
        side: BorderSide(color: scheme.outline.withValues(alpha: .45)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: paperEdge,
        side: BorderSide(color: scheme.onSurface, width: 1.5),
        textStyle: buttonType,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: paperEdge,
        textStyle: buttonType,
        side: BorderSide(color: scheme.outline, width: 1.5),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainer,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      indicatorColor: scheme.primary.withValues(alpha: .15),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
    ),
  );
}
