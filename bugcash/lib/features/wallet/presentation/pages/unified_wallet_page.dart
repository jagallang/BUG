import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/wallet_entity.dart';
import '../providers/wallet_provider.dart';
import '../widgets/withdrawal_dialog.dart';
import 'transaction_history_page.dart';
import '../../../../shared/widgets/responsive_wrapper.dart';

/// 통합 지갑 페이지
/// - 테스터: 잔액, 이번 달 적립, 총 적립, 출금 버튼, 거래 내역
/// - 공급자: 잔액, 이번 달 충전/사용, 총 충전, 포인트 충전 버튼, 거래 내역
class UnifiedWalletPage extends ConsumerStatefulWidget {
  final String userId;
  final String userType; // 'tester' or 'provider'

  const UnifiedWalletPage({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  ConsumerState<UnifiedWalletPage> createState() => _UnifiedWalletPageState();
}

class _UnifiedWalletPageState extends ConsumerState<UnifiedWalletPage> {
  int _selectedChargeAmount = 30000;

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider(widget.userId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.userType == 'tester' ? '내 지갑' : '포인트 지갑',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          // 거래 내역 버튼
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TransactionHistoryPage(
                    userId: widget.userId,
                    userType: widget.userType,
                  ),
                ),
              );
            },
            tooltip: '거래 내역',
          ),
        ],
      ),
      body: walletAsync.when(
        data: (wallet) => _buildContent(context, wallet),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.w,
                color: Colors.red[400],
              ),
              SizedBox(height: 16.h),
              Text(
                '지갑 정보를 불러올 수 없습니다',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[600],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '오류: ${error.toString()}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.red[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WalletEntity wallet) {
    return SingleChildScrollView(
      padding: ResponsiveWrapper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),

          // 1. 잔액 카드 (공통)
          _buildBalanceCard(context, wallet),

          SizedBox(height: 16.h),

          // 2. 월간 통계 (역할별)
          if (widget.userType == 'tester')
            _buildTesterMonthlyStats(context)
          else
            _buildProviderMonthlyStats(context),

          SizedBox(height: 16.h),

          // 3. 빠른 작업 버튼 (역할별)
          if (widget.userType == 'tester')
            _buildWithdrawalButton(context, wallet)
          else
            _buildChargeSection(),

          SizedBox(height: 24.h),

          // 4. 최근 거래 내역 미리보기
          _buildRecentTransactions(context),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  /// 잔액 카드 (공통)
  Widget _buildBalanceCard(BuildContext context, WalletEntity wallet) {
    final color = widget.userType == 'tester'
        ? Colors.green
        : Colors.indigo;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.shade700,
              color.shade500,
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 28.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  widget.userType == 'tester' ? '출금 가능 포인트' : '보유 포인트',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              _formatAmount(wallet.balance),
              style: TextStyle(
                color: Colors.white,
                fontSize: 36.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 테스터 월간 통계
  Widget _buildTesterMonthlyStats(BuildContext context) {
    final monthlyEarnedAsync = ref.watch(monthlyEarnedProvider(widget.userId));

    return Row(
      children: [
        Expanded(
          child: monthlyEarnedAsync.when(
            data: (amount) => _buildStatCard(
              context,
              '이번 달 적립',
              amount,
              Icons.savings_outlined,
              Colors.green,
            ),
            loading: () => _buildLoadingStatCard(context, '이번 달 적립'),
            error: (_, __) => _buildErrorStatCard(context, '이번 달 적립'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: monthlyEarnedAsync.when(
            data: (_) {
              final walletAsync = ref.watch(walletProvider(widget.userId));
              return walletAsync.maybeWhen(
                data: (wallet) => _buildStatCard(
                  context,
                  '총 적립 금액',
                  wallet.totalEarned,
                  Icons.trending_up,
                  Colors.blue,
                ),
                orElse: () => _buildLoadingStatCard(context, '총 적립 금액'),
              );
            },
            loading: () => _buildLoadingStatCard(context, '총 적립 금액'),
            error: (_, __) => _buildErrorStatCard(context, '총 적립 금액'),
          ),
        ),
      ],
    );
  }

  /// 공급자 월간 통계
  Widget _buildProviderMonthlyStats(BuildContext context) {
    final monthlyChargedAsync = ref.watch(monthlyChargedProvider(widget.userId));
    final monthlySpentAsync = ref.watch(monthlySpentProvider(widget.userId));

    return Row(
      children: [
        Expanded(
          child: monthlyChargedAsync.when(
            data: (amount) => _buildStatCard(
              context,
              '이번 달 충전',
              amount,
              Icons.add_circle_outline,
              Colors.blue,
            ),
            loading: () => _buildLoadingStatCard(context, '이번 달 충전'),
            error: (_, __) => _buildErrorStatCard(context, '이번 달 충전'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: monthlySpentAsync.when(
            data: (amount) => _buildStatCard(
              context,
              '이번 달 사용',
              amount,
              Icons.remove_circle_outline,
              Colors.orange,
            ),
            loading: () => _buildLoadingStatCard(context, '이번 달 사용'),
            error: (_, __) => _buildErrorStatCard(context, '이번 달 사용'),
          ),
        ),
      ],
    );
  }

  /// 통계 카드
  Widget _buildStatCard(
    BuildContext context,
    String label,
    int amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20.sp),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              _formatAmount(amount),
              style: TextStyle(
                color: color,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 로딩 중 통계 카드
  Widget _buildLoadingStatCard(BuildContext context, String label) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              height: 20.h,
              width: 20.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }

  /// 에러 통계 카드
  Widget _buildErrorStatCard(BuildContext context, String label) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '오류',
              style: TextStyle(
                color: Colors.red,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 출금 버튼 (테스터)
  Widget _buildWithdrawalButton(BuildContext context, WalletEntity wallet) {
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
                Icon(Icons.arrow_circle_up, color: Colors.green[700], size: 24.sp),
                SizedBox(width: 8.w),
                Text(
                  '출금',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              '출금 가능 금액: ${_formatAmount(wallet.balance)}',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => WithdrawalDialog(wallet: wallet),
                  );
                },
                icon: Icon(Icons.arrow_circle_up, size: 20.sp),
                label: Text(
                  '출금 신청',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 포인트 충전 섹션 (공급자)
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
                Flexible(
                  fit: FlexFit.loose,
                  child: ElevatedButton(
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

  /// 최근 거래 내역 미리보기
  Widget _buildRecentTransactions(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider(widget.userId));

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.grey[700], size: 24.sp),
                    SizedBox(width: 8.w),
                    Text(
                      '최근 거래',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TransactionHistoryPage(
                          userId: widget.userId,
                          userType: widget.userType,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    '전체보기',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 48.sp,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            '거래 내역이 없습니다',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 최근 3개만 표시
                final recentTransactions = transactions.take(3).toList();
                return Column(
                  children: recentTransactions.map((transaction) {
                    final isPositive = transaction.type == 'charge' || transaction.type == 'earn';
                    final color = isPositive ? Colors.green : Colors.red;
                    final icon = isPositive ? Icons.add : Icons.remove;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.1),
                        child: Icon(icon, color: color, size: 20.sp),
                      ),
                      title: Text(
                        transaction.description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _formatDate(transaction.createdAt),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Text(
                        '${isPositive ? '+' : '-'}${_formatAmount(transaction.amount)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: const CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Center(
                  child: Text(
                    '거래 내역을 불러올 수 없습니다',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 금액 포맷팅 (천단위 쉼표)
  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}P';
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
