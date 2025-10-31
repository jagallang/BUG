import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // v2.186.36: Clipboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // v2.186.36: 앱 링크 열기
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/mission_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/extensions/responsive_extensions.dart';
import '../widgets/mission_application_terms_dialog.dart';

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
  bool _isLoadingApplicationStatus = false;
  bool _hasAlreadyApplied = false;
  String? _applicationStatus;
  Map<String, dynamic>? _appDetails;

  String get missionId => widget.mission.id ?? '';
  String get missionTitle => widget.mission.title ?? '미션 $missionId';
  String get missionAppName => widget.mission.appName ?? '앱 테스트';
  String get missionDescription => widget.mission.description ?? '새로운 테스트 미션에 참여해보세요!';
  int get missionReward => widget.mission.rewardPoints ?? widget.mission.reward ?? 0;

  // 3단계 고급보상시스템 데이터 접근 함수
  Map<String, dynamic> get _advancedRewardData {
    if (_appDetails == null) return {};
    return _appDetails!['rewards'] as Map<String, dynamic>? ?? {};
  }


  // v2.112.0: dailyMissionPoints removed (reward system simplification)

  int get finalCompletionPoints {
    final rewards = _advancedRewardData;
    return (rewards['finalCompletionPoints'] as num?)?.toInt() ?? 0;
  }

  int get bonusPoints {
    final rewards = _advancedRewardData;
    return (rewards['bonusPoints'] as num?)?.toInt() ?? 0;
  }

  // v2.112.0: Simplified reward calculation - removed daily points calculation
  int get totalAdvancedReward {
    // 고급보상 데이터가 없으면 기존 방식 사용
    if (_advancedRewardData.isEmpty) {
      return missionReward;
    }

    // v2.112.0: Only finalCompletionPoints + bonusPoints
    return finalCompletionPoints + bonusPoints;
  }

  // v2.112.0: Simplified reward system check - removed dailyMissionPoints
  bool get hasAdvancedRewardSystem {
    final rewards = _advancedRewardData;
    return rewards.containsKey('finalCompletionPoints') ||
           rewards.containsKey('bonusPoints');
  }

  String get missionCategory => widget.mission.type?.toString().split('.').last ?? '기능 테스트';
  int get currentParticipants => widget.mission.currentParticipants ?? widget.mission.testers ?? 0;
  int get maxParticipants => widget.mission.maxParticipants ?? widget.mission.maxTesters ?? 10;
  // v2.122.2: 공급자가 입력한 테스트 시간 우선 사용
  int get estimatedMinutes =>
      _appDetails?['testTimeMinutes'] ??
      widget.mission.estimatedMinutes ??
      widget.mission.duration ??
      30;
  List<String> get requiredSkills => widget.mission.requiredSkills ?? <String>[];
  String get providerId {
    // 1. 앱 디테일에서 조회된 providerId 우선 사용
    if (_appDetails != null && _appDetails!['detectedProviderId'] != null) {
      return _appDetails!['detectedProviderId'];
    }

    // 2. mission 객체에서 providerId 확인
    try {
      final missionProviderId = widget.mission.providerId;
      if (missionProviderId != null && missionProviderId.isNotEmpty) {
        return missionProviderId;
      }
    } catch (e) {
      // providerId 필드가 없는 경우
    }

    // 3. createdBy 필드 확인
    try {
      final createdBy = (widget.mission as dynamic).createdBy;
      if (createdBy != null && createdBy.isNotEmpty) {
        return createdBy;
      }
    } catch (e) {
      // createdBy 필드가 없는 경우
    }

    return '';
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
    _checkApplicationStatus();
  }

  // 공급자가 등록한 앱 상세정보를 Firestore에서 가져오기
  Future<void> _loadAppDetails() async {

    try {
      debugPrint('🔍 [_loadAppDetails] 시작');
      debugPrint('   ├─ appId: $appId');
      debugPrint('   ├─ missionId: $missionId');
      debugPrint('   ├─ missionAppName: $missionAppName');
      debugPrint('   └─ widget.mission.providerId: ${widget.mission.providerId}');

      Map<String, dynamic>? appData;
      String? detectedProviderId;

      // 0. missions 컬렉션에서 먼저 providerId 확인 (최우선)
      if (missionId.isNotEmpty) {
        debugPrint('   🔍 0. missions 컬렉션 조회 시도: $missionId');
        final missionDoc = await FirebaseFirestore.instance
            .collection('missions')
            .doc(missionId)
            .get();

        debugPrint('   📊 missions.exists: ${missionDoc.exists}');
        if (missionDoc.exists) {
          final missionData = missionDoc.data();
          detectedProviderId = missionData?['providerId'] ?? missionData?['createdBy'];
          debugPrint('   ✅ missions에서 providerId 발견: $detectedProviderId');

          // missions 문서에 appId가 있으면 그것도 가져오기
          if (missionData?['appId'] != null) {
            final missionAppId = missionData!['appId'] as String;
            debugPrint('   📱 missions에서 appId도 발견: $missionAppId');
          }
        }
      }

      // 1. appId가 있으면 직접 조회 (확장된 컬렉션 검색)
      if (appId != null && appId!.isNotEmpty) {
        AppLogger.info('🔍 앱 조회 시작 - appId: $appId, appName: $missionAppName', 'MissionDetailPage');

        // 1-1. provider_apps 컬렉션에서 조회 (permission-denied 예외 처리)
        try {
          debugPrint('   🔍 1-1. provider_apps 조회 시도: $appId');
          final appDoc = await FirebaseFirestore.instance
              .collection('provider_apps')
              .doc(appId)
              .get();

          debugPrint('   📊 provider_apps.exists: ${appDoc.exists}');
          if (appDoc.exists) {
            appData = appDoc.data();
            detectedProviderId = appData?['providerId'] ?? appData?['createdBy'];
            debugPrint('   ✅ provider_apps 발견! detectedProviderId: $detectedProviderId');
            AppLogger.info('✅ App details loaded from provider_apps by ID', 'MissionDetailPage');
          }
        } catch (e) {
          debugPrint('   ⚠️ provider_apps 조회 실패 (권한 없음 또는 오류): $e');
        }

        // 1-1에서 찾지 못했으면 계속 진행
        if (appData == null) {
          AppLogger.info('❌ provider_apps에서 미발견, apps 컬렉션 시도', 'MissionDetailPage');

          // 1-2. apps 컬렉션에서 조회 (permission-denied 예외 처리)
          try {
            debugPrint('   🔍 1-2. apps 조회 시도: $appId');
            final fallbackDoc = await FirebaseFirestore.instance
                .collection('apps')
                .doc(appId)
                .get();

            debugPrint('   📊 apps.exists: ${fallbackDoc.exists}');
            if (fallbackDoc.exists) {
              appData = fallbackDoc.data();
              detectedProviderId = appData?['providerId'] ?? appData?['createdBy'];
              debugPrint('   ✅ apps 발견! detectedProviderId: $detectedProviderId');
              AppLogger.info('✅ App details loaded from apps collection by ID', 'MissionDetailPage');
            }
          } catch (e) {
            debugPrint('   ⚠️ apps 조회 실패 (권한 없음 또는 오류): $e');
          }

          // 1-2에서도 찾지 못했으면 projects 시도
          if (appData == null) {
            AppLogger.info('❌ apps에서 미발견, projects 컬렉션 시도', 'MissionDetailPage');

            // 1-3. projects 컬렉션에서 조회 (permission-denied 예외 처리)
            try {
              debugPrint('   🔍 1-3. projects 조회 시도: $appId');
              final projectDoc = await FirebaseFirestore.instance
                  .collection('projects')
                  .doc(appId)
                  .get();

              debugPrint('   📊 projects.exists: ${projectDoc.exists}');
              if (projectDoc.exists) {
                appData = projectDoc.data();
                detectedProviderId = appData?['providerId'] ?? appData?['createdBy'];
                debugPrint('   ✅ projects 발견! detectedProviderId: $detectedProviderId');
                debugPrint('   📦 projectDoc.data keys: ${projectDoc.data()?.keys.toList()}');
                AppLogger.info('✅ App details loaded from projects collection by ID', 'MissionDetailPage');
              } else {
                debugPrint('   ❌ 모든 컬렉션에서 appId로 미발견');
                AppLogger.warning('❌ 모든 컬렉션에서 appId로 미발견: $appId', 'MissionDetailPage');
              }
            } catch (e) {
              debugPrint('   ⚠️ projects 조회 실패 (권한 없음 또는 오류): $e');
            }
          }
        }
      }

      // 2. appId가 없거나 찾지 못했으면 앱 이름으로 검색 (확장된 컬렉션 검색)
      if (appData == null && missionAppName.isNotEmpty) {
        AppLogger.info('🔍 앱 이름으로 조회 시작 - appName: $missionAppName', 'MissionDetailPage');

        // 2-1. provider_apps 컬렉션에서 앱 이름으로 검색
        final querySnapshot = await FirebaseFirestore.instance
            .collection('provider_apps')
            .where('appName', isEqualTo: missionAppName)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          appData = querySnapshot.docs.first.data();
          detectedProviderId = appData['providerId'] ?? appData['createdBy'];
          AppLogger.info('✅ App details loaded from provider_apps by name', 'MissionDetailPage');
        } else {
          AppLogger.info('❌ provider_apps에서 미발견, apps 컬렉션 시도', 'MissionDetailPage');

          // 2-2. apps 컬렉션에서 검색
          final fallbackQuery = await FirebaseFirestore.instance
              .collection('apps')
              .where('name', isEqualTo: missionAppName)
              .limit(1)
              .get();

          if (fallbackQuery.docs.isNotEmpty) {
            appData = fallbackQuery.docs.first.data();
            detectedProviderId = appData['providerId'] ?? appData['createdBy'];
            AppLogger.info('✅ App details loaded from apps collection by name', 'MissionDetailPage');
          } else {
            AppLogger.info('❌ apps에서 미발견, projects 컬렉션 시도', 'MissionDetailPage');

            // 2-3. projects 컬렉션에서 검색 (새로 추가)
            final projectQuery = await FirebaseFirestore.instance
                .collection('projects')
                .where('appName', isEqualTo: missionAppName)
                .limit(1)
                .get();

            if (projectQuery.docs.isNotEmpty) {
              appData = projectQuery.docs.first.data();
              detectedProviderId = appData['providerId'] ?? appData['createdBy'];
              AppLogger.info('✅ App details loaded from projects collection by name', 'MissionDetailPage');
            } else {
              AppLogger.warning('❌ 모든 컬렉션에서 appName으로 미발견: $missionAppName', 'MissionDetailPage');
            }
          }
        }
      }

      setState(() {
        _appDetails = appData;
        // detectedProviderId를 appDetails에 추가
        if (appData != null && detectedProviderId != null) {
          _appDetails!['detectedProviderId'] = detectedProviderId;
        }
      });

      // 결과 로깅 강화
      debugPrint('🔍 [_loadAppDetails] 결과');
      debugPrint('   ├─ appData != null: ${appData != null}');
      debugPrint('   ├─ detectedProviderId: $detectedProviderId');
      debugPrint('   └─ 최종 providerId getter: ${this.providerId}');

      if (appData != null && detectedProviderId != null) {
        AppLogger.info('🎉 providerId 조회 성공: $detectedProviderId', 'MissionDetailPage');
        AppLogger.info('📊 앱 데이터 필드: ${appData.keys.toList()}', 'MissionDetailPage');
      } else if (appData == null) {
        AppLogger.warning('❌ 앱 데이터 미발견 - AppId: $appId, AppName: $missionAppName', 'MissionDetailPage');
      } else {
        AppLogger.warning('⚠️ 앱 데이터는 있지만 providerId 누락 - AppId: $appId', 'MissionDetailPage');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [_loadAppDetails] 에러 발생!');
      debugPrint('   에러: $e');
      debugPrint('   스택: $stackTrace');
      AppLogger.error('Failed to load app details', 'MissionDetailPage', e);
    }
  }

  // 미션 신청 상태 확인
  Future<void> _checkApplicationStatus() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    setState(() {
      _isLoadingApplicationStatus = true;
    });

    try {
      // 중복 신청 체크
      final hasApplied = await MissionService.hasUserApplied(missionId, authState.user!.uid);

      if (hasApplied) {
        // 신청 상태 조회
        String applicationStatus = await _getApplicationStatus(authState.user!.uid);

        // not_applied가 아닌 경우에만 hasAlreadyApplied를 true로 설정
        if (applicationStatus != 'not_applied') {
          setState(() {
            _hasAlreadyApplied = true;
            _applicationStatus = applicationStatus;
          });
        }

        AppLogger.info('신청 상태 확인: $_applicationStatus', 'MissionDetailPage');
      }
    } catch (e) {
      AppLogger.error('신청 상태 확인 실패', 'MissionDetailPage', e);
    } finally {
      setState(() {
        _isLoadingApplicationStatus = false;
      });
    }
  }

  // 신청 상태 조회 (개선된 로직)
  Future<String> _getApplicationStatus(String testerId) async {
    try {
      AppLogger.info('🔍 신청 상태 조회 시작 - testerId: $testerId, missionId: $missionId', 'MissionDetailPage');

      // 1순위: mission_workflows 컬렉션에서 missionId 기준으로 직접 조회
      final workflowQuery = await FirebaseFirestore.instance
          .collection('mission_workflows')
          .where('missionId', isEqualTo: missionId)
          .where('testerId', isEqualTo: testerId)
          .limit(1)
          .get();

      if (workflowQuery.docs.isNotEmpty) {
        final data = workflowQuery.docs.first.data();
        final status = data['status'] ?? data['currentState'] ?? 'pending';
        AppLogger.info('✅ mission_workflows에서 상태 발견: $status', 'MissionDetailPage');
        return status;
      }

      // 2순위: mission_workflows 컬렉션에서 appId 기준으로 조회 (하위 호환성)
      final mission = await MissionService.getMission(missionId);
      if (mission?.appId != null) {
        final appBasedQuery = await FirebaseFirestore.instance
            .collection('mission_workflows')
            .where('appId', isEqualTo: mission!.appId)
            .where('testerId', isEqualTo: testerId)
            .limit(1)
            .get();

        if (appBasedQuery.docs.isNotEmpty) {
          final data = appBasedQuery.docs.first.data();
          final status = data['status'] ?? data['currentState'] ?? 'pending';
          AppLogger.info('✅ mission_workflows(appId)에서 상태 발견: $status', 'MissionDetailPage');
          return status;
        }
      }

      // 3순위: mission_applications 컬렉션 확인 (기존 호환성)
      final applicationQuery = await FirebaseFirestore.instance
          .collection('mission_applications')
          .where('missionId', isEqualTo: missionId)
          .where('testerId', isEqualTo: testerId)
          .limit(1)
          .get();

      if (applicationQuery.docs.isNotEmpty) {
        final status = applicationQuery.docs.first.data()['status'] ?? 'pending';
        AppLogger.info('✅ mission_applications에서 상태 발견: $status', 'MissionDetailPage');
        return status;
      }

      AppLogger.info('❌ 모든 컬렉션에서 신청 데이터를 찾을 수 없음', 'MissionDetailPage');
      return 'not_applied';
    } catch (e) {
      AppLogger.error('신청 상태 조회 실패', 'MissionDetailPage', e);
      return 'unknown';
    }
  }

  // 신청 상태 한글 번역 함수
  String _translateApplicationStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '검토 중';
      case 'reviewing':
        return '검토 중';
      case 'approved':
        return '승인됨';
      case 'accepted':
        return '승인됨';
      case 'rejected':
        return '거부됨';
      case 'declined':
        return '거부됨';
      case 'in_progress':
        return '진행 중';
      case 'completed':
        return '완료됨';
      case 'not_applied':
        return '미신청';
      case 'unknown':
        return '확인 중';
      default:
        return '확인 중';
    }
  }

  // 상태별 색상 반환 함수
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'reviewing':
        return const Color(0xFFFF9800); // Material Orange 500
      case 'approved':
      case 'accepted':
        return const Color(0xFF4CAF50); // Material Green 500
      case 'rejected':
      case 'declined':
        return const Color(0xFFF44336); // Material Red 500
      case 'in_progress':
        return const Color(0xFF2196F3); // Material Blue 500
      case 'completed':
        return const Color(0xFF9C27B0); // Material Purple 500
      case 'not_applied':
        return const Color(0xFF757575); // Material Grey 600
      case 'unknown':
      default:
        return const Color(0xFF9E9E9E); // Material Grey 500
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
            // v2.121.0: 앱 스크린샷 갤러리
            if (_appDetails?['screenshots'] != null &&
                (_appDetails!['screenshots'] as List).isNotEmpty) ...[
              SizedBox(height: 20.h),
              _buildAppScreenshots(),
            ],
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
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  missionCategory,
                  style: TextStyle(
                    color: Colors.orange[800],
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
              fontSize: 20.responsiveFont(context),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            missionAppName,
            style: TextStyle(
              fontSize: 16.responsiveFont(context),
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
              Icon(Icons.info_outline, color: Colors.orange[700], size: 20.w),
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
                  '$estimatedMinutes분',
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
        Icon(icon, color: Colors.orange[600], size: 20.w),
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
                      color: Colors.orange[600],
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
              color: Colors.orange[600],
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

  // v2.121.0: 앱 스크린샷 갤러리
  Widget _buildAppScreenshots() {
    final screenshots = (_appDetails?['screenshots'] as List?)?.cast<String>() ?? [];

    if (screenshots.isEmpty) {
      return const SizedBox.shrink();
    }

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
              Icon(Icons.photo_library, color: Colors.orange[700], size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '앱 스크린샷',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 140.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: screenshots.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showFullscreenImage(screenshots, index),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < screenshots.length - 1 ? 8.w : 0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        screenshots[index],
                        height: 140.h,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 80.w,
                            height: 140.h,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80.w,
                            height: 140.h,
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                     color: Colors.grey[400],
                                     size: 30.w),
                                SizedBox(height: 4.h),
                                Text(
                                  '로드 실패',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // v2.121.0: 전체 화면 이미지 뷰어
  void _showFullscreenImage(List<String> screenshots, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: screenshots.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      screenshots[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                   color: Colors.white54,
                                   size: 60.w),
                              SizedBox(height: 16.h),
                              Text(
                                '이미지 로드 실패',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 40.h,
              right: 20.w,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30.w),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
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
              Icon(Icons.apps, color: Colors.orange[700], size: 20.w),
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
            _buildAppLinkRow('앱 설치 링크', _appDetails!['appUrl']), // v2.186.36: 복사 + 바로가기 버튼 추가
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
                '💰 리워드 정보',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // 고급보상시스템이 있는 경우 상세 표시
          if (hasAdvancedRewardSystem) ...[
            _buildAdvancedRewardDetails(),
            SizedBox(height: 12.h),
            Divider(color: Colors.grey[300]),
            SizedBox(height: 12.h),
          ],

          // 총 포인트 표시
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
                  '총 리워드: ',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${NumberFormat('#,###').format(hasAdvancedRewardSystem ? totalAdvancedReward : missionReward)}P',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // v2.112.0: Simplified reward details - removed daily mission rewards
  Widget _buildAdvancedRewardDetails() {
    return Column(
      children: [
        // v2.112.0: Only showing final completion reward (no daily rewards)
        if (finalCompletionPoints > 0 || bonusPoints > 0)
          _buildRewardRow(
            '완료 리워드',
            finalCompletionPoints + bonusPoints,
            Icons.check_circle,
            Colors.green,
            '완료 ${NumberFormat('#,###').format(finalCompletionPoints)}P + 추가 ${NumberFormat('#,###').format(bonusPoints)}P',
          ),
      ],
    );
  }

  // 보상 항목 행 위젯
  Widget _buildRewardRow(String label, int amount, IconData icon, Color color, String detail) {
    if (amount <= 0) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16.w),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${NumberFormat('#,###').format(amount)}P',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
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
          // v2.122.2: 공급자가 입력한 테스트 기간과 시간 표시
          _buildDetailRow(
            '테스트 기간',
            '${_appDetails?['testPeriodDays'] ?? metadata['testPeriod'] ?? 14}일'
          ),
          _buildDetailRow(
            '예상 소요시간',
            '${_appDetails?['testTimeMinutes'] ?? metadata['testTime'] ?? 30}분'
          ),
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

  // v2.186.36: 앱 링크 행 (복사 + 바로가기 버튼 포함)
  Widget _buildAppLinkRow(String label, String url) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    url,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  icon: Icon(Icons.copy, size: 18.w, color: Colors.blue[700]),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('링크가 복사되었습니다'),
                        backgroundColor: Colors.blue,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: '링크 복사',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 32.w,
                    minHeight: 32.w,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.open_in_new, size: 18.w, color: Colors.blue[700]),
                  onPressed: () async {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('링크를 열 수 없습니다'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  tooltip: '링크 열기',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 32.w,
                    minHeight: 32.w,
                  ),
                ),
              ],
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
                  '총 리워드',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${NumberFormat('#,###').format(hasAdvancedRewardSystem ? totalAdvancedReward : missionReward)}P',
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
          height: context.isMobile ? 56.h : 48.h, // 모바일에서 더 큰 버튼
          child: ElevatedButton(
            onPressed: _getButtonAction(authState, isFull),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getButtonColor(isFull),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: _isApplying || _isLoadingApplicationStatus
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Text(
                    _getButtonText(isFull),
                    style: TextStyle(
                      fontSize: 16.responsiveFont(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // 버튼 액션 결정
  VoidCallback? _getButtonAction(AuthState authState, bool isFull) {
    if (_isApplying || _isLoadingApplicationStatus || isFull) {
      return null;
    }

    if (_hasAlreadyApplied) {
      // 이미 신청한 경우 신청 현황 페이지로 이동
      return () => _navigateToApplicationStatus();
    }

    // 신청 가능한 경우
    return () => _applyToMission(authState);
  }

  // 버튼 색상 결정
  Color _getButtonColor(bool isFull) {
    if (isFull) {
      return Colors.grey[400]!;
    }

    if (_hasAlreadyApplied) {
      switch (_applicationStatus) {
        case 'pending':
          return Colors.amber[700]!;
        case 'approved':
        case 'active':
          return Colors.green[600]!;
        case 'rejected':
          return Colors.red[600]!;
        default:
          return Colors.orange[600]!;
      }
    }

    return Colors.orange[600]!;
  }

  // 버튼 텍스트 결정
  String _getButtonText(bool isFull) {
    if (isFull) {
      return '모집 완료';
    }

    if (_hasAlreadyApplied) {
      switch (_applicationStatus) {
        case 'pending':
          return '신청 검토중';
        case 'approved':
        case 'active':
          return '신청 현황 보기';
        case 'rejected':
          return '신청 거부됨';
        case 'not_applied':
          return '미션 신청하기';
        default:
          return '미션 신청하기';
      }
    }

    return '미션 신청하기';
  }

  // 신청 현황 페이지로 이동
  void _navigateToApplicationStatus() {
    final translatedStatus = _translateApplicationStatus(_applicationStatus ?? 'unknown');
    final statusColor = _getStatusColor(_applicationStatus ?? 'unknown');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text('신청 상태: $translatedStatus'),
          ],
        ),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 3),
      ),
    );

    // TODO: 신청 현황 페이지 구현 후 Navigation 추가
    // Navigator.pushNamed(context, '/application-status', arguments: missionId);
  }

  // v2.179.0: 미션 신청 약관 동의 모달 표시
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

    // v2.179.0: 약관 동의 및 구글 메일 입력 모달 표시
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => MissionApplicationTermsDialog(
        missionName: missionAppName,
        testerEmail: ref.read(currentUserProvider)?.email, // v2.186.38: Gmail 자동 입력
      ),
    );

    // 모달을 닫았거나 동의하지 않은 경우
    if (result == null || result['agreed'] != true) {
      return;
    }

    final googleEmail = result['googleEmail'] as String?;
    if (googleEmail == null || googleEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('구글 메일 주소가 필요합니다.'),
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

      // providerId 검증 및 조회
      String finalProviderId = providerId;
      if (finalProviderId.isEmpty) {
        debugPrint('⚠️ providerId가 비어있음! missions 컬렉션에서 조회 시도');

        // missions 컬렉션에서 providerId 조회
        try {
          final missionDoc = await FirebaseFirestore.instance
              .collection('missions')
              .doc(missionId)
              .get();

          if (missionDoc.exists) {
            final missionData = missionDoc.data();
            finalProviderId = missionData?['providerId'] ?? missionData?['createdBy'] ?? '';
            debugPrint('✅ missions에서 providerId 조회 성공: $finalProviderId');
          }
        } catch (e) {
          debugPrint('❌ missions 조회 실패: $e');
        }
      }

      // 최종 검증
      if (finalProviderId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('공급자 정보를 찾을 수 없습니다. 관리자에게 문의하세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 공급자 이름 가져오기
      String providerName = 'Unknown Provider';
      try {
        final providerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(finalProviderId)
            .get();
        if (providerDoc.exists) {
          final data = providerDoc.data() as Map<String, dynamic>;
          providerName = data['displayName'] ?? data['name'] ?? 'Unknown Provider';
        }
      } catch (e) {
        debugPrint('Provider name lookup failed: $e');
      }

      // v2.179.0: googleEmail 추가
      final applicationData = {
        'missionId': missionId,
        'testerId': authState.user!.uid,
        'providerId': finalProviderId,  // 검증된 providerId 사용
        'providerName': providerName,
        'testerName': authState.user!.displayName,
        'testerEmail': authState.user!.email,
        'googleEmail': googleEmail, // v2.179.0: 구글플레이 테스터 등록용
        'missionName': missionAppName,
        'status': 'pending',
        'message': '미션에 참여하고 싶습니다.',
        'appliedAt': DateTime.now(),
        'dailyReward': missionReward,
        // v2.186.24: totalDays 제거 → mission_workflow_service가 projects.testPeriodDays에서 자동 조회
        'requirements': requiredSkills,
        'testerInfo': {
          'userType': authState.user!.primaryRole.toString(),
          'experience': 'beginner',
          'name': authState.user!.displayName,
          'email': authState.user!.email,
          'googleEmail': googleEmail, // v2.179.0: 구글플레이 테스터 등록용
          'motivation': '새로운 앱을 테스트하며 버그를 찾는 것에 관심이 있습니다.',
        },
      };

      debugPrint('🎯 UI - 미션 신청 버튼 클릭됨! missionId: $missionId');
      debugPrint('🎯 UI - testerId: ${authState.user!.uid}');
      debugPrint('🎯 UI - providerId (검증 후): $finalProviderId');

      await missionService.applyToMission(missionId, applicationData);

      AppLogger.info('미션 신청 호출 완료', 'MissionDetailPage');

      if (mounted) {
        // 신청 성공 후 상태 새로고침
        await _checkApplicationStatus();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('미션 신청이 완료되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
          // 미션 신청 성공 시 진행중 탭으로 이동하라는 정보 전달
          Navigator.pop(context, {'success': true, 'navigateToTab': 1}); // 1번 탭은 '진행 중'
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        Color backgroundColor = Colors.red;

        // 중복 신청 에러인 경우 특별 처리
        if (errorMessage.contains('이미 신청한 미션입니다')) {
          errorMessage = '이미 신청하신 미션입니다. 신청 현황을 확인해보세요.';
          backgroundColor = Colors.orange;

          // 신청 상태 새로고침
          await _checkApplicationStatus();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 4),
            ),
          );
        }
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