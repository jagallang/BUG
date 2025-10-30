import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wallet_entity.dart';
import '../providers/wallet_provider.dart';
import '../pages/transaction_history_page.dart';
import '../../../payment/presentation/pages/charge_point_page.dart';

/// 공급자 지갑 카드 위젯
/// - 현재 잔액 표시
/// - 이번 달 충전 금액
/// - 이번 달 사용 금액
/// - 충전 버튼 (Payment 모듈로 라우팅)
/// - 거래 내역 버튼
class ProviderWalletCard extends ConsumerWidget {
  final String providerId;

  const ProviderWalletCard({
    super.key,
    required this.providerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider(providerId));
    final monthlyChargedAsync = ref.watch(monthlyChargedProvider(providerId));
    final monthlySpentAsync = ref.watch(monthlySpentProvider(providerId));

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '내 지갑',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // 거래 내역 버튼
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TransactionHistoryPage(
                          userId: providerId,
                          userType: 'provider',
                        ),
                      ),
                    );
                  },
                  tooltip: '거래 내역',
                ),
              ],
            ),
            const Divider(height: 24),

            // 현재 잔액
            walletAsync.when(
              data: (wallet) => _buildBalanceSection(context, wallet),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '잔액을 불러올 수 없습니다\n${error.toString()}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 이번 달 통계
            Row(
              children: [
                Expanded(
                  child: monthlyChargedAsync.when(
                    data: (amount) => _buildStatCard(
                      context,
                      '이번 달 충전',
                      amount,
                      Icons.add_circle_outline,
                      Colors.green,
                    ),
                    loading: () => _buildLoadingStatCard(context, '이번 달 충전'),
                    error: (_, __) => _buildErrorStatCard(context, '이번 달 충전'),
                  ),
                ),
                const SizedBox(width: 12),
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
            ),

            const SizedBox(height: 20),

            // 충전 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChargePointPage(userId: providerId),
                    ),
                  );
                },
                icon: const Icon(Icons.credit_card),
                label: const Text(
                  '포인트 충전하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 잔액 표시 섹션
  Widget _buildBalanceSection(BuildContext context, WalletEntity wallet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '사용 가능 포인트',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatAmount(wallet.balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatAmount(amount),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 로딩 중 통계 카드
  Widget _buildLoadingStatCard(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }

  /// 에러 통계 카드
  Widget _buildErrorStatCard(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '오류',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  // ============================================================
  // v2.182.0: 에스크로 UI 완전 제거
  //
  // 에스크로 시스템은 백그라운드에서만 작동합니다:
  // - 앱 등록 시: depositToEscrow Cloud Function 자동 호출
  // - 전액 예치: wallets/{providerId}.balance → SYSTEM_ESCROW
  // - 자동 반환: 미션 완료 + 7일 후 자동으로 공급자 지갑으로 반환
  //
  // UI에는 순수하게 사용 가능한 지갑 잔액(wallet.balance)만 표시
  // ============================================================

  /* v2.180.0: 제거됨 - 에스크로 내역 확인 다이얼로그
  void _showEscrowDetails(BuildContext context) {
    // 에스크로 holdings 조회 및 표시
    // 더 이상 사용되지 않음
  }

  String _formatDate(dynamic timestamp) {
    // 날짜 포맷팅
    // 더 이상 사용되지 않음
  }
  */
}
