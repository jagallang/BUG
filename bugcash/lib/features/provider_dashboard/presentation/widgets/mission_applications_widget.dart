import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<List<MissionApplication>>? _applicationsStream;

  @override
  void initState() {
    super.initState();
    _initializeApplicationsStream();
  }

  void _initializeApplicationsStream() {
    _applicationsStream = _firestore
        .collection('missionApplications')
        .where('providerId', isEqualTo: widget.providerId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final applications = <MissionApplication>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Get tester info
        final testerDoc = await _firestore
            .collection('testers')
            .doc(data['testerId'])
            .get();

        final testerData = testerDoc.data() ?? {};

        // Get tester stats
        final statsDoc = await _firestore
            .collection('testers')
            .doc(data['testerId'])
            .collection('stats')
            .doc('summary')
            .get();

        final stats = statsDoc.data() ?? {};

        applications.add(MissionApplication(
          id: doc.id,
          missionId: data['missionId'] ?? '',
          testerId: data['testerId'] ?? '',
          providerId: data['providerId'] ?? '',
          testerName: testerData['name'] ?? 'Unknown',
          testerEmail: testerData['email'] ?? '',
          testerProfile: testerData['photoUrl'],
          status: _parseApplicationStatus(data['status'] ?? 'pending'),
          message: data['message'],
          appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
          acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
          rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
          responseMessage: data['responseMessage'],
          testerInfo: {
            'experience': testerData['experience'] ?? 'New',
            'specialization': List<String>.from(testerData['skills'] ?? []),
            'completedMissions': stats['completedMissions'] ?? 0,
            'rating': (stats['averageRating'] ?? 0.0).toDouble(),
          },
        ));
      }

      return applications;
    });
  }

  MissionApplicationStatus _parseApplicationStatus(String status) {
    switch (status.toLowerCase()) {
      case 'reviewing':
        return MissionApplicationStatus.reviewing;
      case 'accepted':
        return MissionApplicationStatus.accepted;
      case 'rejected':
        return MissionApplicationStatus.rejected;
      case 'cancelled':
        return MissionApplicationStatus.cancelled;
      case 'pending':
      default:
        return MissionApplicationStatus.pending;
    }
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
              child: StreamBuilder<List<MissionApplication>>(
                stream: _applicationsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final applications = snapshot.data ?? [];

                  if (applications.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: applications.length,
                    itemBuilder: (context, index) {
                      return _buildApplicationCard(applications[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStats() {
    return StreamBuilder<List<MissionApplication>>(
      stream: _applicationsStream,
      builder: (context, snapshot) {
        final applications = snapshot.data ?? [];
        final pendingCount = applications.where((app) => app.status == MissionApplicationStatus.pending).length;
        final reviewingCount = applications.where((app) => app.status == MissionApplicationStatus.reviewing).length;
        final acceptedCount = applications.where((app) => app.status == MissionApplicationStatus.accepted).length;

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
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
      },
    );
  }

  Widget _buildStatItem(String label, int count, Color color, IconData icon) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.2)),
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
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                                color: Colors.amber.withOpacity(0.2),
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
                            color: Colors.blue.withOpacity(0.1),
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
        color: color.withOpacity(0.1),
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
          onPressed: () async {
            final navigator = Navigator.of(context);
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            try {
              await _firestore
                  .collection('missionApplications')
                  .doc(application.id)
                  .update({
                'status': 'accepted',
                'reviewedAt': FieldValue.serverTimestamp(),
                'acceptedAt': FieldValue.serverTimestamp(),
                'responseMessage': messageController.text.isNotEmpty
                    ? messageController.text
                    : '신청이 승인되었습니다. 미션을 시작해주세요!',
              });

              if (mounted) {
                navigator.pop();

                // 알림 표시
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('${application.testerName}님의 신청을 승인했습니다.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
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
          onPressed: () async {
            final navigator = Navigator.of(context);
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            if (messageController.text.trim().isEmpty) {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('거부 이유를 입력해주세요.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            try {
              await _firestore
                  .collection('missionApplications')
                  .doc(application.id)
                  .update({
                'status': 'rejected',
                'reviewedAt': FieldValue.serverTimestamp(),
                'rejectedAt': FieldValue.serverTimestamp(),
                'responseMessage': messageController.text,
              });

              if (mounted) {
                navigator.pop();

                // 알림 표시
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('${application.testerName}님의 신청을 거부했습니다.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
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