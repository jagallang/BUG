import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/mission_service.dart';
import '../../../../core/utils/logger.dart';

class MissionDetailPage extends ConsumerStatefulWidget {
  final dynamic mission; // MissionModel 또는 MissionCard

  const MissionDetailPage({
    super.key,
    required this.mission,
  });

  @override
  ConsumerState<MissionDetailPage> createState() => _MissionDetailPageState();
}

class _MissionDetailPageState extends ConsumerState<MissionDetailPage> {
  bool _isApplying = false;
  bool _isLoadingAppDetails = false;
  Map<String, dynamic>? _appDetails;

  String get missionId => widget.mission.id ?? '';
  String get missionTitle => widget.mission.title ?? '미션 ${missionId}';
  String get missionAppName => widget.mission.appName ?? '앱 테스트';
  String get missionDescription => widget.mission.description ?? '새로운 테스트 미션에 참여해보세요!';
  int get missionReward => widget.mission.rewardPoints ?? widget.mission.reward ?? 0;
  String get missionCategory => widget.mission.type?.toString().split('.').last ?? '기능 테스트';
  int get currentParticipants => widget.mission.currentParticipants ?? widget.mission.testers ?? 0;
  int get maxParticipants => widget.mission.maxParticipants ?? widget.mission.maxTesters ?? 10;
  int get estimatedMinutes => widget.mission.estimatedMinutes ?? widget.mission.duration ?? 30;
  List<String> get requiredSkills => widget.mission.requiredSkills ?? <String>[];
  String get providerId {
    try {
      return widget.mission.providerId ?? '';
    } catch (e) {
      try {
        // createdBy 필드가 있는 경우에만 접근
        return (widget.mission as dynamic).createdBy ?? '';
      } catch (e2) {
        return '';
      }
    }
  }
  String? get appId {
    try {
      // MissionModel인 경우 appId가 있음
      return widget.mission.appId;
    } catch (e) {
      // MissionCard인 경우 appId가 없을 수 있음
      try {
        // MissionCard에서 id를 appId로 사용 (임시 처리)
        return widget.mission.id;
      } catch (e2) {
        return null;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAppDetails();
  }

  // 공급자가 등록한 앱 상세정보를 Firestore에서 가져오기
  Future<void> _loadAppDetails() async {
    setState(() {
      _isLoadingAppDetails = true;
    });

    try {
      Map<String, dynamic>? appData;

      // 1. appId가 있으면 직접 조회
      if (appId != null && appId!.isNotEmpty) {
        AppLogger.info('Loading app details with appId: $appId', 'MissionDetailPage');

        final appDoc = await FirebaseFirestore.instance
            .collection('provider_apps')
            .doc(appId)
            .get();

        if (appDoc.exists) {
          appData = appDoc.data();
          AppLogger.info('App details loaded from provider_apps by ID', 'MissionDetailPage');
        } else {
          // provider_apps에 없으면 apps 컬렉션에서도 시도
          final fallbackDoc = await FirebaseFirestore.instance
              .collection('apps')
              .doc(appId)
              .get();

          if (fallbackDoc.exists) {
            appData = fallbackDoc.data();
            AppLogger.info('App details loaded from apps collection by ID', 'MissionDetailPage');
          }
        }
      }

      // 2. appId가 없거나 찾지 못했으면 앱 이름으로 검색
      if (appData == null && missionAppName.isNotEmpty) {
        AppLogger.info('Loading app details with appName: $missionAppName', 'MissionDetailPage');

        // provider_apps 컬렉션에서 앱 이름으로 검색
        final querySnapshot = await FirebaseFirestore.instance
            .collection('provider_apps')
            .where('appName', isEqualTo: missionAppName)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          appData = querySnapshot.docs.first.data();
          AppLogger.info('App details loaded from provider_apps by name', 'MissionDetailPage');
        } else {
          // provider_apps에 없으면 apps 컬렉션에서도 검색
          final fallbackQuery = await FirebaseFirestore.instance
              .collection('apps')
              .where('name', isEqualTo: missionAppName)
              .limit(1)
              .get();

          if (fallbackQuery.docs.isNotEmpty) {
            appData = fallbackQuery.docs.first.data();
            AppLogger.info('App details loaded from apps collection by name', 'MissionDetailPage');
          }
        }
      }

      setState(() {
        _appDetails = appData;
        _isLoadingAppDetails = false;
      });

      if (appData == null) {
        AppLogger.warning('App not found in database. AppId: $appId, AppName: $missionAppName', 'MissionDetailPage');
      }
    } catch (e) {
      setState(() {
        _isLoadingAppDetails = false;
      });
      AppLogger.error('Failed to load app details', 'MissionDetailPage', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('미션 상세정보'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMissionHeader(),
            SizedBox(height: 20.h),
            _buildMissionInfo(),
            if (_appDetails != null) ...[
              SizedBox(height: 20.h),
              _buildAppBasicInfo(),
              if (_appDetails!['metadata']?['hasAnnouncement'] == true) ...[
                SizedBox(height: 20.h),
                _buildAnnouncement(),
              ],
              SizedBox(height: 20.h),
              _buildPricingInfo(),
              SizedBox(height: 20.h),
              _buildTestSettings(),
            ],
            SizedBox(height: 20.h),
            _buildRequirements(),
            SizedBox(height: 20.h),
            _buildTestingGuidelines(),
            SizedBox(height: 20.h),
            _buildRewardInfo(),
            SizedBox(height: 100.h),
          ],
        ),
      ),
      bottomNavigationBar: _buildApplyButton(authState),
    );
  }

