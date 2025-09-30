import 'package:flutter/material.dart';
import '../constants/responsive_breakpoints.dart';
import '../providers/responsive_data_provider.dart';

/// 반응형 테마 클래스
/// 화면 크기에 따라 적절한 텍스트 스타일, 스페이싱, 컴포넌트 크기를 제공
class ResponsiveTheme {
  final ResponsiveData responsiveData;

  const ResponsiveTheme(this.responsiveData);

  /// 화면 크기별 기본 텍스트 스타일
  TextTheme get textTheme {
    const baseTheme = TextTheme();
    final scale = responsiveData.fontScale;

    return TextTheme(
      // Display styles
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontSize: _scaleFont(57, scale),
        height: 1.12,
        letterSpacing: -0.25,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontSize: _scaleFont(45, scale),
        height: 1.16,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontSize: _scaleFont(36, scale),
        height: 1.22,
      ),

      // Headline styles
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontSize: _scaleFont(32, scale),
        height: 1.25,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontSize: _scaleFont(28, scale),
        height: 1.29,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontSize: _scaleFont(24, scale),
        height: 1.33,
      ),

      // Title styles
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontSize: _scaleFont(22, scale),
        height: 1.27,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontSize: _scaleFont(16, scale),
        height: 1.50,
        letterSpacing: 0.15,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontSize: _scaleFont(14, scale),
        height: 1.43,
        letterSpacing: 0.1,
      ),

      // Body styles
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontSize: _scaleFont(16, scale),
        height: 1.50,
        letterSpacing: 0.5,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontSize: _scaleFont(14, scale),
        height: 1.43,
        letterSpacing: 0.25,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontSize: _scaleFont(12, scale),
        height: 1.33,
        letterSpacing: 0.4,
      ),

      // Label styles
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontSize: _scaleFont(14, scale),
        height: 1.43,
        letterSpacing: 0.1,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        fontSize: _scaleFont(12, scale),
        height: 1.33,
        letterSpacing: 0.5,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        fontSize: _scaleFont(11, scale),
        height: 1.45,
        letterSpacing: 0.5,
      ),
    );
  }

  /// 반응형 스페이싱 값들
  ResponsiveSpacing get spacing => ResponsiveSpacing(responsiveData);

  /// 반응형 컴포넌트 크기
  ResponsiveComponentSizes get componentSizes => ResponsiveComponentSizes(responsiveData);

  /// 반응형 레이아웃 설정
  ResponsiveLayout get layout => ResponsiveLayout(responsiveData);

  /// 폰트 크기 스케일링
  double _scaleFont(double baseSize, double scale) {
    return baseSize * scale;
  }
}

/// 반응형 스페이싱 클래스
class ResponsiveSpacing {
  final ResponsiveData responsiveData;

  const ResponsiveSpacing(this.responsiveData);

  /// 기본 스페이싱 단위 (8px 기준)
  double get unit => responsiveData.isMobile ? 6.0 : 8.0;

  // 스페이싱 크기들
  double get xs => unit * 0.5; // 3-4px
  double get sm => unit * 1.0; // 6-8px
  double get md => unit * 2.0; // 12-16px
  double get lg => unit * 3.0; // 18-24px
  double get xl => unit * 4.0; // 24-32px
  double get xxl => unit * 6.0; // 36-48px
  double get xxxl => unit * 8.0; // 48-64px

  /// 화면별 컨테이너 패딩
  EdgeInsets get containerPadding => responsiveData.padding;

  /// 카드 패딩
  EdgeInsets get cardPadding {
    if (responsiveData.isMobile) {
      return EdgeInsets.all(md);
    } else if (responsiveData.isTablet) {
      return EdgeInsets.all(lg);
    } else {
      return EdgeInsets.all(xl);
    }
  }

  /// 섹션 간격
  double get sectionSpacing {
    if (responsiveData.isMobile) {
      return lg;
    } else if (responsiveData.isTablet) {
      return xl;
    } else {
      return xxl;
    }
  }

