import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import 'toss_payment_page.dart';
import 'mock_payment_page.dart';

/// 포인트 충전 페이지
class ChargePointPage extends ConsumerStatefulWidget {
  final String userId;

  const ChargePointPage({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ChargePointPage> createState() => _ChargePointPageState();
}

class _ChargePointPageState extends ConsumerState<ChargePointPage> {
  // 충전 금액 옵션
  final List<int> _chargeAmounts = [
    10000, // 1만원
    30000, // 3만원
    50000, // 5만원
    100000, // 10만원
    300000, // 30만원
    500000, // 50만원
  ];

  int? _selectedAmount;
  final TextEditingController _customAmountController = TextEditingController();

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  /// 결제 시작
  Future<void> _startPayment({bool useMock = false}) async {
    final amount = _selectedAmount ?? int.tryParse(_customAmountController.text);

    if (amount == null || amount < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 1,000원 이상 충전 가능합니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    // 개발 모드 또는 useMock이 true면 Mock 결제 페이지 사용
    if (kDebugMode || useMock) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MockPaymentPage(
            userId: widget.userId,
            amount: amount,
          ),
        ),
      );
    } else {
      // 프로덕션 환경에서는 Toss 결제 페이지
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TossPaymentPage(
            userId: widget.userId,
            amount: amount,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('포인트 충전'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 개발 모드 안내 (디버그 모드일 때만 표시)
            if (kDebugMode)
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bug_report, color: Colors.orange[700], size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        '🧪 개발 모드: Mock 결제로 실제 API 없이 테스트합니다',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (kDebugMode) SizedBox(height: 16.h),

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
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      '충전한 포인트는 앱 등록 및 미션 생성에 사용됩니다',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // 충전 금액 선택
            Text(
              '충전 금액 선택',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16.h),

            // 금액 옵션 그리드
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
              ),
              itemCount: _chargeAmounts.length,
              itemBuilder: (context, index) {
                final amount = _chargeAmounts[index];
                final isSelected = _selectedAmount == amount;

                return _buildAmountCard(amount, isSelected);
              },
            ),

            SizedBox(height: 24.h),

            // 직접 입력
            Text(
              '직접 입력',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 12.h),

            TextField(
              controller: _customAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '충전할 금액을 입력하세요 (최소 1,000원)',
                suffixText: '원',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedAmount = null; // 직접 입력 시 선택 해제
                });
              },
            ),

            SizedBox(height: 32.h),

            // 충전하기 버튼
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _startPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  '충전하기',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // 주의사항
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '주의사항',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildNoticeItem('충전된 포인트는 현금으로 환불되지 않습니다'),
                  _buildNoticeItem('결제 후 즉시 포인트가 충전됩니다'),
                  _buildNoticeItem('영수증은 이메일로 발송됩니다'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 금액 카드
  Widget _buildAmountCard(int amount, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAmount = amount;
          _customAmountController.clear();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '${_formatAmount(amount)}원',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  /// 주의사항 항목
  Widget _buildNoticeItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 14.sp)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
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
