import 'package:flutter/material.dart';

class AppColors {
  static const Color scaffoldBackgroundColor = Color(0xFF05060A);
  // Alias for backward compatibility if needed, though usually used directly
  static const Color background = scaffoldBackgroundColor;
  static const Color surfaceColor = Color(0xFF0E1016);

  static const Color primaryGold = Color(0xFFF5C65C);
  static const Color deepGold = Color(0xFFD4AF37);

  static const Color primaryPurple = Color(0xFF6A0DAD);
  static const Color deepPurple = Color(0xFF371B58);

  static const Color accentTeal = Color(0xFF1DE9B6);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC4C8D2);

  static const Color error = Color(0xFFFF5252);

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepPurple, primaryPurple],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [deepGold, primaryGold],
  );
}
