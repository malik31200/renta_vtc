import 'package:flutter/material.dart';

/// Design system "tableau de bord automobile" — CLAUDE.md §6.
/// Fond sombre, lecture rapide, chiffres façon taximètre.
class AppColors {
  AppColors._();

  static const bg = Color(0xFF111318);
  static const surface = Color(0xFF1B1E24);
  static const surfaceAlt = Color(0xFF242830);
  static const divider = Color(0xFF31363F);
  static const amber = Color(0xFFF2A93B);
  static const green = Color(0xFF6FCF97);
  static const red = Color(0xFFE8735A);
  static const textPrimary = Color(0xFFF4F4F0);
  static const textMuted = Color(0xFF8B909A);
}

class AppTheme {
  AppTheme._();

  static const fontFamily = 'Inter';
  static const monoFontFamily = 'Space Mono';

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        surface: AppColors.bg,
        primary: AppColors.amber,
        secondary: AppColors.green,
        error: AppColors.red,
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
            fontFamily: fontFamily,
          )
          .copyWith(
            titleLarge: const TextStyle(
              fontFamily: fontFamily,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
      dividerColor: AppColors.divider,
      cardColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        isDense: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: const Color(0xFF161616),
          padding: const EdgeInsets.symmetric(vertical: 17),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bg,
        selectedItemColor: AppColors.amber,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Style "compteur numérique" pour les montants et distances.
  static const TextStyle mono = TextStyle(
    fontFamily: monoFontFamily,
    color: AppColors.textPrimary,
  );
}
