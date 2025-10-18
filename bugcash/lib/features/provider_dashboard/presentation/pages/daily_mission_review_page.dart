import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/mission_workflow_service.dart';
import '../../../../features/mission/domain/entities/mission_workflow_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

  /// v2.131.0: projects에서 최종 완료 포인트 조회 (rewards/metadata에서 조회)
  Future<int> _loadFinalCompletionPoints() async {
    try {
      final normalizedAppId = widget.mission.appId.replaceAll('provider_app_', '');
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(normalizedAppId)
          .get();

      if (!doc.exists) {
        debugPrint('Project not found: $normalizedAppId');
        return 10000;
      }

      final data = doc.data()!;
      final rewards = data['rewards'] as Map<String, dynamic>?;
      final metadata = data['metadata'] as Map<String, dynamic>?;

      // rewards.finalCompletionPoints 우선, metadata.finalCompletionPoints 폴백
      final finalPoints = rewards?['finalCompletionPoints'] as int? ??
                         metadata?['finalCompletionPoints'] as int? ??
                         10000;

      debugPrint('✅ Loaded finalCompletionPoints: $finalPoints from project $normalizedAppId');
      return finalPoints;
    } catch (e) {
      debugPrint('❌ Failed to load finalCompletionPoints: $e');
      return 10000; // 기본값
    }
  }

  /// v2.131.0: 승인 처리 (최종 Day인 경우 에스크로 포인트 지급 모달 추가)
  Future<void> _approveMission() async {
    final isFinalDay = widget.dayNumber >= widget.mission.totalDays;

    // 최종 Day인 경우 포인트 정보 먼저 로드
    int? finalPoints;
    if (isFinalDay) {
      finalPoints = await _loadFinalCompletionPoints();
    }

    // === 1단계: 승인 확인 다이얼로그 ===
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isFinalDay ? Icons.celebration : Icons.check_circle_outline,
              color: isFinalDay ? Colors.orange : Colors.green,
              size: 28.sp
            ),
            SizedBox(width: 8.w),
            Text(
              isFinalDay ? '최종 미션 승인' : '미션 승인 확인',
              style: TextStyle(fontSize: 18.sp)
            ),
          ],
        ),
        content: Text(
          'Day ${widget.dayNumber} 미션을 승인하시겠습니까?\n\n'
          '${isFinalDay
            ? "🎉 마지막 미션입니다!\n승인 후 에스크로 포인트 지급 단계로 이동합니다.\n\n"
            : ""}'
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
              backgroundColor: isFinalDay ? Colors.orange : Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
            child: Text(
              '승인하기',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      // 미션 승인 처리
      final service = ref.read(missionWorkflowServiceProvider);
      await service.approveDailyMission(
        workflowId: widget.mission.id,
        providerId: widget.mission.providerId,
        dayNumber: widget.dayNumber,
        providerFeedback: _feedbackController.text.trim(),
        rating: _rating,
      );

      // === 최종 Day인 경우에만 2단계 포인트 지급 모달 표시 ===
      if (isFinalDay && mounted) {
        setState(() => _isSubmitting = false); // 로딩 해제

        // 2단계: 에스크로 포인트 지급 확인 모달
        final paymentConfirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false, // 백드롭 클릭 불가
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.orange, size: 28.sp),
                SizedBox(width: 8.w),
                Text('에스크로 포인트 지급', style: TextStyle(fontSize: 18.sp)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '에스크로 계정에 보관된 포인트를\n테스터에게 지급합니다.',
                  style: TextStyle(fontSize: 15.sp, height: 1.5),
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('지급 금액:', style: TextStyle(fontSize: 14.sp)),
                          Text(
                            '${NumberFormat('#,###').format(finalPoints)}원',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text('테스터: ${widget.mission.testerName}', style: TextStyle(fontSize: 14.sp)),
                      Text('이메일: ${widget.mission.testerEmail}', style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  '⚠️ 지급 후에는 취소할 수 없습니다.',
                  style: TextStyle(fontSize: 13.sp, color: Colors.red),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('나중에', style: TextStyle(fontSize: 15.sp)),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: Icon(Icons.send, size: 20.sp),
                label: Text('포인트 지급하기', style: TextStyle(fontSize: 15.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                ),
              ),
            ],
          ),
        );

        if (paymentConfirmed == true) {
          // 로딩 표시
          setState(() => _isSubmitting = true);

          try {
            // 포인트 지급 실행
            await service.payFinalRewardOnly(workflowId: widget.mission.id);

            if (mounted) {
              setState(() => _isSubmitting = false);

              // 3단계: 지급 완료 모달
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 28.sp),
                      SizedBox(width: 8.w),
                      Text('포인트 지급 완료!', style: TextStyle(fontSize: 18.sp)),
                    ],
                  ),
                  content: Text(
                    '${NumberFormat('#,###').format(finalPoints)}원이\n${widget.mission.testerName}님에게 지급되었습니다.\n\n'
                    '미션이 최종 완료되었습니다!',
                    style: TextStyle(fontSize: 15.sp, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // 완료 모달 닫기
                        Navigator.pop(context, true); // 검토 페이지 닫기
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      ),
                      child: Text('확인', style: TextStyle(fontSize: 15.sp)),
                    ),
                  ],
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isSubmitting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('포인트 지급 실패: $e'), backgroundColor: Colors.red),
              );
            }
          }
        } else {
          // "나중에" 선택 시
          if (mounted) {
            Navigator.pop(context, true); // 검토 페이지 닫기
          }
        }
      } else {
        // 일반 Day 승인 성공
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ 미션이 승인되었습니다'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
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
              padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 100.h), // v2.130.0: 하단 패딩 추가
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
                ],
              ),
            ),
      // v2.130.0: 승인/거절 버튼을 하단 고정 영역으로 이동
      bottomNavigationBar: _isLoading ? null : SafeArea(
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, -2),
                blurRadius: 4,
              ),
            ],
          ),
          child: _buildActionButtons(),
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

                  return GestureDetector(
                    onTap: () => _showFullScreenImage(context, imageUrl, index),
                    child: ClipRRect(
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

  /// v2.136.0: 전체화면 이미지 보기 및 다운로드 기능
  void _showFullScreenImage(BuildContext context, String imageUrl, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // 전체화면 이미지 (확대/축소 가능)
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: Colors.white, size: 48.sp),
                          SizedBox(height: 16.h),
                          Text(
                            '이미지를 불러올 수 없습니다',
                            style: TextStyle(color: Colors.white, fontSize: 16.sp),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // 상단 바 (닫기 버튼)
            Positioned(
              top: 40.h,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 이미지 번호 표시
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${index + 1} / ${_screenshots.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // 닫기 버튼
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 24.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 바 (다운로드 버튼)
            Positioned(
              bottom: 40.h,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () => _downloadImage(imageUrl, index),
                  icon: Icon(Icons.download, size: 20.sp),
                  label: Text('다운로드', style: TextStyle(fontSize: 16.sp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.providerBluePrimary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// v2.136.0: 이미지 다운로드 기능
  Future<void> _downloadImage(String imageUrl, int index) async {
    try {
      // 로딩 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20.w,
                height: 20.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16.w),
              const Text('이미지 다운로드 중...'),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      // 다운로드 디렉토리 가져오기
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'screenshot_${widget.mission.appId}_day${widget.dayNumber}_${index + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${directory.path}/$fileName';

      // Dio를 사용하여 이미지 다운로드
      final dio = Dio();
      await dio.download(imageUrl, filePath);

      // 성공 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('다운로드 완료'),
                      Text(
                        filePath,
                        style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      debugPrint('✅ Image downloaded: $filePath');
    } catch (e) {
      debugPrint('❌ Image download failed: $e');

      // 실패 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20.sp),
                SizedBox(width: 12.w),
                const Expanded(child: Text('다운로드 실패. 다시 시도해주세요.')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
