import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/unified_mission_model.dart';

/// 🎯 미션 상태 배지 컴포넌트
/// 양방향 실시간 동기화를 위한 상태 표시 UI
class MissionStatusBadge extends StatelessWidget {
  final String status;
  final bool isRealtime;
  final VoidCallback? onTap;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const MissionStatusBadge({
    super.key,
    required this.status,
    this.isRealtime = false,
    this.onTap,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: padding ?? EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: statusInfo.backgroundColor,
          borderRadius: BorderRadius.circular(12.r),
          border: isRealtime
            ? Border.all(color: statusInfo.accentColor, width: 1)
            : null,
          boxShadow: isRealtime ? [
            BoxShadow(
              color: statusInfo.accentColor.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRealtime) ...[
              Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  color: statusInfo.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4.w),
            ],
            Icon(
              statusInfo.icon,
              size: (fontSize ?? 12.sp) + 2,
              color: statusInfo.textColor,
            ),
            SizedBox(width: 4.w),
            Text(
              statusInfo.displayText,
              style: TextStyle(
                color: statusInfo.textColor,
                fontSize: fontSize ?? 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return _StatusInfo(
          displayText: '신청 대기',
          icon: Icons.hourglass_empty,
          backgroundColor: Colors.orange.shade100,
          textColor: Colors.orange.shade800,
          accentColor: Colors.orange.shade400,
        );
      case 'approved':
        return _StatusInfo(
          displayText: '승인됨',
          icon: Icons.check_circle,
          backgroundColor: Colors.blue.shade100,
          textColor: Colors.blue.shade800,
          accentColor: Colors.blue.shade400,
        );
      case 'in_progress':
        return _StatusInfo(
          displayText: '진행중',
          icon: Icons.play_circle,
          backgroundColor: Colors.purple.shade100,
          textColor: Colors.purple.shade800,
          accentColor: Colors.purple.shade400,
        );
      case 'completed':
        return _StatusInfo(
          displayText: '완료',
          icon: Icons.check_circle_outline,
          backgroundColor: Colors.green.shade100,
          textColor: Colors.green.shade800,
          accentColor: Colors.green.shade400,
        );
      case 'rejected':
        return _StatusInfo(
          displayText: '거절됨',
          icon: Icons.cancel,
          backgroundColor: Colors.red.shade100,
          textColor: Colors.red.shade800,
          accentColor: Colors.red.shade400,
        );
      default:
        return _StatusInfo(
          displayText: '알 수 없음',
          icon: Icons.help_outline,
          backgroundColor: Colors.grey.shade100,
          textColor: Colors.grey.shade800,
          accentColor: Colors.grey.shade400,
        );
    }
  }
}

/// 🏷️ 미션 카드 위젯 (통합 버전)
/// UnifiedMissionModel을 사용하여 모든 미션 정보를 표시
class MissionCardWidget extends StatelessWidget {
  final UnifiedMissionModel mission;
  final VoidCallback? onTap;
  final VoidCallback? onStatusTap;
  final bool showProgress;
  final bool isRealtime;
  final Widget? trailing;

  const MissionCardWidget({
    super.key,
    required this.mission,
    this.onTap,
    this.onStatusTap,
    this.showProgress = true,
    this.isRealtime = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 앱 이름과 상태 배지
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mission.appName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  MissionStatusBadge(
                    status: mission.status,
                    isRealtime: isRealtime,
                    onTap: onStatusTap,
                  ),
                  if (trailing != null) ...[
                    SizedBox(width: 8.w),
                    trailing!,
                  ],
                ],
              ),

              SizedBox(height: 12.h),

              // 테스터 정보
              Row(
                children: [
                  Icon(Icons.person, size: 16.w, color: Colors.grey[600]),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      mission.testerName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8.h),

              // 이메일
              Row(
                children: [
                  Icon(Icons.email, size: 16.w, color: Colors.grey[600]),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      mission.testerEmail,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (showProgress && mission.status == 'in_progress') ...[
                SizedBox(height: 12.h),

                // 진행률 표시
                _buildProgressSection(),
              ],

              SizedBox(height: 12.h),

              // 하단 정보: 신청일시와 포인트
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14.w, color: Colors.grey[500]),
                  SizedBox(width: 4.w),
                  Text(
                    _formatDateTime(mission.appliedAt),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.monetization_on, size: 14.w, color: Colors.amber),
                  SizedBox(width: 4.w),
                  Text(
                    '${mission.dailyPoints}P/일',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '진행률',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),
            Text(
              '${mission.currentDay}/${mission.totalDays}일',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        LinearProgressIndicator(
          value: mission.progressPercentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            mission.progressPercentage >= 100
              ? Colors.green
              : Colors.blue,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '${mission.progressPercentage.toStringAsFixed(1)}% 완료',
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}

/// 📊 미션 통계 카드
class MissionStatsCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const MissionStatsCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24.w,
                color: color,
              ),
              SizedBox(height: 8.h),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔄 실시간 동기화 상태 표시기
class RealtimeSyncIndicator extends StatefulWidget {
  final bool isConnected;
  final DateTime? lastUpdated;

  const RealtimeSyncIndicator({
    super.key,
    required this.isConnected,
    this.lastUpdated,
  });

  @override
  State<RealtimeSyncIndicator> createState() => _RealtimeSyncIndicatorState();
}

class _RealtimeSyncIndicatorState extends State<RealtimeSyncIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isConnected) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(RealtimeSyncIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected != oldWidget.isConnected) {
      if (widget.isConnected) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: widget.isConnected
          ? Colors.green.shade50
          : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: widget.isConnected
            ? Colors.green.shade200
            : Colors.red.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isConnected ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    color: widget.isConnected
                      ? Colors.green
                      : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 6.w),
          Text(
            widget.isConnected ? '실시간 연결' : '연결 끊김',
            style: TextStyle(
              fontSize: 10.sp,
              color: widget.isConnected
                ? Colors.green.shade700
                : Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.lastUpdated != null) ...[
            SizedBox(width: 4.w),
            Text(
              '(${_formatTime(widget.lastUpdated!)})',
              style: TextStyle(
                fontSize: 9.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '방금';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else {
      return '${difference.inHours}시간 전';
    }
  }
}

// 헬퍼 클래스들
class _StatusInfo {
  final String displayText;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;

  _StatusInfo({
    required this.displayText,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
  });
}

/// 🎯 QuickActions 버튼들
class MissionQuickActions extends StatelessWidget {
  final UnifiedMissionModel mission;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onViewDetails;
  final VoidCallback? onProgress;

  const MissionQuickActions({
    super.key,
    required this.mission,
    this.onApprove,
    this.onReject,
    this.onViewDetails,
    this.onProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mission.status == 'pending') ...[
          _QuickActionButton(
            icon: Icons.check,
            color: Colors.green,
            onTap: onApprove,
            tooltip: '승인',
          ),
          SizedBox(width: 4.w),
          _QuickActionButton(
            icon: Icons.close,
            color: Colors.red,
            onTap: onReject,
            tooltip: '거절',
          ),
        ] else if (mission.status == 'in_progress') ...[
          _QuickActionButton(
            icon: Icons.timeline,
            color: Colors.blue,
            onTap: onProgress,
            tooltip: '진행현황',
          ),
        ],
        SizedBox(width: 4.w),
        _QuickActionButton(
          icon: Icons.visibility,
          color: Colors.grey,
          onTap: onViewDetails,
          tooltip: '상세보기',
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String tooltip;

  const _QuickActionButton({
    required this.icon,
    required this.color,
    this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4.r),
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Icon(
            icon,
            size: 18.w,
            color: color,
          ),
        ),
      ),
    );
  }
}