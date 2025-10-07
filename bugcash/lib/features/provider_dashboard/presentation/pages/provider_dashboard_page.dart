import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // v2.50.1: 이용약관 동의 저장
import '../../../../core/utils/logger.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/constants/app_colors.dart';
import 'app_management_page.dart';
import '../../../tester_dashboard/presentation/pages/tester_dashboard_page.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
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
        return _buildPaymentTab();
      case 3:
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

    // 관리자 권한에 따라 네비게이션 아이템 구성
    final List<BottomNavigationBarItem> navigationItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: '대시보드',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.apps),
        label: '앱 관리',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.payment),
        label: '결제',
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
        backgroundColor: Colors.indigo[900],
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
        title: Text(
          '공급자 대시보드',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('알림 기능 (개발 중)')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프로필 기능 (개발 중)')),
              );
            },
          ),
        ],
      ),
      body: _buildCurrentTab(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.indigo[900],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.indigo[300],
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
              color: Colors.indigo[900],
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

          // Step 1: 앱 등록
          _buildGuideStep(
            stepNumber: '1',
            title: '앱 등록하기',
            description: '테스트할 앱의 정보를 등록합니다.',
            details: [
              '• 앱 이름, 설명, 카테고리 입력',
              '• 테스트 기간 설정 (기본 14일)',
              '• 일일 미션 포인트 설정 (테스터 보상)',
              '• 앱 아이콘 및 스크린샷 업로드',
            ],
            icon: Icons.app_registration,
            color: Colors.blue,
          ),
          SizedBox(height: 24.h),

          // Step 2: 테스터 모집
          _buildGuideStep(
            stepNumber: '2',
            title: '테스터 자동 모집',
            description: '등록된 앱에 테스터들이 자동으로 지원합니다.',
            details: [
              '• 시스템이 자동으로 테스터 매칭',
              '• 테스터 프로필 및 경력 확인 가능',
              '• 테스터 탭에서 지원 현황 확인',
            ],
            icon: Icons.people,
            color: Colors.green,
          ),
          SizedBox(height: 24.h),

          // Step 3: 일일 미션 진행
          _buildGuideStep(
            stepNumber: '3',
            title: '일일 미션 자동 진행',
            description: '테스터들이 매일 앱을 테스트합니다.',
            details: [
              '• 14일 동안 매일 자동 미션 생성',
              '• 테스터가 앱 사용 및 피드백 제출',
              '• 실시간으로 진행 상황 모니터링',
              '• 오늘 탭에서 일일 미션 확인',
            ],
            icon: Icons.task_alt,
            color: Colors.orange,
          ),
          SizedBox(height: 24.h),

          // Step 4: 피드백 검토
          _buildGuideStep(
            stepNumber: '4',
            title: '피드백 검토 및 승인',
            description: '테스터의 피드백을 검토하고 승인합니다.',
            details: [
              '• 오늘 탭에서 제출된 피드백 확인',
              '• 피드백 내용 검토 (텍스트, 스크린샷)',
              '• 승인 또는 반려 처리',
              '• 승인 시 테스터에게 포인트 지급',
            ],
            icon: Icons.rate_review,
            color: Colors.purple,
          ),
          SizedBox(height: 24.h),

          // Step 5: 테스트 완료
          _buildGuideStep(
            stepNumber: '5',
            title: '테스트 완료 및 결과 확인',
            description: '14일 테스트 완료 후 종합 리포트를 확인합니다.',
            details: [
              '• 종료 탭에서 완료된 앱 확인',
              '• 전체 피드백 종합 분석',
              '• 테스터 평가 및 품질 개선 인사이트',
            ],
            icon: Icons.check_circle,
            color: Colors.teal,
          ),
          SizedBox(height: 40.h),

          // v2.50.1: 이용 약관 동의
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ 이용 약관',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  '• 등록된 앱 정보는 테스터에게 공개됩니다\n'
                  '• 테스터 피드백은 성실히 검토해 주세요\n'
                  '• 포인트는 테스트 완료 후 자동 정산됩니다\n'
                  '• 부적절한 앱 등록 시 서비스 이용이 제한될 수 있습니다',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 16.h),
                // v2.50.1: 동의 체크박스
                Consumer(
                  builder: (context, ref, child) {
                    final user = ref.watch(authProvider).user;
                    final termsAccepted = user?.providerProfile?.termsAccepted ?? false;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: termsAccepted ? AppColors.primary : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: termsAccepted,
                        onChanged: (value) => _handleTermsAcceptance(value ?? false),
                        title: Text(
                          '위 이용약관을 확인하였으며 동의합니다',
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
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),

          // v2.50.1: 약관 동의 필수 - 시작하기 버튼
          Consumer(
            builder: (context, ref, child) {
              final user = ref.watch(authProvider).user;
              final termsAccepted = user?.providerProfile?.termsAccepted ?? false;

              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: termsAccepted
                          ? () {
                              // 앱 등록 탭으로 이동
                              setState(() {
                                _selectedIndex = 1; // 앱 탭
                              });
                            }
                          : null, // 약관 미동의 시 비활성화
                      style: ElevatedButton.styleFrom(
                        backgroundColor: termsAccepted ? Colors.indigo[700] : Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            termsAccepted ? Icons.rocket_launch : Icons.lock,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            termsAccepted ? '앱 등록하러 가기' : '이용약관 동의 필요',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!termsAccepted) ...[
                    SizedBox(height: 12.h),
                    Text(
                      '⚠️ 서비스 이용을 위해 위의 이용약관에 동의해주세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildGuideStep({
    required String stepNumber,
    required String title,
    required String description,
    required List<String> details,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Number Circle
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: color, size: 32.sp),
              ),
            ),
            SizedBox(width: 16.w),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'STEP $stepNumber',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...details.map((detail) => Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Text(
                          detail,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      )),
                ],
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



  Widget _buildPaymentTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 💳 내 지갑 카드
          _buildWalletCard(),
          SizedBox(height: 24.h),

          // 💸 포인트 충전 섹션
          _buildChargeSection(),
          SizedBox(height: 24.h),

          // 📊 거래 내역
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
            colors: [Colors.indigo[700]!, Colors.indigo[900]!],
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
                Icon(Icons.add_card, color: Colors.indigo[700], size: 24.sp),
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
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${_selectedChargeAmount}원 결제 기능은 곧 추가됩니다!'),
                        backgroundColor: Colors.indigo[700],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[700],
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Row(
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 📊 거래 내역
  Widget _buildTransactionHistory() {
    // 하드코딩된 샘플 거래 내역
    final List<Map<String, dynamic>> transactions = [
      {
        'type': 'charge',
        'description': '포인트 충전',
        'amount': 30000,
        'date': '2025-01-26 14:23',
        'balance': 80000,
      },
      {
        'type': 'spend',
        'description': '앱테스트 프로젝트 등록',
        'amount': -20000,
        'date': '2025-01-25 10:15',
        'balance': 50000,
      },
      {
        'type': 'charge',
        'description': '포인트 충전',
        'amount': 50000,
        'date': '2025-01-24 16:30',
        'balance': 70000,
      },
      {
        'type': 'spend',
        'description': '앱테스트 프로젝트 등록',
        'amount': -15000,
        'date': '2025-01-23 09:45',
        'balance': 20000,
      },
      {
        'type': 'charge',
        'description': '포인트 충전',
        'amount': 10000,
        'date': '2025-01-22 11:20',
        'balance': 35000,
      },
    ];

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
                Icon(Icons.receipt_long, color: Colors.indigo[700], size: 24.sp),
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

            ...transactions.map((transaction) {
              final isCharge = transaction['type'] == 'charge';
              final icon = isCharge ? Icons.add_circle : Icons.remove_circle;
              final color = isCharge ? Colors.green[600]! : Colors.red[600]!;

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
                            transaction['description'],
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            transaction['date'],
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isCharge ? '+' : ''}${transaction['amount'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} P',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '잔액: ${transaction['balance'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} P',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            SizedBox(height: 12.h),

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
                    color: Colors.indigo[700],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

  // v2.50.1: 이용약관 동의 처리
  Future<void> _handleTermsAcceptance(bool accepted) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.error('사용자가 로그인되지 않았습니다', 'ProviderDashboard', null);
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

      // v2.50.1: authProvider 재초기화 (Firestore 변경사항 반영)
      ref.invalidate(authProvider);

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
}