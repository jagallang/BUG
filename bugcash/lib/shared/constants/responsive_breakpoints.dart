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

  /// Mobile padding
  static const double mobilePaddingHorizontal = 16.0;
  static const double mobilePaddingVertical = 16.0;

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
  static const double mobileFontScale = 0.9;
  static const double tabletFontScale = 1.0;
  static const double desktopFontScale = 1.1;
  static const double wideDesktopFontScale = 1.2;

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

  /// Check if screen width is tablet
  static bool isTabletWidth(double width) => width >= mobile && width < tablet;

  /// Check if screen width is desktop
  static bool isDesktopWidth(double width) => width >= tablet && width < desktop;

  /// Check if screen width is wide desktop
  static bool isWideDesktopWidth(double width) => width >= desktop;

  /// Get appropriate column count for screen width
  static int getColumnCount(double width) {
    if (isMobileWidth(width)) return mobileColumns;
    if (isTabletWidth(width)) return tabletColumns;
    if (isDesktopWidth(width)) return desktopColumns;
    return wideDesktopColumns;
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
  static double getFontScale(double width) {
    if (isMobileWidth(width)) return mobileFontScale;
    if (isTabletWidth(width)) return tabletFontScale;
    if (isDesktopWidth(width)) return desktopFontScale;
    return wideDesktopFontScale;
  }

  /// Get appropriate sidebar width for screen width
  static double getSidebarWidth(double width) {
    if (isMobileWidth(width)) return sidebarWidthMobile;
    if (isTabletWidth(width)) return sidebarWidthTablet;
    if (isDesktopWidth(width)) return sidebarWidthDesktop;
    return sidebarWidthWideDesktop;
  }
}