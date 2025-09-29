import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// BugCash 앱 전용 로딩 위젯들
/// Material Design 3 가이드라인을 따른 사용자 친화적 로딩 인디케이터
class BugCashLoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;
  final bool showMessage;

  const BugCashLoadingWidget({
    super.key,
    this.message,
    this.size,
    this.color,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? 40.0,
            height: size ?? 40.0,
            child: CircularProgressIndicator(
              strokeWidth: 3.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? colorScheme.primary,
              ),
            ),
          ),
          if (showMessage && message != null) ...[
            SizedBox(height: 16.h),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// 미션 카드용 스켈레톤 로딩
class MissionCardSkeleton extends StatefulWidget {
  final int itemCount;

  const MissionCardSkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  State<MissionCardSkeleton> createState() => _MissionCardSkeletonState();
}

class _MissionCardSkeletonState extends State<MissionCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.only(bottom: 16.h),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // 앱 아이콘 스켈레톤
                          Container(
                            width: 48.w,
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.3 + (0.3 * _animation.value),
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 앱 이름 스켈레톤
                                Container(
                                  width: double.infinity,
                                  height: 16.h,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest.withValues(
                                      alpha: 0.3 + (0.3 * _animation.value),
                                    ),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                // 미션 제목 스켈레톤
                                Container(
                                  width: 200.w,
                                  height: 14.h,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest.withValues(
                                      alpha: 0.3 + (0.3 * _animation.value),
                                    ),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 보상 스켈레톤
                          Container(
                            width: 60.w,
                            height: 24.h,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.3 + (0.3 * _animation.value),
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      // 설명 스켈레톤
                      Container(
                        width: double.infinity,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(
                            0.3 + (0.3 * _animation.value),
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 180.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(
                            0.3 + (0.3 * _animation.value),
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // 버튼 스켈레톤
                      Container(
                        width: double.infinity,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(
                            0.3 + (0.3 * _animation.value),
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 버튼 로딩 상태 위젯
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final String text;
  final String? loadingText;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.text,
    this.loadingText,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 48.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? colorScheme.primary,
          foregroundColor: textColor ?? colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
          elevation: isLoading ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16.w,
                    height: 16.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (loadingText != null) ...[
                    SizedBox(width: 8.w),
                    Text(
                      loadingText!,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              )
            : Text(
                text,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// 미션 상세 페이지 로딩 위젯
class MissionDetailLoading extends StatelessWidget {
  const MissionDetailLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const BugCashLoadingWidget(
      message: '미션 정보를 불러오는 중...',
      size: 36.0,
    );
  }
}

/// 어플리케이션 상태 로딩 위젯
class ApplicationStatusLoading extends StatelessWidget {
  const ApplicationStatusLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const BugCashLoadingWidget(
      message: '신청 현황을 확인하는 중...',
      size: 24.0,
      showMessage: false,
    );
  }
}

/// 새로고침 인디케이터
class BugCashRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const BugCashRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      strokeWidth: 3.0,
      displacement: 40.0,
      child: child,
    );
  }
}