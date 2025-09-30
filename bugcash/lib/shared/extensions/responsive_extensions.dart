import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/responsive_data_provider.dart';
import '../theme/responsive_theme.dart';
import '../constants/responsive_breakpoints.dart';

/// BuildContext에 반응형 관련 확장 메서드 추가
extension ResponsiveContextExtension on BuildContext {
  /// 현재 화면 크기
  Size get screenSize => MediaQuery.of(this).size;

  /// 화면 너비
  double get screenWidth => screenSize.width;

  /// 화면 높이
  double get screenHeight => screenSize.height;

  /// 모바일 여부
  bool get isMobile => ResponsiveBreakpoints.isMobileWidth(screenWidth);

  /// 태블릿 여부
  bool get isTablet => ResponsiveBreakpoints.isTabletWidth(screenWidth);

  /// 데스크탑 여부
  bool get isDesktop => ResponsiveBreakpoints.isDesktopWidth(screenWidth) ||
                        ResponsiveBreakpoints.isWideDesktopWidth(screenWidth);

  /// 와이드 데스크탑 여부
  bool get isWideDesktop => ResponsiveBreakpoints.isWideDesktopWidth(screenWidth);

  /// 반응형 패딩 가져오기
  EdgeInsets get responsivePadding => EdgeInsets.symmetric(
    horizontal: ResponsiveBreakpoints.getPaddingHorizontal(screenWidth),
    vertical: ResponsiveBreakpoints.getPaddingVertical(screenWidth),
  );

  /// 반응형 그리드 컬럼 수
  int get responsiveColumns => ResponsiveBreakpoints.getColumnCount(screenWidth);

  /// 반응형 폰트 스케일
  double get fontScale => ResponsiveBreakpoints.getFontScale(screenWidth);

  /// 사이드바 너비
  double get sidebarWidth => ResponsiveBreakpoints.getSidebarWidth(screenWidth);

  /// 컨텐츠 최대 너비
  double get maxContentWidth => screenWidth > ResponsiveBreakpoints.desktop
      ? ResponsiveBreakpoints.maxContentWidth
      : screenWidth;
}

/// WidgetRef에 반응형 관련 확장 메서드 추가
extension ResponsiveRefExtension on WidgetRef {
  /// ResponsiveData 가져오기
  ResponsiveData responsiveData(BuildContext context) {
    return read(responsiveDataProvider(context.screenSize));
  }

  /// ResponsiveTheme 가져오기
  ResponsiveTheme responsiveTheme(BuildContext context) {
    return ResponsiveTheme(responsiveData(context));
  }

  /// 캐시된 ResponsiveData 가져오기 (Provider 스코프 내에서)
  ResponsiveData? get cachedResponsiveData => read(contextResponsiveDataProvider);
}

/// double 숫자에 반응형 관련 확장 메서드 추가
extension ResponsiveDoubleExtension on double {
  /// 반응형 폰트 크기 적용
  double responsiveFont(BuildContext context) {
    return this * context.fontScale;
  }

  /// 반응형 스페이싱 적용
  double responsiveSpacing(BuildContext context) {
    final unit = context.isMobile ? 6.0 : 8.0;
    return this * unit;
  }

  /// 화면 크기 기반 스케일 적용
  double scaleByScreen(BuildContext context, {
    double mobileScale = 0.8,
    double tabletScale = 1.0,
    double desktopScale = 1.2,
  }) {
    if (context.isMobile) return this * mobileScale;
    if (context.isTablet) return this * tabletScale;
    return this * desktopScale;
  }
}

/// int 숫자에 반응형 관련 확장 메서드 추가
extension ResponsiveIntExtension on int {
  /// 반응형 폰트 크기로 변환
  double responsiveFont(BuildContext context) {
    return toDouble().responsiveFont(context);
  }

  /// 반응형 스페이싱으로 변환
  double responsiveSpacing(BuildContext context) {
    return toDouble().responsiveSpacing(context);
  }

