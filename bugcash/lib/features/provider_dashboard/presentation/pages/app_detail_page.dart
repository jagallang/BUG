import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/constants/app_colors.dart';
import 'app_management_page.dart';

class AppDetailPage extends ConsumerStatefulWidget {
  final ProviderAppModel app;

  const AppDetailPage({
    super.key,
    required this.app,
  });

  @override
  ConsumerState<AppDetailPage> createState() => _AppDetailPageState();
}

class _AppDetailPageState extends ConsumerState<AppDetailPage> {
  late TextEditingController _appNameController;
  late TextEditingController _appUrlController;
  late TextEditingController _descriptionController;
  late TextEditingController _announcementController;
  late TextEditingController _requirementsController;
  late TextEditingController _participantCountController;
  late TextEditingController _testPeriodController;
  late TextEditingController _testTimeController;

  // 새 필드 컨트롤러들
  late TextEditingController _minExperienceController;
  late TextEditingController _specialRequirementsController;
  late TextEditingController _testingGuidelinesController;
  late TextEditingController _minOSVersionController;
  late TextEditingController _appStoreUrlController;
  // v2.112.0: dailyMissionPoints controller removed (reward system simplification)
  late TextEditingController _finalCompletionPointsController;
  late TextEditingController _bonusPointsController;

  late String _selectedCategory;
  late String _selectedType;
  late String _selectedDifficulty;
  late String _selectedInstallType;
  late String _selectedDailyTestTime;
  late String _selectedApprovalCondition;

