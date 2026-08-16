import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const primary = Color(0xFF2F3B2F);      // Deep Olive
  static const secondary = Color(0xFFB59A6A);    // Soft Gold

  // Backgrounds
  static const background = Color(0xFFF8F4ED);   // Warm Beige
  static const surface = Colors.white;
  static const card = Color(0xFFFFFCF8);

  // Accent Colors
  static const olive = Color(0xFF68705C);
  static const lightOlive = Color(0xFFB8C1AE);

  static const gold = Color(0xFFB59A6A);
  static const lightGold = Color(0xFFD8C8A5);

  // Text
  static const textPrimary = Color(0xFF222222);
  static const textSecondary = Color(0xFF6F6F6F);
  static const textLight = Colors.white;

  // Status Colors
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFF9A825);
  static const error = Color(0xFFD32F2F);

  // Border & Shadow
  static const border = Color(0xFFE7DFD3);
  static const shadow = Color(0x14000000);

  // -------- Compatibility --------
  // حتى ما ينكسر أي كود قديم
  static const sand = background;
  static const brown = secondary;
  static const darkBrown = primary;
  static const white = Colors.white;
  static const textDark = textPrimary;
}