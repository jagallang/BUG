import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/responsive_breakpoints.dart';

/// 반응형 데이터를 캐싱하는 모델 클래스
@immutable
class ResponsiveData {
  final double screenWidth;
  final double screenHeight;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final bool isWideDesktop;
  final int gridColumns;
  final EdgeInsets padding;
  final double fontScale;
  final double sidebarWidth;

  const ResponsiveData({
    required this.screenWidth,
    required this.screenHeight,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.isWideDesktop,
    required this.gridColumns,
    required this.padding,
    required this.fontScale,
    required this.sidebarWidth,
  });

  factory ResponsiveData.fromScreenSize(Size screenSize) {
    final width = screenSize.width;
    final height = screenSize.height;

    return ResponsiveData(
      screenWidth: width,
      screenHeight: height,
      isMobile: ResponsiveBreakpoints.isMobileWidth(width),
      isTablet: ResponsiveBreakpoints.isTabletWidth(width),
      isDesktop: ResponsiveBreakpoints.isDesktopWidth(width),
      isWideDesktop: ResponsiveBreakpoints.isWideDesktopWidth(width),
      gridColumns: ResponsiveBreakpoints.getColumnCount(width),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveBreakpoints.getPaddingHorizontal(width),
        vertical: ResponsiveBreakpoints.getPaddingVertical(width),
      ),
      fontScale: ResponsiveBreakpoints.getFontScale(width),
      sidebarWidth: ResponsiveBreakpoints.getSidebarWidth(width),
    );
  }

  /// 카드 너비 계산 (간격 고려)
  double getCardWidth({int requestedColumns = 3}) {
    final actualColumns = gridColumns < requestedColumns ? gridColumns : requestedColumns;
    final availableWidth = (screenWidth > ResponsiveBreakpoints.desktop
        ? ResponsiveBreakpoints.maxContentWidth
        : screenWidth) - padding.horizontal;

    const spacing = ResponsiveBreakpoints.gridSpacing;
    return (availableWidth - (spacing * (actualColumns - 1))) / actualColumns;
  }

  /// 반응형 폰트 크기 계산
  double getResponsiveFontSize(double baseSize) {
    return baseSize * fontScale;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponsiveData &&
          runtimeType == other.runtimeType &&
          screenWidth == other.screenWidth &&
          screenHeight == other.screenHeight;

  @override
  int get hashCode => screenWidth.hashCode ^ screenHeight.hashCode;

  @override
  String toString() {
    return 'ResponsiveData(width: $screenWidth, height: $screenHeight, '
        'isMobile: $isMobile, isTablet: $isTablet, isDesktop: $isDesktop, '
        'gridColumns: $gridColumns)';
  }
}

/// ResponsiveData Provider - MediaQuery 결과를 캐싱
final responsiveDataProvider = Provider.family<ResponsiveData, Size>((ref, screenSize) {
  return ResponsiveData.fromScreenSize(screenSize);
});

/// BuildContext에서 ResponsiveData를 쉽게 가져오는 Provider
final contextResponsiveDataProvider = Provider<ResponsiveData?>((ref) {
  // 이 Provider는 Widget에서 override되어 사용됩니다
  return null;
});