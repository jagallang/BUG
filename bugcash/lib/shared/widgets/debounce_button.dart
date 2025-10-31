import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// v2.186.34: 중복 클릭 방지 버튼 위젯 (재사용 가능)
///
/// 특징:
/// - 비동기 작업 중 자동으로 버튼 비활성화
/// - 로딩 인디케이터 표시 옵션
/// - finally 블록으로 안전한 상태 복구
/// - 커스터마이징 가능한 스타일
///
/// 사용 예시:
/// ```dart
/// DebounceButton(
///   onPressed: () async {
///     await someAsyncOperation();
///   },
///   child: Text('클릭'),
/// )
/// ```
class DebounceButton extends StatefulWidget {
  /// 버튼 클릭 시 실행될 비동기 함수
  final Future<void> Function()? onPressed;

  /// 버튼 자식 위젯 (텍스트, 아이콘 등)
  final Widget child;

  /// 로딩 중 표시될 위젯 (기본값: CircularProgressIndicator)
  final Widget? loadingWidget;

  /// 로딩 중 표시할 텍스트 (loadingWidget 우선)
  final String? loadingText;

  /// 버튼 스타일
  final ButtonStyle? style;

  /// 로딩 인디케이터 표시 여부 (기본값: true)
  final bool showLoadingIndicator;

  /// 에러 발생 시 SnackBar 표시 여부 (기본값: true)
  final bool showErrorSnackBar;

  /// 커스텀 에러 메시지 포맷터
  final String Function(Object error)? errorMessageBuilder;

  const DebounceButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loadingWidget,
    this.loadingText,
    this.style,
    this.showLoadingIndicator = true,
    this.showErrorSnackBar = true,
    this.errorMessageBuilder,
  });

  @override
  State<DebounceButton> createState() => _DebounceButtonState();
}

class _DebounceButtonState extends State<DebounceButton> {
  bool _isProcessing = false;

  Future<void> _handlePress() async {
    // 이미 처리 중이면 무시
    if (_isProcessing) {
      debugPrint('[DebounceButton] Already processing, ignoring tap');
      return;
    }

    if (widget.onPressed == null) return;

    // 즉시 플래그 설정
    setState(() => _isProcessing = true);
    if (!mounted) return;

    try {
      await widget.onPressed!();
    } catch (e, stackTrace) {
      debugPrint('[DebounceButton] Error: $e');
      debugPrint('[DebounceButton] StackTrace: $stackTrace');

      // 에러 SnackBar 표시
      if (widget.showErrorSnackBar && mounted) {
        final errorMessage = widget.errorMessageBuilder?.call(e) ??
                             '작업 중 오류가 발생했습니다: ${e.toString()}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // 항상 플래그 해제
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _handlePress,
      style: widget.style,
      child: _isProcessing && widget.showLoadingIndicator
          ? _buildLoadingWidget()
          : widget.child,
    );
  }

  Widget _buildLoadingWidget() {
    if (widget.loadingWidget != null) {
      return widget.loadingWidget!;
    }

    if (widget.loadingText != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16.w,
            height: 16.h,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 8.w),
          Text(widget.loadingText!),
        ],
      );
    }

    // 기본 로딩 인디케이터
    return SizedBox(
      width: 16.w,
      height: 16.h,
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}

/// OutlinedButton 버전
class DebounceOutlinedButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget child;
  final Widget? loadingWidget;
  final String? loadingText;
  final ButtonStyle? style;
  final bool showLoadingIndicator;
  final bool showErrorSnackBar;
  final String Function(Object error)? errorMessageBuilder;

  const DebounceOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loadingWidget,
    this.loadingText,
    this.style,
    this.showLoadingIndicator = true,
    this.showErrorSnackBar = true,
    this.errorMessageBuilder,
  });

  @override
  State<DebounceOutlinedButton> createState() => _DebounceOutlinedButtonState();
}

class _DebounceOutlinedButtonState extends State<DebounceOutlinedButton> {
  bool _isProcessing = false;

