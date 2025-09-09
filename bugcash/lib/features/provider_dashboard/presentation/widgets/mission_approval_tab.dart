import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum MissionSubmissionStatus {
  submitted,          // 제출됨
  approved,           // 승인됨  
  rejected,           // 거부됨
  pending,            // 승인 대기
  needsRevision,      // 보완 요청
  resubmitted,        // 재제출됨
}

class SubmittedMission {
  final String id;
  final String missionTitle;
  final String testerName;
  final String testerId;
  final String appName;
  final DateTime submissionTime;
  final List<MissionScreenshotData> screenshots;
  final String? notes;
  MissionSubmissionStatus status;
  final int rewardPoints;
  String? rejectionReason;        // 거부 이유
  String? revisionRequest;        // 보완 요청사항
  DateTime? rejectionTime;        // 거부/보완요청 시간
  DateTime? resubmissionTime;     // 재제출 시간
  
  SubmittedMission({
    required this.id,
    required this.missionTitle,
    required this.testerName,
    required this.testerId,
    required this.appName,
    required this.submissionTime,
    required this.screenshots,
    this.notes,
    this.status = MissionSubmissionStatus.submitted,
    required this.rewardPoints,
    this.rejectionReason,
    this.revisionRequest,
    this.rejectionTime,
    this.resubmissionTime,
  });
}

class MissionScreenshotData {
  final String id;
  final String type; // 'start', 'middle', 'end'
  final DateTime timestamp;
  final String? imagePath;
  
  MissionScreenshotData({
    required this.id,
    required this.type,
    required this.timestamp,
    this.imagePath,
  });
}

class MissionApprovalTab extends StatefulWidget {
  final String providerId;
  
  const MissionApprovalTab({
    super.key,
    required this.providerId,
  });

  @override
  State<MissionApprovalTab> createState() => _MissionApprovalTabState();
}

