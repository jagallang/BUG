import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/payment_entity.dart';

/// 결제 성공 페이지
class PaymentSuccessPage extends StatelessWidget {
  final PaymentEntity? payment;

  const PaymentSuccessPage({
    super.key,
    this.payment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제 완료'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 성공 아이콘
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80.sp,
                ),
              ),

              SizedBox(height: 24.h),

              // 성공 메시지
              Text(
                '결제가 완료되었습니다',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                '포인트가 충전되었습니다',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                ),
              ),

              SizedBox(height: 32.h),

              // 결제 정보 카드 (payment가 있을 때만 표시)
              if (payment != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('결제 금액', '${_formatAmount(payment!.amount)}원', isHighlight: true),
                      Divider(height: 24.h),
                      _buildInfoRow('주문번호', payment!.orderId),
                      SizedBox(height: 12.h),
                      _buildInfoRow('결제 방법', _getPaymentMethodText(payment!.method)),
                      SizedBox(height: 12.h),
                      _buildInfoRow('결제 일시', _formatDateTime(payment!.approvedAt ?? payment!.requestedAt)),
                    ],
                  ),
                ),

              SizedBox(height: 32.h),

              // 확인 버튼
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    // 모든 결제 관련 페이지 닫고 대시보드로 돌아가기
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // 거래 내역 보기 버튼
              TextButton(
                onPressed: () {
                  // TODO: 거래 내역 페이지로 이동
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  '거래 내역 보기',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 정보 행
  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 20.sp : 14.sp,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? AppColors.primary : Colors.black87,
          ),
        ),
      ],
    );
  }

  /// 금액 포맷팅
  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// 결제 방법 텍스트
  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return '카드 결제';
      case PaymentMethod.transfer:
        return '계좌 이체';
      case PaymentMethod.kakaopay:
        return '카카오페이';
      case PaymentMethod.naverpay:
        return '네이버페이';
      case PaymentMethod.tosspay:
        return '토스페이';
    }
  }

  /// 날짜 시간 포맷팅
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy년 MM월 dd일 HH:mm').format(dateTime);
  }
}
