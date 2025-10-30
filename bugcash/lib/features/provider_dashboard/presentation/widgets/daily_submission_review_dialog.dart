import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../features/shared/models/mission_workflow_model.dart';
import '../../../../core/services/mission_workflow_service.dart';
import '../../../../core/utils/logger.dart';

/// 일일 미션 제출 검토 다이얼로그
/// 공급자가 테스터의 일일 미션 제출을 검토하고 승인/거부
class DailySubmissionReviewDialog extends StatefulWidget {
  final String workflowId;
  final int dayNumber;
  final DailyMissionInteraction interaction;
  final String providerId;
  final VoidCallback onReviewed;

  const DailySubmissionReviewDialog({
    super.key,
    required this.workflowId,
    required this.dayNumber,
    required this.interaction,
    required this.providerId,
    required this.onReviewed,
  });

  @override
  State<DailySubmissionReviewDialog> createState() =>
      _DailySubmissionReviewDialogState();
}

class _DailySubmissionReviewDialogState
    extends State<DailySubmissionReviewDialog> {
  final _feedbackController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  /// 승인 처리
  Future<void> _handleApprove() async {
    setState(() => _isSubmitting = true);

    try {
      final service = MissionWorkflowService();
      await service.approveDailyMission(
        workflowId: widget.workflowId,
        providerId: widget.providerId,
        dayNumber: widget.dayNumber,
        providerFeedback: _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim(),
        rating: _rating,
      );

      if (mounted) {
        AppLogger.info(
          'Daily mission approved: workflow=${widget.workflowId}, day=${widget.dayNumber}',
          'SubmissionReview',
        );

        Navigator.of(context).pop();
        widget.onReviewed();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 일일 미션을 승인했습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error(
        'Failed to approve mission: $e',
        'SubmissionReview',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 승인 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// 거부 처리
  Future<void> _handleReject() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 거부 사유를 입력해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = MissionWorkflowService();
      // Note: rejectDailyMission 메서드는 추가 구현 필요
      // 여기서는 providerFeedback만 업데이트하는 방식으로 처리
      AppLogger.warning(
        'Reject feature needs implementation in MissionWorkflowService',
        'SubmissionReview',
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onReviewed();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ 거부 기능은 추후 구현 예정입니다.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      AppLogger.error(
        'Failed to reject mission: $e',
        'SubmissionReview',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 거부 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600.w,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.rate_review, color: Colors.blue, size: 28.w),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day ${widget.dayNumber} 제출 검토',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '제출일: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.interaction.testerCompletedAt!)}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // 컨텐츠
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 테스터 피드백
                    _buildSection(
                      title: '테스터 피드백',
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          widget.interaction.testerFeedback ?? '피드백 없음',
                          style: TextStyle(fontSize: 14.sp),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // 스크린샷
                    if (widget.interaction.testerScreenshots.isNotEmpty) ...[
                      _buildSection(
                        title: '스크린샷 (${widget.interaction.testerScreenshots.length}장)',
                        child: _buildScreenshotGallery(),
                      ),
                      SizedBox(height: 20.h),
                    ],

                    // 평점
                    _buildSection(
                      title: '평점',
                      child: _buildRatingSelector(),
                    ),

                    SizedBox(height: 20.h),

                    // 공급자 피드백 입력
                    _buildSection(
                      title: '피드백 (선택사항)',
                      child: TextField(
                        controller: _feedbackController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: '테스터에게 전달할 피드백을 입력하세요.',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          counterStyle: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 액션 버튼
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _handleReject,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('거부'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleApprove,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('승인'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        child,
      ],
    );
  }

  Widget _buildScreenshotGallery() {
    return SizedBox(
      height: 120.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.interaction.testerScreenshots.length,
        itemBuilder: (context, index) {
          final url = widget.interaction.testerScreenshots[index];
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () => _showFullScreenImage(url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  url,
                  width: 120.w,
                  height: 120.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120.w,
                      height: 120.h,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final star = index + 1;
        return IconButton(
          onPressed: () => setState(() => _rating = star),
          icon: Icon(
            star <= _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32.w,
          ),
        );
      }),
    );
  }

  void _showFullScreenImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }
}