class _MissionApprovalTabState extends State<MissionApprovalTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SubmittedMission> _allMissions = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeMockData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _initializeMockData() {
    _allMissions = [
      SubmittedMission(
        id: 'mission_1',
        missionTitle: '채팅앱 알림 기능 테스트',
        testerName: '김테스터',
        testerId: 'tester_001',
        appName: '채팅메신저 앱',
        submissionTime: DateTime.now().subtract(const Duration(hours: 2)),
        screenshots: [
          MissionScreenshotData(
            id: 'shot_1',
            type: 'start',
            timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
          ),
          MissionScreenshotData(
            id: 'shot_2',
            type: 'middle',
            timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 8)),
          ),
          MissionScreenshotData(
            id: 'shot_3',
            type: 'end',
            timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 1)),
          ),
        ],
        notes: '푸시 알림이 제대로 동작하며, 메시지 읽음 표시도 정상적으로 업데이트됩니다.',
        status: MissionSubmissionStatus.submitted,
        rewardPoints: 5000,
      ),
      SubmittedMission(
        id: 'mission_2',
        missionTitle: '게임 앱 성능 테스트',
        testerName: '박테스터',
        testerId: 'tester_002',
        appName: '모바일 게임 앱',
        submissionTime: DateTime.now().subtract(const Duration(hours: 4)),
        screenshots: [
          MissionScreenshotData(
            id: 'shot_4',
            type: 'start',
            timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 12)),
          ),
          MissionScreenshotData(
            id: 'shot_5',
            type: 'middle',
            timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 6)),
          ),
          MissionScreenshotData(
            id: 'shot_6',
            type: 'end',
            timestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 1)),
          ),
        ],
        status: MissionSubmissionStatus.approved,
        rewardPoints: 7000,
      ),
      SubmittedMission(
        id: 'mission_3',
        missionTitle: '쇼핑앱 결제 플로우 테스트',
        testerName: '이테스터',
        testerId: 'tester_003',
        appName: '온라인 쇼핑몰',
        submissionTime: DateTime.now().subtract(const Duration(minutes: 30)),
        screenshots: [
          MissionScreenshotData(
            id: 'shot_7',
            type: 'start',
            timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
          ),
          MissionScreenshotData(
            id: 'shot_8',
            type: 'middle',
            timestamp: DateTime.now().subtract(const Duration(minutes: 38)),
          ),
          MissionScreenshotData(
            id: 'shot_9',
            type: 'end',
            timestamp: DateTime.now().subtract(const Duration(minutes: 31)),
          ),
        ],
        notes: '결제 과정에서 로딩이 다소 오래 걸리는 부분이 있었습니다.',
        status: MissionSubmissionStatus.submitted,
        rewardPoints: 6000,
      ),
      SubmittedMission(
        id: 'mission_4',
        missionTitle: '소셜미디어 앱 공유 기능 테스트',
        testerName: '최테스터',
        testerId: 'tester_004',
        appName: '소셜미디어 앱',
        submissionTime: DateTime.now().subtract(const Duration(hours: 6)),
        screenshots: [
          MissionScreenshotData(
            id: 'shot_10',
            type: 'start',
            timestamp: DateTime.now().subtract(const Duration(hours: 6, minutes: 12)),
          ),
          MissionScreenshotData(
            id: 'shot_11',
            type: 'middle',
            timestamp: DateTime.now().subtract(const Duration(hours: 6, minutes: 6)),
          ),
          MissionScreenshotData(
            id: 'shot_12',
            type: 'end',
            timestamp: DateTime.now().subtract(const Duration(hours: 6, minutes: 1)),
          ),
        ],
        notes: '공유 기능이 동작하지만 이미지 업로드 속도가 느립니다.',
        status: MissionSubmissionStatus.needsRevision,
        rewardPoints: 4000,
        rejectionReason: '스크린샷 품질 부족',
        revisionRequest: '스크린샷이 흐릿하고 텍스트가 잘 보이지 않습니다. 더 선명한 스크린샷을 다시 촬영해 주세요. 특히 공유 기능 사용 과정을 단계별로 명확하게 보여주시기 바랍니다.',
        rejectionTime: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
  }
  
  List<SubmittedMission> _getMissionsByStatus(MissionSubmissionStatus status) {
    return _allMissions.where((mission) => mission.status == status).toList();
  }
  
  void _handleMissionApproval(SubmittedMission mission, bool approved) {
    if (approved) {
      setState(() {
        mission.status = MissionSubmissionStatus.approved;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${mission.testerName}님의 미션이 승인되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showRejectionDialog(mission);
    }
  }
  
  void _showRejectionDialog(SubmittedMission mission) {
    final rejectionReasonController = TextEditingController();
    final revisionRequestController = TextEditingController();
    bool isRevisionRequest = true; // 기본값을 보완요청으로 설정
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('미션 검토 결과'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${mission.testerName}님의 "${mission.missionTitle}" 미션',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.h),
                
                // 처리 유형 선택
                Text('처리 유형', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: Text('보완 요청'),
                        subtitle: Text('수정 후 재제출 가능'),
                        value: true,
                        groupValue: isRevisionRequest,
                        onChanged: (value) {
                          setDialogState(() {
                            isRevisionRequest = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: Text('완전 거부'),
                        subtitle: Text('재제출 불가'),
                        value: false,
                        groupValue: isRevisionRequest,
                        onChanged: (value) {
                          setDialogState(() {
                            isRevisionRequest = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                // 거부 이유 입력
                Text('거부 이유', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8.h),
                TextField(
                  controller: rejectionReasonController,
                  decoration: InputDecoration(
                    hintText: '거부하는 이유를 간단히 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                
                SizedBox(height: 16.h),
                
                // 보완 요청사항 입력 (보완요청인 경우에만)
                if (isRevisionRequest) ...[
                  Text('보완 요청사항', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: revisionRequestController,
                    decoration: InputDecoration(
                      hintText: '어떤 부분을 어떻게 보완해야 하는지 상세히 설명해주세요',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                if (rejectionReasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('거부 이유를 입력해주세요.')),
                  );
                  return;
                }
                
                if (isRevisionRequest && revisionRequestController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('보완 요청사항을 입력해주세요.')),
                  );
                  return;
                }
                
                setState(() {
                  mission.status = isRevisionRequest 
                    ? MissionSubmissionStatus.needsRevision 
                    : MissionSubmissionStatus.rejected;
                  mission.rejectionReason = rejectionReasonController.text;
                  mission.revisionRequest = isRevisionRequest 
                    ? revisionRequestController.text 
                    : null;
                  mission.rejectionTime = DateTime.now();
                });
                
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isRevisionRequest 
                        ? '${mission.testerName}님에게 보완요청을 보냈습니다.'
                        : '${mission.testerName}님의 미션을 거부했습니다.',
                    ),
                    backgroundColor: isRevisionRequest ? Colors.orange : Colors.red,
                  ),
                );
              },
              child: Text(isRevisionRequest ? '보완요청' : '거부하기'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final submittedMissions = _getMissionsByStatus(MissionSubmissionStatus.submitted)
      ..addAll(_getMissionsByStatus(MissionSubmissionStatus.resubmitted));
    final revisionMissions = _getMissionsByStatus(MissionSubmissionStatus.needsRevision);
    final approvedMissions = _getMissionsByStatus(MissionSubmissionStatus.approved);
    final rejectedMissions = _getMissionsByStatus(MissionSubmissionStatus.rejected);
    
    return Column(
      children: [
        Container(
          color: Colors.grey[100],
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            isScrollable: true,
            tabs: [
              Tab(
                text: '승인 대기 (${submittedMissions.length})',
                icon: const Icon(Icons.pending_actions),
              ),
              Tab(
                text: '보완요청 (${revisionMissions.length})',
                icon: const Icon(Icons.edit_note),
              ),
              Tab(
                text: '승인 완료 (${approvedMissions.length})',
                icon: const Icon(Icons.check_circle),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMissionList(submittedMissions, showApprovalButtons: true),
              _buildMissionList(revisionMissions, showRevisionInfo: true),
              _buildMissionList(approvedMissions),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMissionList(List<SubmittedMission> missions, {bool showApprovalButtons = false, bool showRevisionInfo = false}) {
    if (missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48.w,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              '미션이 없습니다',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: missions.length,
      itemBuilder: (context, index) {
        final mission = missions[index];
        return _buildMissionCard(mission, showApprovalButtons: showApprovalButtons, showRevisionInfo: showRevisionInfo);
      },
    );
  }
  
  Widget _buildMissionCard(SubmittedMission mission, {bool showApprovalButtons = false, bool showRevisionInfo = false}) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with mission title and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    mission.missionTitle,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(mission.status),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    _getStatusText(mission.status),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // Tester and app info
            Row(
              children: [
                Icon(Icons.person, size: 16.w, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  mission.testerName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(width: 16.w),
                Icon(Icons.apps, size: 16.w, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  mission.appName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8.h),
            
            // Submission time and reward
            Row(
              children: [
                Icon(Icons.access_time, size: 16.w, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  '제출: ${_formatDateTime(mission.submissionTime)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
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
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // Screenshots section
            Text(
              '스크린샷 (${mission.screenshots.length}개)',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: mission.screenshots.map((screenshot) {
                return Container(
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.image,
                        size: 24.w,
                        color: Colors.grey[600],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _getScreenshotTypeText(screenshot.type),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            
            // Notes if available
            if (mission.notes != null) ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '테스터 피드백',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      mission.notes!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Revision request information
            if (showRevisionInfo && mission.rejectionReason != null) ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700, size: 16.w),
                        SizedBox(width: 8.w),
                        Text(
                          '거부 이유',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          mission.rejectionTime != null ? _formatDateTime(mission.rejectionTime!) : '',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      mission.rejectionReason!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (showRevisionInfo && mission.revisionRequest != null) ...[
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, color: Colors.orange.shade700, size: 16.w),
                        SizedBox(width: 8.w),
                        Text(
                          '보완 요청사항',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      mission.revisionRequest!,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Approval buttons for submitted missions
            if (showApprovalButtons) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleMissionApproval(mission, false),
                      icon: const Icon(Icons.close),
                      label: const Text('거부'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleMissionApproval(mission, true),
                      icon: const Icon(Icons.check),
                      label: const Text('승인'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(MissionSubmissionStatus status) {
    switch (status) {
      case MissionSubmissionStatus.submitted:
        return Colors.orange;
      case MissionSubmissionStatus.approved:
        return Colors.green;
      case MissionSubmissionStatus.rejected:
        return Colors.red;
      case MissionSubmissionStatus.pending:
        return Colors.blue;
      case MissionSubmissionStatus.needsRevision:
        return Colors.orange;
      case MissionSubmissionStatus.resubmitted:
        return Colors.purple;
    }
  }
  
  String _getStatusText(MissionSubmissionStatus status) {
    switch (status) {
      case MissionSubmissionStatus.submitted:
        return '승인 대기';
      case MissionSubmissionStatus.approved:
        return '승인 완료';
      case MissionSubmissionStatus.rejected:
        return '거부됨';
      case MissionSubmissionStatus.pending:
        return '처리 중';
      case MissionSubmissionStatus.needsRevision:
        return '보완 요청';
      case MissionSubmissionStatus.resubmitted:
        return '재제출됨';
    }
  }
  
  String _getScreenshotTypeText(String type) {
    switch (type) {
      case 'start':
        return '시작';
      case 'middle':
        return '중간';
      case 'end':
        return '종료';
      default:
        return type;
    }
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