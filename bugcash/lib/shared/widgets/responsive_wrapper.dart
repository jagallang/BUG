import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    this.maxWidth = 1200, // 기본 최대 너비 1200px
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
    final bool isDesktop = screenWidth > 1024;
    final bool isTablet = screenWidth > 600 && screenWidth <= 1024;

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
                      color: Colors.black.withValues(alpha: 0.05),
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

    if (screenWidth > 1024) {
      // Desktop
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    } else if (screenWidth > 600) {
      // Tablet
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    } else {
      // Mobile
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }
  }

  /// 화면 크기에 따른 그리드 컬럼 수 반환
  static int getResponsiveGridColumns(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 1200) {
      return 4;
    } else if (screenWidth > 900) {
      return 3;
    } else if (screenWidth > 600) {
      return 2;
    } else {
      return 1;
    }
  }

  /// 화면 크기에 따른 카드 너비 반환
  static double getResponsiveCardWidth(BuildContext context, {int columns = 3}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = screenWidth > 1200 ? 1200.0 : screenWidth;
    final padding = getResponsivePadding(context);
    final availableWidth = maxContentWidth - padding.horizontal;

    // 화면 크기에 따른 컬럼 수 조정
    int actualColumns = columns;
    if (screenWidth <= 600) {
      actualColumns = 1;
    } else if (screenWidth <= 900) {
      actualColumns = 2;
    } else if (screenWidth <= 1200) {
      actualColumns = columns > 3 ? 3 : columns;
    }

    // 카드 간격 고려
    const spacing = 16.0;
    return (availableWidth - (spacing * (actualColumns - 1))) / actualColumns;
  }

  /// 브레이크포인트 확인 헬퍼 메서드들
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// 반응형 폰트 크기 계산
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 1200) {
      return baseSize * 1.1; // Desktop: 10% 크게
    } else if (screenWidth > 600) {
      return baseSize; // Tablet: 기본 크기
    } else {
      return baseSize * 0.9; // Mobile: 10% 작게
    }
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
    this.maxWidth = 1200,
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