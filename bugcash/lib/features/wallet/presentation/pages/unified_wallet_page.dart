import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/wallet_provider.dart';
import '../widgets/withdrawal_dialog.dart';
import 'transaction_history_page.dart';
import '../../../../shared/widgets/responsive_wrapper.dart';

/// v2.147.0: 완전 통합 지갑 페이지
/// - 모든 사용자: 잔액, 포인트 충전, 출금, 거래 내역
/// - 역할 구분 없이 동일한 UI 제공
class UnifiedWalletPage extends ConsumerStatefulWidget {
  final String userId;

  const UnifiedWalletPage({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<UnifiedWalletPage> createState() => _UnifiedWalletPageState();
}

class _UnifiedWalletPageState extends ConsumerState<UnifiedWalletPage> {
  int _selectedChargeAmount = 30000;

  @override
  Widget build(BuildContext context) {
    print('🟦 [UnifiedWalletPage] build() - userId: ${widget.userId}');
    final walletAsync = ref.watch(walletProvider(widget.userId));

    // v2.155.0: 상세 디버깅 로그
    print('🔍 [v2.155.0] walletAsync = $walletAsync');
    print('🔍 [v2.155.0] walletAsync.isLoading = ${walletAsync.isLoading}');
    print('🔍 [v2.155.0] walletAsync.hasValue = ${walletAsync.hasValue}');
    print('🔍 [v2.155.0] walletAsync.hasError = ${walletAsync.hasError}');
    if (walletAsync.hasValue) {
      print('🔍 [v2.155.0] walletAsync.value.balance = ${walletAsync.value?.balance}');
    }
    if (walletAsync.hasError) {
      print('🔍 [v2.155.0] walletAsync.error = ${walletAsync.error}');
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '내 지갑', // v2.147.0: 역할 구분 없이 통일
          style: TextStyle(
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
                    userType: 'unified', // v2.147.0: 통합 모드
                  ),
                ),
              );
            },
            tooltip: '거래 내역',
          ),
        ],
      ),
      body: walletAsync.when(
        data: (wallet) {
          print('✅ [v2.155.0] DATA 콜백 실행 - balance: ${wallet.balance}');
          return _buildContent(context, wallet);
        },
        loading: () {
          print('⏳ [v2.155.0] LOADING 콜백 실행');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          print('❌ [v2.155.0] ERROR 콜백 실행: $error');
          print('❌ [v2.155.0] Stack: $stack');
          return Center(
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
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, WalletEntity wallet) {
    // v2.154.0: 디버그 로그와 try-catch 제거, 원래 빌드 방식으로 복원
    return SingleChildScrollView(
      padding: ResponsiveWrapper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),

          // 1. 잔액 카드 (공통)
          _buildBalanceCard(context, wallet),

          SizedBox(height: 16.h),

          // v2.147.0: 통합 작업 버튼 (출금 + 충전)
          _buildUnifiedActionsSection(wallet),

          SizedBox(height: 24.h),

          // 4. 최근 거래 내역 미리보기
          _buildRecentTransactions(context),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  /// v2.147.0: 잔액 카드 (통합)
  Widget _buildBalanceCard(BuildContext context, WalletEntity wallet) {
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
              Colors.blue.shade700, // v2.147.0: 통일된 테마 색상
              Colors.blue.shade500,
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
                  '보유 포인트', // v2.147.0: 통일된 레이블
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

  /// v2.147.0: 통합 작업 섹션 (출금 + 충전)
  Widget _buildUnifiedActionsSection(WalletEntity wallet) {
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
            // 포인트 충전 섹션
            Row(
              children: [
                Icon(Icons.add_card, color: Colors.blue[700], size: 24.sp),
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
            SizedBox(height: 16.h),

            // v2.155.0: BoxConstraints 에러 수정 - Column으로 변경
            // 충전 금액 선택 드롭다운
            Container(
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
                        '${_formatAmount(amount)}',
                        style: TextStyle(fontSize: 16.sp),
                        overflow: TextOverflow.ellipsis,
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
            SizedBox(height: 12.h),
            // 결제 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_formatAmount(_selectedChargeAmount)} 결제 기능은 곧 추가됩니다!'),
                      backgroundColor: Colors.blue[700],
                    ),
                  );
                },
                icon: Icon(Icons.payment, size: 20.sp),
                label: Text(
                  '결제하기',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),
            Divider(height: 1, color: Colors.grey[300]),
            SizedBox(height: 24.h),

            // 출금 섹션
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
                          userType: 'unified', // v2.147.0: 통합 지갑 모드
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
                    final isPositive = transaction.type == TransactionType.charge || transaction.type == TransactionType.earn;
                    final color = isPositive ? Colors.green : Colors.red;
                    final icon = isPositive ? Icons.add : Icons.remove;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.1), // v2.150.0: withValues → withOpacity (호환성)
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
