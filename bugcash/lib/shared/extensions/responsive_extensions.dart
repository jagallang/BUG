import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/responsive_data_provider.dart';
import '../theme/responsive_theme.dart';
import '../constants/responsive_breakpoints.dart';
import '../../core/constants/app_colors.dart';

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

  /// 작은 태블릿 여부 (600px-768px, 폰트 크기 개선을 위한 중간 브레이크포인트)
  bool get isSmallTablet => ResponsiveBreakpoints.isSmallTabletWidth(screenWidth);

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

  /// 반응형 폰트 스케일 (웹 모바일 180%, 작은 태블릿 130% 확대)
  /// 최소 폰트 스케일 0.9 보장, 중간 브레이크포인트 지원
  double get fontScale => ResponsiveBreakpoints.getFontScale(screenWidth, isWeb: kIsWeb);

  /// 사이드바 너비
  double get sidebarWidth => ResponsiveBreakpoints.getSidebarWidth(screenWidth);

  /// 컨텐츠 최대 너비
  double get maxContentWidth => screenWidth > ResponsiveBreakpoints.desktop
      ? ResponsiveBreakpoints.maxContentWidth
      : screenWidth;

  /// 웹에서 모바일 사이즈 여부 (180% 폰트 적용 대상)
  bool get isWebMobile => kIsWeb && isMobile;
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
  /// 반응형 폰트 크기 적용 (웹 모바일 180%, 작은 태블릿 130% 확대)
  /// 최소 폰트 스케일 0.9 보장, 중간 브레이크포인트에서 부드러운 스케일링
  double responsiveFont(BuildContext context) {
    final scale = context.fontScale;
    // 최소 크기 보장: 어떤 경우에도 원본의 90% 이하로 내려가지 않음
    return this * scale;
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
  /// 반응형 카드 elevation 적용 (데스크톱에서 더 높은 elevation)
  Widget withResponsiveCardElevation(BuildContext context) {
    if (context.isDesktop) {
      return Card(
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: this,
      );
    } else if (context.isTablet) {
      return Card(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: this,
      );
    } else {
      return Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: this,
      );
    }
  }
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

  // ============================================
  // Phase 3: Advanced 3D Design System
  // ============================================

  /// Glassmorphism 효과 적용
  Widget withGlassEffect({
    double borderRadius = 12.0,
    double blur = 20.0,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.glassBackground,
                AppColors.glassBackground.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1.5,
            ),
            boxShadow: AppColors.glassShadow,
          ),
          child: this,
        ),
      ),
    );
  }

  /// Neumorphism 효과 적용
  Widget withNeumorphism({
    bool isPressed = false,
    double borderRadius = 12.0,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.neuLight,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
          ? AppColors.neuShadowConcave
          : AppColors.neuShadowConvex,
      ),
      child: this,
    );
  }

  /// 고급 gradient 배경 적용
  Widget withGradientBackground({
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    double borderRadius = 12.0,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppColors.cardShadowElevated,
      ),
      child: this,
    );
  }

  /// 미세한 호버 애니메이션 효과
  Widget withHoverAnimation({
    Duration duration = const Duration(milliseconds: 200),
    double scale = 1.02,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: duration,
        transform: Matrix4.identity()..scale(1.0),
        child: this,
      ),
    );
  }

  /// 3D 카드 스타일 (그림자 + 호버 효과 결합)
  Widget with3DCard({
    bool isElevated = false,
    double borderRadius = 12.0,
  }) {
    return withHoverAnimation().withGradientBackground(
      colors: AppColors.cardGradientLight,
      borderRadius: borderRadius,
    );
  }

  // ============================================
  // Phase 4: 사용자 타입별 맞춤화 헬퍼
  // ============================================

  /// 사용자 타입별 카드 스타일 적용
  Widget withUserTypeCard({
    required String userType,
    double borderRadius = 12.0,
    bool withHover = true,
  }) {
    final gradientColors = AppColors.getGradientColors(userType);
    final cardShadow = AppColors.getCardShadow(userType);

    Widget card = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: cardShadow,
      ),
      child: this,
    );

    return withHover ? card.withHoverAnimation() : card;
  }

  /// 사용자 타입별 배지 스타일
  Widget withUserTypeBadge({
    required String userType,
    double borderRadius = 8.0,
  }) {
    final primaryColor = AppColors.getPrimaryColor(userType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: this,
    );
  }

  /// 권한별 차별화된 글래스 효과
  Widget withRoleBasedGlass({
    required String userType,
    double borderRadius = 12.0,
    double blur = 20.0,
  }) {
    final primaryColor = AppColors.getPrimaryColor(userType);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withValues(alpha: 0.15),
                primaryColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: this,
        ),
      ),
    );
  }
}

/// TextStyle에 반응형 관련 확장 메서드 추가
extension ResponsiveTextStyleExtension on TextStyle {
  /// 반응형 폰트 크기 적용 (웹 모바일 180%, 작은 태블릿 130% 확대)
  /// 최소 폰트 스케일 0.9 보장, 중간 브레이크포인트에서 부드러운 스케일링
  TextStyle responsiveFont(BuildContext context) {
    final currentSize = fontSize ?? 14.0;
    final scale = context.fontScale;
    // 최소 크기 보장: 어떤 경우에도 원본의 90% 이하로 내려가지 않음
    return copyWith(
      fontSize: currentSize * scale,
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