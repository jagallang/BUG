import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/mission_model.dart';

class MissionApplicationsWidget extends StatefulWidget {
  final String providerId;

  const MissionApplicationsWidget({
    super.key,
    required this.providerId,
  });

  @override
  State<MissionApplicationsWidget> createState() => _MissionApplicationsWidgetState();
}

class _MissionApplicationsWidgetState extends State<MissionApplicationsWidget> {
  List<MissionApplication> _applications = [];

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    _applications = [
      MissionApplication(
        id: 'app_001',
        missionId: 'mission_001',
        testerId: 'tester_kim_001',
        providerId: widget.providerId,
        testerName: '김테스터',
        testerEmail: 'kim.tester@example.com',
        testerProfile: 'https://example.com/profile1.jpg',
        status: MissionApplicationStatus.pending,
        message: '안녕하세요! 모바일 앱 테스트 경험이 3년 있으며, 특히 채팅 앱 테스트에 전문성을 갖고 있습니다. 꼼꼼하게 테스트하여 품질 높은 피드백 제공하겠습니다.',
        appliedAt: DateTime.now().subtract(const Duration(hours: 1)),
        testerInfo: {
          'experience': '3년',
          'specialization': ['채팅앱', 'SNS앱', 'UI/UX'],
          'completedMissions': 45,
          'rating': 4.8,
        },
      ),
      MissionApplication(
        id: 'app_002',
        missionId: 'mission_002',
        testerId: 'tester_lee_002',
        providerId: widget.providerId,
        testerName: '이테스터',
        testerEmail: 'lee.tester@example.com',
        status: MissionApplicationStatus.pending,
        message: '안드로이드와 iOS 양쪽 플랫폼 테스트 가능합니다. 버그 발견 및 상세한 리포트 작성에 강점이 있습니다.',
        appliedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        testerInfo: {
          'experience': '2년',
          'specialization': ['크로스플랫폼', '버그리포트'],
          'completedMissions': 28,
          'rating': 4.6,
        },
      ),
      MissionApplication(
        id: 'app_003',
        missionId: 'mission_003',
        testerId: 'tester_park_003',
        providerId: widget.providerId,
        testerName: '박테스터',
        testerEmail: 'park.tester@example.com',
        status: MissionApplicationStatus.reviewing,
        message: '게임 앱 테스트 전문가입니다. 성능 테스트와 사용성 테스트에 특화되어 있습니다.',
        appliedAt: DateTime.now().subtract(const Duration(hours: 3)),
        reviewedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        testerInfo: {
          'experience': '4년',
          'specialization': ['게임앱', '성능테스트'],
          'completedMissions': 67,
          'rating': 4.9,
        },
      ),
      MissionApplication(
        id: 'app_004',
        missionId: 'mission_004',
        testerId: 'tester_jung_004',
        providerId: widget.providerId,
        testerName: '정테스터',
        testerEmail: 'jung.tester@example.com',
        status: MissionApplicationStatus.accepted,
        message: '이커머스 앱 테스트에 전문성이 있습니다. 결제 플로우와 사용자 경험 개선에 도움을 드릴 수 있습니다.',
        appliedAt: DateTime.now().subtract(const Duration(hours: 5)),
        reviewedAt: DateTime.now().subtract(const Duration(hours: 4)),
        acceptedAt: DateTime.now().subtract(const Duration(hours: 4)),
        responseMessage: '경험과 전문성을 인정하여 승인합니다. 좋은 결과 기대하겠습니다!',
        testerInfo: {
          'experience': '5년',
          'specialization': ['이커머스', '결제시스템', 'UX/UI'],
          'completedMissions': 89,
          'rating': 4.9,
        },
      ),
      MissionApplication(
        id: 'app_005',
        missionId: 'mission_005',
        testerId: 'tester_choi_005',
        providerId: widget.providerId,
        testerName: '최테스터',
        testerEmail: 'choi.tester@example.com',
        status: MissionApplicationStatus.rejected,
        message: '앱 테스트에 관심이 많습니다. 열심히 하겠습니다.',
        appliedAt: DateTime.now().subtract(const Duration(hours: 8)),
        reviewedAt: DateTime.now().subtract(const Duration(hours: 7)),
        rejectedAt: DateTime.now().subtract(const Duration(hours: 7)),
        responseMessage: '죄송하지만 해당 미션은 더 많은 경험이 필요합니다. 다른 미션에 도전해보세요.',
        testerInfo: {
          'experience': '신규',
          'specialization': [],
          'completedMissions': 2,
          'rating': 4.0,
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange.shade50,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Header Stats
            _buildHeaderStats(),
            
            SizedBox(height: 16.h),
            
            // Application List
            Expanded(
              child: _applications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _applications.length,
                      itemBuilder: (context, index) {
                        return _buildApplicationCard(_applications[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStats() {
    final pendingCount = _applications.where((app) => app.status == MissionApplicationStatus.pending).length;
    final reviewingCount = _applications.where((app) => app.status == MissionApplicationStatus.reviewing).length;
    final acceptedCount = _applications.where((app) => app.status == MissionApplicationStatus.accepted).length;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '미션 신청 관리',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('대기 중', pendingCount, Colors.orange, Icons.hourglass_empty),
              ),
              Expanded(
                child: _buildStatItem('검토 중', reviewingCount, Colors.blue, Icons.visibility),
              ),
              Expanded(
                child: _buildStatItem('승인됨', acceptedCount, Colors.green, Icons.check_circle),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color, IconData icon) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.w),
          SizedBox(height: 6.h),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(MissionApplication application) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Tester Profile
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    application.testerName[0],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                
                // Tester Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            application.testerName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          if (application.testerInfo?['rating'] != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, size: 12.w, color: Colors.amber.shade700),
                                  SizedBox(width: 2.w),
                                  Text(
                                    '${application.testerInfo!['rating']}',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '${application.testerInfo?['experience'] ?? '신규'} • ${application.testerInfo?['completedMissions'] ?? 0}회 완료',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                _buildStatusBadge(application.status),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // Application Message
            if (application.message != null && application.message!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  application.message!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ],
            
            // Tester Specializations
            if (application.testerInfo?['specialization'] != null) ...[
              Wrap(
                spacing: 6.w,
                runSpacing: 4.h,
                children: (application.testerInfo!['specialization'] as List<String>)
                    .map((spec) => Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            spec,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 10.sp,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              SizedBox(height: 12.h),
            ],
            
            // Applied Time
            Row(
              children: [
                Icon(Icons.schedule, size: 14.w, color: Colors.grey),
                SizedBox(width: 4.w),
                Text(
                  '신청: ${_formatDateTime(application.appliedAt)}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${application.testerId}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            
            // Response Message (if any)
            if (application.responseMessage != null && application.responseMessage!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _getResponseMessageColor(application.status),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '응답 메시지:',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      application.responseMessage!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Action Buttons
            if (application.status == MissionApplicationStatus.pending) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectApplication(application),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                      child: Text(
                        '거부',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _acceptApplication(application),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                      child: Text(
                        '승인',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildStatusBadge(MissionApplicationStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case MissionApplicationStatus.pending:
        color = Colors.orange;
        text = '대기중';
        icon = Icons.hourglass_empty;
        break;
      case MissionApplicationStatus.reviewing:
        color = Colors.blue;
        text = '검토중';
        icon = Icons.visibility;
        break;
      case MissionApplicationStatus.accepted:
        color = Colors.green;
        text = '승인됨';
        icon = Icons.check_circle;
        break;
      case MissionApplicationStatus.rejected:
        color = Colors.red;
        text = '거부됨';
        icon = Icons.cancel;
        break;
      case MissionApplicationStatus.cancelled:
        color = Colors.grey;
        text = '취소됨';
        icon = Icons.block;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.w, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getResponseMessageColor(MissionApplicationStatus status) {
    switch (status) {
      case MissionApplicationStatus.accepted:
        return Colors.green.shade50;
      case MissionApplicationStatus.rejected:
        return Colors.red.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64.w,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16.h),
          Text(
            '신청된 미션이 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '테스터들의 미션 신청을 기다리고 있습니다',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _acceptApplication(MissionApplication application) {
    showDialog(
      context: context,
      builder: (context) => _buildAcceptDialog(application),
    );
  }

  void _rejectApplication(MissionApplication application) {
    showDialog(
      context: context,
      builder: (context) => _buildRejectDialog(application),
    );
  }

  Widget _buildAcceptDialog(MissionApplication application) {
    final messageController = TextEditingController();
    
    return AlertDialog(
      title: const Text('미션 신청 승인'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${application.testerName}님의 미션 신청을 승인하시겠습니까?'),
          SizedBox(height: 16.h),
          TextField(
            controller: messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '테스터에게 전달할 메시지를 작성해주세요 (선택사항)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
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
            setState(() {
              final index = _applications.indexOf(application);
              _applications[index] = application.copyWith(
                status: MissionApplicationStatus.accepted,
                reviewedAt: DateTime.now(),
                acceptedAt: DateTime.now(),
                responseMessage: messageController.text.isNotEmpty 
                    ? messageController.text 
                    : '신청이 승인되었습니다. 미션을 시작해주세요!',
              );
            });
            Navigator.of(context).pop();
            
            // 알림 표시
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${application.testerName}님의 신청을 승인했습니다.'),
                backgroundColor: Colors.green,
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('승인', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildRejectDialog(MissionApplication application) {
    final messageController = TextEditingController();
    
    return AlertDialog(
      title: const Text('미션 신청 거부'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${application.testerName}님의 미션 신청을 거부하시겠습니까?'),
          SizedBox(height: 16.h),
          TextField(
            controller: messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '거부 이유를 작성해주세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
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
            if (messageController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('거부 이유를 입력해주세요.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            
            setState(() {
              final index = _applications.indexOf(application);
              _applications[index] = application.copyWith(
                status: MissionApplicationStatus.rejected,
                reviewedAt: DateTime.now(),
                rejectedAt: DateTime.now(),
                responseMessage: messageController.text,
              );
            });
            Navigator.of(context).pop();
            
            // 알림 표시
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${application.testerName}님의 신청을 거부했습니다.'),
                backgroundColor: Colors.red,
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('거부', style: TextStyle(color: Colors.white)),
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