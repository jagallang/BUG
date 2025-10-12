import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/mission_workflow_service.dart';
import '../../../../features/shared/models/mission_workflow_model.dart';
import 'daily_mission_submission_page.dart';

/// 미션 진행 상황 추적 페이지
/// 테스터가 현재 진행 중인 미션의 전체 일정과 진행률을 확인
class MissionTrackingPage extends ConsumerStatefulWidget {
  final String workflowId;
  final String appId; // v2.9.0: 공급자 질문 로드용

  const MissionTrackingPage({
    super.key,
    required this.workflowId,
    required this.appId,
  });

  @override
  ConsumerState<MissionTrackingPage> createState() => _MissionTrackingPageState();
}

class _MissionTrackingPageState extends ConsumerState<MissionTrackingPage> {
  late Stream<MissionWorkflowModel> _workflowStream;

  @override
  void initState() {
    super.initState();
    // v2.11.2: Firestore 실시간 스트림 (snapshots 사용)
    _workflowStream = ref
        .read(missionWorkflowServiceProvider)
        .watchMissionWorkflow(widget.workflowId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('미션 진행 현황'),
        elevation: 0,
      ),
      body: StreamBuilder<MissionWorkflowModel>(
        stream: _workflowStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.w, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text('데이터 로드 실패: ${snapshot.error}'),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final workflow = snapshot.data!;
          return _buildContent(workflow);
        },
      ),
    );
  }

  Widget _buildContent(MissionWorkflowModel workflow) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 미션 개요 카드
          _buildOverviewCard(workflow),
          SizedBox(height: 24.h),

          // 일일 미션 타임라인
          _buildTimelineSection(workflow),
        ],
      ),
    );
  }

  /// 미션 개요 카드
  Widget _buildOverviewCard(MissionWorkflowModel workflow) {
    final completedDays = workflow.dailyInteractions
        .where((i) => i.testerCompleted)
        .length;
    final progress = workflow.totalDays > 0
        ? (completedDays / workflow.totalDays * 100)
        : 0.0;

    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 앱 이름
            Text(
              workflow.appName,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),

            // 기간 정보
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16.w, color: Colors.grey[600]),
                SizedBox(width: 8.w),
                Text(
                  '${DateFormat('yyyy-MM-dd').format(workflow.appliedAt)} ~ ${workflow.totalDays}일',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // 진행률 바
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '진행률',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$completedDays / ${workflow.totalDays} 일 (${progress.toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 8.h,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // 보상 정보
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.orange, size: 24.w),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '획득 보상',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,###').format(workflow.totalEarnedReward)}원',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '일당 ${NumberFormat('#,###').format(workflow.dailyReward)}원',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
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

  /// 일일 미션 타임라인 섹션
  Widget _buildTimelineSection(MissionWorkflowModel workflow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '일일 미션 타임라인',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),

        // 타임라인 아이템들
        ...List.generate(workflow.totalDays, (index) {
          final dayNumber = index + 1;
          final interaction = workflow.dailyInteractions.firstWhere(
            (i) => i.dayNumber == dayNumber,
            orElse: () => DailyMissionInteraction(
              id: '',
              missionId: workflow.id,
              testerId: workflow.testerId,
              providerId: workflow.providerId,
              dayNumber: dayNumber,
              date: DateTime.now().add(Duration(days: index)),
              dailyReward: workflow.dailyReward,
            ),
          );

          return _buildTimelineItem(
            workflow: workflow,
            dayNumber: dayNumber,
            interaction: interaction,
            isLast: index == workflow.totalDays - 1,
          );
        }),
      ],
    );
  }

  /// v2.12.0: 타임라인 개별 아이템 (날짜별 활성화 로직 적용)
  Widget _buildTimelineItem({
    required MissionWorkflowModel workflow,
    required int dayNumber,
    required DailyMissionInteraction interaction,
    required bool isLast,
  }) {
    // v2.12.0: 새로운 상태 판단 로직
    final dayStatus = workflow.getDayStatus(dayNumber);

    // 상태별 UI 설정
    Color statusColor;
    IconData statusIcon;
    String statusText;
    bool canSubmit = false;

    switch (dayStatus) {
      case DayStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = '승인됨';
        canSubmit = false;
        break;
      case DayStatus.submitted:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = '검토 대기';
        canSubmit = false;
        break;
      case DayStatus.unlocked:
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle_outlined;
        statusText = '제출 가능';
        canSubmit = true;
        break;
      case DayStatus.locked:
        statusColor = Colors.grey;
        statusIcon = Icons.lock_outline;
        statusText = '잠김';
        canSubmit = false;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임라인 라인
          Column(
            children: [
              Icon(statusIcon, color: statusColor, size: 32.w),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.w,
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),

          // 컨텐츠 카드
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day 번호 + 상태
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Day $dayNumber',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // v2.12.0: 잠김 상태 안내
                      if (dayStatus == DayStatus.locked) ...[
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16.w,
                                color: Colors.grey[600]),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                '이전 미션을 완료하고 승인받으세요',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // 제출 정보 (완료된 경우만)
                      if (interaction.testerCompleted) ...[
                        SizedBox(height: 12.h),
                        Text(
                          '제출일: ${DateFormat('yyyy-MM-dd HH:mm').format(interaction.testerCompletedAt!)}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (interaction.testerFeedback != null) ...[
                          SizedBox(height: 8.h),
                          Text(
                            '피드백:',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            interaction.testerFeedback!,
                            style: TextStyle(fontSize: 14.sp),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (interaction.testerScreenshots.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          Text(
                            '스크린샷: ${interaction.testerScreenshots.length}장',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],

                      // v2.12.0: 승인 정보 (승인된 경우)
                      if (interaction.providerApproved) ...[
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green,
                                  size: 20.w),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '승인됨',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    if (interaction.providerApprovedAt != null)
                                      Text(
                                        DateFormat('yyyy-MM-dd HH:mm')
                                            .format(interaction.providerApprovedAt!),
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (interaction.providerRating != null)
                                Row(
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.amber,
                                        size: 16.w),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '${interaction.providerRating}/5',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],

                      // v2.12.0: 액션 버튼 (canSubmit 기반)
                      if (canSubmit) ...[
                        SizedBox(height: 12.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToSubmission(dayNumber, workflow.appName),
                            icon: const Icon(Icons.upload),
                            label: const Text('미션 제출하기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 제출 페이지로 이동
  void _navigateToSubmission(int dayNumber, String missionTitle) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyMissionSubmissionPage(
          workflowId: widget.workflowId,
          dayNumber: dayNumber,
          missionTitle: missionTitle,
          appId: widget.appId, // v2.9.0
        ),
      ),
    );

    // v2.11.2: 실시간 스트림이 자동으로 Firestore 변경사항을 감지하므로
    // 수동 새로고침 로직 불필요 (watchMissionWorkflow 사용)
  }
}
