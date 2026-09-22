import 'package:flutter/material.dart';

/// Яркая игровая палитра в духе Duolingo: сочные цвета, крупная
/// типографика, «пухлые» кнопки с жёсткой тенью снизу.
class Palette {
  static const Color bg = Color(0xFFFFFDF7);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8E8E8);

  static const Color green = Color(0xFF4CB944);
  static const Color greenDark = Color(0xFF379630);
  static const Color greenSoft = Color(0xFFE4F6E2);

  static const Color blue = Color(0xFF1CB0F6);
  static const Color blueDark = Color(0xFF1899D6);

  static const Color yellow = Color(0xFFFFC800);
  static const Color yellowDark = Color(0xFFE0A800);

  static const Color orange = Color(0xFFFF9600);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color coralDark = Color(0xFFE14C4C);
  static const Color purple = Color(0xFFA560E8);

  static const Color ink = Color(0xFF3C3C3C);
  static const Color inkSoft = Color(0xFF8F8F8F);

  static const Color skyTop = Color(0xFFA6E4FF);
  static const Color skyBottom = Color(0xFFEAF9E0);
  static const Color grass = Color(0xFF90D26D);
  static const Color grassDark = Color(0xFF6FBF4E);
}

class AppTheme {
  static ThemeData light() {
    final ColorScheme scheme =
        ColorScheme.fromSeed(seedColor: Palette.green).copyWith(
      primary: Palette.green,
      secondary: Palette.blue,
      surface: Palette.card,
      error: Palette.coral,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Palette.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.bg,
        foregroundColor: Palette.ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Palette.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Palette.card,
        selectedItemColor: Palette.green,
        unselectedItemColor: Palette.inkSoft,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.green,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.ink,
          side: const BorderSide(color: Palette.border, width: 2),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Palette.ink,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge:
            TextStyle(color: Palette.ink, fontWeight: FontWeight.w800, fontSize: 28),
        headlineMedium:
            TextStyle(color: Palette.ink, fontWeight: FontWeight.w800, fontSize: 22),
        titleMedium:
            TextStyle(color: Palette.ink, fontWeight: FontWeight.w700, fontSize: 16),
        bodyMedium: TextStyle(color: Palette.ink, fontSize: 15, height: 1.45),
        bodySmall: TextStyle(color: Palette.inkSoft, fontSize: 13, height: 1.4),
        labelSmall: TextStyle(color: Palette.inkSoft, fontSize: 11),
      ),
    );
  }
}
