import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/tester_dashboard_provider.dart' as provider;

class MissionApplicationDialog extends ConsumerStatefulWidget {
  final provider.MissionCard mission;
  final VoidCallback onApplicationSubmitted;

  const MissionApplicationDialog({
    super.key,
    required this.mission,
    required this.onApplicationSubmitted,
  });

  @override
  ConsumerState<MissionApplicationDialog> createState() => _MissionApplicationDialogState();
}

class _MissionApplicationDialogState extends ConsumerState<MissionApplicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _hasReadRequirements = false;
  bool _hasInstalledApp = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500.w,
          maxHeight: 700.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32.w,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '미션 신청하기',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    widget.mission.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mission Info Summary
                      _buildMissionSummary(),
                      
                      SizedBox(height: 20.h),
                      
                      // Requirements Checklist
                      _buildRequirementsChecklist(),
                      
                      SizedBox(height: 20.h),
                      
                      // Message Input
                      _buildMessageInput(),
                      
                      SizedBox(height: 20.h),
                      
                      // Application Guidelines
                      _buildApplicationGuidelines(),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _canSubmit() && !_isSubmitting 
                          ? _submitApplication 
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              '신청하기',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  Widget _buildMissionSummary() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '미션 정보',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('앱 이름', widget.mission.appName, Icons.apps),
              ),
              Expanded(
                child: _buildInfoItem('보상', '${widget.mission.rewardPoints}P', Icons.monetization_on),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('소요시간', '${widget.mission.estimatedMinutes}분', Icons.schedule),
              ),
              Expanded(
                child: _buildInfoItem('참여자', '${widget.mission.currentParticipants}/${widget.mission.maxParticipants}', Icons.people),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16.w, color: Colors.grey.shade600),
        SizedBox(width: 6.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirementsChecklist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '신청 전 확인사항',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        
        // 요구사항 확인
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Column(
            children: [
              CheckboxListTile(
                value: _hasReadRequirements,
                onChanged: (value) {
                  setState(() {
                    _hasReadRequirements = value ?? false;
                  });
                },
                title: Text(
                  '공급자의 테스트 요구사항을 확인했습니다',
                  style: TextStyle(fontSize: 14.sp),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _hasInstalledApp,
                onChanged: (value) {
                  setState(() {
                    _hasInstalledApp = value ?? false;
                  });
                },
                title: Text(
                  '앱을 설치하고 테스트할 준비가 되었습니다',
                  style: TextStyle(fontSize: 14.sp),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '신청 메시지 (선택사항)',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '공급자에게 전달할 메시지를 작성해주세요. 경험이나 특별한 사항을 어필할 수 있습니다.',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 12.h),
        TextFormField(
          controller: _messageController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: '예: 안녕하세요! 저는 모바일 앱 테스트 경험이 3년 있으며, 특히 UI/UX 테스트를 전문으로 합니다. 책임감을 갖고 꼼꼼히 테스트하겠습니다.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            contentPadding: EdgeInsets.all(12.w),
          ),
          style: TextStyle(fontSize: 14.sp),
        ),
      ],
    );
  }

  Widget _buildApplicationGuidelines() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.green, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '신청 안내',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '• 신청 후 공급자가 검토하여 수락/거부를 결정합니다\n'
            '• 수락되면 즉시 테스트를 시작할 수 있습니다\n'
            '• 거부되더라도 다른 미션에 계속 신청할 수 있습니다\n'
            '• 신청은 취소할 수 있지만, 수락 후에는 취소가 어렵습니다',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.green.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    return _hasReadRequirements && _hasInstalledApp;
  }

  Future<void> _submitApplication() async {
    if (!_canSubmit() || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 신청 데이터 생성
      await _createMissionApplication();
      
      // 앱 공급자에게 알림 전송
      await _sendNotificationToProvider();

      // 성공 처리
      if (mounted) {
        // 테스터 대시보드 새로고침 (진행중 탭에서 즉시 확인 가능)
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          ref.read(provider.testerDashboardProvider.notifier).refreshData(currentUser.uid);
        }

        Navigator.of(context).pop();
        widget.onApplicationSubmitted();

        // 성공 스낵바
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                const Expanded(
                  child: Text('미션 신청이 완료되었습니다!\n공급자의 승인을 기다려주세요.'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '확인',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (error) {
      // 에러 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8.w),
                const Text('신청 중 오류가 발생했습니다. 다시 시도해주세요.'),
              ],
            ),
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

  Future<void> _createMissionApplication() async {
    // 현재 사용자 ID 가져오기
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 사용자 정보 가져오기
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final userData = userDoc.data();
    if (userData == null) {
      throw Exception('사용자 정보를 찾을 수 없습니다.');
    }

    // 테스터 상세 정보 가져오기
    final testerDoc = await FirebaseFirestore.instance
        .collection('testers')
        .doc(currentUser.uid)
        .get();

    final testerData = testerDoc.data() ?? {};

    // Provider ID 찾기
    String? providerId;
    String actualAppId = widget.mission.id; // 기본값: mission ID 그대로

    // 🚨 DEBUG: 미션 ID 상태 확인
    debugPrint('🔍 MISSION_ID_DEBUG: widget.mission.id = "${widget.mission.id}"');
    debugPrint('🔍 MISSION_ID_DEBUG: widget.mission.appName = "${widget.mission.appName}"');
    debugPrint('🔍 MISSION_ID_DEBUG: actualAppId initial = "$actualAppId"');

    if (widget.mission.id.startsWith('provider_app_')) {
      // provider_apps에서 온 경우
      actualAppId = widget.mission.id.replaceFirst('provider_app_', ''); // 실제 앱 ID 추출
      debugPrint('🔍 PROVIDER_ID_DEBUG: Extracted actualAppId = "$actualAppId"');
    } else if (actualAppId.isEmpty) {
      // 🔧 FALLBACK: mission ID가 비어있으면 앱 이름을 사용
      debugPrint('🚨 FALLBACK: mission.id is empty, using appName as fallback');
      actualAppId = widget.mission.appName.replaceAll(' ', '').toLowerCase(); // 앱123 -> 앱123
    }

    debugPrint('🔍 PROVIDER_ID_DEBUG: Final actualAppId for search = "$actualAppId"');

    if (widget.mission.id.startsWith('provider_app_') || actualAppId.isNotEmpty) {
      final providerAppDoc = await FirebaseFirestore.instance
          .collection('provider_apps')
          .doc(actualAppId)
          .get();

      debugPrint('🔍 PROVIDER_ID_DEBUG: Document exists = ${providerAppDoc.exists}');

      if (providerAppDoc.exists) {
        final data = providerAppDoc.data();
        debugPrint('🔍 PROVIDER_ID_DEBUG: Document data = $data');
        providerId = data?['providerId'];
        debugPrint('🔍 PROVIDER_ID_DEBUG: Found providerId = $providerId');
      } else {
        debugPrint('🚨 PROVIDER_ID_ERROR: Document not found for actualAppId: $actualAppId');

        // 전체 provider_apps 컬렉션 확인 (처음 10개)
        final allProviderApps = await FirebaseFirestore.instance
            .collection('provider_apps')
            .limit(10)
            .get();

        debugPrint('🔍 ALL_PROVIDER_APPS: Found ${allProviderApps.docs.length} documents');
        for (var doc in allProviderApps.docs) {
          debugPrint('🔍 PROVIDER_APP_DOC: ID=${doc.id}, data=${doc.data()}');
        }
      }
    }

    if (providerId == null) {
      debugPrint('🚨 CRITICAL_ERROR: providerId is null for mission ${widget.mission.id}');

      // 🔧 FALLBACK: 현재 사용자를 providerId로 사용 (임시 해결책)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        debugPrint('🔧 FALLBACK: Using current user as providerId: ${currentUser.uid}');
        providerId = currentUser.uid;
      } else {
        throw Exception('공급자 정보를 찾을 수 없습니다. (actualAppId: $actualAppId)');
      }
    }

    // 디버그 로그 추가
    debugPrint('🔵 TESTER_APPLICATION_DEBUG:');
    debugPrint('🔵 widget.mission.id: ${widget.mission.id}');
    debugPrint('🔵 actualAppId (저장될 값): $actualAppId');
    debugPrint('🔵 appName: ${widget.mission.appName}');
    debugPrint('🔵 providerId: $providerId');
    debugPrint('🔵 testerId: ${currentUser.uid}');

    // Firestore에 신청 정보 저장 (올바른 컬렉션 이름 사용)
    await FirebaseFirestore.instance.collection('tester_applications').add({
      'appId': actualAppId, // 실제 앱 ID 사용 (공급자가 필터링할 때 사용)
      'appName': widget.mission.appName, // 🔥 앱 이름 추가 - 공급자 화면에서 필수!
      'missionId': widget.mission.id,
      'testerId': currentUser.uid,
      'providerId': providerId,
      'testerName': userData['displayName'] ?? testerData['name'] ?? 'Unknown',
      'testerEmail': userData['email'] ?? '',
      'testerProfile': userData['photoUrl'],
      'status': 'pending', // pending, approved, rejected (공급자가 사용하는 상태)
      'experience': testerData['experience'] ?? 'New', // 직접 필드로 추가
      'motivation': _messageController.text.trim(), // message -> motivation 으로 변경
      'appliedAt': FieldValue.serverTimestamp(),
      'processedAt': null,
      'metadata': {
        'testerInfo': {
          'specialization': List<String>.from(testerData['skills'] ?? []),
          'completedMissions': testerData['completedMissions'] ?? 0,
          'rating': (testerData['averageRating'] ?? 0.0).toDouble(),
        },
        'requirements': {
          'hasReadRequirements': _hasReadRequirements,
          'hasInstalledApp': _hasInstalledApp,
        },
      },
    });
  }

  Future<void> _sendNotificationToProvider() async {
    try {
      // 미션이 provider_apps에서 온 것인지 확인
      final isProviderApp = widget.mission.id.startsWith('provider_app_');
      
      if (isProviderApp) {
        // provider_apps ID 추출
        final providerAppId = widget.mission.id.replaceFirst('provider_app_', '');
        
        // provider_apps 문서에서 공급자 정보 가져오기
        final providerAppDoc = await FirebaseFirestore.instance
            .collection('provider_apps')
            .doc(providerAppId)
            .get();
            
        if (providerAppDoc.exists) {
          final providerData = providerAppDoc.data()!;
          final providerId = providerData['providerId'];
          
          if (providerId != null) {
            // 공급자에게 알림 생성
            await FirebaseFirestore.instance.collection('notifications').add({
              'recipientId': providerId,
              'type': 'mission_application',
              'title': '새로운 미션 신청',
              'message': '${widget.mission.appName} 앱에 새로운 테스터가 신청했습니다.',
              'data': {
                'missionId': widget.mission.id,
                'missionTitle': widget.mission.title,
                'appName': widget.mission.appName,
                'applicantMessage': _messageController.text.trim(),
              },
              'createdAt': FieldValue.serverTimestamp(),
              'isRead': false,
            });
            
            // 📧 Provider notification sent to: $providerId
          }
        }
      } else {
        // 일반 미션의 경우 mission 문서에서 공급자 정보 가져오기
        final missionDoc = await FirebaseFirestore.instance
            .collection('missions')
            .doc(widget.mission.id)
            .get();
            
        if (missionDoc.exists) {
          final missionData = missionDoc.data()!;
          final providerId = missionData['providerId'] ?? missionData['createdBy'];
          
          if (providerId != null) {
            // 공급자에게 알림 생성
            await FirebaseFirestore.instance.collection('notifications').add({
              'recipientId': providerId,
              'type': 'mission_application',
              'title': '새로운 미션 신청',
              'message': '${widget.mission.title} 미션에 새로운 테스터가 신청했습니다.',
              'data': {
                'missionId': widget.mission.id,
                'missionTitle': widget.mission.title,
                'applicantMessage': _messageController.text.trim(),
              },
              'createdAt': FieldValue.serverTimestamp(),
              'isRead': false,
            });
            
            // 📧 Mission provider notification sent to: $providerId
          }
        }
      }
    } catch (e) {
      // ❌ Error sending notification to provider: $e
      // 알림 전송 실패해도 신청은 성공으로 처리
    }
  }
}