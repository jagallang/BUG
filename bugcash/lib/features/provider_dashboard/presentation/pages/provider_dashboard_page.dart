import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // v2.50.1: 이용약관 동의 저장
import 'package:intl/intl.dart'; // v2.72.0: 거래 내역 날짜 포맷팅
import '../../../../core/utils/logger.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/constants/app_colors.dart';
import 'app_management_page.dart';
import '../../../tester_dashboard/presentation/pages/tester_dashboard_page.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
// v2.51.0: 지갑 기능 추가
import '../../../wallet/presentation/widgets/provider_wallet_card.dart';
// v2.74.0: 통합 지갑 페이지 추가
import '../../../wallet/presentation/pages/unified_wallet_page.dart';
// 채팅 기능 제거됨
// import '../widgets/payment_management_tab.dart';

class ProviderDashboardPage extends ConsumerStatefulWidget {
  final String providerId;

  const ProviderDashboardPage({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends ConsumerState<ProviderDashboardPage> {
  int _selectedIndex = 0;

  // v2.50.2: 가이드 확장 상태 관리
  final Set<int> _expandedSteps = {};

  // v2.50.4: 약관 동의 로컬 상태 (체크박스 상태만 관리)
  bool _termsCheckboxChecked = false;

  // v2.50.7: 약관 동의 처리 중 로딩 상태
  bool _isAcceptingTerms = false;

  @override
  void initState() {
    super.initState();
    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.info('Initializing Provider Dashboard for: ${widget.providerId}', 'ProviderDashboard');
    });
  }

  Widget _buildCurrentTab() {
    // 현재 사용자의 권한 확인
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final hasAdminRole = user?.roles.contains(UserType.admin) == true ||
                        user?.primaryRole == UserType.admin;

    switch (_selectedIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildAppsTab();
      case 2:
        // v2.74.0: 결제 탭 제거로 인덱스 변경 (2번 -> 관리자 탭)
        // 관리자 권한이 있는 경우에만 관리자 탭 표시
        if (hasAdminRole) {
          return _buildAdminTab();
        } else {
          // 권한이 없는 경우 대시보드로 리디렉션
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedIndex = 0);
            }
          });
          return _buildDashboardTab();
        }
      default:
        return _buildDashboardTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 사용자의 권한 확인
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final hasAdminRole = user?.roles.contains(UserType.admin) == true ||
                        user?.primaryRole == UserType.admin;

    // v2.74.0: 결제 탭 제거, 관리자 권한에 따라 네비게이션 아이템 구성
    final List<BottomNavigationBarItem> navigationItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: '사용안내',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.apps),
        label: '앱 관리',
      ),
      // 관리자 권한이 있을 때만 관리자 탭 표시
      if (hasAdminRole)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: '관리자',
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.providerBluePrimary, // v2.78.0: 파스텔 블루 테마
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: '테스터 모드로 전환',
          onPressed: () {
            // 테스터 대시보드로 이동
            final userId = CurrentUserService.getCurrentUserIdOrDefault();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => TesterDashboardPage(
                  testerId: userId,
                ),
              ),
            );
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // BUGS 텍스트 로고 - v2.78.0
            Text(
              'BUGS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    blurRadius: 2,
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // v2.73.0: 4개 아이콘 배치
          // 1. 프로필 아이콘
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            tooltip: '프로필',
            onPressed: () => _navigateToProfile(context),
          ),
          // 2. 지갑 아이콘 (공급자 전용: 포인트 충전)
          IconButton(
            icon: const Icon(Icons.wallet, color: Colors.white),
            tooltip: '포인트 충전',
            onPressed: () => _navigateToChargePoints(context),
          ),
          // 3. 알림 아이콘
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: '알림',
            onPressed: () => _showNotifications(context),
          ),
          // 4. 햄버거 메뉴
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: '메뉴',
            offset: Offset(0, 50.h),
            onSelected: (String value) {
              debugPrint('🔵 PopupMenu 선택됨: $value');
              switch (value) {
                case 'settings':
                  debugPrint('🔵 설정 메뉴 선택');
                  _navigateToSettings(context);
                  break;
                case 'logout':
                  debugPrint('🔵 로그아웃 메뉴 선택');
                  _showLogoutConfirmation(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 12.w),
                    const Text('설정'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red[600]),
                    SizedBox(width: 12.w),
                    const Text('로그아웃', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildCurrentTab(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.providerBluePrimary, // v2.78.0: 파스텔 블루 테마
        selectedItemColor: Colors.white,
        unselectedItemColor: AppColors.providerBlueLight.withValues(alpha: 0.7), // v2.78.0
        currentIndex: _selectedIndex,
        onTap: (index) {
          debugPrint('BottomNavigationBar tapped: $index');

          // 관리자 권한이 없는데 관리자 탭(3번)을 클릭한 경우 방지
          if (!hasAdminRole && index >= 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ 관리자 권한이 필요합니다'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          setState(() => _selectedIndex = index);
        },
        items: navigationItems,
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📱 앱 테스트 사용 가이드
          Text(
            '📱 BugCash 앱 테스트 사용 가이드',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.providerBluePrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '공급자님의 앱을 테스터들에게 검증받는 5단계 프로세스',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 32.h),

          // v2.50.2: Step 1-5 확장형 아코디언
          _buildAccordionStep(
            stepNumber: 1,
            title: '앱 등록하기',
            description: '테스트할 앱의 정보를 등록합니다.',
            details: [
              '• 앱 이름, 설명, 카테고리 입력',
              '• 테스트 기간 설정 (기본 14일)',
              '• 일일 미션 포인트 설정 (테스터 보상)',
              '• 앱 아이콘 및 스크린샷 업로드',
            ],
            icon: Icons.app_settings_alt, // v2.50.3: 설정이 들어간 앱 아이콘
            color: AppColors.providerBluePrimary, // v2.76.0: 색상 통일
          ),
          SizedBox(height: 12.h),

          _buildAccordionStep(
            stepNumber: 2,
            title: '테스터 자동 모집',
            description: '등록된 앱에 테스터들이 자동으로 지원합니다.',
            details: [
              '• 시스템이 자동으로 테스터 매칭',
              '• 테스터 프로필 및 경력 확인 가능',
              '• 테스터 탭에서 지원 현황 확인',
            ],
            icon: Icons.people,
            color: AppColors.providerBluePrimary, // v2.76.0: 색상 통일
          ),
          SizedBox(height: 12.h),

          _buildAccordionStep(
            stepNumber: 3,
            title: '일일 미션 자동 진행',
            description: '테스터들이 매일 앱을 테스트합니다.',
            details: [
              '• 14일 동안 매일 자동 미션 생성',
              '• 테스터가 앱 사용 및 피드백 제출',
              '• 실시간으로 진행 상황 모니터링',
              '• 오늘 탭에서 일일 미션 확인',
            ],
            icon: Icons.assignment_turned_in, // v2.50.3: 체크 표시가 있는 과제 아이콘
            color: AppColors.providerBluePrimary, // v2.76.0: 색상 통일
          ),
          SizedBox(height: 12.h),

          _buildAccordionStep(
            stepNumber: 4,
            title: '피드백 검토 및 승인',
            description: '테스터의 피드백을 검토하고 승인합니다.',
            details: [
              '• 오늘 탭에서 제출된 피드백 확인',
              '• 피드백 내용 검토 (텍스트, 스크린샷)',
              '• 승인 또는 반려 처리',
              '• 승인 시 테스터에게 포인트 지급',
            ],
            icon: Icons.rate_review,
            color: AppColors.providerBluePrimary, // v2.76.0: 색상 통일
          ),
          SizedBox(height: 12.h),

          _buildAccordionStep(
            stepNumber: 5,
            title: '테스트 완료 및 결과 확인',
            description: '14일 테스트 완료 후 종합 리포트를 확인합니다.',
            details: [
              '• 종료 탭에서 완료된 앱 확인',
              '• 전체 피드백 종합 분석',
              '• 테스터 평가 및 품질 개선 인사이트',
            ],
            icon: Icons.check_circle,
            color: AppColors.providerBluePrimary, // v2.76.0: 색상 통일
          ),
          SizedBox(height: 40.h),

          // v2.50.2: 이용 약관 동의 (모달) - 한 번 동의하면 숨김 처리
          Consumer(
            builder: (context, ref, child) {
              final user = ref.watch(authProvider).user;
              final termsAccepted = user?.providerProfile?.termsAccepted ?? false;

              // 이미 동의한 경우 전체 섹션 숨김
              if (termsAccepted) {
                return SizedBox.shrink();
              }

              return Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '✅ 이용 약관',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showTermsDialog(context),
                          icon: Icon(Icons.article, size: 18.sp),
                          label: Text('자세히 보기'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'BugCash 앱 테스트 서비스 이용약관 및 개인정보처리방침에 대한 동의가 필요합니다.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // v2.50.4: 동의 체크박스 (로컬 상태)
                    // v2.50.7: 동의 처리 중 로딩 표시
                    _isAcceptingTerms
                        ? Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: AppColors.primary, width: 2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20.sp,
                                  height: 20.sp,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  '동의 처리 중...',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: _termsCheckboxChecked ? AppColors.primary : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: _termsCheckboxChecked,
                                  onChanged: (value) {
                                    setState(() {
                                      _termsCheckboxChecked = value ?? false;
                                    });
                                  },
                                  title: Text(
                                    '이용약관 및 개인정보처리방침에 동의합니다',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  activeColor: AppColors.primary,
                                  dense: true,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              // v2.50.4: 동의 버튼
                              SizedBox(
                                width: double.infinity,
                                height: 48.h,
                                child: ElevatedButton(
                                  onPressed: _termsCheckboxChecked
                                      ? () => _handleTermsAcceptance(true)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _termsCheckboxChecked
                                        ? AppColors.primary
                                        : Colors.grey[400],
                                    disabledBackgroundColor: Colors.grey[400],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                  child: Text(
                                    _termsCheckboxChecked ? '동의하기' : '체크박스를 선택해주세요',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // v2.50.2: 확장 가능한 아코디언 스텝
  Widget _buildAccordionStep({
    required int stepNumber,
    required String title,
    required String description,
    required List<String> details,
    required IconData icon,
    required Color color,
  }) {
    final isExpanded = _expandedSteps.contains(stepNumber);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          childrenPadding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
          initiallyExpanded: false,
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedSteps.add(stepNumber);
              } else {
                _expandedSteps.remove(stepNumber);
              }
            });
          },
          leading: Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: color, size: 28.sp),
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'STEP $stepNumber',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details
                    .map((detail) => Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle, color: color, size: 16.sp),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  detail.replaceFirst('• ', ''),
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[800],
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppsTab() {
    AppLogger.info('🔧🔧🔧 Building Apps Tab', 'ProviderDashboard');
    AppLogger.info('Provider ID: ${widget.providerId}', 'ProviderDashboard');
    
    // 앱 관리 페이지 import 및 사용
    return AppManagementPage(providerId: widget.providerId);
  }



  // v2.52.0: 실시간 지갑 UI 적용
  Widget _buildPaymentTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 💳 내 지갑 카드 (v2.52.0: 실시간 데이터 연동)
          ProviderWalletCard(providerId: widget.providerId),
          SizedBox(height: 24.h),

          // 💸 포인트 충전 섹션 (TODO: Payment 모듈 개발 후 활성화)
          _buildChargeSection(),
          SizedBox(height: 24.h),

          // 📊 거래 내역 (TODO: TransactionListItem 사용하여 구현)
          _buildTransactionHistory(),
        ],
      ),
    );
  }

  // 💳 내 지갑 카드
  Widget _buildWalletCard() {
    const int currentBalance = 50000; // 하드코딩된 보유 포인트

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            colors: [Colors.indigo[700]!, AppColors.providerBluePrimary!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.white, size: 28.sp),
                    SizedBox(width: 12.w),
                    Text(
                      '내 포인트 지갑',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Text(
              '보유 포인트',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '${currentBalance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} P',
              style: TextStyle(
                fontSize: 36.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '💡 1,000원 = 1,000포인트',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💸 포인트 충전 섹션
  int _selectedChargeAmount = 30000;

  Widget _buildChargeSection() {
    final List<int> chargeOptions = [10000, 30000, 50000, 100000];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_card, color: AppColors.providerBluePrimary, size: 24.sp), // v2.76.0: 색상 통일
                SizedBox(width: 8.w),
                Text(
                  '포인트 충전',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // 충전 금액 선택 (드롭다운 + 결제 버튼)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedChargeAmount,
                        isExpanded: true,
                        items: chargeOptions.map((amount) {
                          return DropdownMenuItem<int>(
                            value: amount,
                            child: Text(
                              '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원 (${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} P)',
                              style: TextStyle(fontSize: 16.sp),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedChargeAmount = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Flexible(
                  fit: FlexFit.loose,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${_selectedChargeAmount}원 결제 기능은 곧 추가됩니다!'),
                          backgroundColor: AppColors.providerBluePrimary, // v2.76.0: 색상 통일
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.providerBluePrimary, // v2.76.0: 색상 통일
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.payment, color: Colors.white, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          '결제하기',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  // 📊 거래 내역 (v2.72.0: Firestore 실시간 데이터)
  Widget _buildTransactionHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: widget.providerId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48.sp),
                  SizedBox(height: 16.h),
                  Text(
                    '거래 내역을 불러올 수 없습니다',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 48.sp),
                  SizedBox(height: 16.h),
                  Text(
                    '아직 거래 내역이 없습니다',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          );
        }

        final transactions = snapshot.data!.docs;

        return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: AppColors.providerBluePrimary, size: 24.sp), // v2.76.0: 색상 통일
                SizedBox(width: 8.w),
                Text(
                  '최근 거래 내역',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            ...transactions.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final type = data['type'] as String? ?? 'unknown';
              final amount = data['amount'] as int? ?? 0;
              final description = data['description'] as String? ?? '거래';
              final createdAt = data['createdAt'] as Timestamp?;

              // 날짜 포맷팅
              String dateString = '미상';
              if (createdAt != null) {
                final date = createdAt.toDate();
                dateString = DateFormat('yyyy-MM-dd HH:mm').format(date);
              }

              // 타입에 따른 아이콘과 색상
              final isPositive = type == 'charge' || type == 'earn';
              final icon = isPositive ? Icons.add_circle : Icons.remove_circle;
              final color = isPositive ? Colors.green[600]! : Colors.red[600]!;

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 32.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            dateString,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${NumberFormat('#,###').format(amount)} P',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),

            SizedBox(height: 12.h),

            if (transactions.length >= 10)
              Center(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('전체 거래 내역 기능은 곧 추가됩니다!')),
                    );
                  },
                  child: Text(
                    '더보기',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.providerBluePrimary, // v2.76.0: 색상 통일
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
      },
    );
  }


  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }





  // Recent Activities Methods
  Widget _buildRecentActivities(List<Map<String, dynamic>> activities) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppColors.cardShadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 활동',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          if (activities.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  '최근 활동이 없습니다',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
                ),
              ),
            )
          else
            ...activities.take(3).map((activity) => _buildActivityItem(
              title: activity['title'] ?? '활동',
              subtitle: activity['description'] ?? '',
              time: _formatTime(activity['timestamp']),
              icon: _getActivityIcon(activity['type']),
              color: _getActivityColor(activity['priority']),
            )),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesLoading() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppColors.cardShadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 활동',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          ...List.generate(3, (index) => _buildActivityItemLoading()),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesError() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppColors.cardShadowMedium,
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
          SizedBox(height: 16.h),
          Text(
            '최근 활동을 불러올 수 없습니다',
            style: TextStyle(fontSize: 16.sp, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItemLoading() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  height: 12.h,
                  width: 100.w,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '방금 전';
    try {
      final DateTime time = timestamp is DateTime ? timestamp : DateTime.parse(timestamp.toString());
      final Duration diff = DateTime.now().difference(time);
      
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}분 전';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}시간 전';
      } else {
        return '${diff.inDays}일 전';
      }
    } catch (e) {
      return '방금 전';
    }
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'bug_report':
        return Icons.bug_report;
      case 'mission_completed':
        return Icons.check_circle;
      case 'tester_joined':
        return Icons.person_add;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }



  Widget _buildSimpleStatsCards() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Icon(Icons.apps, size: 32.sp, color: Colors.blue),
                  SizedBox(height: 8.h),
                  Text(
                    '0',
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '등록된 앱',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Icon(Icons.people, size: 32.sp, color: Colors.green),
                  SizedBox(height: 8.h),
                  Text(
                    '0',
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '테스터',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleRecentActivities() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: AppColors.cardShadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 활동',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Center(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    '아직 활동 내역이 없습니다',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '앱을 등록하고 테스터를 모집해보세요!',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12.sp),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // 관리자 탭 - 프로젝트 검수 기능
  Widget _buildAdminTab() {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const AdminDashboardPage(),
        );
      },
    );
  }

  // v2.50.2: 이용약관 전체 내용 모달 다이얼로그
  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: 700.w,
          height: 600.h,
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BugCash 서비스 이용약관',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Divider(height: 24.h, thickness: 2),

              // 스크롤 가능한 본문
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTermsSection(
                        '제1조 (목적)',
                        '본 약관은 BugCash(이하 "회사")가 제공하는 앱 테스트 중개 서비스(이하 "서비스")의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.',
                      ),
                      _buildTermsSection(
                        '제2조 (정의)',
                        '1. "앱 공급자"란 자신의 애플리케이션을 테스터에게 테스트받고자 서비스에 등록한 자를 말합니다.\n'
                        '2. "테스터"란 등록된 앱을 테스트하고 피드백을 제공하며 보상을 받는 자를 말합니다.\n'
                        '3. "포인트"란 테스터가 미션 완료 시 지급받는 가상의 보상으로, 추후 현금으로 환전할 수 있는 수단입니다.\n'
                        '4. "미션"이란 앱 공급자가 설정한 일일 테스트 과제를 의미합니다.',
                      ),
                      _buildTermsSection(
                        '제3조 (앱 공급자의 의무)',
                        '1. 앱 공급자는 등록하는 앱 정보가 정확하고 사실임을 보장해야 합니다.\n'
                        '2. 앱 공급자는 테스터가 제출한 피드백을 성실히 검토하고 승인/반려 처리해야 합니다.\n'
                        '3. 부적절하거나 불법적인 앱을 등록할 경우 서비스 이용이 제한될 수 있습니다.\n'
                        '4. 앱 공급자는 테스트 기간(기본 14일) 동안 앱의 정상 작동을 보장해야 합니다.',
                      ),
                      _buildTermsSection(
                        '제4조 (테스터의 의무)',
                        '1. 테스터는 성실하게 앱을 테스트하고 정확한 피드백을 제공해야 합니다.\n'
                        '2. 테스터는 일일 미션을 수행하며, 허위 또는 부실한 피드백 제출 시 포인트가 지급되지 않을 수 있습니다.\n'
                        '3. 테스터는 테스트 중 알게 된 정보를 외부에 유출하거나 부정한 목적으로 사용할 수 없습니다.',
                      ),
                      _buildTermsSection(
                        '제5조 (서비스 이용 및 포인트)',
                        '1. 앱 공급자가 설정한 포인트는 테스터의 미션 완료 및 피드백 승인 시 자동 지급됩니다.\n'
                        '2. 포인트는 테스트 완료 후 회사의 정산 정책에 따라 처리됩니다.\n'
                        '3. 부정한 방법으로 포인트를 획득하려는 시도 시 계정이 정지될 수 있습니다.',
                      ),
                      _buildTermsSection(
                        '제6조 (개인정보처리방침)',
                        '1. 회사는 이용자의 개인정보를 관련 법령에 따라 보호합니다.\n'
                        '2. 수집되는 개인정보: 이메일, 이름, 프로필 사진, 테스트 활동 기록\n'
                        '3. 개인정보는 서비스 제공, 포인트 지급, 사용자 인증 목적으로만 사용됩니다.\n'
                        '4. 이용자는 언제든지 개인정보 열람, 수정, 삭제를 요청할 수 있습니다.',
                      ),
                      _buildTermsSection(
                        '제7조 (서비스 제한)',
                        '1. 회사는 다음의 경우 서비스 이용을 제한할 수 있습니다:\n'
                        '   - 허위 정보 등록 또는 부정한 방법으로 서비스 이용 시\n'
                        '   - 다른 이용자의 권리를 침해하거나 명예를 훼손한 경우\n'
                        '   - 관련 법령 또는 본 약관을 위반한 경우\n'
                        '2. 서비스 제한 시 사전 통지를 원칙으로 하나, 긴급한 경우 사후 통지할 수 있습니다.',
                      ),
                      _buildTermsSection(
                        '제8조 (면책조항)',
                        '1. 회사는 천재지변, 시스템 장애 등 불가항력으로 인한 서비스 중단에 대해 책임을 지지 않습니다.\n'
                        '2. 회사는 이용자 간의 분쟁에 대해 중재 의무를 부담하지 않습니다.\n'
                        '3. 앱 테스트 결과에 대한 최종 책임은 앱 공급자에게 있습니다.',
                      ),
                      _buildTermsSection(
                        '제9조 (약관의 변경)',
                        '본 약관은 관련 법령 및 회사 정책에 따라 변경될 수 있으며, 변경 시 서비스 내 공지사항을 통해 고지합니다.',
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '시행일: 2025년 1월 1일\n문의: episode0611@gmail.com',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16.h),
              // 닫기 버튼
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(
                    '확인',
                    style: TextStyle(fontSize: 16.sp, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // v2.50.1: 이용약관 동의 처리
  // v2.50.3: Firestore 업데이트 완료 후 상태 반영 개선
  Future<void> _handleTermsAcceptance(bool accepted) async {
    // v2.50.7: 로딩 상태 시작
    setState(() {
      _isAcceptingTerms = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.error('사용자가 로그인되지 않았습니다', 'ProviderDashboard', null);
        setState(() {
          _isAcceptingTerms = false;
        });
        return;
      }

      AppLogger.info(
        'Terms acceptance: $accepted for user: ${currentUser.uid}',
        'ProviderDashboard',
      );

      // Firestore에 약관 동의 상태 업데이트
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
        'providerProfile': {
          'termsAccepted': accepted,
          'termsAcceptedAt': accepted ? FieldValue.serverTimestamp() : null,
        },
      }, SetOptions(merge: true));

      AppLogger.info('Firestore update completed, waiting for stream update...', 'ProviderDashboard');

      // v2.50.7: Firestore → AuthProvider 스트림 반영 시간 대기 (500ms → 1000ms)
      await Future.delayed(const Duration(milliseconds: 1000));

      // authProvider 재초기화 (Firestore 변경사항 반영)
      ref.invalidate(authProvider);

      // v2.50.7: 로딩 상태 종료
      if (mounted) {
        setState(() {
          _isAcceptingTerms = false;
          _termsCheckboxChecked = false; // 체크박스 초기화
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accepted ? '✅ 이용약관에 동의하셨습니다' : '❌ 이용약관 동의가 취소되었습니다',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: accepted ? AppColors.statusSuccess : AppColors.neutral600,
          ),
        );
      }

      AppLogger.info('Terms acceptance updated successfully', 'ProviderDashboard');
    } catch (e) {
      AppLogger.error('약관 동의 처리 실패', 'ProviderDashboard', e);

      // v2.50.7: 에러 시 로딩 상태 종료
      if (mounted) {
        setState(() {
          _isAcceptingTerms = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('약관 동의 처리 중 오류가 발생했습니다: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    }
  }

  // v2.73.0: 프로필 페이지로 이동
  void _navigateToProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('프로필 페이지 (개발 중)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // v2.74.0: 통합 지갑 페이지로 이동 (공급자 전용)
  void _navigateToChargePoints(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnifiedWalletPage(
          userId: widget.providerId,
          userType: 'provider',
        ),
      ),
    );
  }

  // v2.73.0: 알림 표시
  void _showNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('알림 기능 (개발 중)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // v2.73.0: 설정 페이지로 이동
  void _navigateToSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('설정 페이지 (개발 중)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // v2.73.0: 로그아웃 확인
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(authProvider.notifier).signOut();
              },
              child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}