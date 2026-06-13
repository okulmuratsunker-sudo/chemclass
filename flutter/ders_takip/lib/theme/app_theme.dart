import 'package:flutter/material.dart';

/// Colors mirroring the `:root` / `[data-theme="light"]` CSS variables in
/// `ders-takip.html`.
class AppColors {
  final Color bg;
  final Color s1;
  final Color s2;
  final Color border;
  final Color border2;
  final Color green;
  final Color green2;
  final Color blue;
  final Color red;
  final Color yellow;
  final Color text1;
  final Color text2;
  final Color text3;

  const AppColors({
    required this.bg,
    required this.s1,
    required this.s2,
    required this.border,
    required this.border2,
    required this.green,
    required this.green2,
    required this.blue,
    required this.red,
    required this.yellow,
    required this.text1,
    required this.text2,
    required this.text3,
  });

  static const dark = AppColors(
    bg: Color(0xFF080C14),
    s1: Color(0xFF0D1420),
    s2: Color(0xFF111927),
    border: Color(0xFF1C2A3A),
    border2: Color(0xFF243347),
    green: Color(0xFF00E5B0),
    green2: Color(0xFF00B88C),
    blue: Color(0xFF3D8BFF),
    red: Color(0xFFFF4757),
    yellow: Color(0xFFFFD32A),
    text1: Color(0xFFE8F4F8),
    text2: Color(0xFF7A9AB5),
    text3: Color(0xFF3D5870),
  );

  static const light = AppColors(
    bg: Color(0xFFF0F4F8),
    s1: Color(0xFFFFFFFF),
    s2: Color(0xFFE8EDF2),
    border: Color(0xFFC9D4DE),
    border2: Color(0xFFA8BECE),
    green: Color(0xFF009E7A),
    green2: Color(0xFF007A5E),
    blue: Color(0xFF2A78F0),
    red: Color(0xFFD42F3F),
    yellow: Color(0xFFA07000),
    text1: Color(0xFF0A1628),
    text2: Color(0xFF4A6080),
    text3: Color(0xFF7A96B0),
  );
}

extension AppColorsX on ThemeData {
  AppColors get dt => brightness == Brightness.dark ? AppColors.dark : AppColors.light;
}

class AppTheme {
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);
  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors c, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
      fontFamily: 'Segoe UI',
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.green,
        onPrimary: const Color(0xFF06251F),
        secondary: c.blue,
        onSecondary: Colors.white,
        error: c.red,
        onError: Colors.white,
        surface: c.s1,
        onSurface: c.text1,
        surfaceContainerHighest: c.s2,
        outline: c.border,
      ),
      cardColor: c.s1,
      dividerColor: c.border,
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.text1,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: c.s1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.s2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.green),
        ),
        hintStyle: TextStyle(color: c.text3),
        labelStyle: TextStyle(color: c.text2),
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: c.text1,
            displayColor: c.text1,
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.green,
          foregroundColor: const Color(0xFF06251F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text1,
          side: BorderSide(color: c.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.s2,
        side: BorderSide(color: c.border),
        labelStyle: TextStyle(color: c.text1, fontSize: 12),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.s1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.s1,
        selectedItemColor: c.green,
        unselectedItemColor: c.text2,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.s2,
        contentTextStyle: TextStyle(color: c.text1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
