/// 반응형 디자인을 위한 브레이크포인트 상수 정의
///
/// 모든 반응형 관련 값들을 중앙화하여 일관성 있는 디자인 시스템 구축
class ResponsiveBreakpoints {
  // 인스턴스화를 막기 위한 private 생성자
  ResponsiveBreakpoints._();

  // ============================================
  // 화면 크기 브레이크포인트
  // ============================================

  /// 모바일 브레이크포인트 (스마트폰)
  static const double mobile = 600;

  /// 소형 태블릿 브레이크포인트
  static const double smallTablet = 768;

  /// 태블릿 브레이크포인트 (태블릿 및 소형 노트북)
  static const double tablet = 1024;

  /// 데스크탑 브레이크포인트 (데스크톱 및 대형 화면)
  static const double desktop = 1200;

  /// 와이드 데스크탑 브레이크포인트 (울트라 와이드 모니터)
  static const double wideDesktop = 1920;

  // ============================================
  // 컨테이너 최대 너비
  // ============================================

  /// 콘텐츠 컨테이너 기본 최대 너비
  static const double maxContentWidth = 1200;

  /// 좁은 콘텐츠(폼, 다이얼로그) 최대 너비
  static const double maxNarrowWidth = 600;

  /// 넓은 콘텐츠(대시보드) 최대 너비
  static const double maxWideWidth = 1440;

  /// 관리자 대시보드 최대 너비(데이터 중심 화면용)
  static const double maxAdminDashboardWidth = 1920;

  // ============================================
  // 그리드 시스템
  // ============================================

  /// 화면 크기에 따른 그리드 열 수
  static const int mobileColumns = 1;
  static const int tabletColumns = 2;
  static const int desktopColumns = 3;
  static const int wideDesktopColumns = 4;

  /// 그리드 간격
  static const double gridSpacing = 16.0;
  static const double gridSpacingLarge = 24.0;

  // ============================================
  // 패딩 및 마진
  // ============================================

  /// 모바일 패딩 (모바일에서 더 큰 패딩으로 가독성 향상)
  static const double mobilePaddingHorizontal = 20.0;
  static const double mobilePaddingVertical = 20.0;

  /// 태블릿 패딩
  static const double tabletPaddingHorizontal = 24.0;
  static const double tabletPaddingVertical = 20.0;

  /// 데스크탑 패딩
  static const double desktopPaddingHorizontal = 32.0;
  static const double desktopPaddingVertical = 24.0;

  /// 와이드 데스크탑 패딩
  static const double wideDesktopPaddingHorizontal = 48.0;
  static const double wideDesktopPaddingVertical = 32.0;

  // ============================================
  // 폰트 크기 스케일링
  // ============================================

  /// 폰트 크기 스케일 배율
  /// 작은 화면에서 가독성을 위해 크게 확대하여 사용성 향상
  /// 웹 모바일 120%, 작은 태블릿 110%로 적절한 스케일링
  /// 최소 폰트 크기 보장으로 사용성 개선
  static const double mobileFontScale = 1.1; // 모바일에서 110% 확대
  static const double webMobileFontScale = 1.2; // 웹 모바일 120% 확대 (130%에서 추가 10% 감소)
  static const double smallTabletFontScale = 1.1; // 작은 태블릿에서 110% 확대 (120%에서 추가 10% 감소)
  static const double tabletFontScale = 1.0;
  static const double desktopFontScale = 1.0;
  static const double wideDesktopFontScale = 1.0;

  /// 최소 폰트 스케일 (접근성 보장을 위한 최소 크기)
  /// 어떤 화면 크기에서도 이 값 이하로 내려가지 않음
  static const double minFontScale = 0.9;

  // ============================================
  // 컴포넌트 크기
  // ============================================

  /// 사이드바 너비
  static const double sidebarWidthMobile = 200.0;
  static const double sidebarWidthTablet = 220.0;
  static const double sidebarWidthDesktop = 240.0;
  static const double sidebarWidthWideDesktop = 280.0;

  /// 카드 크기
  static const double cardMinWidth = 280.0;
  static const double cardMaxWidth = 400.0;

  /// 다이얼로그 크기
  static const double dialogWidthSmall = 400.0;
  static const double dialogWidthMedium = 600.0;
  static const double dialogWidthLarge = 800.0;

  // ============================================
  // 헬퍼 메서드
  // ============================================

  /// 화면 너비가 모바일 구간인지 확인
  static bool isMobileWidth(double width) => width < mobile;

  /// 화면 너비가 소형 태블릿 구간인지 확인
  static bool isSmallTabletWidth(double width) => width >= mobile && width < smallTablet;

  /// 화면 너비가 태블릿 구간인지 확인
  static bool isTabletWidth(double width) => width >= smallTablet && width < tablet;

  /// 화면 너비가 데스크탑 구간인지 확인
  static bool isDesktopWidth(double width) => width >= tablet && width < desktop;

  /// 화면 너비가 와이드 데스크탑 구간인지 확인
  static bool isWideDesktopWidth(double width) => width >= desktop;

  /// 화면 너비에 맞는 열 개수 반환
  static int getColumnCount(double width) {
    if (isMobileWidth(width)) return mobileColumns;        // <600px: 1열
    if (isSmallTabletWidth(width)) return tabletColumns;   // 600-768px: 2열
    if (isTabletWidth(width)) return tabletColumns;        // 768-1024px: 2열
    if (isDesktopWidth(width)) return desktopColumns;      // 1024-1200px: 3열
    return wideDesktopColumns;                             // >=1200px: 4열
  }

  /// 화면 너비에 맞는 가로 패딩 반환
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

  /// 화면 너비에 맞는 폰트 스케일 반환
  /// 웹 전용: 작은 화면(<600px) 120%, 작은 태블릿(600-768px) 110% 확대
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

  /// 화면 너비에 맞는 사이드바 너비 반환
  static double getSidebarWidth(double width) {
    if (isMobileWidth(width)) return sidebarWidthMobile;
    if (isTabletWidth(width)) return sidebarWidthTablet;
    if (isDesktopWidth(width)) return sidebarWidthDesktop;
    return sidebarWidthWideDesktop;
  }

  /// 관리자 대시보드 전용 패딩 반환 (더 넓은 콘텐츠 영역)
  static double getAdminDashboardPaddingHorizontal(double width) {
    if (isMobileWidth(width)) return mobilePaddingHorizontal;
    if (isTabletWidth(width)) return tabletPaddingHorizontal;
    if (isDesktopWidth(width)) return 24.0; // 데스크탑: 더 좁은 패딩
    return 32.0; // 와이드 데스크탑: 콘텐츠 영역 최대 활용
  }
}
