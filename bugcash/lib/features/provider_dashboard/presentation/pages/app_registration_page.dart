import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/app_registration_provider.dart';
import '../../domain/models/provider_model.dart';

class AppRegistrationPage extends ConsumerStatefulWidget {
  final String providerId;

  const AppRegistrationPage({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<AppRegistrationPage> createState() => _AppRegistrationPageState();
}

class _AppRegistrationPageState extends ConsumerState<AppRegistrationPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  
  // Form controllers
  final _appNameController = TextEditingController();
  final _packageNameController = TextEditingController();
  final _versionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _developerController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _privacyPolicyController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _releaseNotesController = TextEditingController();
  
  // Form values
  AppCategory _selectedCategory = AppCategory.productivity;
  AppType _selectedType = AppType.android;
  ContentRating _selectedRating = ContentRating.everyone;
  bool _isFreemium = false;
  bool _containsAds = false;
  bool _requiresPermissions = false;
  double _targetAge = 13.0;
  
  // File uploads
  File? _appIconFile;
  List<File> _screenshotFiles = [];
  File? _appBinaryFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _appNameController.dispose();
    _packageNameController.dispose();
    _versionController.dispose();
    _descriptionController.dispose();
    _shortDescriptionController.dispose();
    _developerController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _privacyPolicyController.dispose();
    _keywordsController.dispose();
    _releaseNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registrationState = ref.watch(appRegistrationProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('새 앱 등록'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: '기본 정보'),
            Tab(text: '상세 정보'),
            Tab(text: '미디어 파일'),
            Tab(text: '검토 및 제출'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(),
                  _buildDetailedInfoTab(),
                  _buildMediaFilesTab(),
                  _buildReviewSubmitTab(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('앱 기본 정보'),
          SizedBox(height: 16.h),
          
          // App Name
          _buildTextFormField(
            controller: _appNameController,
            label: '앱 이름',
            hint: '마켓에 표시될 앱 이름을 입력하세요',
            isRequired: true,
            maxLength: 50,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '앱 이름을 입력해주세요';
              }
              if (value.length < 2) {
                return '앱 이름은 최소 2글자 이상이어야 합니다';
              }
              return null;
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Package Name
          _buildTextFormField(
            controller: _packageNameController,
            label: '패키지명/Bundle ID',
            hint: 'com.example.myapp',
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '패키지명을 입력해주세요';
              }
              final regex = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$');
              if (!regex.hasMatch(value)) {
                return '올바른 패키지명 형식이 아닙니다 (예: com.example.myapp)';
              }
              return null;
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Version
          _buildTextFormField(
            controller: _versionController,
            label: '버전',
            hint: '1.0.0',
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '버전을 입력해주세요';
              }
              final regex = RegExp(r'^\d+\.\d+\.\d+$');
              if (!regex.hasMatch(value)) {
                return '올바른 버전 형식이 아닙니다 (예: 1.0.0)';
              }
              return null;
            },
          ),
          
          SizedBox(height: 16.h),
          
          // App Type
          _buildDropdownField<AppType>(
            label: '앱 타입',
            value: _selectedType,
            items: AppType.values,
            onChanged: (value) => setState(() => _selectedType = value!),
            itemBuilder: (type) {
              switch (type) {
                case AppType.android:
                  return 'Android';
                case AppType.ios:
                  return 'iOS';
                case AppType.web:
                  return 'Web';
                case AppType.desktop:
                  return 'Desktop';
              }
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Category
          _buildDropdownField<AppCategory>(
            label: '카테고리',
            value: _selectedCategory,
            items: AppCategory.values,
            onChanged: (value) => setState(() => _selectedCategory = value!),
            itemBuilder: (category) {
              switch (category) {
                case AppCategory.productivity:
                  return '생산성';
                case AppCategory.entertainment:
                  return '엔터테인먼트';
                case AppCategory.education:
                  return '교육';
                case AppCategory.game:
                  return '게임';
                case AppCategory.social:
                  return '소셜';
                case AppCategory.finance:
                  return '금융';
                case AppCategory.health:
                  return '건강';
                case AppCategory.utility:
                  return '유틸리티';
                case AppCategory.shopping:
                  return '쇼핑';
                case AppCategory.travel:
                  return '여행';
              }
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Short Description
          _buildTextFormField(
            controller: _shortDescriptionController,
            label: '짧은 설명',
            hint: '앱을 한 줄로 설명해보세요',
            isRequired: true,
            maxLength: 80,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '짧은 설명을 입력해주세요';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('상세 정보'),
          SizedBox(height: 16.h),
          
          // Full Description
          _buildTextFormField(
            controller: _descriptionController,
            label: '상세 설명',
            hint: '앱의 기능과 특징을 자세히 설명해주세요',
            isRequired: true,
            maxLines: 8,
            maxLength: 4000,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '상세 설명을 입력해주세요';
              }
              if (value.length < 50) {
                return '상세 설명은 최소 50글자 이상이어야 합니다';
              }
              return null;
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Developer Info
          _buildTextFormField(
            controller: _developerController,
            label: '개발자/회사명',
            hint: '개발자 또는 회사 이름',
            isRequired: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '개발자/회사명을 입력해주세요';
              }
              return null;
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Contact Email
          _buildTextFormField(
            controller: _emailController,
            label: '연락처 이메일',
            hint: 'contact@example.com',
            isRequired: true,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '연락처 이메일을 입력해주세요';
              }
              final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
              if (!regex.hasMatch(value)) {
                return '올바른 이메일 형식이 아닙니다';
              }
              return null;
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Website
          _buildTextFormField(
            controller: _websiteController,
            label: '웹사이트 (선택)',
            hint: 'https://example.com',
            keyboardType: TextInputType.url,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final regex = RegExp(r'^https?:\/\/[^\s]+$');
                if (!regex.hasMatch(value)) {
                  return '올바른 URL 형식이 아닙니다';
                }
              }
              return null;
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Privacy Policy
          _buildTextFormField(
            controller: _privacyPolicyController,
            label: '개인정보처리방침 URL (선택)',
            hint: 'https://example.com/privacy',
            keyboardType: TextInputType.url,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final regex = RegExp(r'^https?:\/\/[^\s]+$');
                if (!regex.hasMatch(value)) {
                  return '올바른 URL 형식이 아닙니다';
                }
              }
              return null;
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Keywords
          _buildTextFormField(
            controller: _keywordsController,
            label: '키워드',
            hint: '키워드1, 키워드2, 키워드3',
            maxLength: 100,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final keywords = value.split(',');
                if (keywords.length > 10) {
                  return '키워드는 최대 10개까지 입력 가능합니다';
                }
              }
              return null;
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Content Rating
          _buildDropdownField<ContentRating>(
            label: '콘텐츠 등급',
            value: _selectedRating,
            items: ContentRating.values,
            onChanged: (value) => setState(() => _selectedRating = value!),
            itemBuilder: (rating) {
              switch (rating) {
                case ContentRating.everyone:
                  return '전체 이용가';
                case ContentRating.teen:
                  return '12세 이상';
                case ContentRating.mature:
                  return '17세 이상';
                case ContentRating.adult:
                  return '성인';
              }
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Target Age Slider
          _buildSliderField(
            label: '목표 연령대',
            value: _targetAge,
            min: 3,
            max: 65,
            divisions: 31,
            onChanged: (value) => setState(() => _targetAge = value),
            valueFormatter: (value) => '${value.round()}세',
          ),
          
          SizedBox(height: 16.h),
          
          // App Settings
          _buildSwitchTile(
            title: '프리미엄 기능 포함',
            subtitle: '앱 내 결제나 구독 기능이 포함되어 있습니까?',
            value: _isFreemium,
            onChanged: (value) => setState(() => _isFreemium = value),
          ),
          
          _buildSwitchTile(
            title: '광고 포함',
            subtitle: '앱에 광고가 표시됩니까?',
            value: _containsAds,
            onChanged: (value) => setState(() => _containsAds = value),
          ),
          
          _buildSwitchTile(
            title: '특별 권한 필요',
            subtitle: '카메라, 위치, 연락처 등의 권한이 필요합니까?',
            value: _requiresPermissions,
            onChanged: (value) => setState(() => _requiresPermissions = value),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaFilesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('미디어 파일'),
          SizedBox(height: 16.h),
          
          // App Icon
          _buildFileUploadSection(
            title: '앱 아이콘',
            subtitle: '512x512px PNG 파일을 업로드하세요',
            isRequired: true,
            file: _appIconFile,
            onUpload: _pickAppIcon,
            fileType: '이미지',
          ),
          
          SizedBox(height: 24.h),
          
          // Screenshots
          _buildScreenshotsSection(),
          
          SizedBox(height: 24.h),
          
          // App Binary
          _buildFileUploadSection(
            title: '앱 파일',
            subtitle: _selectedType == AppType.android 
                ? 'APK 또는 AAB 파일을 업로드하세요'
                : _selectedType == AppType.ios
                    ? 'IPA 파일을 업로드하세요'
                    : '앱 실행 파일을 업로드하세요',
            isRequired: true,
            file: _appBinaryFile,
            onUpload: _pickAppBinary,
            fileType: '앱 파일',
          ),
          
          SizedBox(height: 16.h),
          
          // Release Notes
          _buildTextFormField(
            controller: _releaseNotesController,
            label: '릴리즈 노트',
            hint: '이번 버전의 새로운 기능과 개선사항을 설명해주세요',
            maxLines: 5,
            maxLength: 500,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSubmitTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('검토 및 제출'),
          SizedBox(height: 16.h),
          
          _buildReviewCard(
            title: '기본 정보',
            items: [
              '앱 이름: ${_appNameController.text.isEmpty ? "미입력" : _appNameController.text}',
              '패키지명: ${_packageNameController.text.isEmpty ? "미입력" : _packageNameController.text}',
              '버전: ${_versionController.text.isEmpty ? "미입력" : _versionController.text}',
              '카테고리: ${_getCategoryText(_selectedCategory)}',
            ],
            isComplete: _appNameController.text.isNotEmpty && 
                       _packageNameController.text.isNotEmpty && 
                       _versionController.text.isNotEmpty,
          ),
          
          SizedBox(height: 16.h),
          
          _buildReviewCard(
            title: '개발자 정보',
            items: [
              '개발자: ${_developerController.text.isEmpty ? "미입력" : _developerController.text}',
              '연락처: ${_emailController.text.isEmpty ? "미입력" : _emailController.text}',
              '웹사이트: ${_websiteController.text.isEmpty ? "없음" : _websiteController.text}',
            ],
            isComplete: _developerController.text.isNotEmpty && 
                       _emailController.text.isNotEmpty,
          ),
          
          SizedBox(height: 16.h),
          
          _buildReviewCard(
            title: '미디어 파일',
            items: [
              '앱 아이콘: ${_appIconFile == null ? "미업로드" : "업로드됨"}',
              '스크린샷: ${_screenshotFiles.length}개',
              '앱 파일: ${_appBinaryFile == null ? "미업로드" : "업로드됨"}',
            ],
            isComplete: _appIconFile != null && _appBinaryFile != null,
          ),
          
          SizedBox(height: 24.h),
          
          _buildSubmissionGuidelines(),
          
          SizedBox(height: 24.h),
          
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = false,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<T>(
          value: value,
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemBuilder(item)),
            );
          }).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
    required String Function(double) valueFormatter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              valueFormatter(value),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildFileUploadSection({
    required String title,
    required String subtitle,
    required bool isRequired,
    File? file,
    required VoidCallback onUpload,
    required String fileType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(text: title),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 12.h),
        InkWell(
          onTap: onUpload,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: double.infinity,
            height: 120.h,
            decoration: BoxDecoration(
              border: Border.all(
                color: file != null ? Colors.green : Colors.grey.shade300,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12.r),
              color: file != null ? Colors.green.shade50 : Colors.grey.shade50,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  file != null ? Icons.check_circle : Icons.cloud_upload,
                  size: 32.w,
                  color: file != null ? Colors.green : Colors.grey.shade400,
                ),
                SizedBox(height: 8.h),
                Text(
                  file != null 
                      ? '${fileType} 업로드 완료'
                      : '${fileType} 업로드하기',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: file != null ? Colors.green : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (file != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    file.path.split('/').last,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenshotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            children: [
              const TextSpan(text: '스크린샷'),
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '최소 2개, 최대 8개의 스크린샷을 업로드하세요',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 12.h),
        if (_screenshotFiles.isNotEmpty) ...[
          SizedBox(
            height: 120.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _screenshotFiles.length + 1,
              itemBuilder: (context, index) {
                if (index == _screenshotFiles.length) {
                  return _buildAddScreenshotButton();
                }
                return _buildScreenshotItem(_screenshotFiles[index], index);
              },
            ),
          ),
        ] else ...[
          _buildAddScreenshotButton(),
        ],
      ],
    );
  }

  Widget _buildAddScreenshotButton() {
    return InkWell(
      onTap: _pickScreenshot,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 80.w,
        height: 120.h,
        margin: EdgeInsets.only(right: 8.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12.r),
          color: Colors.grey.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 24.w,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 8.h),
            Text(
              '추가',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenshotItem(File file, int index) {
    return Container(
      width: 80.w,
      height: 120.h,
      margin: EdgeInsets.only(right: 8.w),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.file(
              file,
              width: 80.w,
              height: 120.h,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _removeScreenshot(index),
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16.w,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required List<String> items,
    required bool isComplete,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isComplete ? Icons.check_circle : Icons.error,
                  color: isComplete ? Colors.green : Colors.red,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isComplete ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...items.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Text(
                '• $item',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionGuidelines() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Colors.blue,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  '제출 전 확인사항',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            const Text('• 모든 필수 정보가 정확히 입력되었는지 확인해주세요'),
            const Text('• 앱 파일이 정상적으로 실행되는지 테스트해주세요'),
            const Text('• 스크린샷이 앱의 주요 기능을 보여주는지 확인해주세요'),
            const Text('• 개인정보처리방침이 필요한 경우 URL을 제공해주세요'),
            const Text('• 검토 과정에서 추가 정보를 요청할 수 있습니다'),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isFormComplete = _isFormComplete();
    final isLoading = ref.watch(appRegistrationProvider).isLoading;

    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: isFormComplete && !isLoading ? _submitApp : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Text(
                '앱 등록 신청',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_tabController.index > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _tabController.animateTo(_tabController.index - 1);
                },
                child: const Text('이전'),
              ),
            ),
          if (_tabController.index > 0) SizedBox(width: 16.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _tabController.index < 3
                  ? () {
                      if (_validateCurrentTab()) {
                        _tabController.animateTo(_tabController.index + 1);
                      }
                    }
                  : null,
              child: Text(_tabController.index < 3 ? '다음' : '제출'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Helper methods
  String _getCategoryText(AppCategory category) {
    switch (category) {
      case AppCategory.productivity:
        return '생산성';
      case AppCategory.entertainment:
        return '엔터테인먼트';
      case AppCategory.education:
        return '교육';
      case AppCategory.game:
        return '게임';
      case AppCategory.social:
        return '소셜';
      case AppCategory.finance:
        return '금융';
      case AppCategory.health:
        return '건강';
      case AppCategory.utility:
        return '유틸리티';
      case AppCategory.shopping:
        return '쇼핑';
      case AppCategory.travel:
        return '여행';
    }
  }

  bool _validateCurrentTab() {
    switch (_tabController.index) {
      case 0: // Basic Info
        return _appNameController.text.isNotEmpty &&
               _packageNameController.text.isNotEmpty &&
               _versionController.text.isNotEmpty &&
               _shortDescriptionController.text.isNotEmpty;
      case 1: // Detailed Info
        return _descriptionController.text.isNotEmpty &&
               _developerController.text.isNotEmpty &&
               _emailController.text.isNotEmpty;
      case 2: // Media Files
        return _appIconFile != null && 
               _screenshotFiles.length >= 2 && 
               _appBinaryFile != null;
      case 3: // Review
        return _isFormComplete();
      default:
        return true;
    }
  }

  bool _isFormComplete() {
    return _appNameController.text.isNotEmpty &&
           _packageNameController.text.isNotEmpty &&
           _versionController.text.isNotEmpty &&
           _shortDescriptionController.text.isNotEmpty &&
           _descriptionController.text.isNotEmpty &&
           _developerController.text.isNotEmpty &&
           _emailController.text.isNotEmpty &&
           _appIconFile != null &&
           _screenshotFiles.length >= 2 &&
           _appBinaryFile != null;
  }

  // File picker methods
  Future<void> _pickAppIcon() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _appIconFile = File(image.path);
      });
    }
  }

  Future<void> _pickScreenshot() async {
    if (_screenshotFiles.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('스크린샷은 최대 8개까지 업로드할 수 있습니다.')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _screenshotFiles.add(File(image.path));
      });
    }
  }

  Future<void> _pickAppBinary() async {
    // For now, we'll simulate file picking
    // In a real implementation, you'd use file_picker package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('파일 선택 기능이 곧 구현될 예정입니다.')),
    );
    
    // Simulate file selection
    setState(() {
      _appBinaryFile = File('dummy_app_file.apk');
    });
  }

  void _removeScreenshot(int index) {
    setState(() {
      _screenshotFiles.removeAt(index);
    });
  }

  Future<void> _submitApp() async {
    if (!_formKey.currentState!.validate() || !_isFormComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필수 정보를 입력해주세요.')),
      );
      return;
    }

    try {
      final appData = {
        'providerId': widget.providerId,
        'appName': _appNameController.text,
        'packageName': _packageNameController.text,
        'version': _versionController.text,
        'description': _descriptionController.text,
        'shortDescription': _shortDescriptionController.text,
        'developer': _developerController.text,
        'email': _emailController.text,
        'website': _websiteController.text,
        'privacyPolicy': _privacyPolicyController.text,
        'keywords': _keywordsController.text,
        'releaseNotes': _releaseNotesController.text,
        'category': _selectedCategory,
        'type': _selectedType,
        'contentRating': _selectedRating,
        'targetAge': _targetAge,
        'isFreemium': _isFreemium,
        'containsAds': _containsAds,
        'requiresPermissions': _requiresPermissions,
        'appIconFile': _appIconFile,
        'screenshotFiles': _screenshotFiles,
        'appBinaryFile': _appBinaryFile,
      };

      await ref.read(appRegistrationProvider.notifier).submitApp(appData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('앱 등록 신청이 완료되었습니다. 검토 후 연락드리겠습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('앱 등록 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}