import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import 'app_detail_page.dart';
import 'tester_management_page.dart';

// Provider for managing apps (using optimized projects collection)
final providerAppsProvider = StreamProvider.family<List<ProviderAppModel>, String>((ref, providerId) {
  return FirebaseFirestore.instance
      .collection('projects')
      .where('providerId', isEqualTo: providerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ProviderAppModel.fromFirestore(doc))
          .toList());
});

// App Model
class ProviderAppModel {
  final String id;
  final String providerId;
  final String appName;
  final String appUrl;
  final String description;
  final String category;
  final String status;
  final int totalTesters;
  final int activeTesters;
  final int totalBugs;
  final int resolvedBugs;
  final double progressPercentage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  ProviderAppModel({
    required this.id,
    required this.providerId,
    required this.appName,
    required this.appUrl,
    required this.description,
    required this.category,
    required this.status,
    required this.totalTesters,
    required this.activeTesters,
    required this.totalBugs,
    required this.resolvedBugs,
    required this.progressPercentage,
    required this.createdAt,
    required this.updatedAt,
    required this.metadata,
  });

  factory ProviderAppModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProviderAppModel(
      id: doc.id,
      providerId: data['providerId'] ?? '',
      appName: data['appName'] ?? '',
      appUrl: data['appUrl'] ?? data['appStoreUrl'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      status: data['status'] ?? 'draft',
      totalTesters: data['totalTesters'] ?? data['maxTesters'] ?? 0,
      activeTesters: data['activeTesters'] ?? 0,
      totalBugs: data['totalBugs'] ?? 0,
      resolvedBugs: data['resolvedBugs'] ?? 0,
      progressPercentage: (data['progressPercentage'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'providerId': providerId,
      'appName': appName,
      'appUrl': appUrl,
      'description': description,
      'category': category,
      'status': status,
      'totalTesters': totalTesters,
      'activeTesters': activeTesters,
      'totalBugs': totalBugs,
      'resolvedBugs': resolvedBugs,
      'progressPercentage': progressPercentage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }
}

class AppManagementPage extends ConsumerStatefulWidget {
  final String providerId;

  const AppManagementPage({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<AppManagementPage> createState() => _AppManagementPageState();
}

class _AppManagementPageState extends ConsumerState<AppManagementPage> {
  bool _showUploadDialog = false;
  // Basic info controllers
  final _appNameController = TextEditingController();
  final _appUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _testingGuidelinesController = TextEditingController();
  final _minOSVersionController = TextEditingController();
  final _appStoreUrlController = TextEditingController();

  // Advanced options
  String _selectedCategory = 'Productivity';
  String _selectedInstallType = 'play_store';
  String _selectedDifficulty = 'easy';
  String _selectedType = 'functional';
  List<String> _selectedPlatforms = ['android'];
  int _maxTesters = 10;
  int _testPeriodDays = 14;
  int _baseReward = 5000;
  int _bonusReward = 2000;

  // Requirements
  final _minExperienceController = TextEditingController();
  final _specialRequirementsController = TextEditingController();
  List<String> _requiredSpecializations = [];

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
    'News',
    'Photo & Video',
    'Music',
    'Lifestyle',
    'Business',
    'Medical',
    'Weather',
    'Sports',
    'Navigation',
    'Utilities',
    'Other',
  ];

  final List<String> _difficulties = [
    'easy',
    'medium',
    'hard',
    'expert',
  ];

  final List<String> _types = [
    'functional',
    'usability',
    'performance',
    'security',
    'compatibility',
    'regression',
    'exploratory',
    'automated',
  ];

  final List<String> _platforms = [
    'android',
    'ios',
    'web',
    'windows',
    'mac',
    'linux',
  ];

  final List<String> _specializations = [
    'UI/UX Testing',
    'Performance Testing',
    'Security Testing',
    'API Testing',
    'Mobile Testing',
    'Web Testing',
    'Game Testing',
    'E-commerce Testing',
    'Payment Testing',
    'Accessibility Testing',
    'Localization Testing',
    'Device Testing',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _appUrlController.dispose();
    _descriptionController.dispose();
    _testingGuidelinesController.dispose();
    _minOSVersionController.dispose();
    _appStoreUrlController.dispose();
    _minExperienceController.dispose();
    _specialRequirementsController.dispose();
    super.dispose();
  }

  Future<void> _uploadApp() async {
    if (_appNameController.text.isEmpty || 
        _appUrlController.text.isEmpty || 
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력해주세요')),
      );
      return;
    }

    try {
      final newProject = {
        'type': _selectedType,
        'appId': '', // Will be set to document ID after creation
        'appName': _appNameController.text,
        'appUrl': _appUrlController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'installType': _selectedInstallType,
        'platform': _selectedPlatforms.first, // Primary platform
        'providerId': widget.providerId,
        'status': 'draft', // New projects start as draft
        'difficulty': _selectedDifficulty,

        // Extended fields matching database indexes
        'maxTesters': _maxTesters,
        'testPeriodDays': _testPeriodDays,
        'rewardPoints': _baseReward, // For backward compatibility
        'totalTesters': 0,
        'activeTesters': 0,
        'totalBugs': 0,
        'resolvedBugs': 0,
        'progressPercentage': 0.0,

        // Testing guidelines and requirements
        'testingGuidelines': _testingGuidelinesController.text,
        'minOSVersion': _minOSVersionController.text,
        'appStoreUrl': _appStoreUrlController.text,

        // Advanced reward system
        'rewards': {
          'baseReward': _baseReward,
          'bonusReward': _bonusReward,
          'currency': 'KRW',
        },

        // Requirements matching indexed fields
        'requirements': {
          'platforms': _selectedPlatforms,
          'minExperience': _minExperienceController.text.isEmpty ? 'beginner' : _minExperienceController.text,
          'specializations': _requiredSpecializations,
          'specialRequirements': _specialRequirementsController.text,
          'maxParticipants': _maxTesters,
          'testDuration': _testPeriodDays,
        },

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Metadata with all config
        'metadata': {
          'installType': _selectedInstallType,
          'difficulty': _selectedDifficulty,
          'type': _selectedType,
          'platforms': _selectedPlatforms,
          'version': '1.0',
          'configVersion': '2.0', // Indicate this is the new enhanced format
        },
      };

      // Create project in the new optimized structure
      final docRef = await FirebaseFirestore.instance
          .collection('projects')
          .add(newProject);

      // Update the document with its ID as appId
      await docRef.update({'appId': docRef.id});

      if (mounted) {
        setState(() {
          _showUploadDialog = false;
          _appNameController.clear();
          _appUrlController.clear();
          _descriptionController.clear();
          _testingGuidelinesController.clear();
          _minOSVersionController.clear();
          _appStoreUrlController.clear();
          _minExperienceController.clear();
          _specialRequirementsController.clear();
          _selectedCategory = 'Productivity';
          _selectedInstallType = 'play_store';
          _selectedDifficulty = 'easy';
          _selectedType = 'functional';
          _selectedPlatforms = ['android'];
          _maxTesters = 10;
          _testPeriodDays = 14;
          _baseReward = 5000;
          _bonusReward = 2000;
          _requiredSpecializations = [];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('앱이 성공적으로 등록되었습니다')),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to upload app', e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('앱 등록 실패: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appsAsyncValue = ref.watch(providerAppsProvider(widget.providerId));
    
    return appsAsyncValue.when(
      data: (apps) => _buildContent(apps),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _buildErrorContent(error),
    );
  }

  Widget _buildContent(List<ProviderAppModel> apps) {
    return Scaffold(
      body: Column(
        children: [
          // Header with tabs
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Add button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '앱 관리',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(
                        width: 120.w,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showUploadDialog = true;
                            });
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('앱 등록'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),

          // App content
          Expanded(
            child: _buildAppsTab(apps),
          ),
        ],
      ),
      // Upload Dialog
      floatingActionButton: _showUploadDialog ? null : null,
      bottomSheet: _showUploadDialog ? _buildUploadDialog() : null,
    );
  }

  Widget _buildAppsTab(List<ProviderAppModel> apps) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: apps.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return _buildAppCard(app);
              },
            ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apps,
            size: 80.sp,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16.h),
          Text(
            '등록된 앱이 없습니다',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '새로운 앱을 등록하여 테스팅을 시작하세요',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(ProviderAppModel app) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Header
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.apps,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.appName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      app.category,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(app.status),
            ],
          ),
          SizedBox(height: 16.h),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '테스팅 진행률',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${app.progressPercentage.toInt()}%',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              LinearProgressIndicator(
                value: app.progressPercentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6.h,
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Statistics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('테스터', '${app.activeTesters}/${app.totalTesters}'),
              _buildStatItem('버그', '${app.resolvedBugs}/${app.totalBugs}'),
              _buildStatItem('상태', app.status == 'active' ? '진행중' : '대기'),
            ],
          ),
          SizedBox(height: 16.h),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36.h,
                  child: OutlinedButton(
                    onPressed: () async {
                      // Navigate to app detail page
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (context) => AppDetailPage(app: app),
                        ),
                      );

