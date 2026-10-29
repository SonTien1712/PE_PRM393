import 'package:flutter/material.dart';

import 'app_spacing.dart';

abstract final class AppTheme {
  static const income = Color(0xFF15805E);
  static const expense = Color(0xFFCB3F4F);
  static const teal = Color(0xFF007F78);
  static const canvas = Color(0xFFF5F8F7);
  static const ink = Color(0xFF173B37);
  static const muted = Color(0xFF526763);
  static const line = Color(0xFFDCE7E3);
  static const incomeSurface = Color(0xFFF4FBF7);
  static const expenseSurface = Color(0xFFFFF8F9);
  static const warning = Color(0xFF805500);
  static const surfaceCard = Colors.white;
  static const onCard = ink;

  static TextStyle _type(double size, FontWeight weight, {Color color = ink}) =>
      TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: size,
        fontWeight: weight,
        height: 1.4,
        color: color,
      );

  static TextTheme get _textTheme => TextTheme(
    displayLarge: _type(48, FontWeight.w700),
    displayMedium: _type(40, FontWeight.w700),
    displaySmall: _type(36, FontWeight.w700),
    headlineLarge: _type(32, FontWeight.w700),
    headlineMedium: _type(28, FontWeight.w700),
    headlineSmall: _type(24, FontWeight.w700),
    titleLarge: _type(20, FontWeight.w600),
    titleMedium: _type(16, FontWeight.w600),
    titleSmall: _type(14, FontWeight.w600),
    bodyLarge: _type(16, FontWeight.w400),
    bodyMedium: _type(14, FontWeight.w400),
    bodySmall: _type(12, FontWeight.w400, color: muted),
    labelLarge: _type(14, FontWeight.w600),
    labelMedium: _type(12, FontWeight.w500),
    labelSmall: _type(11, FontWeight.w500),
  );

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: teal).copyWith(
      primary: teal,
      onPrimary: Colors.white,
      surface: surfaceCard,
      onSurface: onCard,
      onSurfaceVariant: muted,
      outlineVariant: line,
    );
    return ThemeData(
      fontFamily: 'BeVietnamPro',
      textTheme: _textTheme,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: line,
        titleTextStyle: _type(18, FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(color: Color(0xFF708782)),
        ),
        errorMaxLines: 3,
        helperMaxLines: 3,
        hintStyle: _type(14, FontWeight.w400, color: muted),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        side: const BorderSide(color: line),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: teal,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: surfaceCard,
        indicatorColor: Color(0xFFE0F2EC),
        height: 72,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: line),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.fixed,
        backgroundColor: ink,
      ),
    );
  }
}
