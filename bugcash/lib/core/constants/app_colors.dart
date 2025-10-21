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
  
  // Enhanced Shadow Colors for Material Design 3
  static Color shadowLight = Colors.black.withOpacity(0.05);
  static Color shadowMedium = Colors.black.withOpacity(0.1);
  static Color shadowDark = Colors.black.withOpacity(0.15);
  static Color shadowElevated = Colors.black.withOpacity(0.2);

  // Card Specific Shadows (더 입체적인 효과)
  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> cardShadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> cardShadowElevated = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];
  
  // Overlay Colors
  static Color overlayLight = Colors.white.withOpacity(0.2);
  static Color overlayMedium = Colors.white.withOpacity(0.5);
  
  // Progress Colors
  static Color progressBackground = Colors.white.withOpacity(0.5);
  
  // Badge Colors
  static const Color goldBadge = Color(0xFFFFD700);
  static const Color silverBadge = Color(0xFFC0C0C0);
  static const Color bronzeBadge = Color(0xFFCD7F32);

  // ============================================
  // Phase 5: Refined Color System (v2.2.0)
  // ============================================

  /// Neutral Palette (Monochrome Base)
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);

  /// Status Badge Colors (Semantic)
  static const Color statusPending = Color(0xFFFF9800);      // 주황 (대기)
  static const Color statusPendingBg = Color(0xFFFFF3E0);
  static const Color statusActive = Color(0xFF00BFA5);       // Primary (승인/진행)
  static const Color statusActiveBg = Color(0xFFE0F7F4);
  static const Color statusSuccess = Color(0xFF4CAF50);      // 녹색 (완료)
  static const Color statusSuccessBg = Color(0xFFE8F5E9);
  static const Color statusError = Color(0xFFF44336);        // 빨강 (거절)
  static const Color statusErrorBg = Color(0xFFFFEBEE);

  /// Accent for Points/Money
  static const Color accentGold = Color(0xFFFFA726);         // 부드러운 골드
  static const Color accentGoldBg = Color(0xFFFFF8E1);

  // ============================================
  // Phase 3: Advanced 3D Design System
  // ============================================

  // Glassmorphism Colors
  static Color glassBackground = Colors.white.withOpacity(0.25);
  static Color glassBackgroundDark = Colors.black.withOpacity(0.15);
  static Color glassBorder = Colors.white.withOpacity(0.3);
  static Color glassBorderDark = Colors.white.withOpacity(0.1);

  // Neumorphism Colors
  static const Color neuLight = Color(0xFFF0F0F3);
  static const Color neuDark = Color(0xFFD1D1D4);
  static const Color neuHighlight = Color(0xFFFFFFFF);
  static const Color neuShadow = Color(0xFFA3A3A3);

  // Advanced Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF00BFA5),
    Color(0xFF4EDBC5),
  ];

  static const List<Color> heroGradient = [
    Color(0xFF667eea),
    Color(0xFF764ba2),
  ];

  static const List<Color> successGradient = [
    Color(0xFF4CAF50),
    Color(0xFF81C784),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFFF9800),
    Color(0xFFFFB74D),
  ];

  static const List<Color> cardGradientLight = [
    Color(0xFFFDFDFD),
    Color(0xFFF8F9FA),
  ];

  static const List<Color> cardGradientSubtle = [
    Color(0xFFFFFFFF),
    Color(0xFFF5F7FA),
  ];

  // Glass Effect Shadows
  static List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 40,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.05),
      blurRadius: 1,
      offset: const Offset(0, 1),
      blurStyle: BlurStyle.inner,
    ),
  ];

  // Neumorphism Shadows
  static List<BoxShadow> neuShadowConvex = [
    BoxShadow(
      color: neuShadow.withOpacity(0.5),
      blurRadius: 15,
      offset: const Offset(5, 5),
    ),
    const BoxShadow(
      color: neuHighlight,
      blurRadius: 15,
      offset: Offset(-5, -5),
    ),
  ];

  static List<BoxShadow> neuShadowConcave = [
    const BoxShadow(
      color: neuHighlight,
      blurRadius: 15,
      offset: Offset(5, 5),
    ),
    BoxShadow(
      color: neuShadow.withOpacity(0.5),
      blurRadius: 15,
      offset: const Offset(-5, -5),
    ),
  ];

  // ============================================
  // Phase 4: 사용자 타입별 맞춤화 색상 시스템
  // ============================================

  /// Tester 전용 색상 (오렌지/옐로우 bugs 테마) - v2.77.0
  static const Color testerPrimary = Color(0xFFFF9800);           // 메인 오렌지
  static const Color testerSecondary = Color(0xFFFFB74D);         // 밝은 오렌지
  static const Color testerAccent = Color(0xFFFFC107);            // 액센트 옐로우
  static const Color testerOrangePrimary = Color(0xFFFF9800);     // 메인 오렌지
  static const Color testerOrangeLight = Color(0xFFFFB74D);       // 밝은 오렌지
  static const Color testerOrangeDark = Color(0xFFF57C00);        // 진한 오렌지
  static const Color testerYellow = Color(0xFFFFC107);            // 액센트 옐로우
  static const Color testerYellowLight = Color(0xFFFFD54F);       // 밝은 옐로우
  static const List<Color> testerGradient = [
    Color(0xFFFF9800),  // 오렌지
    Color(0xFFFFB74D),  // 밝은 오렌지
  ];
  static const List<Color> testerOrangeGradient = [
    Color(0xFFFF9800),  // 오렌지
    Color(0xFFFFB74D),  // 밝은 오렌지
  ];
  static List<BoxShadow> testerCardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Provider 전용 색상 (청량한 파스텔 블루 테마) - v2.78.0, v2.84.0 중복 제거
  /// 공급자 대시보드 전체에 일관되게 사용되는 파스텔 블루 색상 팔레트
  static const Color providerBluePrimary = Color(0xFF5BA3D0);       // 메인 파스텔 블루 (AppBar, 버튼, 주요 요소)
  static const Color providerBlueLight = Color(0xFF8FC5E3);         // 밝은 파스텔 블루 (테두리, 밝은 액센트)
  static const Color providerBlueDark = Color(0xFF4284AC);          // 진한 블루 (텍스트, 제목)
  static const Color providerBlueAccent = Color(0xFF7BB7D9);        // 액센트 블루 (강조 요소)
  static const List<Color> providerBlueGradient = [
    Color(0xFF5BA3D0),  // 파스텔 블루
    Color(0xFF8FC5E3),  // 밝은 파스텔 블루
  ];
  static List<BoxShadow> providerCardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Admin 전용 색상 (권위있고 고급스러운 느낌)
  static const Color adminPrimary = Color(0xFF9C27B0);
  static const Color adminSecondary = Color(0xFFBA68C8);
  static const Color adminAccent = Color(0xFF7B1FA2);
  static const List<Color> adminGradient = [
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
  ];
  static List<BoxShadow> adminCardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// 사용자 타입별 색상 헬퍼 메서드
  static Color getPrimaryColor(String userType) {
    switch (userType.toLowerCase()) {
      case 'tester':
        return testerPrimary;
      case 'provider':
        return providerBluePrimary;
      case 'admin':
        return adminPrimary;
      default:
        return primary;
    }
  }

  static List<Color> getGradientColors(String userType) {
    switch (userType.toLowerCase()) {
      case 'tester':
        return testerGradient;
      case 'provider':
        return providerBlueGradient;
      case 'admin':
        return adminGradient;
      default:
        return primaryGradient;
    }
  }

  static List<BoxShadow> getCardShadow(String userType) {
    switch (userType.toLowerCase()) {
      case 'tester':
        return testerCardShadow;
      case 'provider':
        return providerCardShadow;
      case 'admin':
        return adminCardShadow;
      default:
        return cardShadowMedium;
    }
  }
}