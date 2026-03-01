import 'package:flutter/material.dart';

class AppTheme {
  // Bảng màu chính (Premium Color Palette)
  static const Color primaryColor = Color(0xFF0D6EFD);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  static const Color incomeColor = Color(0xFF2ECC71); // Xanh lá ngọc
  static const Color expenseColor = Color(0xFFE74C3C); // Đỏ san hô

  static const Color textMainDark = Color(0xFFF8F9FA);
  static const Color textSubDark = Color(0xFFA0AEC0);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        surface: surfaceDark,
        onSurface: textMainDark,
      ),
      fontFamily: 'Inter', // Hoặc dùng phông Roboto mặc định nếu chưa cài font
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textMainDark),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    );
  }

  // Bạn có thể mở rộng LightTheme sau
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFF4F6F9),
    );
  }
}
