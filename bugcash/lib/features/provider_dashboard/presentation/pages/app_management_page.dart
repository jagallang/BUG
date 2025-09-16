import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';

// Provider for managing apps
final providerAppsProvider = StreamProvider.family<List<ProviderAppModel>, String>((ref, providerId) {
  return FirebaseFirestore.instance
      .collection('provider_apps')
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
      appUrl: data['appUrl'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      status: data['status'] ?? 'active',
      totalTesters: data['totalTesters'] ?? 0,
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
  final _appNameController = TextEditingController();
  final _appUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Productivity';
  String _selectedInstallType = 'play_store'; // play_store, apk_upload, testflight, enterprise

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

  @override
  void dispose() {
    _appNameController.dispose();
    _appUrlController.dispose();
    _descriptionController.dispose();
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
      final newApp = {
        'providerId': widget.providerId,
        'appName': _appNameController.text,
        'appUrl': _appUrlController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'installType': _selectedInstallType,
        'status': 'active',
        'totalTesters': 0,
        'activeTesters': 0,
        'totalBugs': 0,
        'resolvedBugs': 0,
        'progressPercentage': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': {},
      };

      await FirebaseFirestore.instance
          .collection('provider_apps')
          .add(newApp);

      if (mounted) {
        setState(() {
          _showUploadDialog = false;
          _appNameController.clear();
          _appUrlController.clear();
          _descriptionController.clear();
          _selectedCategory = 'Productivity';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('앱이 성공적으로 등록되었습니다')),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to upload app', e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('앱 등록 실패: ${e.toString()}')),
      );
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
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Add button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '내 앱 관리',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(
                  width: 120.w, // Fixed width
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

            // Apps List
            Expanded(
              child: apps.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: apps.length,
                      itemBuilder: (context, index) {
                        final app = apps[index];
                        return _buildAppCard(app);
                      },
                    ),
            ),
          ],
        ),
      ),

      // Upload Dialog
      floatingActionButton: _showUploadDialog ? null : null,
      bottomSheet: _showUploadDialog ? _buildUploadDialog() : null,
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
                    onPressed: () {
                      // View details
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${app.appName} 상세 정보')),
                      );
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
                      // Manage app
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${app.appName} 관리')),
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
    switch (status) {
      case 'active':
        color = Colors.indigo[600]!;
        text = '활성';
        break;
      case 'paused':
        color = Colors.indigo[400]!;
        text = '일시정지';
        break;
      case 'completed':
        color = Colors.indigo[300]!;
        text = '완료';
        break;
      default:
        color = Colors.grey;
        text = '대기';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
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
        maxHeight: MediaQuery.of(context).size.height * 0.85,  // 화면 높이의 85%로 제한
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
      child: SingleChildScrollView(  // ScrollView 추가
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '새 앱 등록',
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
          TextField(
            controller: _appNameController,
            decoration: InputDecoration(
              labelText: '앱 이름',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          DropdownButtonFormField<String>(
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
                // 힌트 텍스트를 타입에 따라 변경
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
          SizedBox(height: 12.h),
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
          DropdownButtonFormField<String>(
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
          SizedBox(height: 12.h),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '설명',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
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
      body: Stack(
        children: [
          // Main error content
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Add button (same as success state)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '내 앱 관리',
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
                SizedBox(height: 24.h),
                
                // Error state content
                Expanded(
                  child: Center(
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
                            // Refresh the provider
                            ref.refresh(providerAppsProvider(widget.providerId));
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
                  ),
                ),
              ],
            ),
          ),
          
          // Upload dialog overlay
          if (_showUploadDialog)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: EdgeInsets.all(20.w),
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: _buildUploadDialog(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}