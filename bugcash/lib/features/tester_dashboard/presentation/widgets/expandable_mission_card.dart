import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tester_dashboard_provider.dart';
import '../../../../services/test_session_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/mission_model.dart' show MissionType, MissionDifficulty;

class ExpandableMissionCard extends ConsumerStatefulWidget {
  final MissionCard mission;
  final String testerId;

  const ExpandableMissionCard({
    super.key,
    required this.mission,
    required this.testerId,
  });

  @override
  ConsumerState<ExpandableMissionCard> createState() => _ExpandableMissionCardState();
}

class _ExpandableMissionCardState extends ConsumerState<ExpandableMissionCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isApplying = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Future<void> _applyForMission() async {
    if (_isApplying) return;

    setState(() {
      _isApplying = true;
    });

    try {
      final testSessionService = ref.read(testSessionServiceProvider);

      // Create test session with pending status
      await testSessionService.createTestSession(
        missionId: widget.mission.id,
        testerId: widget.testerId,
        providerId: widget.mission.providerId ?? 'unknown',
        appId: widget.mission.appName,
        totalRewardPoints: widget.mission.rewardPoints,
      );

      if (mounted) {
        // Show success dialog
        await _showApplicationSuccessDialog();

        // Close expansion after successful application
        setState(() {
          _isExpanded = false;
        });
        _animationController.reverse();
      }
    } catch (e) {
      AppLogger.error('Failed to apply for mission', 'ExpandableMissionCard', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신청 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  Future<void> _showApplicationSuccessDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24.w),
              SizedBox(width: 8.w),
              const Text('신청 완료'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('미션 신청이 완료되었습니다!'),
              SizedBox(height: 8.h),
              Text(
                '공급자의 승인을 기다린 후 14일간의 테스트를 시작할 수 있습니다.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // Main card content
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          mission.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${mission.rewardPoints}P',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // Description
                  Text(
                    mission.description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                    ),
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 12.h),

                  // Info row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                        Icons.people,
                        '${mission.currentParticipants}/${mission.maxParticipants}',
                        '참여자',
                      ),
                      _buildInfoItem(
                        Icons.schedule,
                        '${mission.deadline != null ? mission.deadline!.difference(DateTime.now()).inDays : 7}일',
                        '남은 기간',
                      ),
                      _buildInfoItem(
                        Icons.calendar_today,
                        '14일',
                        '테스트 기간',
                      ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // Expand/Collapse indicator
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
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16.w,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
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

                  // Mission details
                  _buildDetailSection('📱 앱 정보', [
                    _buildDetailItem('앱 이름', mission.appName),
                    _buildDetailItem('카테고리', _getMissionTypeText(mission.type)),
                    _buildDetailItem('테스트 유형', '기능 테스트'),
                  ]),

                  SizedBox(height: 16.h),

                  _buildDetailSection('📋 테스트 요구사항', [
                    _buildDetailItem('난이도', _getDifficultyText(mission.difficulty)),
                    _buildDetailItem('필요 기기', 'Android/iOS'),
                    _buildDetailItem('예상 소요시간', '${(mission.estimatedMinutes / 60).ceil()}시간/일'),
                  ]),

                  SizedBox(height: 16.h),

                  _buildDetailSection('💰 보상 정보', [
                    _buildDetailItem('총 보상', '${mission.rewardPoints} 포인트'),
                    _buildDetailItem('일일 보상', '${(mission.rewardPoints / 14).round()} 포인트'),
                    _buildDetailItem('완료 보너스', '${(mission.rewardPoints * 0.1).round()} 포인트'),
                  ]),

                  SizedBox(height: 24.h),

                  // Application button
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: _isApplying ? null : _applyForMission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: _isApplying
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                const Text('신청 중...'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_arrow, size: 20),
                                SizedBox(width: 8.w),
                                const Text('14일 테스트 신청하기'),
                              ],
                            ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Application info
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16.w, color: Colors.blue),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '신청 후 공급자의 승인을 받으면 14일간의 일일 테스트가 시작됩니다.',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.w, color: Colors.grey[600]),
            SizedBox(width: 4.w),
            Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8.h),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMissionTypeText(MissionType type) {
    switch (type) {
      case MissionType.bugReport:
        return '버그 리포트';
      case MissionType.featureTesting:
        return '기능 테스트';
      case MissionType.usabilityTest:
        return '사용성 테스트';
      case MissionType.performanceTest:
        return '성능 테스트';
      case MissionType.performance:
        return '성능 테스트';
      case MissionType.survey:
        return '설문조사';
      case MissionType.feedback:
        return '피드백 수집';
      case MissionType.functional:
        return '기능 테스트';
      case MissionType.uiUx:
        return 'UI/UX 테스트';
      case MissionType.security:
        return '보안 테스트';
      case MissionType.compatibility:
        return '호환성 테스트';
      case MissionType.accessibility:
        return '접근성 테스트';
      case MissionType.localization:
        return '지역화 테스트';
      default:
        return '기능 테스트';
    }
  }

  String _getDifficultyText(MissionDifficulty difficulty) {
    switch (difficulty) {
      case MissionDifficulty.easy:
        return '쉬움';
      case MissionDifficulty.medium:
        return '보통';
      case MissionDifficulty.hard:
        return '어려움';
      case MissionDifficulty.expert:
        return '전문가';
      default:
        return '보통';
    }
  }

}