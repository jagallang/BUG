import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MissionSubmissionStatus {
  submitted,          // 제출됨
  approved,           // 승인됨  
  rejected,           // 거부됨
  pending,            // 승인 대기
  needsRevision,      // 보완 요청
  resubmitted,        // 재제출됨
}

// Firebase Provider for mission submissions
final missionSubmissionsProvider = StreamProvider.family<List<SubmittedMission>, String>((ref, providerId) {
  return FirebaseFirestore.instance
      .collection('mission_submissions')
      .where('providerId', isEqualTo: providerId)
      .orderBy('submissionTime', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
    final List<SubmittedMission> submissions = [];
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      
      // Get mission details
      final missionDoc = await FirebaseFirestore.instance
          .collection('missions')
          .doc(data['missionId'])
          .get();
      
      // Get tester details
      final testerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(data['testerId'])
          .get();
      
      if (missionDoc.exists && testerDoc.exists) {
        final missionData = missionDoc.data()!;
        final testerData = testerDoc.data()!;
        
        submissions.add(SubmittedMission(
          id: doc.id,
          missionTitle: missionData['title'] ?? 'Unknown Mission',
          testerName: testerData['displayName'] ?? 'Unknown Tester',
          testerId: data['testerId'],
          appName: missionData['appName'] ?? 'Unknown App',
          submissionTime: (data['submissionTime'] as Timestamp).toDate(),
          screenshots: _parseScreenshots(data['screenshots'] ?? []),
          notes: data['notes'],
          status: _parseStatus(data['status'] ?? 'submitted'),
          rewardPoints: data['rewardPoints'] ?? 0,
          rejectionReason: data['rejectionReason'],
          revisionRequest: data['revisionRequest'],
          rejectionTime: (data['rejectionTime'] as Timestamp?)?.toDate(),
          resubmissionTime: (data['resubmissionTime'] as Timestamp?)?.toDate(),
        ));
      }
    }
    
    return submissions;
  });
});

