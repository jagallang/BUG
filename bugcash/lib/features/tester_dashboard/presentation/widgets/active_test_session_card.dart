import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../models/test_session_model.dart';
import '../../../../services/test_session_service.dart';
import '../../../../core/utils/logger.dart';

class ActiveTestSessionCard extends ConsumerStatefulWidget {
  final TestSession session;

  const ActiveTestSessionCard({
    super.key,
    required this.session,
  });

  @override
  ConsumerState<ActiveTestSessionCard> createState() => _ActiveTestSessionCardState();
}

class _ActiveTestSessionCardState extends ConsumerState<ActiveTestSessionCard> {
  bool _isExpanded = false;
  bool _isSubmitting = false;
  final TextEditingController _feedbackController = TextEditingController();
  final List<File> _screenshots = [];
  int _testDurationMinutes = 30; // Default from session metadata

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize test duration from session metadata
    _testDurationMinutes = _getDefaultTestTime();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    setState(() {
      _screenshots.addAll(pickedFiles.map((xFile) => File(xFile.path)));
    });
    }

  Future<void> _submitDailyTest() async {
    if (_isSubmitting) return;

    final todayTest = widget.session.todayTest;
    if (todayTest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘 테스트할 항목이 없습니다')),
      );
      return;
    }

    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('피드백을 입력해주세요')),
      );
      return;
    }

    if (_screenshots.isEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('스크린샷 없음'),
          content: const Text('스크린샷 없이 제출하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('제출'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final testSessionService = ref.read(testSessionServiceProvider);

      // Upload screenshots if any
      final List<String> screenshotUrls = [];
      // In a real implementation, you would upload files to Firebase Storage
      // For now, we'll use local file paths
      for (final screenshot in _screenshots) {
        screenshotUrls.add(screenshot.path);
      }

      await testSessionService.submitDailyTest(
        sessionId: widget.session.id,
        day: todayTest.day,
        feedbackFromTester: _feedbackController.text.trim(),
        screenshots: screenshotUrls,
        testDurationMinutes: _testDurationMinutes,
        additionalData: {
          'submittedAt': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${todayTest.day}일차 테스트가 제출되었습니다'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        _feedbackController.clear();
        _screenshots.clear();
        setState(() {
          _isExpanded = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to submit daily test', 'ActiveTestSessionCard', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('제출 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final todayTest = session.todayTest;
    final isWaitingForApproval = todayTest?.status == DailyTestStatus.submitted;
    final canSubmitToday = todayTest?.status == DailyTestStatus.pending;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // Main card content
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.play_circle,
                          color: Colors.blue.shade700,
                          size: 24.w,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.appId,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_getTestPeriod()}일 테스트 (${session.completedDays}/${_getTestPeriod()}일 완료)',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(session.status),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Progress bar
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '진행률',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${(session.progressPercentage * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      LinearProgressIndicator(
                        value: session.progressPercentage,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Today's test info
                  if (todayTest != null) ...[
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: _getTodayTestColor(todayTest.status),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getTodayTestIcon(todayTest.status),
                            size: 16.w,
                            color: _getTodayTestIconColor(todayTest.status),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              _getTodayTestText(todayTest),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: _getTodayTestTextColor(todayTest.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 8.h),

                  // Expand indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isExpanded ? '접기' : '자세히 보기',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16.w,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_isExpanded) ...[
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12.r),
                  bottomRight: Radius.circular(12.r),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.grey[300], height: 1),
                  SizedBox(height: 16.h),

                  // Daily test submission form
                  if (canSubmitToday) ...[
                    Text(
                      '${todayTest!.day}일차 테스트 제출',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Feedback input
                    TextField(
                      controller: _feedbackController,
                      decoration: InputDecoration(
                        labelText: '테스트 결과 및 피드백',
                        hintText: '앱 사용 경험, 발견한 문제점, 개선사항 등을 적어주세요',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        contentPadding: EdgeInsets.all(12.w),
                      ),
                      maxLines: 4,
                    ),

                    SizedBox(height: 16.h),

                    // Test duration selector
                    Row(
                      children: [
                        Text(
                          '테스트 소요 시간:',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Slider(
                            value: _testDurationMinutes.toDouble(),
                            min: _getMinTestTime().toDouble(),
                            max: _getMaxTestTime().toDouble(),
                            divisions: _getTestTimeDivisions(),
                            label: '$_testDurationMinutes${_getTimeUnit()}',
                            onChanged: (value) {
                              setState(() {
                                _testDurationMinutes = value.round();
                              });
                            },
                          ),
                        ),
                        Text(
                          '$_testDurationMinutes${_getTimeUnit()}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // Screenshot section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '스크린샷 (${_screenshots.length}개)',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate, size: 16),
                          label: const Text('추가'),
                        ),
                      ],
                    ),

                    if (_screenshots.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      SizedBox(
                        height: 80.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _screenshots.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.only(right: 8.w),
                              width: 80.w,
                              height: 80.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Image.file(
                                      _screenshots[index],
                                      width: 80.w,
                                      height: 80.h,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 2.w,
                                    right: 2.w,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _screenshots.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        width: 20.w,
                                        height: 20.w,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 12.w,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    SizedBox(height: 24.h),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitDailyTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: _isSubmitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('제출 중...'),
                                ],
                              )
                            : Text(_getSubmitButtonText()),
                      ),
                    ),
                  ] else if (isWaitingForApproval) ...[
                    // Waiting for approval state
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 48.w,
                            color: Colors.orange,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '${todayTest!.day}일차 테스트 승인 대기 중',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _getApprovalWaitingMessage(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Other states
                    Center(
                      child: Text(
                        _getNoTestAvailableMessage(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(TestSessionStatus status) {
    Color color;
    String text;

    switch (status) {
      case TestSessionStatus.active:
        color = Colors.green;
        text = '진행 중';
        break;
      case TestSessionStatus.approved:
        color = Colors.blue;
        text = '승인됨';
        break;
      case TestSessionStatus.pending:
        color = Colors.orange;
        text = '대기 중';
        break;
      case TestSessionStatus.completed:
        color = Colors.purple;
        text = '완료';
        break;
      case TestSessionStatus.paused:
        color = Colors.amber;
        text = '일시정지';
        break;
      default:
        color = Colors.grey;
        text = '알 수 없음';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getTodayTestColor(DailyTestStatus status) {
    switch (status) {
      case DailyTestStatus.pending:
        return Colors.blue.shade50;
      case DailyTestStatus.submitted:
        return Colors.orange.shade50;
      case DailyTestStatus.approved:
        return Colors.green.shade50;
      case DailyTestStatus.rejected:
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getTodayTestIconColor(DailyTestStatus status) {
    switch (status) {
      case DailyTestStatus.pending:
        return Colors.blue;
      case DailyTestStatus.submitted:
        return Colors.orange;
      case DailyTestStatus.approved:
        return Colors.green;
      case DailyTestStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTodayTestTextColor(DailyTestStatus status) {
    switch (status) {
      case DailyTestStatus.pending:
        return Colors.blue.shade700;
      case DailyTestStatus.submitted:
        return Colors.orange.shade700;
      case DailyTestStatus.approved:
        return Colors.green.shade700;
      case DailyTestStatus.rejected:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getTodayTestIcon(DailyTestStatus status) {
    switch (status) {
      case DailyTestStatus.pending:
        return Icons.assignment;
      case DailyTestStatus.submitted:
        return Icons.hourglass_empty;
      case DailyTestStatus.approved:
        return Icons.check_circle;
      case DailyTestStatus.rejected:
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  String _getTodayTestText(DailyTestProgress todayTest) {
    switch (todayTest.status) {
      case DailyTestStatus.pending:
        return '${todayTest.day}일차 테스트를 진행하고 결과를 제출해주세요';
      case DailyTestStatus.submitted:
        return '${todayTest.day}일차 테스트 제출 완료 - 승인 대기 중';
      case DailyTestStatus.approved:
        return '${todayTest.day}일차 테스트 승인 완료';
      case DailyTestStatus.rejected:
        return '${todayTest.day}일차 테스트 재제출 필요';
      default:
        return '${todayTest.day}일차 테스트 상태를 확인할 수 없습니다';
    }
  }

  // 동적 데이터 메서드들
  int _getTestPeriod() {
    // 세션 메타데이터에서 테스트 기간 가져오기
    return widget.session.sessionMetadata['testPeriod'] as int? ?? 14;
  }

  int _getDefaultTestTime() {
    // 세션 메타데이터에서 기본 테스트 시간 가져오기
    return widget.session.sessionMetadata['defaultTestTime'] as int? ?? 30;
  }

  int _getMinTestTime() {
    // 세션 메타데이터에서 최소 테스트 시간 가져오기
    return widget.session.sessionMetadata['minTestTime'] as int? ?? 10;
  }

  int _getMaxTestTime() {
    // 세션 메타데이터에서 최대 테스트 시간 가져오기
    return widget.session.sessionMetadata['maxTestTime'] as int? ?? 120;
  }

  int _getTestTimeDivisions() {
    // 세션 메타데이터에서 슬라이더 구간 수 가져오기
    final min = _getMinTestTime();
    final max = _getMaxTestTime();
    return widget.session.sessionMetadata['testTimeDivisions'] as int? ??
           ((max - min) / 10).round();
  }

  String _getTimeUnit() {
    // 세션 메타데이터에서 시간 단위 가져오기
    return widget.session.sessionMetadata['timeUnit'] as String? ?? '분';
  }

  String _getSubmitButtonText() {
    // 세션 메타데이터에서 제출 버튼 텍스트 가져오기
    return widget.session.sessionMetadata['submitButtonText'] as String? ??
           '오늘의 테스트 제출하기';
  }

  String _getApprovalWaitingMessage() {
    // 세션 메타데이터에서 승인 대기 메시지 가져오기
    return widget.session.sessionMetadata['approvalWaitingMessage'] as String? ??
           '공급자가 검토 후 승인해드립니다';
  }

  String _getNoTestAvailableMessage() {
    // 세션 메타데이터에서 빈 상태 메시지 가져오기
    return widget.session.sessionMetadata['noTestAvailableMessage'] as String? ??
           '현재 제출 가능한 테스트가 없습니다';
  }
}