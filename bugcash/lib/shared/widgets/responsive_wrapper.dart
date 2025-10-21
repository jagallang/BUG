import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/responsive_breakpoints.dart';

/// 반응형 레이아웃을 위한 Wrapper 위젯
/// 대형 모니터에서 콘텐츠 최대 너비를 제한하고 중앙 정렬
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color? backgroundColor;
  final bool showShadow;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.maxContentWidth,
    this.backgroundColor,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    // 모바일 환경에서는 Wrapper 적용 안함
    if (!kIsWeb) {
      return child;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = ResponsiveBreakpoints.isDesktopWidth(screenWidth);

    return Container(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
          ),
          decoration: isDesktop && showShadow
              ? BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 0),
                    ),
                  ],
                )
              : null,
          child: child,
        ),
      ),
    );
  }

  /// 화면 크기에 따른 적응형 패딩 반환
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return EdgeInsets.symmetric(
      horizontal: ResponsiveBreakpoints.getPaddingHorizontal(screenWidth),
      vertical: ResponsiveBreakpoints.getPaddingVertical(screenWidth),
    );
  }

  /// 화면 크기에 따른 그리드 컬럼 수 반환
  static int getResponsiveGridColumns(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return ResponsiveBreakpoints.getColumnCount(screenWidth);
  }

  /// 화면 크기에 따른 카드 너비 반환
  static double getResponsiveCardWidth(BuildContext context, {int columns = 3}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = screenWidth > ResponsiveBreakpoints.desktop
        ? ResponsiveBreakpoints.maxContentWidth
        : screenWidth;
    final padding = getResponsivePadding(context);
    final availableWidth = maxContentWidth - padding.horizontal;

    // 화면 크기에 따른 컬럼 수 조정
    int actualColumns = ResponsiveBreakpoints.getColumnCount(screenWidth);
    if (actualColumns < columns) {
      actualColumns = actualColumns; // Use breakpoint-based columns
    } else {
      actualColumns = columns; // Use requested columns if screen allows
    }

    // 카드 간격 고려
    const spacing = ResponsiveBreakpoints.gridSpacing;
    return (availableWidth - (spacing * (actualColumns - 1))) / actualColumns;
  }

  /// 브레이크포인트 확인 헬퍼 메서드들
  static bool isMobile(BuildContext context) {
    return ResponsiveBreakpoints.isMobileWidth(MediaQuery.of(context).size.width);
  }

  static bool isTablet(BuildContext context) {
    return ResponsiveBreakpoints.isTabletWidth(MediaQuery.of(context).size.width);
  }

  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return ResponsiveBreakpoints.isDesktopWidth(width) || ResponsiveBreakpoints.isWideDesktopWidth(width);
  }

  /// 반응형 폰트 크기 계산
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = ResponsiveBreakpoints.getFontScale(screenWidth);
    return baseSize * scale;
  }
}

/// 반응형 스캐폴드 - Scaffold를 ResponsiveWrapper로 감싸는 위젯
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Color? backgroundColor;
  final bool showShadow;
  final double maxWidth;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.backgroundColor,
    this.showShadow = true,
    this.maxWidth = ResponsiveBreakpoints.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      backgroundColor: backgroundColor,
    );

    // 웹 환경에서만 ResponsiveWrapper 적용
    if (kIsWeb) {
      return ResponsiveWrapper(
        maxWidth: maxWidth,
        backgroundColor: backgroundColor,
        showShadow: showShadow,
        child: scaffold,
      );
    }

    return scaffold;
  }
}