  /// 화면 크기 기반 스케일 적용
  double scaleByScreen(BuildContext context, {
    double mobileScale = 0.8,
    double tabletScale = 1.0,
    double desktopScale = 1.2,
  }) {
    return toDouble().scaleByScreen(
      context,
      mobileScale: mobileScale,
      tabletScale: tabletScale,
      desktopScale: desktopScale,
    );
  }
}

/// Widget에 반응형 관련 확장 메서드 추가
extension ResponsiveWidgetExtension on Widget {
  /// ResponsiveBuilder로 감싸기
  Widget responsive({
    Widget Function(BuildContext context, ResponsiveData responsive)? builder,
  }) {
    if (builder != null) {
      return Builder(
        builder: (context) {
          final data = ResponsiveData.fromScreenSize(context.screenSize);
          return builder(context, data);
        },
      );
    }

    return Builder(
      builder: (context) {
        final data = ResponsiveData.fromScreenSize(context.screenSize);
        return ProviderScope(
          overrides: [
            contextResponsiveDataProvider.overrideWithValue(data),
          ],
          child: this,
        );
      },
    );
  }

  /// 조건부 렌더링 - 모바일에서만 표시
  Widget showOnMobile(BuildContext context) {
    return context.isMobile ? this : const SizedBox.shrink();
  }

  /// 조건부 렌더링 - 태블릿에서만 표시
  Widget showOnTablet(BuildContext context) {
    return context.isTablet ? this : const SizedBox.shrink();
  }

  /// 조건부 렌더링 - 데스크탑에서만 표시
  Widget showOnDesktop(BuildContext context) {
    return context.isDesktop ? this : const SizedBox.shrink();
  }

  /// 조건부 렌더링 - 모바일이 아닌 경우에만 표시
  Widget hideOnMobile(BuildContext context) {
    return !context.isMobile ? this : const SizedBox.shrink();
  }

  /// 반응형 패딩 적용
  Widget withResponsivePadding(BuildContext context, {
    double factor = 1.0,
  }) {
    final padding = context.responsivePadding * factor;
    return Padding(
      padding: padding,
      child: this,
    );
  }

  /// 화면 크기별 다른 위젯 렌더링
  Widget adaptiveLayout({
    required BuildContext context,
    Widget? mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (context.isMobile && mobile != null) return mobile;
    if (context.isTablet && tablet != null) return tablet;
    if (context.isDesktop && desktop != null) return desktop;
    return this; // 기본값
  }
}

/// TextStyle에 반응형 관련 확장 메서드 추가
extension ResponsiveTextStyleExtension on TextStyle {
  /// 반응형 폰트 크기 적용
  TextStyle responsiveFont(BuildContext context) {
    final currentSize = fontSize ?? 14.0;
    return copyWith(
      fontSize: currentSize * context.fontScale,
    );
  }

  /// 화면 크기별 폰트 크기 조정
  TextStyle adaptiveFontSize(BuildContext context, {
    double? mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    double targetSize = fontSize ?? 14.0;

    if (context.isMobile && mobileSize != null) {
      targetSize = mobileSize;
    } else if (context.isTablet && tabletSize != null) {
      targetSize = tabletSize;
    } else if (context.isDesktop && desktopSize != null) {
      targetSize = desktopSize;
    }

    return copyWith(fontSize: targetSize);
  }
}

/// EdgeInsets에 반응형 관련 확장 메서드 추가
extension ResponsiveEdgeInsetsExtension on EdgeInsets {
  /// 반응형 스케일 적용
  EdgeInsets responsiveScale(BuildContext context) {
    final scale = context.fontScale;
    return EdgeInsets.fromLTRB(
      left * scale,
      top * scale,
      right * scale,
      bottom * scale,
    );
  }

  /// 화면 크기별 패딩 조정
  EdgeInsets adaptiveScale(BuildContext context, {
    double mobileScale = 0.8,
    double tabletScale = 1.0,
    double desktopScale = 1.2,
  }) {
    late double scale;
    if (context.isMobile) {
      scale = mobileScale;
    } else if (context.isTablet) {
      scale = tabletScale;
    } else {
      scale = desktopScale;
    }

    return EdgeInsets.fromLTRB(
      left * scale,
      top * scale,
      right * scale,
      bottom * scale,
    );
  }
}