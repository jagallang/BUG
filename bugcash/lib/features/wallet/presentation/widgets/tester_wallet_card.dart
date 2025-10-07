import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wallet_entity.dart';
import '../providers/wallet_provider.dart';

/// 테스터 지갑 카드 위젯
/// - 현재 잔액 표시
/// - 이번 달 적립 금액
/// - 총 적립 금액
/// - 출금 버튼 (출금 다이얼로그)
/// - 거래 내역 버튼
class TesterWalletCard extends ConsumerWidget {
  final String testerId;

  const TesterWalletCard({
    super.key,
    required this.testerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider(testerId));
    final monthlyEarnedAsync = ref.watch(monthlyEarnedProvider(testerId));

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
                // TODO: 거래 내역 버튼
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    // TODO: 거래 내역 페이지로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('거래 내역 기능은 개발 예정입니다')),
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

            // 통계 섹션
            walletAsync.when(
              data: (wallet) => Row(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      '총 적립 금액',
                      wallet.totalEarned,
                      Icons.trending_up,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              loading: () => Row(
                children: [
                  Expanded(child: _buildLoadingStatCard(context, '이번 달 적립')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildLoadingStatCard(context, '총 적립 금액')),
                ],
              ),
              error: (_, __) => Row(
                children: [
                  Expanded(child: _buildErrorStatCard(context, '이번 달 적립')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildErrorStatCard(context, '총 적립 금액')),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 출금 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: 출금 다이얼로그 표시
                  _showWithdrawDialog(context, walletAsync.value);
                },
                icon: const Icon(Icons.arrow_circle_up),
                label: const Text(
                  '출금 신청',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.green,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade700,
            Colors.green.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '출금 가능 포인트',
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

  /// 출금 다이얼로그
  /// TODO: 출금 신청 프로세스 구현
  /// TODO: 최소 출금 금액 검증 (예: 10,000P 이상)
  /// TODO: 출금 수수료 계산 표시
  /// TODO: 은행 계좌 정보 입력/관리
  /// TODO: 출금 신청 후 상태 관리 (pending → completed)
  void _showWithdrawDialog(BuildContext context, WalletEntity? wallet) {
    if (wallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지갑 정보를 불러올 수 없습니다')),
      );
      return;
    }

    // TODO: 최소 출금 금액 체크
    const minWithdrawAmount = 10000;
    if (wallet.balance < minWithdrawAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('최소 출금 금액은 ${_formatAmount(minWithdrawAmount)}입니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('출금 신청'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('출금 가능 금액: ${_formatAmount(wallet.balance)}'),
            const SizedBox(height: 16),
            const Text(
              '출금 기능은 개발 예정입니다.',
              style: TextStyle(color: Colors.orange),
            ),
            const SizedBox(height: 8),
            const Text(
              'TODO:\n'
              '- 출금 금액 입력\n'
              '- 은행 계좌 정보 입력/선택\n'
              '- 출금 수수료 계산 표시\n'
              '- 출금 신청 처리\n'
              '- 출금 내역 관리',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
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
}
