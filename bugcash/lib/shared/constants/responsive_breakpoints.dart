/// 반응형 디자인을 위한 브레이크포인트 상수 정의
///
/// 모든 반응형 관련 값들을 중앙화하여 일관성 있는 디자인 시스템 구축
class ResponsiveBreakpoints {
  // Private constructor to prevent instantiation
  ResponsiveBreakpoints._();

  // ============================================
  // Screen Size Breakpoints
  // ============================================

  /// Mobile breakpoint (phones)
  static const double mobile = 600;

  /// Small tablet breakpoint (small tablets)
  static const double smallTablet = 768;

  /// Tablet breakpoint (tablets and small laptops)
  static const double tablet = 1024;

  /// Desktop breakpoint (desktops and large screens)
  static const double desktop = 1200;

  /// Wide desktop breakpoint (ultra-wide monitors)
  static const double wideDesktop = 1920;

  // ============================================
  // Container Max Widths
  // ============================================

  /// Default max width for content containers
  static const double maxContentWidth = 1200;

  /// Max width for narrow content (forms, dialogs)
  static const double maxNarrowWidth = 600;

  /// Max width for wide content (dashboards)
  static const double maxWideWidth = 1440;

  // ============================================
  // Grid System
  // ============================================

  /// Grid columns for different screen sizes
  static const int mobileColumns = 1;
  static const int tabletColumns = 2;
  static const int desktopColumns = 3;
  static const int wideDesktopColumns = 4;

  /// Grid spacing
  static const double gridSpacing = 16.0;
  static const double gridSpacingLarge = 24.0;

  // ============================================
  // Padding & Margins
  // ============================================

  /// Mobile padding (모바일에서 더 큰 패딩으로 가독성 향상)
  static const double mobilePaddingHorizontal = 20.0;
  static const double mobilePaddingVertical = 20.0;

  /// Tablet padding
  static const double tabletPaddingHorizontal = 24.0;
  static const double tabletPaddingVertical = 20.0;

  /// Desktop padding
  static const double desktopPaddingHorizontal = 32.0;
  static const double desktopPaddingVertical = 24.0;

  /// Wide desktop padding
  static const double wideDesktopPaddingHorizontal = 48.0;
  static const double wideDesktopPaddingVertical = 32.0;

  // ============================================
  // Font Size Scaling
  // ============================================

  /// Font size scale factors
  /// 작은 화면에서 가독성을 위해 크게 확대하여 사용성 향상
  /// 웹 모바일 180%, 작은 태블릿 130%로 강화된 스케일링
  /// 최소 폰트 크기 보장으로 사용성 개선
  static const double mobileFontScale = 1.1; // 모바일에서 110% 확대
  static const double webMobileFontScale = 1.4; // 웹 모바일 180% 확대
  static const double smallTabletFontScale = 1.3; // 작은 태블릿에서 130% 확대
  static const double tabletFontScale = 1.0;
  static const double desktopFontScale = 1.1;
  static const double wideDesktopFontScale = 1.2;

  /// 최소 폰트 스케일 (접근성 보장을 위한 최소 크기)
  /// 어떤 화면 크기에서도 이 값 이하로 내려가지 않음
  static const double minFontScale = 0.9;

  // ============================================
  // Component Sizes
  // ============================================

  /// Sidebar widths
  static const double sidebarWidthMobile = 200.0;
  static const double sidebarWidthTablet = 220.0;
  static const double sidebarWidthDesktop = 240.0;
  static const double sidebarWidthWideDesktop = 280.0;

  /// Card sizes
  static const double cardMinWidth = 280.0;
  static const double cardMaxWidth = 400.0;

  /// Dialog sizes
  static const double dialogWidthSmall = 400.0;
  static const double dialogWidthMedium = 600.0;
  static const double dialogWidthLarge = 800.0;

  // ============================================
  // Helper Methods
  // ============================================

  /// Check if screen width is mobile
  static bool isMobileWidth(double width) => width < mobile;

  /// Check if screen width is small tablet
  static bool isSmallTabletWidth(double width) => width >= mobile && width < smallTablet;

  /// Check if screen width is tablet
  static bool isTabletWidth(double width) => width >= smallTablet && width < tablet;

  /// Check if screen width is desktop
  static bool isDesktopWidth(double width) => width >= tablet && width < desktop;

  /// Check if screen width is wide desktop
  static bool isWideDesktopWidth(double width) => width >= desktop;

  /// Get appropriate column count for screen width
  static int getColumnCount(double width) {
    if (isMobileWidth(width)) return mobileColumns;        // <600px: 1열
    if (isSmallTabletWidth(width)) return tabletColumns;   // 600-768px: 2열
    if (isTabletWidth(width)) return tabletColumns;        // 768-1024px: 2열
    if (isDesktopWidth(width)) return desktopColumns;      // 1024-1200px: 3열
    return wideDesktopColumns;                             // >=1200px: 4열
  }

  /// Get appropriate padding for screen width
  static double getPaddingHorizontal(double width) {
    if (isMobileWidth(width)) return mobilePaddingHorizontal;
    if (isTabletWidth(width)) return tabletPaddingHorizontal;
    if (isDesktopWidth(width)) return desktopPaddingHorizontal;
    return wideDesktopPaddingHorizontal;
  }

  static double getPaddingVertical(double width) {
    if (isMobileWidth(width)) return mobilePaddingVertical;
    if (isTabletWidth(width)) return tabletPaddingVertical;
    if (isDesktopWidth(width)) return desktopPaddingVertical;
    return wideDesktopPaddingVertical;
  }

  /// Get appropriate font scale for screen width
  /// 웹 전용: 작은 화면(<600px) 165%, 작은 태블릿(600-768px) 145% 확대
  /// 모바일 앱: 기존 110% 스케일 유지
  /// 최소 폰트 스케일 보장으로 가독성 개선
  static double getFontScale(double width, {bool isWeb = false}) {
    double scale;

    if (isMobileWidth(width)) {
      // 웹: 165% 확대, 모바일 앱: 110% 확대
      scale = isWeb ? webMobileFontScale : mobileFontScale;
    } else if (isSmallTabletWidth(width)) {
      // 웹에서만 145% 확대, 모바일 앱은 기본값 사용
      scale = isWeb ? smallTabletFontScale : tabletFontScale;
    } else if (isTabletWidth(width)) {
      scale = tabletFontScale;
    } else if (isDesktopWidth(width)) {
      scale = desktopFontScale;
    } else {
      scale = wideDesktopFontScale;
    }

    // 최소 폰트 스케일 보장 (어떤 경우에도 minFontScale 이하로 내려가지 않음)
    return scale < minFontScale ? minFontScale : scale;
  }

  /// Get appropriate sidebar width for screen width
  static double getSidebarWidth(double width) {
    if (isMobileWidth(width)) return sidebarWidthMobile;
    if (isTabletWidth(width)) return sidebarWidthTablet;
    if (isDesktopWidth(width)) return sidebarWidthDesktop;
    return sidebarWidthWideDesktop;
  }
}