  bool _hasAnnouncement = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'Productivity',
    'Social',
    'Entertainment',
    'Education',
    'Health & Fitness',
    'Finance',
    'Shopping',
    'Travel',
    'Food & Drink',
    'Games',
    'Other',
  ];

  final List<String> _types = ['app', 'website', 'service'];
  final List<String> _difficulties = ['easy', 'medium', 'hard', 'expert'];
  final List<String> _installTypes = ['play_store', 'apk_upload'];
  // v2.43.2: 5분 단위로 20분까지 제한
  final List<String> _dailyTestTimes = ['5분', '10분', '15분', '20분'];
  // v2.43.6: 스크린샷 필수만 남기고 나머지 주석처리
  final List<String> _approvalConditions = [
    '스크린샷 필수',
    // '녹화영상 필수',
    // '스크린샷+녹화영상'
  ];

  // 레거시 카테고리를 새 카테고리로 매핑하는 함수
  String _mapLegacyCategory(String? category) {
    const mapping = {
      'functional': 'Productivity',
      'ui_ux': 'Social',
      'performance': 'Productivity',
      'security': 'Other',
      'compatibility': 'Other',
      'crash': 'Other',
      'other': 'Other',
    };

    if (category == null) return _categories.first;

    // 이미 새 카테고리 형식인 경우 그대로 사용 (유효성 검증)
    if (_categories.contains(category)) {
      return category;
    }

    // 레거시 카테고리 매핑
    return mapping[category.toLowerCase()] ?? _categories.first;
  }

  // 드롭다운 값이 유효한지 확인하고 안전한 값 반환
  String _getSafeDropdownValue(String? value, List<String> options, {String? defaultValue}) {
    if (value == null || !options.contains(value)) {
      return defaultValue ?? options.first;
    }
    return value;
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _appNameController = TextEditingController(text: widget.app.appName);
    _appUrlController = TextEditingController(text: widget.app.appUrl);
    _descriptionController =
        TextEditingController(text: widget.app.description);
    _selectedCategory = _mapLegacyCategory(widget.app.category);

    // 기존 메타데이터에서 정보 가져오기
    final metadata = widget.app.metadata;
    _hasAnnouncement = metadata['hasAnnouncement'] ?? false;
    // v2.43.2: isActive는 앱관리 탭에서 관리하므로 여기서는 제거
    _announcementController =
        TextEditingController(text: metadata['announcement'] ?? '');
    _requirementsController =
        TextEditingController(text: metadata['requirements'] ?? '');
    // v2.170.0: projects 문서의 실제 값 사용 (하드코딩 제거)
    _participantCountController = TextEditingController(
        text: (metadata['maxTesters'] ?? metadata['participantCount'] ?? 10).toString());
    _testPeriodController =
        TextEditingController(text: (metadata['testPeriodDays'] ?? metadata['testPeriod'] ?? 14).toString());
    _testTimeController =
        TextEditingController(text: (metadata['testTimeMinutes'] ?? metadata['testTime'] ?? 30).toString());

    // 새 필드들 초기화 (안전한 드롭다운 값 설정)
    _selectedType = _getSafeDropdownValue(metadata['type'], _types);
    _selectedDifficulty =
        _getSafeDropdownValue(metadata['difficulty'], _difficulties);
    _selectedInstallType =
        _getSafeDropdownValue(metadata['installType'], _installTypes);
    // v2.43.6: 디폴트 10분으로 설정
    _selectedDailyTestTime =
        _getSafeDropdownValue(metadata['dailyTestTime'], _dailyTestTimes, defaultValue: '10분');
    _selectedApprovalCondition = _getSafeDropdownValue(
        metadata['approvalCondition'], _approvalConditions);

    _minExperienceController =
        TextEditingController(text: metadata['minExperience'] ?? '');
    _specialRequirementsController =
        TextEditingController(text: metadata['specialRequirements'] ?? '');
    _testingGuidelinesController =
        TextEditingController(text: metadata['testingGuidelines'] ?? '');
    _minOSVersionController =
        TextEditingController(text: metadata['minOSVersion'] ?? '');
    _appStoreUrlController =
        TextEditingController(text: metadata['appStoreUrl'] ?? '');

    // v2.112.0: Reward system simplification - Only finalCompletionPoints remains
    // 보상 시스템 필드들 - rewards 객체 우선, metadata 폴백
    final rewards = metadata['rewards'] as Map<String, dynamic>?;
    final legacyPrice = metadata['price'] as int?;

    // 안전한 디버깅 로그 추가
    debugPrint('🔍 AppDetailPage 데이터 로딩 - ${widget.app.appName}');
    debugPrint('📋 metadata keys: ${metadata.keys.toList()}');
    debugPrint('🎁 rewards: $rewards');
    debugPrint('💰 legacyPrice: $legacyPrice');

    // v2.112.0: dailyMissionPoints removed, only finalCompletionPoints used
    final finalCompletionPoints = rewards?['finalCompletionPoints'] as int? ??
        metadata['finalCompletionPoints'] as int? ??
        (legacyPrice != null ? (legacyPrice * 0.6).round() : 1000);
    final bonusPoints = rewards?['bonusPoints'] as int? ??
        metadata['bonusPoints'] as int? ??
        (legacyPrice != null ? (legacyPrice * 0.3).round() : 500);

    // 최종 계산된 값들 로그
    debugPrint('📊 최종 보상 값 계산됨 (v2.112.0):');
    debugPrint('   finalCompletionPoints: $finalCompletionPoints');
    debugPrint('   bonusPoints: $bonusPoints');

    _finalCompletionPointsController =
        TextEditingController(text: finalCompletionPoints.toString());
    _bonusPointsController =
        TextEditingController(text: bonusPoints.toString());
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _appUrlController.dispose();
    _descriptionController.dispose();
    _announcementController.dispose();
    _requirementsController.dispose();
    _participantCountController.dispose();
    _testPeriodController.dispose();
    _testTimeController.dispose();

    // 새 컨트롤러들 dispose
    _minExperienceController.dispose();
    _specialRequirementsController.dispose();
    _testingGuidelinesController.dispose();
    _minOSVersionController.dispose();
    _appStoreUrlController.dispose();
    // v2.112.0: dailyMissionPointsController removed
    _finalCompletionPointsController.dispose();
    _bonusPointsController.dispose();

    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_appNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _participantCountController.text.isEmpty ||
        _testPeriodController.text.isEmpty ||
        _testTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 필드를 모두 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 참여자 수 검증
      final participantCount = int.tryParse(_participantCountController.text);
      if (participantCount == null || participantCount < 1) {
        throw Exception('참여자 수는 1명 이상이어야 합니다');
      }

      // 테스트 기간 검증 (v2.18.0: 최대 20일 제한)
      final testPeriod = int.tryParse(_testPeriodController.text);
      if (testPeriod == null || testPeriod < 1) {
        throw Exception('테스트 기간은 1일 이상이어야 합니다');
      }
      if (testPeriod > 20) {
        throw Exception('테스트 기간은 최대 20일까지 설정 가능합니다');
      }

      // 테스트 시간 검증
      final testTime = int.tryParse(_testTimeController.text);
      if (testTime == null || testTime < 1) {
        throw Exception('테스트 시간은 1분 이상이어야 합니다');
      }

      // v2.112.0: Simplified reward system validation - only finalCompletionPoints
      final finalCompletionPoints =
          int.tryParse(_finalCompletionPointsController.text);
      final bonusPoints = int.tryParse(_bonusPointsController.text);

      if (finalCompletionPoints == null || finalCompletionPoints < 0) {
        throw Exception('올바른 최종 완료 포인트를 입력해주세요');
      }
      if (bonusPoints == null || bonusPoints < 0) {
        throw Exception('올바른 보너스 포인트를 입력해주세요');
      }

      final updatedData = {
        'appName': _appNameController.text,
        'appUrl': _appUrlController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'totalTesters': participantCount, // maxTesters와 동기화
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': {
          ...widget.app.metadata,
          // 기존 필드들
          'hasAnnouncement': _hasAnnouncement,
          'announcement': _hasAnnouncement ? _announcementController.text : '',
          'requirements': _requirementsController.text,
          'participantCount': participantCount,
          'testPeriod': testPeriod,
          'testTime': testTime,
          // v2.43.2: isActive는 앱관리 탭에서 관리

          // 앱 등록 폼과 동기화된 새 필드들
          'type': _selectedType,
          'difficulty': _selectedDifficulty,
          'installType': _selectedInstallType,
          'dailyTestTime': _selectedDailyTestTime,
          'approvalCondition': _selectedApprovalCondition,

          // 추가 필수 필드들
          'minExperience': _minExperienceController.text,
          'specialRequirements': _specialRequirementsController.text,
          'testingGuidelines': _testingGuidelinesController.text,
          'minOSVersion': _minOSVersionController.text,
          'appStoreUrl': _appStoreUrlController.text,

          // v2.112.0: Simplified reward system - removed dailyMissionPoints
          'finalCompletionPoints': finalCompletionPoints,
          'bonusPoints': bonusPoints,

          // 최대 테스터 수 (totalTesters와 동기화)
          'maxTesters': participantCount,
        },

        // v2.112.0: Simplified rewards object - removed dailyMissionPoints
        'rewards': {
          'finalCompletionPoints': finalCompletionPoints,
          'bonusPoints': bonusPoints,
        },
      };

      // 문서 존재 여부 확인 후 업데이트
      final docRef =
          FirebaseFirestore.instance.collection('projects').doc(widget.app.id);

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception('문서를 찾을 수 없습니다. ID: ${widget.app.id}');
      }

      await docRef.update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('앱 정보가 성공적으로 업데이트되었습니다')),
        );
        Navigator.of(context).pop(true); // 변경사항이 있음을 알림
      }
    } catch (e) {
      AppLogger.error('Failed to update app', e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업데이트 실패: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.providerBluePrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppColors.providerBluePrimary.withOpacity(0.3),
        title: Text(
          '앱 게시 관리',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: Text(
              '저장',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppInfoSection(),
                  SizedBox(height: 24.h),
                  // v2.43.2: _buildStatusSection() 제거 (앱 게시 상태는 앱관리 탭에서 관리)
                  // v2.43.3: _buildTestTypeSection() 제거
                  // v2.43.4: _buildAnnouncementSection() 제거 (앱 공지사항 제거)
                  _buildAdvancedRewardSection(),
                  SizedBox(height: 24.h),
                  _buildTestConfigSection(),
                  SizedBox(height: 24.h),
                  _buildNewFeaturesSection(),
                  SizedBox(height: 24.h),
                  _buildRequirementsSection(),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
    );
  }

  // v2.43.2: _buildStatusSection() 제거 (앱 게시 상태는 앱관리 탭에서 관리)

  Widget _buildAppInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📱 앱 기본 정보',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.providerBlueDark,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _appNameController,
              decoration: InputDecoration(
                labelText: '앱 이름 *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.apps),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _appUrlController,
              decoration: InputDecoration(
                labelText: '앱 URL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.link),
              ),
            ),
            SizedBox(height: 16.h),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '앱 설명 *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // v2.43.4: _buildAnnouncementSection() 제거 (앱 공지사항 제거)

  Widget _buildAdvancedRewardSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💰 리워드 지급',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.providerBlueDark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '테스터에게 지급할 리워드를 설정하세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            // v2.112.0: Only finalCompletionPoints field (dailyMissionPoints removed)
            Row(
              children: [
                // 프로젝트 종료 포인트
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _finalCompletionPointsController,
                          keyboardType: TextInputType.number,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: '종료시 추가지급',
                            suffix: Text('P', style: TextStyle(color: Colors.green[700])),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                            prefixIcon: const Icon(Icons.check_circle),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Column(
                        children: [
                          SizedBox(
                            width: 32.w,
                            height: 24.h,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.arrow_drop_up, size: 24.sp),
                              onPressed: () {
                                int current = int.tryParse(_finalCompletionPointsController.text) ?? 0;
                                setState(() {
                                  _finalCompletionPointsController.text = (current + 100).toString();
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 32.w,
                            height: 24.h,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.arrow_drop_down, size: 24.sp),
                              onPressed: () {
                                int current = int.tryParse(_finalCompletionPointsController.text) ?? 0;
                                if (current > 0) {
                                  setState(() {
                                    _finalCompletionPointsController.text = (current - 100).toString();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestConfigSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚙️ 테스트 설정',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.providerBlueDark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '테스트 참여자 수, 기간, 시간을 설정하세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            // v2.43.5: 3개 필드를 가로로 한 줄 배치
            Row(
              children: [
                // 참여자 수
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _participantCountController,
                          keyboardType: TextInputType.number,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: '참여자 수',
                            suffix: Text('명', style: TextStyle(color: Colors.indigo[700])),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                            prefixIcon: const Icon(Icons.people),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Column(
                        children: [
                          SizedBox(
                            width: 32.w,
                            height: 24.h,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.arrow_drop_up, size: 24.sp),
                              onPressed: () {
                                int current = int.tryParse(_participantCountController.text) ?? 1;
                                if (current < 20) {
                                  setState(() {
                                    _participantCountController.text = (current + 1).toString();
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: 32.w,
                            height: 24.h,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.arrow_drop_down, size: 24.sp),
                              onPressed: () {
                                int current = int.tryParse(_participantCountController.text) ?? 1;
                                if (current > 1) {
                                  setState(() {
                                    _participantCountController.text = (current - 1).toString();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // 테스트 기간
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _testPeriodController,
                          keyboardType: TextInputType.number,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: '테스트 기간',
                            suffix: Text('일', style: TextStyle(color: Colors.indigo[700])),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Column(
                        children: [
                          SizedBox(
                            width: 32.w,
                            height: 24.h,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.arrow_drop_up, size: 24.sp),
                              onPressed: () {
                                int current = int.tryParse(_testPeriodController.text) ?? 1;
                                if (current < 30) {
                                  setState(() {
                                    _testPeriodController.text = (current + 1).toString();
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: 32.w,
                            height: 24.h,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.arrow_drop_down, size: 24.sp),
                              onPressed: () {
                                int current = int.tryParse(_testPeriodController.text) ?? 1;
                                if (current > 1) {
                                  setState(() {
                                    _testPeriodController.text = (current - 1).toString();
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // 일일 테스트 시간
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _getSafeDropdownValue(_selectedDailyTestTime, _dailyTestTimes),
                    isExpanded: true,
                    items: _dailyTestTimes.map((time) {
                      return DropdownMenuItem(
                        value: time,
                        child: Text(time),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDailyTestTime = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: '일일 테스트 시간',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      prefixIcon: const Icon(Icons.access_time),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ 주의사항',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.providerBlueDark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '테스터가 알아야 할 주의사항이나 특별 지시사항을 입력하세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _requirementsController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: '주의사항',
                hintText: '예: 특정 기기에서 테스트, 특정 기능 집중 테스트 등...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.warning_amber),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // v2.43.3: _buildTestTypeSection() 제거 (테스트 유형 설정 항목 제거)

  Widget _buildNewFeaturesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 앱테스트 가이드라인',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.providerBlueDark,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '테스터가 따라야 할 가이드라인과 승인 조건을 설정하세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            // v2.43.4: 승인 조건만 남김
            DropdownButtonFormField<String>(
              value: _selectedApprovalCondition,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: '승인 조건',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r)),
                prefixIcon: const Icon(Icons.check_circle),
              ),
              items: _approvalConditions.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(condition),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedApprovalCondition = value!;
                });
              },
            ),
            SizedBox(height: 16.h),
            // v2.43.4: 테스팅 가이드라인만 남김
            TextField(
              controller: _testingGuidelinesController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: '테스팅 가이드라인',
                hintText: '테스터가 따라야 할 구체적인 테스팅 지침을 작성하세요',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r)),
                prefixIcon: const Icon(Icons.assignment),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