List<MissionScreenshotData> _parseScreenshots(List<dynamic> screenshots) {
  return screenshots.map((screenshot) {
    return MissionScreenshotData(
      id: screenshot['id'] ?? '',
      type: screenshot['type'] ?? 'unknown',
      timestamp: (screenshot['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imagePath: screenshot['imagePath'],
    );
  }).toList();
}

MissionSubmissionStatus _parseStatus(String status) {
  switch (status) {
    case 'approved':
      return MissionSubmissionStatus.approved;
    case 'rejected':
      return MissionSubmissionStatus.rejected;
    case 'pending':
      return MissionSubmissionStatus.pending;
    case 'needsRevision':
      return MissionSubmissionStatus.needsRevision;
    case 'resubmitted':
      return MissionSubmissionStatus.resubmitted;
    default:
      return MissionSubmissionStatus.submitted;
  }
}

String _statusToString(MissionSubmissionStatus status) {
  switch (status) {
    case MissionSubmissionStatus.approved:
      return 'approved';
    case MissionSubmissionStatus.rejected:
      return 'rejected';
    case MissionSubmissionStatus.pending:
      return 'pending';
    case MissionSubmissionStatus.needsRevision:
      return 'needsRevision';
    case MissionSubmissionStatus.resubmitted:
      return 'resubmitted';
    default:
      return 'submitted';
  }
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

class MissionApprovalTab extends ConsumerStatefulWidget {
  final String providerId;
  
  const MissionApprovalTab({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<MissionApprovalTab> createState() => _MissionApprovalTabState();
}

class _MissionApprovalTabState extends ConsumerState<MissionApprovalTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateMissionStatus(String submissionId, MissionSubmissionStatus status, {String? reason}) async {
    try {
      final updateData = {
        'status': _statusToString(status),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (reason != null) {
        if (status == MissionSubmissionStatus.rejected) {
          updateData['rejectionReason'] = reason;
          updateData['rejectionTime'] = FieldValue.serverTimestamp();
        } else if (status == MissionSubmissionStatus.needsRevision) {
          updateData['revisionRequest'] = reason;
          updateData['rejectionTime'] = FieldValue.serverTimestamp();
        }
      }

      await FirebaseFirestore.instance
          .collection('mission_submissions')
          .doc(submissionId)
          .update(updateData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getStatusUpdateMessage(status)),
            backgroundColor: _getStatusColor(status),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('업데이트 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusUpdateMessage(MissionSubmissionStatus status) {
    switch (status) {
      case MissionSubmissionStatus.approved:
        return '미션이 승인되었습니다';
      case MissionSubmissionStatus.rejected:
        return '미션이 거부되었습니다';
      case MissionSubmissionStatus.needsRevision:
        return '보완 요청이 전송되었습니다';
      default:
        return '상태가 업데이트되었습니다';
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionsAsync = ref.watch(missionSubmissionsProvider(widget.providerId));
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: submissionsAsync.when(
              data: (submissions) => _buildTabBarView(submissions),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    SizedBox(height: 16.h),
                    Text(
                      '미션 제출 내역을 불러올 수 없습니다',
                      style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      error.toString(),
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_turned_in, size: 24.w, color: Colors.blue),
          SizedBox(width: 12.w),
          Text(
            '미션 승인 관리',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // TODO: Refresh functionality
              ref.refresh(missionSubmissionsProvider(widget.providerId));
            },
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: '대기 중'),
          Tab(text: '승인됨'),
          Tab(text: '기타'),
        ],
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue,
      ),
    );
  }

  Widget _buildTabBarView(List<SubmittedMission> allSubmissions) {
    final pendingMissions = allSubmissions.where((m) => 
      m.status == MissionSubmissionStatus.submitted || 
      m.status == MissionSubmissionStatus.pending ||
      m.status == MissionSubmissionStatus.resubmitted
    ).toList();
    
    final approvedMissions = allSubmissions.where((m) => 
      m.status == MissionSubmissionStatus.approved
    ).toList();
    
    final otherMissions = allSubmissions.where((m) => 
      m.status == MissionSubmissionStatus.rejected ||
      m.status == MissionSubmissionStatus.needsRevision
    ).toList();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildMissionList(pendingMissions, showActions: true),
        _buildMissionList(approvedMissions, showActions: false),
        _buildMissionList(otherMissions, showActions: true),
      ],
    );
  }

  Widget _buildMissionList(List<SubmittedMission> missions, {bool showActions = true}) {
    if (missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64.w, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              '제출된 미션이 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
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
        return _buildMissionCard(missions[index], showActions: showActions);
      },
    );
  }

  Widget _buildMissionCard(SubmittedMission mission, {bool showActions = true}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.missionTitle,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${mission.testerName} • ${mission.appName}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(mission.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _getStatusText(mission.status),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(mission.status),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Mission info
            Row(
              children: [
                Icon(Icons.schedule, size: 14.w, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  _formatDateTime(mission.submissionTime),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
                SizedBox(width: 16.w),
                Icon(Icons.monetization_on, size: 14.w, color: Colors.orange),
                SizedBox(width: 4.w),
                Text(
                  '${mission.rewardPoints}P',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            if (mission.notes != null && mission.notes!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  mission.notes!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],

            // Screenshots info
            if (mission.screenshots.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.photo_camera, size: 14.w, color: Colors.grey[600]),
                  SizedBox(width: 4.w),
                  Text(
                    '스크린샷 ${mission.screenshots.length}개',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],

            // Action buttons
            if (showActions && (mission.status == MissionSubmissionStatus.submitted || 
                mission.status == MissionSubmissionStatus.resubmitted)) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectionDialog(mission),
                      icon: Icon(Icons.close, size: 16.w),
                      label: const Text('거부'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRevisionDialog(mission),
                      icon: Icon(Icons.edit, size: 16.w),
                      label: const Text('보완요청'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateMissionStatus(mission.id, MissionSubmissionStatus.approved),
                      icon: Icon(Icons.check, size: 16.w),
                      label: const Text('승인'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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

  void _showRejectionDialog(SubmittedMission mission) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('미션 거부'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${mission.missionTitle} 미션을 거부하시겠습니까?'),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '거부 사유',
                hintText: '테스터에게 전달할 거부 사유를 입력해주세요',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateMissionStatus(mission.id, MissionSubmissionStatus.rejected, 
                  reason: controller.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('거부', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRevisionDialog(SubmittedMission mission) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('보완 요청'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${mission.missionTitle} 미션에 보완을 요청하시겠습니까?'),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '보완 요청사항',
                hintText: '테스터가 보완해야 할 내용을 구체적으로 입력해주세요',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateMissionStatus(mission.id, MissionSubmissionStatus.needsRevision, 
                  reason: controller.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('요청', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(MissionSubmissionStatus status) {
    switch (status) {
      case MissionSubmissionStatus.approved:
        return Colors.green;
      case MissionSubmissionStatus.rejected:
        return Colors.red;
      case MissionSubmissionStatus.needsRevision:
        return Colors.orange;
      case MissionSubmissionStatus.resubmitted:
        return Colors.blue;
      case MissionSubmissionStatus.pending:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(MissionSubmissionStatus status) {
    switch (status) {
      case MissionSubmissionStatus.approved:
        return '승인됨';
      case MissionSubmissionStatus.rejected:
        return '거부됨';
      case MissionSubmissionStatus.needsRevision:
        return '보완요청';
      case MissionSubmissionStatus.resubmitted:
        return '재제출됨';
      case MissionSubmissionStatus.pending:
        return '대기중';
      default:
        return '제출됨';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}