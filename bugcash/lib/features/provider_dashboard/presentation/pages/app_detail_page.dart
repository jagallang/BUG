import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/logger.dart';
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
  late TextEditingController _priceController;
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
  late TextEditingController _baseRewardController;
  late TextEditingController _bonusRewardController;
  late TextEditingController _dailyMissionPointsController;
  late TextEditingController _finalCompletionPointsController;
  late TextEditingController _bonusPointsController;

  late String _selectedCategory;
  late String _selectedType;
  late String _selectedDifficulty;
  late String _selectedInstallType;
  late String _selectedDailyTestTime;
  late String _selectedApprovalCondition;

  bool _hasAnnouncement = false;
  bool _isActive = true;
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
  final List<String> _dailyTestTimes = ['10분', '20분', '30분', '45분', '60분', '90분', '120분'];
  final List<String> _approvalConditions = ['스크린샷 필수', '녹화영상 필수', '스크린샷+녹화영상'];

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
  String _getSafeDropdownValue(String? value, List<String> options) {
    if (value == null || !options.contains(value)) {
      return options.first;
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
    _descriptionController = TextEditingController(text: widget.app.description);
    _selectedCategory = _mapLegacyCategory(widget.app.category);

    // 기존 메타데이터에서 정보 가져오기
    final metadata = widget.app.metadata;
    _hasAnnouncement = metadata['hasAnnouncement'] ?? false;
    _isActive = metadata['isActive'] ?? true;
    _announcementController = TextEditingController(text: metadata['announcement'] ?? '');
    _priceController = TextEditingController(text: (metadata['price'] ?? 0).toString());
    _requirementsController = TextEditingController(text: metadata['requirements'] ?? '');
    _participantCountController = TextEditingController(text: (metadata['participantCount'] ?? widget.app.totalTesters ?? 1).toString());
    _testPeriodController = TextEditingController(text: (metadata['testPeriod'] ?? 14).toString());
    _testTimeController = TextEditingController(text: (metadata['testTime'] ?? 30).toString());

    // 새 필드들 초기화 (안전한 드롭다운 값 설정)
    _selectedType = _getSafeDropdownValue(metadata['type'], _types);
    _selectedDifficulty = _getSafeDropdownValue(metadata['difficulty'], _difficulties);
    _selectedInstallType = _getSafeDropdownValue(metadata['installType'], _installTypes);
    _selectedDailyTestTime = _getSafeDropdownValue(metadata['dailyTestTime'], _dailyTestTimes);
    _selectedApprovalCondition = _getSafeDropdownValue(metadata['approvalCondition'], _approvalConditions);

    _minExperienceController = TextEditingController(text: metadata['minExperience'] ?? '');
    _specialRequirementsController = TextEditingController(text: metadata['specialRequirements'] ?? '');
    _testingGuidelinesController = TextEditingController(text: metadata['testingGuidelines'] ?? '');
    _minOSVersionController = TextEditingController(text: metadata['minOSVersion'] ?? '');
    _appStoreUrlController = TextEditingController(text: metadata['appStoreUrl'] ?? '');

    // 보상 시스템 필드들
    _baseRewardController = TextEditingController(text: (metadata['baseReward'] ?? metadata['price'] ?? 5000).toString());
    _bonusRewardController = TextEditingController(text: (metadata['bonusReward'] ?? 2000).toString());
    _dailyMissionPointsController = TextEditingController(text: (metadata['dailyMissionPoints'] ?? 100).toString());
    _finalCompletionPointsController = TextEditingController(text: (metadata['finalCompletionPoints'] ?? 1000).toString());
    _bonusPointsController = TextEditingController(text: (metadata['bonusPoints'] ?? 500).toString());
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _appUrlController.dispose();
    _descriptionController.dispose();
    _announcementController.dispose();
    _priceController.dispose();
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
    _baseRewardController.dispose();
    _bonusRewardController.dispose();
    _dailyMissionPointsController.dispose();
    _finalCompletionPointsController.dispose();
    _bonusPointsController.dispose();

    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_appNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _baseRewardController.text.isEmpty ||
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
      // 기본 보상 검증
      final baseReward = double.tryParse(_baseRewardController.text);
      if (baseReward == null || baseReward < 0) {
        throw Exception('올바른 기본 보상을 입력해주세요');
      }

      // 보너스 보상 검증
      final bonusReward = double.tryParse(_bonusRewardController.text);
      if (bonusReward == null || bonusReward < 0) {
        throw Exception('올바른 보너스 보상을 입력해주세요');
      }

      // 참여자 수 검증
      final participantCount = int.tryParse(_participantCountController.text);
      if (participantCount == null || participantCount < 1) {
        throw Exception('참여자 수는 1명 이상이어야 합니다');
      }

      // 테스트 기간 검증
      final testPeriod = int.tryParse(_testPeriodController.text);
      if (testPeriod == null || testPeriod < 1) {
        throw Exception('테스트 기간은 1일 이상이어야 합니다');
      }

      // 테스트 시간 검증
      final testTime = int.tryParse(_testTimeController.text);
      if (testTime == null || testTime < 1) {
        throw Exception('테스트 시간은 1분 이상이어야 합니다');
      }

      // 포인트 시스템 검증
      final dailyMissionPoints = int.tryParse(_dailyMissionPointsController.text);
      final finalCompletionPoints = int.tryParse(_finalCompletionPointsController.text);
      final bonusPoints = int.tryParse(_bonusPointsController.text);

      if (dailyMissionPoints == null || dailyMissionPoints < 0) {
        throw Exception('올바른 일일 미션 포인트를 입력해주세요');
      }
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
        'totalTesters': participantCount,  // maxTesters와 동기화
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
          'isActive': _isActive,

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

          // 보상 시스템 (기본 보상으로 price 대체)
          'price': baseReward,  // 하위 호환성을 위해 유지
          'baseReward': baseReward,
          'bonusReward': bonusReward,
          'dailyMissionPoints': dailyMissionPoints,
          'finalCompletionPoints': finalCompletionPoints,
          'bonusPoints': bonusPoints,

          // 최대 테스터 수 (totalTesters와 동기화)
          'maxTesters': participantCount,
        },
      };

      await FirebaseFirestore.instance
          .collection('apps')
          .doc(widget.app.id)
          .update(updatedData);

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
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        title: Text(
          '앱 상세 관리',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
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
                  _buildStatusSection(),
                  SizedBox(height: 24.h),
                  _buildTestTypeSection(),
                  SizedBox(height: 24.h),
                  _buildAnnouncementSection(),
                  SizedBox(height: 24.h),
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

  Widget _buildStatusSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '🎯 앱 게시 상태',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeColor: Colors.green[700],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              _isActive
                  ? '현재 앱이 활성화되어 테스터들에게 표시됩니다'
                  : '현재 앱이 비활성화되어 테스터들에게 표시되지 않습니다',
              style: TextStyle(
                fontSize: 14.sp,
                color: _isActive ? Colors.green[600] : Colors.red[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                color: Colors.indigo[900],
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

  Widget _buildAnnouncementSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '📢 앱 공지사항',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _hasAnnouncement,
                  onChanged: (value) {
                    setState(() {
                      _hasAnnouncement = value;
                      if (!value) {
                        _announcementController.clear();
                      }
                    });
                  },
                  activeColor: Colors.indigo[700],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              _hasAnnouncement
                  ? '테스터들에게 보여질 공지사항을 작성하세요'
                  : '공지사항 기능을 활성화하려면 스위치를 켜세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            if (_hasAnnouncement) ...[
              SizedBox(height: 16.h),
              TextField(
                controller: _announcementController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: '공지사항 내용',
                  hintText: '테스터들에게 전달할 중요한 정보를 입력하세요...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  prefixIcon: const Icon(Icons.announcement),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedRewardSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💰 고급 보상 시스템',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '다양한 보상 체계를 설정하세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _baseRewardController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '기본 보상 *',
                      hintText: '5000',
                      suffix: Text('P', style: TextStyle(color: Colors.indigo[700])),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      prefixIcon: const Icon(Icons.monetization_on),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: TextField(
                    controller: _bonusRewardController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '보너스 보상',
                      hintText: '2000',
                      suffix: Text('P', style: TextStyle(color: Colors.indigo[700])),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      prefixIcon: const Icon(Icons.star),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dailyMissionPointsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '일일 미션 포인트',
                      hintText: '100',
                      suffix: Text('P', style: TextStyle(color: Colors.orange[700])),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      prefixIcon: const Icon(Icons.today),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _finalCompletionPointsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '최종 완료 포인트',
                      hintText: '1000',
                      suffix: Text('P', style: TextStyle(color: Colors.green[700])),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      prefixIcon: const Icon(Icons.check_circle),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _bonusPointsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '보너스 포인트',
                      hintText: '500',
                      suffix: Text('P', style: TextStyle(color: Colors.purple[700])),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      prefixIcon: const Icon(Icons.star),
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
                color: Colors.indigo[900],
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _participantCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '참여자 수 *',
                      hintText: '예: 5',
                      suffix: Text(
                        '명',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[700],
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      prefixIcon: const Icon(Icons.people),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: TextField(
                    controller: _testPeriodController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '테스트 기간 *',
                      hintText: '예: 14',
                      suffix: Text(
                        '일',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[700],
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _testTimeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '일일 테스트 시간 *',
                hintText: '예: 30',
                suffix: Text(
                  '분',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[700],
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.access_time),
              ),
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
              '📋 기타 요구사항',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '테스터가 알아야 할 추가 요구사항이나 특별 지시사항을 입력하세요',
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
                labelText: '요구사항',
                hintText: '예: 특정 기기에서 테스트, 특정 기능 집중 테스트 등...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.checklist),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestTypeSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔧 테스트 유형 설정',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '테스트 대상의 유형과 난이도를 설정하세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: '테스트 유형',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: _types.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getTypeDisplayName(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    decoration: InputDecoration(
                      labelText: '난이도',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      prefixIcon: const Icon(Icons.trending_up),
                    ),
                    items: _difficulties.map((difficulty) {
                      return DropdownMenuItem(
                        value: difficulty,
                        child: Text(_getDifficultyDisplayName(difficulty)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            DropdownButtonFormField<String>(
              value: _selectedInstallType,
              decoration: InputDecoration(
                labelText: '설치 유형',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                prefixIcon: const Icon(Icons.download),
              ),
              items: _installTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getInstallTypeDisplayName(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedInstallType = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewFeaturesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🆕 신규 기능 설정',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '일일 테스트 시간과 승인 조건을 설정하세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDailyTestTime,
                    decoration: InputDecoration(
                      labelText: '일일 테스트 시간',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      prefixIcon: const Icon(Icons.access_time),
                    ),
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
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedApprovalCondition,
                    decoration: InputDecoration(
                      labelText: '승인 조건',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      prefixIcon: const Icon(Icons.check),
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
                ),
              ],
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _minExperienceController,
              decoration: InputDecoration(
                labelText: '최소 경험 레벨',
                hintText: 'beginner, intermediate, advanced, expert',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                prefixIcon: const Icon(Icons.school),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minOSVersionController,
                    decoration: InputDecoration(
                      labelText: '최소 OS 버전',
                      hintText: 'Android 8.0+, iOS 13.0+',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      prefixIcon: const Icon(Icons.phone_android),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: TextField(
                    controller: _appStoreUrlController,
                    decoration: InputDecoration(
                      labelText: '앱스토어 URL (선택)',
                      hintText: '이미 출시된 앱의 스토어 링크',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      prefixIcon: const Icon(Icons.store),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _specialRequirementsController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: '특별 요구사항',
                hintText: '추가적인 요구사항이나 주의사항을 입력하세요',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                prefixIcon: const Icon(Icons.warning),
                alignLabelWithHint: true,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _testingGuidelinesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '테스팅 가이드라인',
                hintText: '테스터가 따라야 할 구체적인 테스팅 지침을 작성하세요',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                prefixIcon: const Icon(Icons.checklist),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'app': return '앱';
      case 'website': return '웹사이트';
      case 'service': return '서비스';
      default: return type;
    }
  }

  String _getDifficultyDisplayName(String difficulty) {
    switch (difficulty) {
      case 'easy': return '쉬움';
      case 'medium': return '보통';
      case 'hard': return '어려움';
      case 'expert': return '전문가';
      default: return difficulty;
    }
  }

  String _getInstallTypeDisplayName(String type) {
    switch (type) {
      case 'play_store': return '구글 플레이 스토어';
      case 'apk_upload': return 'APK 파일 업로드';
      default: return type;
    }
  }
}