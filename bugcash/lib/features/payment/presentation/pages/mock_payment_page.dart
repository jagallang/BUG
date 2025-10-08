import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/error_message_helper.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

/// Mock 결제 페이지 (테스트용)
/// Toss API 없이 결제 로직만 테스트
class MockPaymentPage extends ConsumerStatefulWidget {
  final String userId;
  final int amount;

  const MockPaymentPage({
    super.key,
    required this.userId,
    required this.amount,
  });

  @override
  ConsumerState<MockPaymentPage> createState() => _MockPaymentPageState();
}

class _MockPaymentPageState extends ConsumerState<MockPaymentPage> {
  bool _isProcessing = false;

  /// Mock 결제 성공 시뮬레이션
  Future<void> _simulatePaymentSuccess() async {
    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      debugPrint('🔵 Mock 결제 시작 - userId: ${widget.userId}, amount: ${widget.amount}');

      // Mock paymentKey와 orderId 생성
      final mockPaymentKey = 'mock_${DateTime.now().millisecondsSinceEpoch}';
      final mockOrderId = 'order_${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('🔵 Mock 결제 정보 생성 - paymentKey: $mockPaymentKey, orderId: $mockOrderId');

      // 2초 대기 (실제 결제처럼)
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      debugPrint('🔵 WalletService.chargePoints 호출 전');

      // WalletService Provider를 통해 포인트 충전
      final walletService = ref.read(walletServiceProvider);

      await walletService.chargePoints(
        widget.userId,
        widget.amount,
        'Mock 포인트 충전 (테스트)',
        metadata: {
          'paymentKey': mockPaymentKey,
          'orderId': mockOrderId,
          'paymentMethod': 'mock',
          'isMockPayment': true,
        },
      );

      debugPrint('✅ WalletService.chargePoints 완료');

      if (!mounted) return;

      // Wallet provider 새로고침
      ref.invalidate(walletProvider(widget.userId));

      // 성공 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Mock 결제 성공! ${widget.amount}P 충전되었습니다'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // 잠시 대기 후 페이지 닫기
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Mock 결제 실패: $e');
      debugPrint('StackTrace: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMessageHelper.getShortErrorMessage(e)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Mock 결제 실패 시뮬레이션
  Future<void> _simulatePaymentFailure() async {
    setState(() => _isProcessing = true);

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Mock 결제 실패 (테스트)'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Mock 중복 결제 시뮬레이션
  Future<void> _simulateDuplicatePayment() async {
    setState(() => _isProcessing = true);

    try {
      // 같은 orderId로 2번 충전 시도
      final mockOrderId = 'duplicate_order_123';
      final walletService = ref.read(walletServiceProvider);

      // 첫 번째 충전
      await walletService.chargePoints(
        widget.userId,
        widget.amount,
        'Mock 중복 결제 테스트 #1',
        metadata: {
          'orderId': mockOrderId,
          'isMockPayment': true,
        },
      );

      // 두 번째 충전 (실제로는 차단되어야 함)
      await walletService.chargePoints(
        widget.userId,
        widget.amount,
        'Mock 중복 결제 테스트 #2',
        metadata: {
          'orderId': mockOrderId,
          'isMockPayment': true,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ 중복 결제가 처리되었습니다 (테스트)'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMessageHelper.getShortErrorMessage(e)),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Mock 대량 거래 시뮬레이션 (알림 테스트)
  Future<void> _simulateLargeTransaction() async {
    setState(() => _isProcessing = true);

    try {
      final walletService = ref.read(walletServiceProvider);

      // 1000만원 충전 (알림 발생 테스트)
      await walletService.chargePoints(
        widget.userId,
        10000000,
        'Mock 대량 거래 테스트',
        metadata: {
          'isMockPayment': true,
          'isLargeTransaction': true,
        },
      );

      if (!mounted) return;

      ref.invalidate(walletProvider(widget.userId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 대량 거래 처리 완료 (알림 발생 확인)'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMessageHelper.getShortErrorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock 결제 테스트'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('결제 처리 중...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 안내 메시지
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            '실제 Toss API 없이 결제 로직만 테스트합니다',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // 결제 정보
                  Text(
                    '결제 정보',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 12.h),

                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('충전 금액', style: TextStyle(fontSize: 16.sp)),
                            Text(
                              '${widget.amount}원',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 24.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('충전 포인트', style: TextStyle(fontSize: 16.sp)),
                            Text(
                              '${widget.amount}P',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // 테스트 시나리오 버튼들
                  Text(
                    '테스트 시나리오',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // 성공 시나리오
                  _buildTestButton(
                    icon: Icons.check_circle,
                    title: '결제 성공',
                    subtitle: '정상적인 결제 플로우 테스트',
                    color: Colors.green,
                    onTap: _simulatePaymentSuccess,
                  ),

                  SizedBox(height: 12.h),

                  // 실패 시나리오
                  _buildTestButton(
                    icon: Icons.error,
                    title: '결제 실패',
                    subtitle: '결제 실패 에러 처리 테스트',
                    color: Colors.red,
                    onTap: _simulatePaymentFailure,
                  ),

                  SizedBox(height: 12.h),

                  // 중복 결제 시나리오
                  _buildTestButton(
                    icon: Icons.warning,
                    title: '중복 결제 시도',
                    subtitle: '중복 결제 차단 로직 테스트',
                    color: Colors.orange,
                    onTap: _simulateDuplicatePayment,
                  ),

                  SizedBox(height: 12.h),

                  // 대량 거래 시나리오
                  _buildTestButton(
                    icon: Icons.trending_up,
                    title: '대량 거래 (1000만원)',
                    subtitle: '거래 모니터링 알림 테스트',
                    color: Colors.purple,
                    onTap: _simulateLargeTransaction,
                  ),

                  SizedBox(height: 32.h),

                  // 취소 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTestButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
