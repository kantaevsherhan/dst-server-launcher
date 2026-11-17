import 'package:flutter/material.dart';

abstract final class Tokens {
  static const background = Color(0xff111716);
  static const panel = Color(0xff1b2421);
  static const raised = Color(0xff25312c);
  static const green = Color(0xff83c76d);
  static const amber = Color(0xffe3b46c);
  static const ink = Color(0xffeef5ee);
  static const muted = Color(0xffadbbb2);
  static const line = Color(0xff46594c);
  static const danger = Color(0xffffb4ab);
  static const radius = 12.0;
  static const gap = 24.0;
}

ThemeData launcherTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Tokens.green,
        brightness: brightness,
      ).copyWith(
        primary: dark ? Tokens.green : const Color(0xff35662a),
        onPrimary: dark ? Tokens.background : Colors.white,
        surface: dark ? Tokens.background : const Color(0xfff5f5ec),
        onSurface: dark ? Tokens.ink : const Color(0xff17211e),
        onSurfaceVariant: dark ? Tokens.muted : const Color(0xff4e6054),
        surfaceContainer: dark ? Tokens.panel : const Color(0xffe9ede2),
        surfaceContainerHighest: dark ? Tokens.raised : const Color(0xffdce4d6),
        outline: dark ? Tokens.line : const Color(0xff73856d),
        error: dark ? Tokens.danger : const Color(0xffa32f28),
      );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'Inter',
    brightness: brightness,
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 40,
        height: 1.12,
        fontWeight: FontWeight.w600,
        letterSpacing: -1,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 30,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 22,
        fontWeight: FontWeight.w600,
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
