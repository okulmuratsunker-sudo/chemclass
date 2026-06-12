import 'package:flutter/material.dart';

/// Avatar background colors (18% opacity versions of [avatarFg]).
const List<Color> avatarBg = [
  Color(0x2E00D4AA),
  Color(0x2EFF6B35),
  Color(0x2EFFD700),
  Color(0x2EA78BFA),
  Color(0x2EF472B6),
  Color(0x2E38BDF8),
  Color(0x2E34D399),
  Color(0x2EFB923C),
];

/// Avatar foreground / accent colors.
const List<Color> avatarFg = [
  Color(0xFF00D4AA),
  Color(0xFFFF6B35),
  Color(0xFFFFD700),
  Color(0xFFA78BFA),
  Color(0xFFF472B6),
  Color(0xFF38BDF8),
  Color(0xFF34D399),
  Color(0xFFFB923C),
];

/// Colors used for class-comparison bars (subset of [avatarFg]).
const List<Color> compareColors = [
  Color(0xFF00D4AA),
  Color(0xFFFF6B35),
  Color(0xFFFFD700),
  Color(0xFFA78BFA),
  Color(0xFFF472B6),
  Color(0xFF38BDF8),
];

class AppColors {
  final Color bg;
  final Color s1;
  final Color s2;
  final Color border;
  final Color green;
  final Color orange;
  final Color red;
  final Color gold;
  final Color text1;
  final Color text2;

  const AppColors({
    required this.bg,
    required this.s1,
    required this.s2,
    required this.border,
    required this.green,
    required this.orange,
    required this.red,
    required this.gold,
    required this.text1,
    required this.text2,
  });

  static const dark = AppColors(
    bg: Color(0xFF0A0E1A),
    s1: Color(0xFF111827),
    s2: Color(0xFF1A2235),
    border: Color(0xFF1E2D45),
    green: Color(0xFF00D4AA),
    orange: Color(0xFFFF6B35),
    red: Color(0xFFFF4444),
    gold: Color(0xFFFFD700),
    text1: Color(0xFFE8F4F8),
    text2: Color(0xFF8BA3B8),
  );

  static const light = AppColors(
    bg: Color(0xFFF0F4F8),
    s1: Color(0xFFFFFFFF),
    s2: Color(0xFFE8EDF2),
    border: Color(0xFFC9D4DE),
    green: Color(0xFF00D4AA),
    orange: Color(0xFFFF6B35),
    red: Color(0xFFFF4444),
    gold: Color(0xFFFFD700),
    text1: Color(0xFF0A1628),
    text2: Color(0xFF4A6080),
  );
}

extension AppColorsX on ThemeData {
  AppColors get cc => brightness == Brightness.dark ? AppColors.dark : AppColors.light;
}

class AppTheme {
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);
  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
      fontFamily: 'Segoe UI',
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.green,
        onPrimary: const Color(0xFF06251F),
        secondary: c.orange,
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
      drawerTheme: DrawerThemeData(backgroundColor: c.s1),
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
        hintStyle: TextStyle(color: c.text2),
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
    return base;
  }
}
