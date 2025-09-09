import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF00BFA5);
  static const Color primaryLight = Color(0xFF4EDBC5);
  static const Color secondary = Color(0xFF4EDBC5);
  
  // UI Colors
  static const Color divider = Color(0xFFE0E0E0);
  
  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  
  // Text Colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF757575);
  
  // Mission Card Colors
  static const List<Color> missionCardColors = [
    Color(0xFFFFE4E1),
    Color(0xFFE6F3FF),
    Color(0xFFF0FFF0),
    Color(0xFFFFF8DC),
  ];
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Wallet Colors
  static const Color goldStart = Color(0xFFFFD700);
  static const Color goldEnd = Color(0xFFFFF8DC);
  static const Color goldText = Color(0xFFB8860B);
  
  // Missing Colors
  static const Color primaryDark = Color(0xFF00998A);
  static const Color cashGreen = Color(0xFF00BFA5);
  
  // Shadow Colors
  static Color shadowLight = Colors.black.withValues(alpha: 0.05);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.1);
  
  // Overlay Colors
  static Color overlayLight = Colors.white.withValues(alpha: 0.2);
  static Color overlayMedium = Colors.white.withValues(alpha: 0.5);
  
  // Progress Colors
  static Color progressBackground = Colors.white.withValues(alpha: 0.5);
  
  // Badge Colors
  static const Color goldBadge = Color(0xFFFFD700);
  static const Color silverBadge = Color(0xFFC0C0C0);
  static const Color bronzeBadge = Color(0xFFCD7F32);
}