  Widget _buildMissionHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  missionCategory,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            missionTitle,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            missionAppName,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionInfo() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '미션 정보',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            missionDescription,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          Divider(color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  '참여자',
                  '$currentParticipants/$maxParticipants명',
                  Icons.people,
                ),
              ),
              Container(
                width: 1,
                height: 40.h,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _buildInfoItem(
                  '예상 시간',
                  '${estimatedMinutes}분',
                  Icons.timer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[600], size: 20.w),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirements() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green[600], size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '참여 조건',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (requiredSkills.isNotEmpty) ...[
            ...requiredSkills.map((skill) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6.w,
                    height: 6.w,
                    margin: EdgeInsets.only(top: 6.h, right: 8.w),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ] else ...[
            _buildRequirementItem('안드로이드 또는 iOS 기기 보유'),
            _buildRequirementItem('테스트 결과를 상세히 기록할 수 있는 능력'),
            _buildRequirementItem('책임감 있게 테스트를 완료할 의지'),
          ],
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String requirement) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            margin: EdgeInsets.only(top: 6.h, right: 8.w),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              requirement,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestingGuidelines() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, color: Colors.orange[600], size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '테스트 가이드라인',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildGuidelineItem('1단계', '앱을 다운로드하고 설치'),
          _buildGuidelineItem('2단계', '주요 기능들을 체계적으로 테스트'),
          _buildGuidelineItem('3단계', '발견한 버그나 개선점을 상세히 기록'),
          _buildGuidelineItem('4단계', '테스트 결과를 리포트로 제출'),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String step, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              step,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 앱 기본정보 섹션 추가
  Widget _buildAppBasicInfo() {
    if (_appDetails == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.apps, color: Colors.blue[600], size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '앱 기본정보',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildDetailRow('앱 이름', _appDetails!['appName'] ?? '정보 없음'),
          _buildDetailRow('카테고리', _appDetails!['category'] ?? '정보 없음'),
          if (_appDetails!['appUrl'] != null && _appDetails!['appUrl'].toString().isNotEmpty)
            _buildDetailRow('앱 URL', _appDetails!['appUrl']),
          _buildDetailRow('등록일', _formatTimestamp(_appDetails!['createdAt'])),
        ],
      ),
    );
  }

  // 공지사항 섹션 추가
  Widget _buildAnnouncement() {
    final announcement = _appDetails?['metadata']?['announcement'];
    if (announcement == null || announcement.toString().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.amber[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign, color: Colors.amber[700], size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '📢 공지사항',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            announcement.toString(),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // 단가정보 섹션 추가
  Widget _buildPricingInfo() {
    final metadata = _appDetails?['metadata'];
    if (metadata == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: Colors.green[600], size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '💰 단가정보',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '테스트 단가: ',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${metadata['price'] ?? 0}원',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 테스트 설정 섹션 추가
  Widget _buildTestSettings() {
    final metadata = _appDetails?['metadata'];
    if (metadata == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.purple[600], size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '⚙️ 테스트 설정',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildDetailRow('참여 인원', '${metadata['participantCount'] ?? 1}명'),
          _buildDetailRow('테스트 기간', '${metadata['testPeriod'] ?? 14}일'),
          _buildDetailRow('예상 소요시간', '${metadata['testTime'] ?? 30}분'),
          if (metadata['requirements'] != null && metadata['requirements'].toString().isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text(
              '기타 요구사항',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                metadata['requirements'].toString(),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 상세정보 행 위젯
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Timestamp 포맷 함수
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '정보 없음';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    return timestamp.toString();
  }

  Widget _buildRewardInfo() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[400]!, Colors.green[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.monetization_on, color: Colors.white, size: 24.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '리워드',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${missionReward}P',
                  style: TextStyle(
                    fontSize: 24.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '완료 시 지급',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(AuthState authState) {
    final isFull = currentParticipants >= maxParticipants;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48.h,
          child: ElevatedButton(
            onPressed: _isApplying || isFull ? null : () => _applyToMission(authState),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFull ? Colors.grey[400] : Colors.blue[600],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: _isApplying
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    isFull ? '모집 완료' : '미션 신청하기',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _applyToMission(AuthState authState) async {
    if (authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인이 필요합니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isApplying = true;
    });

    try {
      final missionService = MissionService();

      // 공급자 이름 가져오기
      String providerName = 'Unknown Provider';
      try {
        final providerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(providerId)
            .get();
        if (providerDoc.exists) {
          final data = providerDoc.data() as Map<String, dynamic>;
          providerName = data['displayName'] ?? data['name'] ?? 'Unknown Provider';
        }
      } catch (e) {
        print('Provider name lookup failed: $e');
      }

      final applicationData = {
        'missionId': missionId,
        'testerId': authState.user!.uid,
        'providerId': providerId,
        'providerName': providerName,
        'testerName': authState.user!.displayName ?? 'Unknown User',
        'testerEmail': authState.user!.email ?? '',
        'missionName': missionAppName,
        'status': 'pending',
        'message': '미션에 참여하고 싶습니다.',
        'appliedAt': DateTime.now(),
        'dailyReward': missionReward,
        'totalDays': estimatedMinutes > 0 ? (estimatedMinutes / 30).ceil() : 14,
        'requirements': requiredSkills,
        'testerInfo': {
          'userType': authState.user!.userType.toString(),
          'experience': 'beginner',
          'name': authState.user!.displayName ?? 'Unknown User',
          'email': authState.user!.email ?? '',
          'motivation': '새로운 앱을 테스트하며 버그를 찾는 것에 관심이 있습니다.',
        },
      };

      print('🎯 UI - 미션 신청 버튼 클릭됨! missionId: $missionId');
      print('🎯 UI - testerId: ${authState.user!.uid}');
      print('🎯 UI - providerId: $providerId');

      await missionService.applyToMission(missionId, applicationData);

      print('🎯 UI - 미션 신청 호출 완료!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('미션 신청이 완료되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('미션 신청에 실패했습니다: $e'),
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
}