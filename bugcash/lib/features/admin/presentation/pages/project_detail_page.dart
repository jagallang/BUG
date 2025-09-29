import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> projectData;

  const ProjectDetailPage({
    super.key,
    required this.projectId,
    required this.projectData,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  // 고급보상시스템 데이터 안전 접근 함수
  Map<String, dynamic> get _advancedRewardData {
    final metadata = widget.projectData['metadata'] as Map<String, dynamic>? ?? {};
    final rewards = widget.projectData['rewards'] as Map<String, dynamic>? ?? {};
    return metadata.isNotEmpty ? metadata : rewards;
  }

  // 개별 보상 계산 함수들 (테스터 미션 상세페이지와 동일한 로직)

  int get dailyMissionPoints {
    final data = _advancedRewardData;
    return (data['dailyMissionPoints'] as num?)?.toInt() ?? 0;
  }

  int get finalCompletionPoints {
    final data = _advancedRewardData;
    return (data['finalCompletionPoints'] as num?)?.toInt() ?? 0;
  }

  int get bonusPoints {
    final data = _advancedRewardData;
    return (data['bonusPoints'] as num?)?.toInt() ?? 0;
  }

  int get estimatedMinutes {
    final data = _advancedRewardData;
    return (data['estimatedMinutes'] as num?)?.toInt() ?? 60;
  }

  // 고급리워드시스템 총 리워드 계산 (심플화된 3단계 보상)
  int get totalAdvancedReward {
    if (_advancedRewardData.isEmpty) {
      return 0; // 고급보상 데이터가 없으면 0
    }
    final estimatedDays = (estimatedMinutes / (24 * 60)).ceil().clamp(1, 30);
    final progressReward = dailyMissionPoints * estimatedDays;
    final completionReward = finalCompletionPoints + bonusPoints;
    return progressReward + completionReward;
  }

  bool get hasAdvancedRewardSystem {
    return _advancedRewardData.isNotEmpty &&
           (dailyMissionPoints > 0 || finalCompletionPoints > 0 || bonusPoints > 0);
  }

  @override
  Widget build(BuildContext context) {
    final appName = widget.projectData['appName'] ?? '알 수 없는 앱';

    return Scaffold(
      appBar: AppBar(
        title: Text('프로젝트 상세 - $appName'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로젝트 기본 정보
            _buildBasicInfoSection(),
            SizedBox(height: 24.h),

            // 고급보상시스템 정보
            _buildAdvancedRewardSection(),
            SizedBox(height: 24.h),

            // 테스트 조건 및 요구사항
            _buildTestRequirementsSection(),
            SizedBox(height: 24.h),

            // 앱 설명 및 가이드라인
            _buildDescriptionSection(),
            SizedBox(height: 32.h),

            // 관리자 승인/거부 액션
            _buildAdminActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final status = widget.projectData['status'] ?? 'pending';
    final createdAt = (widget.projectData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final appUrl = widget.projectData['appUrl'] ?? widget.projectData['appStoreUrl'] ?? '';
    final category = widget.projectData['category'] ?? 'Other';
    final maxTesters = widget.projectData['maxTesters'] ?? 0;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📱 프로젝트 기본 정보',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('프로젝트 ID', widget.projectId),
          _buildInfoRow('앱 이름', widget.projectData['appName'] ?? 'N/A'),
          _buildInfoRow('공급자', widget.projectData['providerId'] ?? 'N/A'),
          _buildInfoRow('상태', _getStatusText(status), statusColor: _getStatusColor(status)),
          _buildInfoRow('카테고리', category),
          _buildInfoRow('앱 URL', appUrl.isNotEmpty ? appUrl : 'N/A'),
          _buildInfoRow('최대 테스터', '$maxTesters명'),
          _buildInfoRow('등록일', DateFormat('yyyy년 MM월 dd일 HH:mm').format(createdAt)),
        ],
      ),
    );
  }

  Widget _buildAdvancedRewardSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💰 고급리워드시스템',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),

          if (hasAdvancedRewardSystem) ...[
            // 고급보상시스템이 설정된 경우
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '총 리워드 (예상)',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₩${NumberFormat('#,###').format(totalAdvancedReward)}',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Divider(color: Colors.green[300]),
                  SizedBox(height: 8.h),
                  if (dailyMissionPoints > 0) ...[
                    _buildRewardRow('일일미션리워드', dailyMissionPoints, isDaily: true),
                    Text(
                      '  └ 예상 ${(estimatedMinutes / (24 * 60)).ceil().clamp(1, 30)}일 × ₩${NumberFormat('#,###').format(dailyMissionPoints)}',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    ),
                  ],
                  if (finalCompletionPoints > 0) _buildRewardRow('최종완료리워드', finalCompletionPoints),
                  if (bonusPoints > 0) _buildRewardRow('추가보너스리워드', bonusPoints),
                ],
              ),
            ),
          ] else ...[
            // 고급보상시스템이 설정되지 않은 경우
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                '⚠️ 고급보상시스템이 설정되지 않았습니다.',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestRequirementsSection() {
    final data = _advancedRewardData;
    final difficulty = data['difficulty'] ?? widget.projectData['difficulty'] ?? 'medium';
    final installType = data['installType'] ?? widget.projectData['installType'] ?? 'play_store';
    final dailyTestTime = data['dailyTestTime'] ?? widget.projectData['dailyTestTime'] ?? '30분';
    final approvalCondition = data['approvalCondition'] ?? widget.projectData['approvalCondition'] ?? '스크린샷 필수';
    final minExperience = data['minExperience'] ?? widget.projectData['minExperience'] ?? '';
    final specialRequirements = data['specialRequirements'] ?? widget.projectData['specialRequirements'] ?? '';
    final minOSVersion = data['minOSVersion'] ?? widget.projectData['minOSVersion'] ?? '';

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 테스트 조건 및 요구사항',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('난이도', _getDifficultyText(difficulty)),
          _buildInfoRow('설치방법', _getInstallTypeText(installType)),
          _buildInfoRow('일일테스트시간', dailyTestTime),
          _buildInfoRow('승인조건', approvalCondition),
          if (estimatedMinutes > 0) _buildInfoRow('예상 소요시간', '$estimatedMinutes분'),
          if (minExperience.isNotEmpty) _buildInfoRow('최소 경험', minExperience),
          if (specialRequirements.isNotEmpty) _buildInfoRow('특별 요구사항', specialRequirements),
          if (minOSVersion.isNotEmpty) _buildInfoRow('최소 OS 버전', minOSVersion),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final description = widget.projectData['description'] ?? '';
    final testingGuidelines = _advancedRewardData['testingGuidelines'] ??
                              widget.projectData['testingGuidelines'] ?? '';

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📄 앱 설명 및 가이드라인',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          if (description.isNotEmpty) ...[
            Text(
              '앱 설명',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                description,
                style: TextStyle(fontSize: 14.sp, height: 1.5),
              ),
            ),
            SizedBox(height: 16.h),
          ],
          if (testingGuidelines.isNotEmpty) ...[
            Text(
              '테스트 가이드라인',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                testingGuidelines,
                style: TextStyle(fontSize: 14.sp, height: 1.5),
              ),
            ),
          ],
          if (description.isEmpty && testingGuidelines.isEmpty) ...[
            Text(
              '설명이나 가이드라인이 제공되지 않았습니다.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminActionsSection() {
    final status = widget.projectData['status'] ?? 'pending';
    final canApprove = status == 'pending' || status == 'draft';
    final canReject = status == 'pending' || status == 'draft';

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚖️ 관리자 검토',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              if (canApprove) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveProject(),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('승인'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
              ],
              if (canReject) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectProject(),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text('거부'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!canApprove && !canReject) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '현재 상태(${_getStatusText(status)})에서는 승인/거부할 수 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: statusColor ?? Colors.black87,
                fontWeight: statusColor != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardRow(String label, int amount, {bool isDaily = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
          ),
          Text(
            '₩${NumberFormat('#,###').format(amount)}${isDaily ? '/일' : ''}',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'draft': return '초안';
      case 'pending': return '승인 대기';
      case 'open': return '승인됨';
      case 'rejected': return '거부됨';
      case 'closed': return '종료됨';
      default: return '알 수 없음';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft': return Colors.blue[600]!;
      case 'pending': return Colors.orange[600]!;
      case 'open': return Colors.green[600]!;
      case 'rejected': return Colors.red[600]!;
      case 'closed': return Colors.grey[600]!;
      default: return Colors.grey[600]!;
    }
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty) {
      case 'easy': return '쉬움';
      case 'medium': return '보통';
      case 'hard': return '어려움';
      case 'expert': return '전문가';
      default: return difficulty;
    }
  }

  String _getInstallTypeText(String installType) {
    switch (installType) {
      case 'play_store': return 'Play Store';
      case 'apk_upload': return 'APK 업로드';
      default: return installType;
    }
  }

  void _approveProject() async {
    try {
      // Try Cloud Functions first, fallback to direct Firestore update if needed
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
        final callable = functions.httpsCallable('reviewProject');

        await callable.call({
          'projectId': widget.projectId,
          'approve': true,
        });
      } catch (cloudError) {
        // Fallback to direct Firestore update
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .update({
          'status': 'open',
          'approvedAt': FieldValue.serverTimestamp(),
          'approvedBy': 'admin',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 프로젝트가 승인되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 승인 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _rejectProject() async {
    // 거부 이유 입력 다이얼로그
    final reason = await _showRejectDialog();
    if (reason == null) return;

    try {
      // Try Cloud Functions first, fallback to direct Firestore update if needed
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
        final callable = functions.httpsCallable('reviewProject');

        await callable.call({
          'projectId': widget.projectId,
          'approve': false,
          'rejectionReason': reason,
        });
      } catch (cloudError) {
        // Fallback to direct Firestore update
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .update({
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': 'admin',
          'rejectionReason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ 프로젝트가 거부되었습니다'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 거부 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로젝트 거부'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('거부 이유를 입력해주세요:'),
            SizedBox(height: 16.h),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '거부 이유를 입력하세요...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}