                      // Refresh the list if changes were made
                      if (result == true && mounted) {
                        ref.invalidate(providerAppsProvider(widget.providerId));
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      '상세보기',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: SizedBox(
                  height: 36.h,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to tester management page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TesterManagementPage(app: app),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      '관리',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    // PRD 기준 프로젝트 상태: pending → open → closed
    switch (status) {
      case 'pending':
        color = Colors.orange[600]!;
        text = '승인 대기';
        icon = Icons.schedule;
        break;
      case 'open':
        color = Colors.green[600]!;
        text = '승인됨';
        icon = Icons.check_circle;
        break;
      case 'closed':
        color = Colors.blue[600]!;
        text = '종료됨';
        icon = Icons.archive;
        break;
      case 'rejected':
        color = Colors.red[600]!;
        text = '거부됨';
        icon = Icons.cancel;
        break;
      case 'draft':
        color = Colors.grey[600]!;
        text = '임시저장';
        icon = Icons.edit;
        break;
      default:
        color = Colors.grey;
        text = '알 수 없음';
        icon = Icons.help;
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
          Icon(
            icon,
            size: 14.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadDialog() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '새 앱/미션 등록',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showUploadDialog = false;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Basic Information Section
            _buildSectionHeader('기본 정보'),
            SizedBox(height: 12.h),
            // App Name
            TextField(
              controller: _appNameController,
              decoration: InputDecoration(
                labelText: '앱/프로젝트 이름 *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Type and Difficulty Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
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
                    decoration: InputDecoration(
                      labelText: '테스트 유형',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
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
                    decoration: InputDecoration(
                      labelText: '난이도',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Install Type and Category Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedInstallType,
                    items: const [
                      DropdownMenuItem(
                        value: 'play_store',
                        child: Text('구글 플레이 스토어'),
                      ),
                      DropdownMenuItem(
                        value: 'apk_upload',
                        child: Text('APK 파일 업로드'),
                      ),
                      DropdownMenuItem(
                        value: 'testflight',
                        child: Text('TestFlight (iOS)'),
                      ),
                      DropdownMenuItem(
                        value: 'enterprise',
                        child: Text('기업용 배포'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedInstallType = value!;
                        _appUrlController.clear();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: '설치 방식',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
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
                    decoration: InputDecoration(
                      labelText: '카테고리',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // App URL
            TextField(
              controller: _appUrlController,
              decoration: InputDecoration(
                labelText: _getUrlLabel(),
                hintText: _getUrlHint(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '설명 *',
                hintText: '앱/프로젝트에 대한 상세 설명을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Platform Selection Section
            _buildSectionHeader('플랫폼 선택'),
            SizedBox(height: 12.h),
            _buildPlatformSelector(),
            SizedBox(height: 20.h),

            // Testing Configuration Section
            _buildSectionHeader('테스트 설정'),
            SizedBox(height: 12.h),
            // Max Testers and Test Period Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _maxTesters.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _maxTesters = int.tryParse(value) ?? 10;
                    },
                    decoration: InputDecoration(
                      labelText: '최대 테스터 수',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextFormField(
                    initialValue: _testPeriodDays.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _testPeriodDays = int.tryParse(value) ?? 14;
                    },
                    decoration: InputDecoration(
                      labelText: '테스트 기간 (일)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Rewards Section
            _buildSectionHeader('보상 설정'),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _baseReward.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _baseReward = int.tryParse(value) ?? 5000;
                    },
                    decoration: InputDecoration(
                      labelText: '기본 보상 (원)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextFormField(
                    initialValue: _bonusReward.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _bonusReward = int.tryParse(value) ?? 2000;
                    },
                    decoration: InputDecoration(
                      labelText: '보너스 보상 (원)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Requirements Section
            _buildSectionHeader('테스터 요구사항'),
            SizedBox(height: 12.h),
            TextField(
              controller: _minExperienceController,
              decoration: InputDecoration(
                labelText: '최소 경험 레벨',
                hintText: 'beginner, intermediate, advanced, expert',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            _buildSpecializationSelector(),
            SizedBox(height: 12.h),
            TextField(
              controller: _specialRequirementsController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: '특별 요구사항',
                hintText: '추가적인 요구사항이나 주의사항을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Additional Info Section
            _buildSectionHeader('추가 정보'),
            SizedBox(height: 12.h),
            TextField(
              controller: _testingGuidelinesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '테스팅 가이드라인',
                hintText: '테스터가 따라야 할 구체적인 테스팅 지침을 작성하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minOSVersionController,
                    decoration: InputDecoration(
                      labelText: '최소 OS 버전',
                      hintText: 'Android 8.0+, iOS 13.0+',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextField(
                    controller: _appStoreUrlController,
                    decoration: InputDecoration(
                      labelText: '앱스토어 URL (선택)',
                      hintText: '이미 출시된 앱의 스토어 링크',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showUploadDialog = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: ElevatedButton(
                      onPressed: _uploadApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: const Text('등록'),
                    ),
                  ),
                ),
              ],
            ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
        ),
      ),
    );
  }

  String _getUrlLabel() {
    switch (_selectedInstallType) {
      case 'play_store':
        return 'Play Store URL';
      case 'apk_upload':
        return 'APK 다운로드 URL';
      case 'testflight':
        return 'TestFlight 링크';
      case 'enterprise':
        return '기업용 배포 링크';
      default:
        return '앱 URL';
    }
  }

  String _getUrlHint() {
    switch (_selectedInstallType) {
      case 'play_store':
        return 'https://play.google.com/store/apps/details?id=...';
      case 'apk_upload':
        return 'APK 파일을 업로드 후 자동 생성됩니다';
      case 'testflight':
        return 'https://testflight.apple.com/join/...';
      case 'enterprise':
        return 'https://your-domain.com/app-install';
      default:
        return '앱 설치 URL을 입력하세요';
    }
  }

  Widget _buildErrorContent(Object error) {
    return Scaffold(
      body: Column(
        children: [
          // Header with tabs (same as success state)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '앱 관리',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(
                        width: 120.w,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showUploadDialog = true;
                            });
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('앱 등록'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),

          // Error content
          Expanded(
            child: _buildAppsErrorTab(error),
          ),
        ],
      ),
      // Upload dialog overlay
      floatingActionButton: _showUploadDialog ? null : null,
      bottomSheet: _showUploadDialog ? _buildUploadDialog() : null,
    );
  }

  Widget _buildAppsErrorTab(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.w,
            color: Colors.red[300],
          ),
          SizedBox(height: 16.h),
          Text(
            '앱 목록을 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(providerAppsProvider(widget.providerId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('새로고침 중...')),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for enhanced UI

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSelector() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _platforms.map((platform) {
        final isSelected = _selectedPlatforms.contains(platform);
        return FilterChip(
          label: Text(_getPlatformDisplayName(platform)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                if (!_selectedPlatforms.contains(platform)) {
                  _selectedPlatforms.add(platform);
                }
              } else {
                _selectedPlatforms.remove(platform);
              }
              // Ensure at least one platform is selected
              if (_selectedPlatforms.isEmpty) {
                _selectedPlatforms.add('android');
              }
            });
          },
          backgroundColor: Colors.grey[200],
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  Widget _buildSpecializationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '필요한 전문 분야 (선택)',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _specializations.map((spec) {
            final isSelected = _requiredSpecializations.contains(spec);
            return FilterChip(
              label: Text(
                spec,
                style: TextStyle(fontSize: 12.sp),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (!_requiredSpecializations.contains(spec)) {
                      _requiredSpecializations.add(spec);
                    }
                  } else {
                    _requiredSpecializations.remove(spec);
                  }
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'functional':
        return '기능 테스트';
      case 'usability':
        return '사용성 테스트';
      case 'performance':
        return '성능 테스트';
      case 'security':
        return '보안 테스트';
      case 'compatibility':
        return '호환성 테스트';
      case 'regression':
        return '회귀 테스트';
      case 'exploratory':
        return '탐색적 테스트';
      case 'automated':
        return '자동화 테스트';
      default:
        return type;
    }
  }

  String _getDifficultyDisplayName(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return '쉬움';
      case 'medium':
        return '보통';
      case 'hard':
        return '어려움';
      case 'expert':
        return '전문가';
      default:
        return difficulty;
    }
  }

  String _getPlatformDisplayName(String platform) {
    switch (platform) {
      case 'android':
        return 'Android';
      case 'ios':
        return 'iOS';
      case 'web':
        return 'Web';
      case 'windows':
        return 'Windows';
      case 'mac':
        return 'macOS';
      case 'linux':
        return 'Linux';
      default:
        return platform;
    }
  }
}