  Future<void> _handlePress() async {
    if (_isProcessing) {
      debugPrint('[DebounceOutlinedButton] Already processing, ignoring tap');
      return;
    }

    if (widget.onPressed == null) return;

    setState(() => _isProcessing = true);
    if (!mounted) return;

    try {
      await widget.onPressed!();
    } catch (e, stackTrace) {
      debugPrint('[DebounceOutlinedButton] Error: $e');
      debugPrint('[DebounceOutlinedButton] StackTrace: $stackTrace');

      if (widget.showErrorSnackBar && mounted) {
        final errorMessage = widget.errorMessageBuilder?.call(e) ??
                             '작업 중 오류가 발생했습니다: ${e.toString()}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _isProcessing ? null : _handlePress,
      style: widget.style,
      child: _isProcessing && widget.showLoadingIndicator
          ? _buildLoadingWidget()
          : widget.child,
    );
  }

  Widget _buildLoadingWidget() {
    if (widget.loadingWidget != null) {
      return widget.loadingWidget!;
    }

    if (widget.loadingText != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16.w,
            height: 16.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(widget.loadingText!),
        ],
      );
    }

    return SizedBox(
      width: 16.w,
      height: 16.h,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

/// TextButton 버전
class DebounceTextButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget child;
  final Widget? loadingWidget;
  final String? loadingText;
  final ButtonStyle? style;
  final bool showLoadingIndicator;
  final bool showErrorSnackBar;
  final String Function(Object error)? errorMessageBuilder;

  const DebounceTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loadingWidget,
    this.loadingText,
    this.style,
    this.showLoadingIndicator = true,
    this.showErrorSnackBar = true,
    this.errorMessageBuilder,
  });

  @override
  State<DebounceTextButton> createState() => _DebounceTextButtonState();
}

class _DebounceTextButtonState extends State<DebounceTextButton> {
  bool _isProcessing = false;

  Future<void> _handlePress() async {
    if (_isProcessing) {
      debugPrint('[DebounceTextButton] Already processing, ignoring tap');
      return;
    }

    if (widget.onPressed == null) return;

    setState(() => _isProcessing = true);
    if (!mounted) return;

    try {
      await widget.onPressed!();
    } catch (e, stackTrace) {
      debugPrint('[DebounceTextButton] Error: $e');
      debugPrint('[DebounceTextButton] StackTrace: $stackTrace');

      if (widget.showErrorSnackBar && mounted) {
        final errorMessage = widget.errorMessageBuilder?.call(e) ??
                             '작업 중 오류가 발생했습니다: ${e.toString()}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _isProcessing ? null : _handlePress,
      style: widget.style,
      child: _isProcessing && widget.showLoadingIndicator
          ? _buildLoadingWidget()
          : widget.child,
    );
  }

  Widget _buildLoadingWidget() {
    if (widget.loadingWidget != null) {
      return widget.loadingWidget!;
    }

    if (widget.loadingText != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16.w,
            height: 16.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(widget.loadingText!),
        ],
      );
    }

    return SizedBox(
      width: 16.w,
      height: 16.h,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

/// IconButton 버전
class DebounceIconButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget icon;
  final Widget? loadingWidget;
  final double? iconSize;
  final Color? color;
  final Color? disabledColor;
  final String? tooltip;
  final bool showErrorSnackBar;
  final String Function(Object error)? errorMessageBuilder;

  const DebounceIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.loadingWidget,
    this.iconSize,
    this.color,
    this.disabledColor,
    this.tooltip,
    this.showErrorSnackBar = true,
    this.errorMessageBuilder,
  });

  @override
  State<DebounceIconButton> createState() => _DebounceIconButtonState();
}

class _DebounceIconButtonState extends State<DebounceIconButton> {
  bool _isProcessing = false;

  Future<void> _handlePress() async {
    if (_isProcessing) {
      debugPrint('[DebounceIconButton] Already processing, ignoring tap');
      return;
    }

    if (widget.onPressed == null) return;

    setState(() => _isProcessing = true);
    if (!mounted) return;

    try {
      await widget.onPressed!();
    } catch (e, stackTrace) {
      debugPrint('[DebounceIconButton] Error: $e');
      debugPrint('[DebounceIconButton] StackTrace: $stackTrace');

      if (widget.showErrorSnackBar && mounted) {
        final errorMessage = widget.errorMessageBuilder?.call(e) ??
                             '작업 중 오류가 발생했습니다: ${e.toString()}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isProcessing ? null : _handlePress,
      icon: _isProcessing
          ? (widget.loadingWidget ??
             SizedBox(
               width: (widget.iconSize ?? 24.sp) * 0.7,
               height: (widget.iconSize ?? 24.sp) * 0.7,
               child: CircularProgressIndicator(
                 strokeWidth: 2,
                 valueColor: AlwaysStoppedAnimation<Color>(
                   widget.color ?? Theme.of(context).primaryColor,
                 ),
               ),
             ))
          : widget.icon,
      iconSize: widget.iconSize,
      color: widget.color,
      disabledColor: widget.disabledColor,
      tooltip: widget.tooltip,
    );
  }
}
