import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tosspayments_widget_sdk_flutter/payment_widget.dart';
import 'package:tosspayments_widget_sdk_flutter/model/payment_widget_options.dart';
import 'package:tosspayments_widget_sdk_flutter/model/payment_info.dart';
import 'package:tosspayments_widget_sdk_flutter/widgets/payment_method.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../providers/payment_provider.dart';
import 'payment_success_page.dart';

/// 토스 결제 위젯 페이지
///
/// ⚠️ [개발 중] 토스페이먼츠 결제 기능은 현재 개발 중입니다.
/// TODO: 토스페이먼츠 Widget SDK 연동 및 결제 프로세스 구현 필요
class TossPaymentPage extends ConsumerStatefulWidget {
  final String userId;
  final int amount;

  const TossPaymentPage({
    super.key,
    required this.userId,
    required this.amount,
  });

  @override
  ConsumerState<TossPaymentPage> createState() => _TossPaymentPageState();
}

class _TossPaymentPageState extends ConsumerState<TossPaymentPage> {
  late PaymentWidget _paymentWidget;
  String? _orderId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _preparePayment();
  }

  /// 결제 준비
  Future<void> _preparePayment() async {
    try {
      // 결제 준비 (orderId 생성 및 Firestore 저장)
      final payment = await ref.read(
        preparePaymentProvider(
          PreparePaymentParams(
            userId: widget.userId,
            amount: widget.amount,
          ),
        ).future,
      );

      final config = ref.read(testPaymentConfigProvider);

      setState(() {
        _orderId = payment.orderId;
        _paymentWidget = PaymentWidget(
          clientKey: config.clientKey,
          customerKey: widget.userId,
        );
        _isLoading = false;
      });

      // 결제위젯 렌더링
      await _paymentWidget.renderPaymentMethods(
        selector: 'payment-method',
        amount: Amount(
          currency: Currency.KRW,
          value: widget.amount.toDouble(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('결제 준비 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  /// 결제 요청
  Future<void> _requestPayment() async {
    if (_orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('결제 정보가 없습니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 토스 결제 위젯 호출
      final result = await _paymentWidget.requestPayment(
        paymentInfo: PaymentInfo(
          orderId: _orderId!,
          orderName: '벅스리워드 포인트 충전 ${_formatAmount(widget.amount)}원',
          customerName: widget.userId,
        ),
      );

      if (!mounted) return;

      // 결제 성공 시
      if (result.success != null) {
        final success = result.success!;

        // Cloud Function을 호출하여 서버 측 결제 검증 및 지갑 업데이트
        // 보안: 클라이언트에서 직접 지갑 잔액 수정 불가, 서버 검증 필수
        try {
          final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
          final callable = functions.httpsCallable('verifyTossPayment');

          final response = await callable.call({
            'paymentKey': success.paymentKey,
            'orderId': success.orderId,
            'amount': widget.amount,
            'userId': widget.userId,
          });

          if (!mounted) return;

          // 검증 성공
          final pointsEarned = response.data['pointsEarned'] as int;

          // Wallet provider 새로고침
          ref.invalidate(walletProvider(widget.userId));

          // 결제 성공 페이지로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PaymentSuccessPage(
                payment: null, // TODO: Payment 모델이 필요한 경우 수정
              ),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('결제 완료! ${pointsEarned.toStringAsFixed(0)}P 충전되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        } on FirebaseFunctionsException catch (e) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('결제 검증 실패: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (result.fail != null) {
        // 결제 실패
        final fail = result.fail!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('결제 실패: ${fail.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('결제 처리 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('결제'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('결제'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 결제 정보
          Container(
            padding: EdgeInsets.all(20.w),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '결제 금액',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${_formatAmount(widget.amount)}원',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // 토스 결제 위젯
          Expanded(
            child: PaymentMethodWidget(
              paymentWidget: _paymentWidget,
              selector: 'payment-method',
            ),
          ),

          // 결제하기 버튼
          Container(
            padding: EdgeInsets.all(20.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _requestPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  '${_formatAmount(widget.amount)}원 결제하기',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 금액 포맷팅
  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
