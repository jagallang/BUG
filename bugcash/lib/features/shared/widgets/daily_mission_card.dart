import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/mission_management_model.dart';
import 'mission_status_badge.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/extensions/responsive_extensions.dart';

/// 일일 미션 카드 위젯
class DailyMissionCard extends StatefulWidget {
  final DailyMissionModel mission;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final VoidCallback? onSubmit;
  final VoidCallback? onResubmit;

  const DailyMissionCard({
    super.key,
    required this.mission,
    this.onTap,
    this.onDelete,
    this.onStart,
    this.onComplete,
    this.onSubmit,
    this.onResubmit,
  });

  @override
  State<DailyMissionCard> createState() => _DailyMissionCardState();
}

class _DailyMissionCardState extends State<DailyMissionCard> {
  bool _deleteConfirmMode = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // v2.10.0: 일련번호 표시 (있는 경우)
              if (widget.mission.serialNumber != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    widget.mission.serialNumber!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
              ],

              // 헤더: 타이틀과 상태 배지
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.mission.missionTitle,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  MissionStatusBadge(
                    status: widget.mission.status,
                    isLarge: true,
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // 미션 설명
              Text(
                widget.mission.missionDescription,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 12.h),

              // 미션 정보
              Row(
                children: [
                  Icon(
                    Icons.date_range,
                    size: 16.sp,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _formatDate(widget.mission.missionDate),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Icon(
                    Icons.monetization_on,
                    size: 16.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${widget.mission.baseReward.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // 거절 사유 표시 (거절된 경우)
              if (widget.mission.status == DailyMissionStatus.rejected && widget.mission.reviewNote != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16.sp,
                            color: Colors.red,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '거절 사유',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.mission.reviewNote!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 16.h),

              // 액션 버튼
              _buildActionButton(),
            ],
          ),
        ),
      ).withUserTypeCard(
        userType: 'tester',
        borderRadius: 16.r,
        withHover: true,
      );
  }

  Widget _buildActionButton() {
    // 디버그 로그
    print('🔍 [DailyMissionCard] _buildActionButton()');
    print('   ├─ currentState: ${widget.mission.currentState}');
    print('   ├─ startedAt: ${widget.mission.startedAt}');
    print('   ├─ completedAt: ${widget.mission.completedAt}');
    print('   └─ status: ${widget.mission.status}');

    // 1. 공급자 승인 대기 중 (application_submitted)
    if (widget.mission.currentState == 'application_submitted') {
      return Row(
        children: [
          // 삭제 버튼 - 2단계 확인 시스템
          if (widget.onDelete != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleDeleteClick,
                icon: Icon(Icons.delete, size: 14.sp),
                label: Text('삭제', style: TextStyle(fontSize: 12.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _deleteConfirmMode ? Colors.red : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            ),
          if (widget.onDelete != null) SizedBox(width: 6.w),
          // 승인 대기 버튼
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: null,
              icon: Icon(Icons.hourglass_empty, size: 16.sp),
              label: Text('공급자 승인 대기 중', style: TextStyle(fontSize: 13.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                disabledBackgroundColor: Colors.orange.withValues(alpha: 0.6),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ),
        ],
      );
    }

    // 2. 미션 시작 전 (approved 또는 application_approved + startedAt 없음)
    if ((widget.mission.currentState == 'approved' || widget.mission.currentState == 'application_approved') &&
        widget.mission.startedAt == null) {
      return _build4ButtonRow(
        canDelete: widget.onDelete != null,
        canStart: widget.onStart != null,
        canComplete: false,
        canSubmit: false,
        startedAt: null,
      );
    }

    // 3. 미션 진행 중 (in_progress, mission_in_progress)
    // 완료 버튼 활성화 (10분 미만 시 경고 다이얼로그 표시)
    if (widget.mission.currentState == 'in_progress' ||
        widget.mission.currentState == 'mission_in_progress') {
      return _build4ButtonRow(
        canDelete: widget.onDelete != null,
        canStart: false,
        canComplete: widget.onComplete != null,
        canSubmit: false,
        startedAt: widget.mission.startedAt,
      );
    }

    // v2.11.3: testing_completed 상태 (완료됨, 제출 대기)
    if (widget.mission.currentState == 'testing_completed') {
      return _build4ButtonRow(
        canDelete: widget.onDelete != null,
        canStart: false,
        canComplete: false, // 이미 완료됨
        canSubmit: widget.onSubmit != null, // 제출 가능
        startedAt: widget.mission.startedAt,
      );
    }

    // 5. 제출 완료 (공급자 검토 대기)
    if (widget.mission.status == DailyMissionStatus.completed) {
      return Row(
        children: [
          // 삭제 버튼 - 2단계 확인 시스템
          if (widget.onDelete != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleDeleteClick,
                icon: Icon(Icons.delete, size: 14.sp),
                label: Text('삭제', style: TextStyle(fontSize: 12.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _deleteConfirmMode ? Colors.red : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            ),
          if (widget.onDelete != null) SizedBox(width: 6.w),
          // 검토 대기 버튼
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: null,
              icon: Icon(Icons.pending, size: 14.sp),
              label: Text('검토 대기 중', style: TextStyle(fontSize: 13.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.7),
                disabledForegroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ),
        ],
      );
    }

    // 6. 승인 완료
    if (widget.mission.status == DailyMissionStatus.approved) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: Icon(Icons.check_circle, size: 14.sp),
          label: Text('승인 완료', style: TextStyle(fontSize: 13.sp)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            disabledBackgroundColor: Colors.green.withValues(alpha: 0.7),
            disabledForegroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        ),
      );
    }

    // 7. 거절됨 (재제출)
    if (widget.mission.status == DailyMissionStatus.rejected) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.onResubmit,
          icon: Icon(Icons.refresh, size: 14.sp),
          label: Text('재제출', style: TextStyle(fontSize: 13.sp)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        ),
      );
    }

    // 기본값 (예상치 못한 상태)
    return Row(
      children: [
        // 삭제 버튼 - 2단계 확인 시스템
        if (widget.onDelete != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handleDeleteClick,
              icon: Icon(Icons.delete, size: 14.sp),
              label: Text('삭제', style: TextStyle(fontSize: 12.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _deleteConfirmMode ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ),
        if (widget.onDelete != null) SizedBox(width: 6.w),
        // 상태 확인 중 버튼
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: null,
            icon: Icon(Icons.help_outline, size: 14.sp),
            label: Text('상태 확인 중', style: TextStyle(fontSize: 13.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              disabledBackgroundColor: Colors.grey.withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ),
      ],
    );
  }

  /// 4개 버튼 가로 레이아웃 (삭제-시작-완료-제출)
  Widget _build4ButtonRow({
    required bool canDelete,
    required bool canStart,
    required bool canComplete,
    required bool canSubmit,
    required DateTime? startedAt,
  }) {
    return Row(
          children: [
            // [삭제] 버튼 - 2단계 확인 시스템
            Expanded(
              child: _buildRowButton(
                icon: Icons.delete,
                label: '삭제',
                color: _deleteConfirmMode ? Colors.red : Colors.grey,
                enabled: canDelete,
                onPressed: canDelete ? _handleDeleteClick : null,
              ),
            ),
            SizedBox(width: 6.w),
            // [시작] 버튼
            Expanded(
              child: _buildRowButton(
                icon: canStart ? Icons.play_arrow : Icons.check,
                label: canStart ? '시작' : '시작됨',
                color: Colors.blue,
                enabled: canStart,
                onPressed: canStart ? widget.onStart : null,
              ),
            ),
            SizedBox(width: 6.w),
            // [완료] 버튼
            Expanded(
              child: _buildRowButton(
                icon: Icons.check_circle,
                label: '완료',
                color: Colors.orange,
                enabled: canComplete,
                onPressed: canComplete ? widget.onComplete : null,
              ),
            ),
            SizedBox(width: 6.w),
            // [제출] 버튼
            Expanded(
              child: _buildRowButton(
                icon: Icons.upload,
                label: '제출',
                color: Colors.green,
                enabled: canSubmit,
                onPressed: canSubmit ? widget.onSubmit : null,
              ),
            ),
          ],
        );
  }

  /// 삭제 버튼 클릭 핸들러 (2단계 확인)
  void _handleDeleteClick() {
    if (!_deleteConfirmMode) {
      // 1단계: 회색 → 빨간색 활성화
      setState(() {
        _deleteConfirmMode = true;
      });
    } else {
      // 2단계: 모달 다이얼로그 표시
      _showDeleteConfirmDialog();
    }
  }

  /// 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28.sp),
            SizedBox(width: 8.w),
            Text('미션 삭제', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '정말로 이 미션을 삭제하시겠습니까?',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8.h),
            Text(
              '삭제된 미션은 복구할 수 없습니다.',
              style: TextStyle(fontSize: 13.sp, color: Colors.red[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              setState(() {
                _deleteConfirmMode = false; // 취소 시 회색으로 복귀
              });
            },
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onDelete?.call();
    }

    // 다이얼로그 닫힌 후 확인 모드 리셋
    if (mounted) {
      setState(() {
        _deleteConfirmMode = false;
      });
    }
  }

  /// 가로 버튼 빌더
  Widget _buildRowButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        elevation: enabled ? 2 : 0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16.sp),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}