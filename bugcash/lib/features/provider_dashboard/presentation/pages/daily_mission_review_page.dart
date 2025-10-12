import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/mission_workflow_service.dart';
import '../../../../features/mission/domain/entities/mission_workflow_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// v2.22.0: 공급자가 제출된 일일 미션을 검토하고 승인/거절하는 페이지
class DailyMissionReviewPage extends ConsumerStatefulWidget {
  final MissionWorkflowEntity mission;
  final int dayNumber;

  const DailyMissionReviewPage({
    super.key,
    required this.mission,
    required this.dayNumber,
  });

  @override
  ConsumerState<DailyMissionReviewPage> createState() => _DailyMissionReviewPageState();
}

class _DailyMissionReviewPageState extends ConsumerState<DailyMissionReviewPage> {
  final _feedbackController = TextEditingController();
  int _rating = 5; // 기본 별점 5점
  bool _isLoading = true;
  bool _isSubmitting = false;

  // 제출된 데이터
  String _testerFeedback = '';
  String _bugReport = '';
  Map<String, String> _questionAnswers = {};
  List<String> _screenshots = [];
  DateTime? _submittedAt;

  @override
  void initState() {
    super.initState();
    _loadSubmissionData();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  /// 제출된 미션 데이터 로드
  Future<void> _loadSubmissionData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('mission_workflows')
          .doc(widget.mission.id)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final dailyInteractions = List<Map<String, dynamic>>.from(data['dailyInteractions'] ?? []);

        // 해당 day의 데이터 찾기
        for (var interaction in dailyInteractions) {
          if (interaction['dayNumber'] == widget.dayNumber) {
            setState(() {
              _testerFeedback = interaction['testerFeedback'] ?? '';
              _screenshots = List<String>.from(interaction['testerScreenshots'] ?? []);
              _submittedAt = (interaction['testerCompletedAt'] as Timestamp?)?.toDate();

              // v2.9.0: testerData에서 bugReport와 questionAnswers 추출
              final testerData = interaction['testerData'] as Map<String, dynamic>? ?? {};
              _bugReport = testerData['bugReport'] ?? '';
              _questionAnswers = Map<String, String>.from(testerData['questionAnswers'] ?? {});

              _isLoading = false;
            });
            break;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 승인 처리
  Future<void> _approveMission() async {
    // 1단계: 일일 리워드 지급 안내
    final firstConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 28.sp),
            SizedBox(width: 8.w),
            Text('리워드 지급 안내', style: TextStyle(fontSize: 18.sp)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Day ${widget.dayNumber} 미션을 승인하면',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.attach_money, color: Colors.green, size: 24.sp),
                  SizedBox(width: 4.w),
                  Text(
                    '${widget.mission.dailyReward.toStringAsFixed(0)}원',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              '의 일일 리워드가 테스터에게 지급됩니다.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(fontSize: 15.sp)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
            child: Text('계속', style: TextStyle(fontSize: 15.sp)),
          ),
        ],
      ),
    );

    if (firstConfirmed != true) return;

    // 2단계: 최종 승인 확인
    if (!mounted) return;
    final finalConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 28.sp),
            SizedBox(width: 8.w),
            Text('최종 승인 확인', style: TextStyle(fontSize: 18.sp)),
          ],
        ),
        content: Text(
          'Day ${widget.dayNumber} 미션을 최종 승인하시겠습니까?\n\n'
          '승인 후에는 취소할 수 없습니다.',
          style: TextStyle(fontSize: 15.sp, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(fontSize: 15.sp)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
            child: Text('최종 승인', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (finalConfirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(missionWorkflowServiceProvider);
      await service.approveDailyMission(
        workflowId: widget.mission.id,
        providerId: widget.mission.providerId,
        dayNumber: widget.dayNumber,
        providerFeedback: _feedbackController.text.trim(),
        rating: _rating,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 미션이 승인되었습니다'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // 성공 시 true 반환
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('승인 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// 거절 처리
  Future<void> _rejectMission() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('거절 사유를 입력해주세요'), backgroundColor: Colors.orange),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('미션 거절'),
        content: Text('이 미션을 거절하시겠습니까?\n\n사유: ${_feedbackController.text.trim()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('거절'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(missionWorkflowServiceProvider);
      await service.rejectDailyMission(
        workflowId: widget.mission.id,
        providerId: widget.mission.providerId,
        dayNumber: widget.dayNumber,
        rejectionReason: _feedbackController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('미션이 거절되었습니다'), backgroundColor: Colors.orange),
        );
        Navigator.pop(context, true); // 성공 시 true 반환
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('거절 실패: $e'), backgroundColor: Colors.red),
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Day ${widget.dayNumber} 미션 검토',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 테스터 정보 카드
                  _buildTesterInfoCard(),
                  SizedBox(height: 16.h),

                  // 테스트 소감
                  _buildFeedbackSection(),
                  SizedBox(height: 16.h),

                  // 버그 리포트
                  if (_bugReport.isNotEmpty) ...[
                    _buildBugReportSection(),
                    SizedBox(height: 16.h),
                  ],

                  // 공급자 질문 답변
                  if (_questionAnswers.isNotEmpty) ...[
                    _buildQuestionAnswersSection(),
                    SizedBox(height: 16.h),
                  ],

                  // 스크린샷 갤러리
                  _buildScreenshotsSection(),
                  SizedBox(height: 16.h),

                  // 공급자 피드백 입력
                  _buildProviderFeedbackSection(),
                  SizedBox(height: 16.h),

                  // 별점 선택
                  _buildRatingSection(),
                  SizedBox(height: 24.h),

                  // 액션 버튼
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildTesterInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, size: 24.sp, color: AppColors.primary),
                SizedBox(width: 8.w),
                Text(
                  '테스터 정보',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text('이름: ${widget.mission.testerName}', style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 4.h),
            Text('이메일: ${widget.mission.testerEmail}', style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 4.h),
            if (_submittedAt != null)
              Text(
                '제출 시간: ${_submittedAt!.year}-${_submittedAt!.month.toString().padLeft(2, '0')}-${_submittedAt!.day.toString().padLeft(2, '0')} ${_submittedAt!.hour.toString().padLeft(2, '0')}:${_submittedAt!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.comment, size: 24.sp, color: Colors.blue),
                SizedBox(width: 8.w),
                Text(
                  '테스트 소감',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              _testerFeedback.isEmpty ? '(작성된 소감 없음)' : _testerFeedback,
              style: TextStyle(fontSize: 14.sp, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBugReportSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, size: 24.sp, color: Colors.red),
                SizedBox(width: 8.w),
                Text(
                  '버그 리포트',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(_bugReport, style: TextStyle(fontSize: 14.sp, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionAnswersSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.question_answer, size: 24.sp, color: Colors.orange),
                SizedBox(width: 8.w),
                Text(
                  '사전 질문 답변',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ..._questionAnswers.entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q: ${entry.key}',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'A: ${entry.value}',
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenshotsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, size: 24.sp, color: Colors.green),
                SizedBox(width: 8.w),
                Text(
                  '스크린샷 (${_screenshots.length}장)',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (_screenshots.isEmpty)
              Text('(업로드된 스크린샷 없음)', style: TextStyle(fontSize: 14.sp, color: Colors.grey))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8.w,
                  mainAxisSpacing: 8.h,
                ),
                itemCount: _screenshots.length,
                itemBuilder: (context, index) {
                  final imageUrl = _screenshots[index];
                  debugPrint('🖼️ Loading screenshot $index: $imageUrl');

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ Image load error for $imageUrl: $error');
                        return Container(
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 24.sp),
                              SizedBox(height: 4.h),
                              Text(
                                'Load Failed',
                                style: TextStyle(fontSize: 10.sp, color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderFeedbackSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, size: 24.sp, color: AppColors.primary),
                SizedBox(width: 8.w),
                Text(
                  '피드백 / 거절 사유',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '승인 시: 테스터에게 전달할 피드백 (선택)\n거절 시: 거절 사유 (필수)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, size: 24.sp, color: Colors.amber),
                SizedBox(width: 8.w),
                Text(
                  '별점 평가 (승인 시에만 적용)',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32.sp,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = star;
                    });
                  },
                );
              }),
            ),
            Center(
              child: Text(
                '$_rating / 5',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _rejectMission,
            icon: Icon(Icons.close, size: 20.sp),
            label: Text('거절', style: TextStyle(fontSize: 16.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _approveMission,
            icon: Icon(Icons.check, size: 20.sp),
            label: Text('승인', style: TextStyle(fontSize: 16.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
      ],
    );
  }
}
