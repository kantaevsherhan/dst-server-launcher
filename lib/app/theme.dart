import 'package:flutter/material.dart';

abstract final class Tokens {
  static const parchment = Color(0xfff4eedf);
  static const paper = Color(0xffeae2d2);
  static const ink = Color(0xff333338);
  static const slate = Color(0xff52626e);
  static const mist = Color(0xffd8dfe0);
  static const burgundy = Color(0xff794d50);
  static const rose = Color(0xffd6a5a2);
  static const sage = Color(0xff5b6955);
  static const night = Color(0xff30343a);
  static const radius = 6.0;
}

ThemeData launcherTheme() {
  const brightness = Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Tokens.burgundy,
        brightness: brightness,
      ).copyWith(
        primary: Tokens.rose,
        onPrimary: Tokens.ink,
        primaryContainer: const Color(0xff62464a),
        onPrimaryContainer: Tokens.parchment,
        secondary: const Color(0xffb0c3cf),
        secondaryContainer: const Color(0xff485662),
        onSecondaryContainer: Tokens.parchment,
        tertiary: const Color(0xffb4c3a6),
        surface: Tokens.night,
        onSurface: Tokens.parchment,
        onSurfaceVariant: const Color(0xffd2cec6),
        surfaceContainer: const Color(0xff393d43),
        surfaceContainerHighest: const Color(0xff48545d),
        outline: const Color(0xff92999d),
        error: const Color(0xffffb4ac),
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
  ButtonStyle feedback(ButtonStyle style, Color ink) => style.copyWith(
    animationDuration: const Duration(milliseconds: 140),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return null;
      if (states.contains(WidgetState.pressed)) {
        return ink.withValues(alpha: .22);
      }
      if (states.contains(WidgetState.focused)) {
        return ink.withValues(alpha: .18);
      }
      if (states.contains(WidgetState.hovered)) {
        return ink.withValues(alpha: .10);
      }
      return null;
    }),
    foregroundBuilder: (context, states, child) {
      final reduced = MediaQuery.disableAnimationsOf(context);
      final down = states.contains(WidgetState.pressed);
      final over = states.contains(WidgetState.hovered);
      return AnimatedScale(
        scale: reduced || states.contains(WidgetState.disabled)
            ? 1
            : down
            ? .96
            : over
            ? 1.035
            : 1,
        duration: reduced
            ? Duration.zero
            : Duration(milliseconds: down ? 65 : 140),
        curve: Curves.easeOutCubic,
        child: child,
      );
    },
  );
  return base.copyWith(
    textButtonTheme: TextButtonThemeData(
      style: feedback(
        TextButton.styleFrom(
          shape: paperEdge,
          minimumSize: const Size(48, 48),
          textStyle: buttonType,
        ),
        scheme.onSurface,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: feedback(
        SegmentedButton.styleFrom(
          shape: paperEdge,
          textStyle: buttonType,
          minimumSize: const Size(56, 48),
          selectedBackgroundColor: scheme.surfaceContainerHighest,
          selectedForegroundColor: scheme.onSurface,
        ),
        scheme.onSurface,
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
      style: feedback(
        FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: paperEdge,
          side: BorderSide(color: scheme.onSurface, width: 1.5),
          textStyle: buttonType,
        ),
        scheme.onPrimary,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: feedback(
        OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: paperEdge,
          textStyle: buttonType,
          side: BorderSide(color: scheme.outline, width: 1.5),
        ),
        scheme.primary,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: feedback(
        IconButton.styleFrom(minimumSize: const Size(48, 48)),
        scheme.primary,
      ),
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
