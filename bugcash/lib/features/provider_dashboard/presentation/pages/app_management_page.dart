import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../shared/widgets/image_upload_widget.dart';
import 'app_detail_page.dart';
import 'mission_management_page_v2.dart';
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
  // v2.171.0: 테스트 설정 필드 추가 (앱게시관리 데이터 매칭용)
  final int? maxTesters;
  final int? testPeriodDays;
  final int? testTimeMinutes;
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
    // v2.171.0: 테스트 설정 필드 추가
    this.maxTesters,
    this.testPeriodDays,
    this.testTimeMinutes,
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
      // v2.171.0: 테스트 설정 필드 읽기 (Firestore 루트 레벨)
      maxTesters: data['maxTesters'] as int?,
      testPeriodDays: data['testPeriodDays'] as int?,
      testTimeMinutes: data['testTimeMinutes'] as int?,
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
  bool _isSubmitting = false; // v2.108.4: 중복 클릭 방지

  // v2.114.0: 스크린샷 업로드 진행상황 추적
  String _uploadStatus = ''; // 업로드 상태 메시지
  int _uploadedCount = 0; // 업로드 완료된 스크린샷 수
  int _totalCount = 0; // 전체 스크린샷 수

  // Basic info controllers
  final _appNameController = TextEditingController();
  final _appUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _testingGuidelinesController = TextEditingController();
  final _minOSVersionController = TextEditingController();
  final _appStoreUrlController = TextEditingController();

  // v2.98.0: 숫자 입력 필드 컨트롤러
  final _maxTestersController = TextEditingController();
  final _testPeriodDaysController = TextEditingController();
  // v2.112.0: _dailyMissionPointsController 제거 (MVP 간소화)
  final _finalCompletionPointsController = TextEditingController();
  // v2.122.0: 테스트 시간 컨트롤러
  final _testTimeMinutesController = TextEditingController();

  // Advanced options
  String _selectedCategory = 'Productivity';
  String _selectedInstallType = 'play_store';
  List<String> _selectedPlatforms = ['android'];
  int _maxTesters = 10;
  int _testPeriodDays = 14;
  // v2.112.0: _dailyMissionPoints 제거 (MVP 간소화 - 최종 완료 포인트만 사용)
  int _finalCompletionPoints = 1000;
  // v2.122.0: 테스트 시간 (분 단위)
  int _testTimeMinutes = 30;

  // v2.97.0: 앱 스크린샷 (최대 3장)
  List<XFile> _appScreenshots = [];

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
    // v2.98.0: 숫자 입력 필드 초기화
    _maxTestersController.text = _maxTesters.toString();
    _testPeriodDaysController.text = _testPeriodDays.toString();
    // v2.112.0: _dailyMissionPointsController 초기화 제거
    _finalCompletionPointsController.text = _finalCompletionPoints.toString();
    // v2.122.0: 테스트 시간 초기화
    _testTimeMinutesController.text = _testTimeMinutes.toString();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _appUrlController.dispose();
    _descriptionController.dispose();
    _testingGuidelinesController.dispose();
    _minOSVersionController.dispose();
    _appStoreUrlController.dispose();
    // v2.98.0: 숫자 입력 필드 컨트롤러 dispose
    _maxTestersController.dispose();
    _testPeriodDaysController.dispose();
    // v2.112.0: _dailyMissionPointsController dispose 제거
    _finalCompletionPointsController.dispose();
    // v2.122.0: 테스트 시간 컨트롤러 dispose
    _testTimeMinutesController.dispose();
    super.dispose();
  }

  /// v2.112.0: 앱 등록에 필요한 총 포인트 계산 (최종 완료 포인트만)
  int _calculateRequiredPoints() {
    // 최종 완료 포인트 × 최대 테스터 수
    return _finalCompletionPoints * _maxTesters;
  }

  Future<void> _uploadApp() async {
    // v2.108.4: 중복 실행 방지
    if (_isSubmitting) {
      AppLogger.warning('App registration already in progress', 'AppManagement');
      return;
    }

    if (_appNameController.text.isEmpty ||
        _appUrlController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력해주세요')),
      );
      return;
    }

    // v2.169.0: 잔액 검증 필수화 (우회 불가)
    final requiredPoints = _calculateRequiredPoints();
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
    final walletBalance = wallet.balance;
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

    // v2.169.0: 1단계 - 앱 등록 확인 (상세 정보 표시)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 등록 확인'),
        content: Text(
          '앱을 등록하시겠습니까?\n\n'
          '📊 프로젝트 포인트 계산:\n'
          '${_formatAmount(_finalCompletionPoints)}P/인 × $_maxTesters명 = ${_formatAmount(requiredPoints)}P\n\n'
          '💰 잔액 확인:\n'
          '현재 잔액: ${_formatAmount(walletBalance)}P\n'
          '차감 후 잔액: ${_formatAmount(walletBalance - requiredPoints)}P\n\n'
          '📋 앱 정보:\n'
          '• 미션 포인트: ${_formatAmount(_finalCompletionPoints)}P/인\n'
          '• 테스터 수: $_maxTesters명\n'
          '• 테스트 기간: $_testPeriodDays일',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('다음'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // v2.169.0: 2단계 - 포인트 차감 및 에스크로 보관 확인 (항상 실행)
    final escrowConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.orange[700], size: 28),
            const SizedBox(width: 8),
            const Text('포인트 차감 확인'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '앱 등록 시 포인트가 차감되어\n에스크로 계좌에 보관됩니다.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💰 프로젝트 포인트: ${_formatAmount(requiredPoints)}P',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(미션 포인트 ${_formatAmount(_finalCompletionPoints)}P/인 × $_maxTesters명)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '잔액: ${_formatAmount(walletBalance)}P → ${_formatAmount(walletBalance - requiredPoints)}P',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '📌 에스크로 보관 안내',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• 포인트는 에스크로 계좌에 안전하게 보관됩니다.\n'
              '• 테스터가 최종 미션을 완료하면 자동으로 지급됩니다.\n'
              '• 중도 취소 시 에스크로 포인트가 반환됩니다.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
            ),
            child: const Text('확인 및 차감'),
          ),
        ],
      ),
    );

    if (escrowConfirm != true || !mounted) return;

    // v2.108.4: 등록 시작 - 플래그 설정
    setState(() => _isSubmitting = true);

    try {
      // v2.114.0: 스크린샷 업로드 (진행상황 피드백 포함)
      List<String> screenshotUrls = [];
      if (_appScreenshots.isNotEmpty) {
        final storageService = StorageService();
        final tempAppId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

        // 진행상황 초기화
        setState(() {
          _totalCount = _appScreenshots.length;
          _uploadedCount = 0;
          _uploadStatus = '스크린샷 업로드 중... (0/$_totalCount)';
        });

        for (int i = 0; i < _appScreenshots.length; i++) {
          try {
            // 현재 업로드 중인 스크린샷 표시
            setState(() {
              _uploadStatus = '스크린샷 업로드 중... (${i + 1}/$_totalCount)';
            });

            final url = await storageService.uploadAppScreenshot(
              appId: tempAppId,
              file: _appScreenshots[i],
              index: i,
            );
            screenshotUrls.add(url);

            // 업로드 성공
            setState(() {
              _uploadedCount++;
              _uploadStatus = '스크린샷 업로드 완료 ($_uploadedCount/$_totalCount)';
            });

            AppLogger.info('Screenshot $i uploaded: $url', 'AppManagement');
          } catch (e) {
            AppLogger.error('Screenshot $i upload failed: $e', 'AppManagement');

            // 업로드 실패 - 사용자에게 알림
            setState(() {
              _uploadStatus = '스크린샷 ${i + 1} 업로드 실패 (계속 진행)';
            });

            // 짧은 대기 후 다음 파일로 진행
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }

        // 업로드 완료 메시지
        if (mounted) {
          setState(() {
            _uploadStatus = '스크린샷 업로드 완료 ($_uploadedCount/$_totalCount)';
          });
        }
      }

      final newProject = {
        'appId': '', // Will be set to document ID after creation
        'appName': _appNameController.text,
        'appUrl': _appUrlController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'installType': _selectedInstallType,
        'platform': _selectedPlatforms.first, // Primary platform
        'providerId': widget.providerId,
        'status': 'draft', // New projects start as draft

        // Extended fields matching database indexes
        'maxTesters': _maxTesters,
        'testPeriodDays': _testPeriodDays,
        'testTimeMinutes': _testTimeMinutes, // v2.122.0: 테스트 시간
        'rewardPoints': _finalCompletionPoints, // For backward compatibility
        'totalTesters': 0,
        // v2.43.0: activeTesters, totalBugs, resolvedBugs, progressPercentage 초기값 제거

        // Testing guidelines and requirements
        'testingGuidelines': _testingGuidelinesController.text,
        'minOSVersion': _minOSVersionController.text,
        'appStoreUrl': _appStoreUrlController.text,

        // v2.97.0: App screenshots
        'screenshots': screenshotUrls,

        // v2.112.0: 보상 시스템 간소화 (최종 완료 포인트만)
        'rewards': {
          'finalCompletionPoints': _finalCompletionPoints,
          'currency': 'KRW',
        },

        // Requirements matching indexed fields
        'requirements': {
          'platforms': _selectedPlatforms,
          'maxParticipants': _maxTesters,
          'testDuration': _testPeriodDays,
          'testTimeMinutes': _testTimeMinutes, // v2.122.0: 테스트 시간
        },

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),

        // Metadata with all config
        'metadata': {
          'installType': _selectedInstallType,
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

      // v2.167.0: 에스크로 예치는 필수 (포인트 검증과 무관하게 항상 실행)
      // Get user document for providerName
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.providerId)
          .get();

      final providerName = userDoc.data()?['displayName'] ?? '공급자';

      // Call depositToEscrow Cloud Function
      final depositFunction = FirebaseFunctions.instanceFor(region: 'asia-northeast1')
          .httpsCallable('depositToEscrow');

      try {
        // v2.112.0: 에스크로 breakdown 간소화 (일일 미션 포인트 제거)
        final result = await depositFunction.call({
          'appId': docRef.id,
          'appName': _appNameController.text,
          'providerId': widget.providerId,
          'providerName': providerName,
          'amount': requiredPoints,
          'breakdown': {
            'maxTesters': _maxTesters,
            'testPeriodDays': _testPeriodDays,
            'missionPoints': _finalCompletionPoints,
            'projectPoints': requiredPoints,
          },
        });

        AppLogger.info('✅ Escrow deposit successful: ${result.data}', 'AppManagement');
      } catch (escrowError) {
        // v2.167.0: 에스크로 예치 실패 시 앱 등록 롤백
        AppLogger.error('❌ Escrow deposit failed, rolling back app registration', escrowError.toString());

        try {
          await docRef.delete();
          AppLogger.info('App registration rolled back successfully', 'AppManagement');
        } catch (rollbackError) {
          AppLogger.error('Failed to rollback app registration', rollbackError.toString());
        }

        throw Exception('에스크로 예치 실패: 앱 등록이 취소되었습니다.\n$escrowError');
      }

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

        // v2.108.4: 등록 완료 - 플래그 해제
        setState(() => _isSubmitting = false);

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
              _appScreenshots = []; // v2.97.0: 스크린샷 초기화
              _selectedCategory = 'Productivity';
              _selectedInstallType = 'play_store';
              _selectedPlatforms = ['android'];
              _maxTesters = 10;
              _testPeriodDays = 14;
              _testTimeMinutes = 30; // v2.122.0: 테스트 시간 초기화
              // v2.112.0: _dailyMissionPoints 재설정 제거
              _finalCompletionPoints = 1000;
              // v2.122.0: 컨트롤러 초기화
              _maxTestersController.text = _maxTesters.toString();
              _testPeriodDaysController.text = _testPeriodDays.toString();
              _testTimeMinutesController.text = _testTimeMinutes.toString();
              _finalCompletionPointsController.text = _finalCompletionPoints.toString();
              // v2.114.0: 업로드 상태 초기화
              _uploadStatus = '';
              _uploadedCount = 0;
              _totalCount = 0;
            });
          }
        });
      }
    } catch (e) {
      AppLogger.error('Failed to upload app', e.toString());
      if (mounted) {
        // v2.114.0: 등록 실패 - 플래그 및 업로드 상태 초기화
        setState(() {
          _isSubmitting = false;
          _uploadStatus = '';
          _uploadedCount = 0;
          _totalCount = 0;
        });

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
          colors: [AppColors.providerBlueLight.withOpacity(0.3), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.providerBlueLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.providerBluePrimary.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // v2.132.0: Status Description 제거 (UI 간소화)

          // App Header (v2.133.0: 아이콘 제거, UI 간소화)
          Row(
            children: [
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
                        color: AppColors.providerBlueLight.withOpacity(0.3),
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withOpacity(0.3),
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
            color: Colors.black.withOpacity(0.1),
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
            // v2.97.0: App Screenshots Section
            _buildSectionHeader('앱 스크린샷 (최대 3장)'),
            SizedBox(height: 12.h),
            ImageUploadWidget(
              selectedImages: _appScreenshots,
              onImagesChanged: (images) {
                setState(() => _appScreenshots = images);
              },
              maxImages: 3,
              emptyStateText: '앱 스크린샷을 추가해주세요 (최대 3장)',
            ),
            SizedBox(height: 20.h),

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


            // v2.134.0: Install Type and Category Column (세로 배치)
            Column(
              children: [
                // 설치 방식 (구글 플레이 스토어로 고정)
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
                  onChanged: null, // v2.134.0: 구글 플레이 스토어로 고정 (비활성화)
                  disabledHint: const Text('구글 플레이 스토어'),
                  decoration: InputDecoration(
                    labelText: '설치 방식',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                // 카테고리
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
            // Max Testers and Test Period Row (v2.98.1: 레이아웃 수정)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxTestersController,
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
                SizedBox(width: 4.w),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32.w,
                      height: 28.h,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.add, size: 16.sp),
                        onPressed: () {
                          setState(() {
                            _maxTesters++;
                            _maxTestersController.text = _maxTesters.toString();
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 32.w,
                      height: 28.h,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.remove, size: 16.sp),
                        onPressed: () {
                          setState(() {
                            if (_maxTesters > 1) {
                              _maxTesters--;
                              _maxTestersController.text = _maxTesters.toString();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextFormField(
                    controller: _testPeriodDaysController,
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
                SizedBox(width: 4.w),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32.w,
                      height: 28.h,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.add, size: 16.sp),
                        onPressed: () {
                          setState(() {
                            _testPeriodDays++;
                            _testPeriodDaysController.text = _testPeriodDays.toString();
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 32.w,
                      height: 28.h,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.remove, size: 16.sp),
                        onPressed: () {
                          setState(() {
                            if (_testPeriodDays > 1) {
                              _testPeriodDays--;
                              _testPeriodDaysController.text = _testPeriodDays.toString();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // v2.122.0: 테스트 시간 설정
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _testTimeMinutesController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _testTimeMinutes = int.tryParse(value) ?? 30;
                    },
                    decoration: InputDecoration(
                      labelText: '테스트 시간 (분)',
                      hintText: '테스터가 앱을 사용할 시간',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32.w,
                      height: 28.h,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.add, size: 16.sp),
                        onPressed: () {
                          setState(() {
                            _testTimeMinutes += 5;
                            _testTimeMinutesController.text = _testTimeMinutes.toString();
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 32.w,
                      height: 28.h,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.remove, size: 16.sp),
                        onPressed: () {
                          setState(() {
                            if (_testTimeMinutes > 5) {
                              _testTimeMinutes -= 5;
                              _testTimeMinutesController.text = _testTimeMinutes.toString();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // v2.112.0: 보상 설정 간소화 (최종 완료 포인트만)
            _buildSectionHeader('보상 설정'),
            SizedBox(height: 12.h),
            // 최종 완료 포인트
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _finalCompletionPointsController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _finalCompletionPoints = int.tryParse(value) ?? 1000;
                    },
                    decoration: InputDecoration(
                      labelText: '미션 포인트 (1명당)',
                      hintText: '테스터 1명이 최종 완료 시 받는 포인트',
                      suffixText: 'P/인',
                      helperText: '프로젝트 포인트 = ${_formatAmount(_calculateRequiredPoints())}P (총 $_maxTesters명)',
                      helperMaxLines: 2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32.w,
                      height: 28.h,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.add, size: 16.sp),
                        onPressed: () {
                          setState(() {
                            _finalCompletionPoints += 100;
                            _finalCompletionPointsController.text = _finalCompletionPoints.toString();
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 32.w,
                      height: 28.h,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.remove, size: 16.sp),
                        onPressed: () {
                          setState(() {
                            if (_finalCompletionPoints > 100) {
                              _finalCompletionPoints -= 100;
                              _finalCompletionPointsController.text = _finalCompletionPoints.toString();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // v2.169.0: 프로젝트 포인트 계산 표시
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate, size: 18.sp, color: Colors.blue.shade700),
                      SizedBox(width: 6.w),
                      Text(
                        '프로젝트 포인트 계산',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${_formatAmount(_finalCompletionPoints)}P/인 × $_maxTesters명 = ${_formatAmount(_calculateRequiredPoints())}P',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '앱 등록 시 ${_formatAmount(_calculateRequiredPoints())}P가 에스크로에 예치됩니다',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Additional Info Section
            _buildSectionHeader('앱테스트 방법'),
            SizedBox(height: 12.h),
            TextField(
              controller: _testingGuidelinesController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: '테스팅 가이드라인',
                hintText: '테스터가 따라야 할 구체적인 테스팅 지침을 작성하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 30.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48.h,
                    child: OutlinedButton(
                      onPressed: () async {
                        // v2.113.0: 취소 확인 모달 추가
                        final confirmCancel = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('앱 등록 취소'),
                            content: Text(
                              _isSubmitting
                                  ? '앱 등록을 취소하시겠습니까?\n\n진행 중인 작업이 중단됩니다.'
                                  : '앱 등록을 취소하시겠습니까?\n\n입력한 내용이 저장되지 않습니다.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('계속 작성'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('취소'),
                              ),
                            ],
                          ),
                        );

                        if (confirmCancel == true && mounted) {
                          if (_isSubmitting) {
                            setState(() {
                              _isSubmitting = false;
                              _showUploadDialog = false;
                              // v2.114.0: 업로드 상태 초기화
                              _uploadStatus = '';
                              _uploadedCount = 0;
                              _totalCount = 0;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('앱 등록이 취소되었습니다'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          } else {
                            setState(() {
                              _showUploadDialog = false;
                            });
                          }
                        }
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
                      onPressed: _isSubmitting ? null : _uploadApp, // v2.108.4: 중복 클릭 방지
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.providerBluePrimary, // v2.76.0: 색상 통일
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: _isSubmitting // v2.114.0: 로딩 및 업로드 상태 표시
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              if (_uploadStatus.isNotEmpty) ...[
                                SizedBox(width: 8.w),
                                Flexible(
                                  child: Text(
                                    _uploadStatus,
                                    style: TextStyle(fontSize: 12.sp, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          )
                        : const Text('등록'),
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
          selectedColor: AppColors.primary.withOpacity(0.2),
          checkmarkColor: AppColors.primary,
        );
      }).toList(),
    );
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

  /// v2.110.0: 앱 삭제 확인 다이얼로그 (에스크로 환불 정보 표시)
  Future<void> _showDeleteConfirmation(ProviderAppModel app) async {
    // v2.110.0: 에스크로 홀딩 조회
    int refundAmount = 0;
    bool isLoadingEscrow = true;

    try {
      final holdingsQuery = await FirebaseFirestore.instance
          .collection('escrow_holdings')
          .where('appId', isEqualTo: app.id)
          .where('status', isEqualTo: 'active')
          .get();

      for (var doc in holdingsQuery.docs) {
        final data = doc.data();
        refundAmount += (data['remainingAmount'] as int?) ?? (data['totalAmount'] as int?) ?? 0;
      }
      isLoadingEscrow = false;
    } catch (e) {
      AppLogger.warning('Failed to fetch escrow holdings: $e', 'AppManagement');
      isLoadingEscrow = false;
    }

    if (!mounted) return;

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
              SizedBox(height: 12.h),

              // 앱 정보
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 ${app.appName}',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
                    ),
                    Text(
                      '📂 ${app.category}',
                      style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),

              // v2.110.0: 환불 정보 표시
              if (refundAmount > 0) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.green[700], size: 18.sp),
                          SizedBox(width: 6.w),
                          Text(
                            '에스크로 환불',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        '💰 ${_formatAmount(refundAmount)}P',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '→ 지갑으로 자동 환불됩니다',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 12.h),

              // 경고 메시지
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red[700], size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '⚠️ 이 작업은 되돌릴 수 없습니다.',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
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

      // v2.110.0: 환불 완료 안내 (2초 후 표시 - Function 실행 시간 고려)
      if (mounted && refundAmount > 0) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '💰 ${_formatAmount(refundAmount)}P 환불 처리 중...\n잠시 후 지갑을 확인하세요',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        });
      }
    }
  }

  /// v2.109.0: 앱 삭제 실행 (워크플로우 체크 추가)
  Future<void> _deleteApp(ProviderAppModel app) async {
    try {
      // v2.109.0: draft 상태가 아니면 삭제 불가
      if (app.status != 'draft') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '삭제 불가: "${_getStatusDisplayName(app.status)}" 상태\n\n'
                'draft 상태의 앱만 삭제할 수 있습니다.\n'
                '진행 중인 프로젝트는 관리자에게 문의하세요.'
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // v2.109.0: 연관된 워크플로우 확인
      final workflowQuery = await FirebaseFirestore.instance
          .collection('mission_workflows')
          .where('projectId', isEqualTo: app.id)
          .get();

      // 워크플로우가 있으면 경고 (draft인데 워크플로우가 있는 경우 정리)
      if (workflowQuery.docs.isNotEmpty) {
        AppLogger.warning(
          'Found ${workflowQuery.docs.length} workflows for draft project ${app.id}, will clean up',
          'AppManagement'
        );
      }

      // v2.109.0: 프로젝트 삭제 (Firestore rules에서 draft 체크)
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(app.id)
          .delete();

      // v2.109.0: draft 상태 워크플로우 정리
      for (var doc in workflowQuery.docs) {
        try {
          await doc.reference.delete();
          AppLogger.info('Deleted workflow ${doc.id} for project ${app.id}', 'AppManagement');
        } catch (e) {
          AppLogger.warning('Failed to delete workflow ${doc.id}: $e', 'AppManagement');
          // 워크플로우 삭제 실패는 무시 (프로젝트는 이미 삭제됨)
        }
      }

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
        String errorMessage = '앱 삭제에 실패했습니다';

        // v2.109.0: Firestore 권한 에러 감지
        if (e.toString().contains('PERMISSION_DENIED') ||
            e.toString().contains('permission-denied')) {
          errorMessage = '삭제 권한이 없습니다\n\n'
                        'draft 상태의 앱만 삭제할 수 있습니다.\n'
                        '현재 상태: ${_getStatusDisplayName(app.status)}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// v2.109.0: 상태 표시명 반환
  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'draft': return '접수 대기';
      case 'pending': return '검수 중';
      case 'open': return '모집 중';
      case 'closed': return '완료';
      case 'rejected': return '거부';
      default: return status;
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
                child: Icon(Icons.visibility, color: Colors.green, size: 16.sp), // v2.132.0: 텍스트 제거, 아이콘만 표시
              ),
              DropdownMenuItem<String>(
                value: 'hidden',
                child: Icon(Icons.visibility_off, color: Colors.grey, size: 16.sp), // v2.132.0: 텍스트 제거, 아이콘만 표시
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
          side: const BorderSide(color: AppColors.providerBluePrimary, width: 1.5),
          backgroundColor: AppColors.providerBlueLight.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
        ),
        // v2.132.0: 텍스트 제거, 아이콘만 표시
        child: Icon(
          Icons.edit,
          color: AppColors.providerBluePrimary,
          size: 16.sp,
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
          debugPrint('🔵 [AppManagement] 미션 버튼 클릭\n'
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
          shadowColor: canUse ? AppColors.providerBluePrimary.withOpacity(0.4) : null,
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