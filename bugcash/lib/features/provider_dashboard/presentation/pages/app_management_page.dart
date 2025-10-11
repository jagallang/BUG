import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/config/feature_flags.dart';
import 'app_detail_page.dart';
import 'mission_management_page_v2.dart';
import '../../../wallet/domain/usecases/wallet_service.dart';
import '../../../wallet/data/repositories/wallet_repository_impl.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

// Provider for managing apps (using optimized projects collection)
final providerAppsProvider = StreamProvider.family<List<ProviderAppModel>, String>((ref, providerId) {
  return FirebaseFirestore.instance
      .collection('projects')
      .where('providerId', isEqualTo: providerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        final docs = snapshot.docs
            .map((doc) => ProviderAppModel.fromFirestore(doc))
            .toList();
        // 클라이언트 측에서 정렬 (인덱스 생성 전까지 임시 방안)
        // 인덱스 생성 후에는 이 정렬이 불필요하지만 안전성을 위해 유지
        docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return docs;
      })
      .handleError((error) {
        // 인덱스 오류 발생 시 orderBy 없이 재시도
        AppLogger.error('Firestore index error, retrying without orderBy', error.toString());
        return FirebaseFirestore.instance
            .collection('projects')
            .where('providerId', isEqualTo: providerId)
            .snapshots()
            .map((snapshot) {
              final docs = snapshot.docs
                  .map((doc) => ProviderAppModel.fromFirestore(doc))
                  .toList();
              // 클라이언트 측에서 정렬
              docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              return docs;
            });
      });
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
  // v2.43.0: activeTesters, totalBugs, resolvedBugs, progressPercentage 제거 (UI 미사용)
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
    // v2.43.0: activeTesters, totalBugs, resolvedBugs, progressPercentage 파라미터 제거
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
      // v2.43.0: activeTesters, totalBugs, resolvedBugs, progressPercentage 제거
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
      // v2.43.0: activeTesters, totalBugs, resolvedBugs, progressPercentage 제거
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
  int _dailyMissionPoints = 100;
  int _finalCompletionPoints = 1000;
  int _bonusPoints = 500;

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
    super.dispose();
  }

  /// 앱 등록에 필요한 총 포인트 계산
  int _calculateRequiredPoints() {
    // 일일 미션 포인트 × 테스트 기간 × 최대 테스터 수
    final dailyTotal = _dailyMissionPoints * _testPeriodDays * _maxTesters;
    // 최종 완료 포인트 × 최대 테스터 수
    final finalTotal = _finalCompletionPoints * _maxTesters;
    // 보너스 포인트 × 최대 테스터 수 (최대 50% 지급 가정)
    final bonusTotal = (_bonusPoints * _maxTesters * 0.5).round();

    return dailyTotal + finalTotal + bonusTotal;
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

    // 필요한 포인트 계산
    final requiredPoints = _calculateRequiredPoints();

    // BuildContext 저장
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 현재 잔액 확인 - walletProvider는 StreamProvider이므로 watch 사용
    final walletAsync = ref.watch(walletProvider(widget.providerId));

    // 로딩 중이거나 에러 상태 처리
    if (walletAsync.isLoading) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('잔액 정보를 불러오는 중...')),
      );
      return;
    }

    if (walletAsync.hasError) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('잔액 정보 불러오기 실패: ${walletAsync.error}')),
      );
      return;
    }

    final wallet = walletAsync.value!;
    final balanceDeficit = requiredPoints - wallet.balance;

    if (wallet.balance < requiredPoints) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            '포인트가 부족합니다\n'
            '필요: ${_formatAmount(requiredPoints)}P\n'
            '보유: ${_formatAmount(wallet.balance)}P\n'
            '부족: ${_formatAmount(balanceDeficit)}P'
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // 포인트 차감 확인
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 등록 확인'),
        content: Text(
          '앱을 등록하시겠습니까?\n\n'
          '필요 포인트: ${_formatAmount(requiredPoints)}P\n'
          '현재 잔액: ${_formatAmount(wallet.balance)}P\n'
          '차감 후 잔액: ${_formatAmount(wallet.balance - requiredPoints)}P\n\n'
          '• 테스터 수: $_maxTesters명\n'
          '• 테스트 기간: $_testPeriodDays일\n'
          '• 일일 미션: ${_formatAmount(_dailyMissionPoints)}P\n'
          '• 최종 완료: ${_formatAmount(_finalCompletionPoints)}P',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('등록'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

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
        'rewardPoints': _finalCompletionPoints, // For backward compatibility
        'totalTesters': 0,
        // v2.43.0: activeTesters, totalBugs, resolvedBugs, progressPercentage 초기값 제거

        // Testing guidelines and requirements
        'testingGuidelines': _testingGuidelinesController.text,
        'minOSVersion': _minOSVersionController.text,
        'appStoreUrl': _appStoreUrlController.text,

        // 고급 보상 시스템 (3단계)
        'rewards': {
          'dailyMissionPoints': _dailyMissionPoints,
          'finalCompletionPoints': _finalCompletionPoints,
          'bonusPoints': _bonusPoints,
          'currency': 'KRW',
        },

        // Requirements matching indexed fields
        'requirements': {
          'platforms': _selectedPlatforms,
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

      // 포인트 차감
      final walletRepo = WalletRepositoryImpl();
      final walletService = WalletService(walletRepo);
      await walletService.spendPoints(
        widget.providerId,
        requiredPoints,
        '앱 등록: ${_appNameController.text}',
        metadata: {
          'appId': docRef.id,
          'appName': _appNameController.text,
          'maxTesters': _maxTesters,
          'testPeriodDays': _testPeriodDays,
          'dailyMissionPoints': _dailyMissionPoints,
          'finalCompletionPoints': _finalCompletionPoints,
          'bonusPoints': _bonusPoints,
        },
      );

      if (mounted) {
        // 성공 메시지를 더 명확하게 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('✅ 앱이 성공적으로 등록되었습니다.\n관리자 승인 후 테스팅이 시작됩니다.'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // 다이얼로그 닫기 및 필드 초기화를 약간 지연
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _showUploadDialog = false;
              _appNameController.clear();
              _appUrlController.clear();
              _descriptionController.clear();
              _testingGuidelinesController.clear();
              _minOSVersionController.clear();
              _appStoreUrlController.clear();
              _selectedCategory = 'Productivity';
              _selectedInstallType = 'play_store';
              _selectedDifficulty = 'easy';
              _selectedType = 'functional';
              _selectedPlatforms = ['android'];
              _maxTesters = 10;
              _testPeriodDays = 14;
              _dailyMissionPoints = 100;
              _finalCompletionPoints = 1000;
              _bonusPoints = 500;
            });
          }
        });
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
              boxShadow: AppColors.cardShadowMedium,
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
                            backgroundColor: AppColors.providerBluePrimary, // v2.76.0: 색상 통일
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.providerBlueLight.withValues(alpha: 0.3), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.providerBlueLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.providerBluePrimary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Description (moved to top for better visibility)
          _buildStatusDescription(app.status),
          SizedBox(height: 16.h),

          // App Header
          Row(
            children: [
              Container(
                width: 56.w,
                height: 56.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.providerBluePrimary, AppColors.providerBlueDark],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.providerBluePrimary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.apps_rounded,
                  color: Colors.white,
                  size: 28.sp,
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
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.providerBlueDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.providerBlueLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(color: AppColors.providerBlueLight, width: 1),
                      ),
                      child: Text(
                        app.category,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.providerBluePrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(app.status),
            ],
          ),
          SizedBox(height: 16.h),

          // v2.43.0: 진행률 및 통계 섹션 제거 (UI 간소화)

          // All Action Buttons in Single Row (v2.43.1: 버튼 비율 조정)
          Row(
            children: [
              // Visibility Dropdown + Input Button (1/4 공간)
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildUnifiedVisibilityDropdown(app),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: _buildUnifiedInputButton(app),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Mission Management Button (2/4 공간)
              Expanded(
                flex: 2,
                child: _buildUnifiedMissionButton(app),
              ),
              SizedBox(width: 8.w),
              // Delete Button (1/4 공간)
              Expanded(
                flex: 1,
                child: _buildUnifiedDeleteButton(app),
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

    // PRD 기준 프로젝트 상태: draft → pending → open → closed
    switch (status) {
      case 'draft':
        color = Colors.blue[600]!;
        text = '접수 대기';
        icon = Icons.hourglass_empty;
        break;
      case 'pending':
        color = Colors.orange[600]!;
        text = '검수 중';
        icon = Icons.schedule;
        break;
      case 'open':
        color = Colors.green[600]!;
        text = '모집 중';
        icon = Icons.check_circle;
        break;
      case 'closed':
        color = Colors.grey[600]!;
        text = '완료';
        icon = Icons.archive;
        break;
      case 'rejected':
        color = Colors.red[600]!;
        text = '거부';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        text = '확인중';
        icon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: color,
          ),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // v2.43.0: _buildStatItem() 제거 - 통계 섹션 제거로 미사용

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

            // 고급 보상 시스템 (3단계)
            _buildSectionHeader('고급 보상 설정'),
            SizedBox(height: 12.h),
            // 일일 미션 포인트
            TextFormField(
              initialValue: _dailyMissionPoints.toString(),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _dailyMissionPoints = int.tryParse(value) ?? 100;
              },
              decoration: InputDecoration(
                labelText: '일일 미션 포인트',
                hintText: '매일 완료 시 지급되는 포인트',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // 최종 완료 포인트
            TextFormField(
              initialValue: _finalCompletionPoints.toString(),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _finalCompletionPoints = int.tryParse(value) ?? 1000;
              },
              decoration: InputDecoration(
                labelText: '최종 완료 포인트',
                hintText: '전체 미션 완료 시 지급되는 포인트',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // 보너스 포인트
            TextFormField(
              initialValue: _bonusPoints.toString(),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _bonusPoints = int.tryParse(value) ?? 500;
              },
              decoration: InputDecoration(
                labelText: '보너스 포인트',
                hintText: '우수한 성과 시 추가 지급되는 포인트',
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
                        backgroundColor: AppColors.providerBluePrimary, // v2.76.0: 색상 통일
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
              boxShadow: AppColors.cardShadowMedium,
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
                            backgroundColor: AppColors.providerBluePrimary, // v2.76.0: 색상 통일
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

  // Status description widget for better user experience
  Widget _buildStatusDescription(String status) {
    String description;
    String nextStep;
    Color backgroundColor;
    IconData icon;

    switch (status) {
      case 'draft':
        description = '앱이 성공적으로 등록되었습니다';
        nextStep = '관리자 검수를 기다리고 있습니다 (보통 1-2일 소요)';
        backgroundColor = Colors.blue[50]!;
        icon = Icons.hourglass_empty;
        break;
      case 'pending':
        description = '관리자가 검수 중입니다';
        nextStep = '승인되면 테스터 모집이 시작됩니다';
        backgroundColor = Colors.orange[50]!;
        icon = Icons.schedule;
        break;
      case 'open':
        description = '테스터 모집이 진행 중입니다';
        nextStep = '신청자를 검토하고 승인해주세요';
        backgroundColor = Colors.green[50]!;
        icon = Icons.check_circle;
        break;
      case 'closed':
        description = '테스트가 완료되었습니다';
        nextStep = '결과를 확인하고 피드백을 검토하세요';
        backgroundColor = Colors.grey[50]!;
        icon = Icons.archive;
        break;
      case 'rejected':
        description = '승인이 거부되었습니다';
        nextStep = '거부 사유를 확인하고 수정 후 재신청하세요';
        backgroundColor = Colors.red[50]!;
        icon = Icons.cancel;
        break;
      default:
        description = '상태를 확인하고 있습니다';
        nextStep = '잠시 후 다시 확인해주세요';
        backgroundColor = Colors.grey[50]!;
        icon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: backgroundColor == Colors.blue[50] ? Colors.blue[200]! :
                 backgroundColor == Colors.orange[50] ? Colors.orange[200]! :
                 backgroundColor == Colors.green[50] ? Colors.green[200]! :
                 backgroundColor == Colors.red[50] ? Colors.red[200]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16.sp,
                color: backgroundColor == Colors.blue[50] ? Colors.blue[600] :
                       backgroundColor == Colors.orange[50] ? Colors.orange[600] :
                       backgroundColor == Colors.green[50] ? Colors.green[600] :
                       backgroundColor == Colors.red[50] ? Colors.red[600] : Colors.grey[600],
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: backgroundColor == Colors.blue[50] ? Colors.blue[700] :
                           backgroundColor == Colors.orange[50] ? Colors.orange[700] :
                           backgroundColor == Colors.green[50] ? Colors.green[700] :
                           backgroundColor == Colors.red[50] ? Colors.red[700] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            nextStep,
            style: TextStyle(
              fontSize: 12.sp,
              color: backgroundColor == Colors.blue[50] ? Colors.blue[600] :
                     backgroundColor == Colors.orange[50] ? Colors.orange[600] :
                     backgroundColor == Colors.green[50] ? Colors.green[600] :
                     backgroundColor == Colors.red[50] ? Colors.red[600] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 앱 공개 상태 업데이트
  Future<void> _updateAppVisibility(ProviderAppModel app, String visibility) async {
    try {
      final newStatus = visibility == 'published' ? 'open' : 'draft';

      await FirebaseFirestore.instance
          .collection('projects')
          .doc(app.id)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              visibility == 'published' ? '앱이 게시되었습니다' : '앱이 숨김 처리되었습니다',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to update app visibility', e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('상태 변경에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 앱 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmation(ProviderAppModel app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '앱 삭제 확인',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('정말로 이 앱을 삭제하시겠습니까?'),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '앱 이름: ${app.appName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text('카테고리: ${app.category}'),
                    SizedBox(height: 8.h),
                    Text(
                      '⚠️ 이 작업은 되돌릴 수 없습니다.',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
              ),
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteApp(app);
    }
  }

  /// 앱 삭제 실행
  Future<void> _deleteApp(ProviderAppModel app) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(app.id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('앱이 성공적으로 삭제되었습니다'),
            backgroundColor: Colors.green,
          ),
        );

        // 리스트 새로고침
        ref.invalidate(providerAppsProvider(widget.providerId));
      }
    } catch (e) {
      AppLogger.error('Failed to delete app', e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('앱 삭제에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 미션관리 기능 사용 가능 여부 확인
  /// 앱 상태가 'draft', 'pending', 'open'일 때 활성화 (테스터 신청 접수 및 승인 가능)
  bool _canUseMissionManagement(ProviderAppModel app) {
    return app.status == 'open' || app.status == 'draft' || app.status == 'pending';
  }

  // === Unified Button Methods ===

  /// 통일된 디자인의 공개/비공개 드롭다운 버튼
  Widget _buildUnifiedVisibilityDropdown(ProviderAppModel app) {
    final String currentVisibility = app.status == 'open' ? 'published' : 'hidden';

    return SizedBox(
      height: 36.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentVisibility,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 16.sp),
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
            onChanged: app.status == 'pending' || app.status == 'rejected' ? null : (String? newValue) {
              if (newValue != null && newValue != currentVisibility) {
                _updateAppVisibility(app, newValue);
              }
            },
            items: [
              DropdownMenuItem<String>(
                value: 'published',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, color: Colors.green, size: 12.sp),
                    SizedBox(width: 2.w),
                    Text('게시', style: TextStyle(fontSize: 11.sp)),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'hidden',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_off, color: Colors.grey, size: 12.sp),
                    SizedBox(width: 2.w),
                    Text('숨김', style: TextStyle(fontSize: 11.sp)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 통일된 디자인의 삭제 버튼
  Widget _buildUnifiedDeleteButton(ProviderAppModel app) {
    return SizedBox(
      height: 36.h,
      child: OutlinedButton(
        onPressed: () => _showPasswordConfirmationDialog(app),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete, color: Colors.red, size: 14.sp),
            SizedBox(width: 4.w),
            Text(
              '삭제',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 통일된 디자인의 정보 입력 버튼
  Widget _buildUnifiedInputButton(ProviderAppModel app) {
    return SizedBox(
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
          side: BorderSide(color: AppColors.providerBluePrimary, width: 1.5),
          backgroundColor: AppColors.providerBlueLight.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
        ),
        child: Text(
          '수정',
          style: TextStyle(
            color: AppColors.providerBluePrimary,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 통일된 디자인의 미션관리 버튼
  Widget _buildUnifiedMissionButton(ProviderAppModel app) {
    final bool canUse = _canUseMissionManagement(app);

    return SizedBox(
      height: 36.h,
      child: ElevatedButton(
        onPressed: canUse ? () {
          // v2.14.6: 프로덕션에서도 로그 출력을 위해 print 사용
          print('🔵 [AppManagement] 미션 버튼 클릭\n'
                '   ├─ 앱: ${app.appName}\n'
                '   ├─ appId: ${app.id}\n'
                '   ├─ providerId: ${app.providerId}\n'
                '   └─ 페이지: MissionManagementPageV2');

          // v2.14.0 Clean Architecture 기반 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MissionManagementPageV2(app: app),
            ),
          );

          FeatureFlagUtils.logFeatureUsage('mission_management_v2', app.providerId);
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canUse ? AppColors.providerBluePrimary : Colors.grey[400],
          foregroundColor: Colors.white,
          elevation: canUse ? 2 : 0,
          shadowColor: canUse ? AppColors.providerBluePrimary.withValues(alpha: 0.4) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_rounded, size: 14.sp),
            SizedBox(width: 4.w),
            Text(
              '미션',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: canUse ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === Password Re-authentication Methods ===

  /// 비밀번호 재인증 다이얼로그 표시
  Future<void> _showPasswordConfirmationDialog(ProviderAppModel app) async {
    final passwordController = TextEditingController();
    bool showPassword = false;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.security, color: Colors.red, size: 24.sp),
                  SizedBox(width: 8.w),
                  Text(
                    '보안 인증',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '앱을 삭제하려면 현재 계정의 비밀번호를 입력하세요.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 20.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              '앱 "${app.appName}"이(가) 영구적으로 삭제됩니다.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.red[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      '비밀번호',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      autofocus: true,
                      onChanged: (value) {
                        setState(() {}); // 비밀번호 입력 시 버튼 상태 업데이트
                      },
                      decoration: InputDecoration(
                        hintText: '현재 계정 비밀번호를 입력하세요',
                        hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        prefixIcon: Icon(Icons.lock, color: Colors.grey[600], size: 20.sp),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[600],
                            size: 20.sp,
                          ),
                          onPressed: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                      ),
                      onFieldSubmitted: (_) {
                        if (passwordController.text.isNotEmpty) {
                          _verifyPasswordAndDelete(dialogContext, app, passwordController.text, setState);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    '취소',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: passwordController.text.isEmpty ? null : () {
                    _verifyPasswordAndDelete(dialogContext, app, passwordController.text, setState);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    '삭제',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 비밀번호 검증 및 앱 삭제 실행
  Future<void> _verifyPasswordAndDelete(
    BuildContext dialogContext,
    ProviderAppModel app,
    String password,
    StateSetter setState,
  ) async {
    // async 전에 Navigator 미리 가져오기
    final navigator = Navigator.of(dialogContext);

    try {
      // 현재 로그인된 사용자 정보 가져오기
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception('로그인된 사용자를 찾을 수 없습니다');
      }

      // Firebase 재인증 수행
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );

      await currentUser.reauthenticateWithCredential(credential);

      // 재인증 성공시 다이얼로그 닫기
      if (!mounted) return;
      if (navigator.canPop()) {
        navigator.pop();
      }

      // 앱 삭제 실행
      await _deleteApp(app);

    } catch (e) {
      // 재인증 실패시 에러 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '비밀번호가 올바르지 않습니다. 다시 확인해주세요.',
              style: TextStyle(fontSize: 14.sp),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 금액 포맷팅 (천단위 쉼표)
  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}