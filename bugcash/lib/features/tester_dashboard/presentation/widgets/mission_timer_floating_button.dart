import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 미션 테스트 중 표시되는 플로팅 타이머 버튼
///
/// 기능:
/// - 0분부터 카운트업 타이머 표시
/// - 5분, 10분 경과 시 알림
/// - 스크린샷 버튼 (항상 활성화)
/// - 완료 버튼 (10분 경과 후 활성화)
/// - 확장/축소 가능한 UI
class MissionTimerFloatingButton extends StatefulWidget {
  /// 미션 시작 시간 (Firestore Timestamp)
  final DateTime startedAt;

  /// 스크린샷 버튼 클릭 시 콜백
  final VoidCallback onScreenshot;

  /// 완료 버튼 클릭 시 콜백
  final VoidCallback onComplete;

  /// 타이머 지속 시간 (기본값: 10분)
  final Duration duration;

  const MissionTimerFloatingButton({
    super.key,
    required this.startedAt,
    required this.onScreenshot,
    required this.onComplete,
    this.duration = const Duration(minutes: 10),
  });

  @override
  State<MissionTimerFloatingButton> createState() => _MissionTimerFloatingButtonState();
}

class _MissionTimerFloatingButtonState extends State<MissionTimerFloatingButton> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isExpanded = false;
  bool _isCompleted = false;
  bool _has5MinuteNotified = false;
  bool _has10MinuteNotified = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateElapsed();
        });
      }
    });
  }

  void _updateElapsed() {
    final now = DateTime.now();
    _elapsed = now.difference(widget.startedAt);

    // 10분 경과 시 완료 상태로 변경
    if (_elapsed >= widget.duration) {
      _isCompleted = true;

      // 10분 알림 (한 번만)
      if (!_has10MinuteNotified) {
        _has10MinuteNotified = true;
        _showTimeNotification('10분 경과', '테스트가 완료되었습니다! 완료 버튼을 눌러주세요.', Colors.green);
      }
    } else {
      _isCompleted = false;

      // 5분 알림 (한 번만)
      if (_elapsed >= const Duration(minutes: 5) && !_has5MinuteNotified) {
        _has5MinuteNotified = true;
        _showTimeNotification('5분 경과', '벌써 5분이 지났습니다! 계속 테스트해주세요.', Colors.blue);
      }
    }
  }

  /// 시간 경과 알림 표시
  void _showTimeNotification(String title, String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.timer, color: Colors.white),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Color _getTimerColor() {
    if (_isCompleted) return Colors.green;
    if (_elapsed >= const Duration(minutes: 7)) return Colors.orange;
    if (_elapsed >= const Duration(minutes: 5)) return Colors.blue;
    return Colors.grey[700]!;
  }

  /// 조기 완료 경고 다이얼로그 표시
  Future<void> _showEarlyCompleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24.sp),
            SizedBox(width: 8.w),
            Text(
              '조기 완료',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '10분이 지나지 않았습니다.',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '경과 시간: ${_formatTime(_elapsed)}',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              '정말 지금 완료하시겠습니까?',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('완료'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16.w,
      bottom: 80.h,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(_isExpanded ? 16.r : 28.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _isExpanded ? 200.w : 56.w,
          height: _isExpanded ? 200.h : 56.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_isExpanded ? 16.r : 28.r),
            border: Border.all(
              color: _getTimerColor(),
              width: 2,
            ),
          ),
          child: _isExpanded ? _buildExpandedContent() : _buildCollapsedContent(),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent() {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = true;
        });
      },
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer,
              color: _getTimerColor(),
              size: 24.sp,
            ),
            SizedBox(height: 2.h),
            Text(
              _formatTime(_elapsed),
              style: TextStyle(
                fontSize: 8.sp,
                fontWeight: FontWeight.bold,
                color: _getTimerColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 상단: 타이머 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '테스트 중',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = false;
                  });
                },
                icon: Icon(Icons.close, size: 16.sp),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          // 중앙: 경과 시간
          Column(
            children: [
              Text(
                _formatTime(_elapsed),
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: _getTimerColor(),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _isCompleted ? '✅ 테스트 완료!' : '경과 시간',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          // 하단: 버튼들
          Column(
            children: [
              // 스크린샷 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onScreenshot,
                  icon: Icon(Icons.camera_alt, size: 14.sp),
                  label: Text(
                    '스크린샷',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              // 완료 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCompleted ? widget.onComplete : _showEarlyCompleteDialog,
                  icon: Icon(
                    _isCompleted ? Icons.check_circle : Icons.lock,
                    size: 14.sp,
                  ),
                  label: Text(
                    '완료',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCompleted ? Colors.green : Colors.grey[300],
                    foregroundColor: _isCompleted ? Colors.white : Colors.grey[600],
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 미션 시작 시 전체 화면에 표시되는 타이머 오버레이
///
/// 3-5초 동안 표시된 후 자동으로 플로팅 버튼으로 축소됨
class MissionStartTimerOverlay extends StatefulWidget {
  /// 표시 지속 시간 (기본값: 3초)
  final Duration displayDuration;

  /// 애니메이션 완료 후 콜백
  final VoidCallback onComplete;

  const MissionStartTimerOverlay({
    super.key,
    this.displayDuration = const Duration(seconds: 3),
    required this.onComplete,
  });

  @override
  State<MissionStartTimerOverlay> createState() => _MissionStartTimerOverlayState();
}

class _MissionStartTimerOverlayState extends State<MissionStartTimerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.displayDuration,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.7 * (1 - _opacityAnimation.value)), // v2.150.0: withValues → withOpacity
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: 1 - _opacityAnimation.value,
                child: Container(
                  padding: EdgeInsets.all(32.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_filled,
                        size: 80.sp,
                        color: Colors.green,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '미션 시작!',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '10분 동안 앱을 테스트해주세요',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer, size: 16.sp, color: Colors.blue),
                            SizedBox(width: 8.w),
                            Text(
                              '10:00',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