  /// 리스트 아이템 간격
  double get listItemSpacing => responsiveData.isMobile ? sm : md;

  /// 버튼 패딩
  EdgeInsets get buttonPadding {
    if (responsiveData.isMobile) {
      return EdgeInsets.symmetric(horizontal: md, vertical: sm);
    } else {
      return EdgeInsets.symmetric(horizontal: lg, vertical: md);
    }
  }
}

/// 반응형 컴포넌트 크기 클래스
class ResponsiveComponentSizes {
  final ResponsiveData responsiveData;

  const ResponsiveComponentSizes(this.responsiveData);

  /// AppBar 높이
  double get appBarHeight {
    if (responsiveData.isMobile) {
      return 56.0;
    } else if (responsiveData.isTablet) {
      return 64.0;
    } else {
      return 72.0;
    }
  }

  /// 버튼 높이
  double get buttonHeight {
    if (responsiveData.isMobile) {
      return 44.0;
    } else if (responsiveData.isTablet) {
      return 48.0;
    } else {
      return 52.0;
    }
  }

  /// 입력 필드 높이
  double get inputFieldHeight {
    if (responsiveData.isMobile) {
      return 48.0;
    } else if (responsiveData.isTablet) {
      return 52.0;
    } else {
      return 56.0;
    }
  }

  /// 카드 최소 높이
  double get cardMinHeight {
    if (responsiveData.isMobile) {
      return 120.0;
    } else if (responsiveData.isTablet) {
      return 140.0;
    } else {
      return 160.0;
    }
  }

  /// 아이콘 크기
  double get iconSize {
    if (responsiveData.isMobile) {
      return 20.0;
    } else if (responsiveData.isTablet) {
      return 22.0;
    } else {
      return 24.0;
    }
  }

  /// 아바타 크기
  double get avatarSize {
    if (responsiveData.isMobile) {
      return 32.0;
    } else if (responsiveData.isTablet) {
      return 36.0;
    } else {
      return 40.0;
    }
  }

  /// Floating Action Button 크기
  double get fabSize {
    if (responsiveData.isMobile) {
      return 56.0;
    } else {
      return 64.0;
    }
  }
}

/// 반응형 레이아웃 설정 클래스
class ResponsiveLayout {
  final ResponsiveData responsiveData;

  const ResponsiveLayout(this.responsiveData);

  /// 사이드바 너비
  double get sidebarWidth => responsiveData.sidebarWidth;

  /// 콘텐츠 최대 너비
  double get maxContentWidth {
    if (responsiveData.screenWidth > ResponsiveBreakpoints.desktop) {
      return ResponsiveBreakpoints.maxContentWidth;
    }
    return responsiveData.screenWidth;
  }

  /// 그리드 컬럼 수
  int get gridColumns => responsiveData.gridColumns;

  /// 그리드 간격
  double get gridSpacing => ResponsiveBreakpoints.gridSpacing;

  /// 카드 너비 계산
  double getCardWidth({int requestedColumns = 3}) {
    return responsiveData.getCardWidth(requestedColumns: requestedColumns);
  }

  /// 다이얼로그 최대 너비
  double get dialogMaxWidth {
    if (responsiveData.isMobile) {
      return responsiveData.screenWidth * 0.9;
    } else if (responsiveData.isTablet) {
      return ResponsiveBreakpoints.dialogWidthMedium;
    } else {
      return ResponsiveBreakpoints.dialogWidthLarge;
    }
  }

  /// BottomSheet 최대 높이
  double get bottomSheetMaxHeight {
    return responsiveData.screenHeight * 0.9;
  }

  /// 브레이크포인트 체크
  bool get isMobile => responsiveData.isMobile;
  bool get isTablet => responsiveData.isTablet;
  bool get isDesktop => responsiveData.isDesktop;
  bool get isWideDesktop => responsiveData.isWideDesktop;
}