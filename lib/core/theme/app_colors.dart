import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color bgTop = Color(0xFF120A1F);
  static const Color bgBottom = Color(0xFF1C0F33);
  static const Color gold = Color(0xFFE6B65C);
  static const Color goldDim = Color(0xFFB98A3E);
  static const Color card = Color(0xFF241640);
  static const Color cardBorder = Color(0xFF3A2560);
  static const Color text = Color(0xFFF5F0E8);
  static const Color textMuted = Color(0xFFB7A9C9);
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF81C784);

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );
}
