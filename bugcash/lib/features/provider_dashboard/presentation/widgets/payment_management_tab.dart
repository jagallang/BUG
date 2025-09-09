import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 결제 정보 모델
class PaymentInfo {
  final String id;
  final String appName;
  final String appId;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final PaymentStatus status;
  final double pointsAllocated;
  final int testersReached;

  PaymentInfo({
    required this.id,
    required this.appName,
    required this.appId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.status,
    required this.pointsAllocated,
    required this.testersReached,
  });
}

enum PaymentStatus {
  pending,    // 결제 대기
  completed,  // 결제 완료
  processing, // 포인트 지급 중
  distributed, // 포인트 지급 완료
  failed,     // 결제 실패
}

class PaymentManagementTab extends ConsumerStatefulWidget {
  final String providerId;

  const PaymentManagementTab({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<PaymentManagementTab> createState() => _PaymentManagementTabState();
}

class _PaymentManagementTabState extends ConsumerState<PaymentManagementTab> {
  // Mock 결제 데이터
  final List<PaymentInfo> _mockPayments = [
    PaymentInfo(
      id: 'payment_001',
      appName: '쇼핑앱 v2.1',
      appId: 'app_001',
      amount: 150000,
      paymentMethod: '신용카드',
      paymentDate: DateTime.now().subtract(const Duration(days: 2)),
      status: PaymentStatus.distributed,
      pointsAllocated: 140000,
      testersReached: 28,
    ),
    PaymentInfo(
      id: 'payment_002',
      appName: '배달앱 v1.5',
      appId: 'app_002',
      amount: 300000,
      paymentMethod: 'PayPal',
      paymentDate: DateTime.now().subtract(const Duration(hours: 6)),
      status: PaymentStatus.processing,
      pointsAllocated: 280000,
      testersReached: 45,
    ),
    PaymentInfo(
      id: 'payment_003',
      appName: '게임앱 v3.0',
      appId: 'app_003',
      amount: 500000,
      paymentMethod: '계좌이체',
      paymentDate: DateTime.now().subtract(const Duration(hours: 1)),
      status: PaymentStatus.completed,
      pointsAllocated: 0,
      testersReached: 0,
    ),
  ];

  double get totalBudget => _mockPayments
      .where((payment) => payment.status != PaymentStatus.failed)
      .fold(0.0, (sum, payment) => sum + payment.amount);

  double get totalAllocated => _mockPayments
      .fold(0.0, (sum, payment) => sum + payment.pointsAllocated);

  double get remainingBudget => totalBudget - totalAllocated;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 24.h),
          _buildBudgetOverview(),
          SizedBox(height: 24.h),
          _buildQuickActions(),
          SizedBox(height: 24.h),
          _buildPaymentHistory(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '결제 & 포인트 관리',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '앱 홍보 예산을 관리하고 테스터들에게 포인트를 지급하세요',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetOverview() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '총 예산',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    '₩${totalBudget.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 32.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _buildBudgetStat('지급완료', '₩${totalAllocated.toStringAsFixed(0)}', Colors.white),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildBudgetStat('잔여예산', '₩${remainingBudget.toStringAsFixed(0)}', Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStat(String label, String value, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: textColor.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠른 작업',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                '새 결제',
                '앱에 예산 충전하기',
                Icons.payment,
                Colors.green,
                () => _showPaymentDialog(),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildActionCard(
                '포인트 지급',
                '테스터들에게 즉시 지급',
                Icons.send,
                Colors.orange,
                () => _showPointDistributionDialog(),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                '결제 내역',
                '전체 결제 기록 보기',
                Icons.history,
                Colors.purple,
                () => _showFullPaymentHistory(),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildActionCard(
                '정산 리포트',
                '월별 정산 보고서',
                Icons.assessment,
                Colors.blue,
                () => _showSettlementReport(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),
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
    );
  }

  Widget _buildPaymentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '최근 결제 내역',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () => _showFullPaymentHistory(),
              child: Text(
                '전체보기',
                style: TextStyle(color: Colors.blue[600]),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _mockPayments.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final payment = _mockPayments[index];
            return _buildPaymentCard(payment);
          },
        ),
      ],
    );
  }

  Widget _buildPaymentCard(PaymentInfo payment) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.appName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${payment.paymentMethod} • ${_formatDate(payment.paymentDate)}',
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
                    '₩${payment.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  _buildStatusChip(payment.status),
                ],
              ),
            ],
          ),
          if (payment.status == PaymentStatus.distributed || payment.status == PaymentStatus.processing) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '포인트 지급: ₩${payment.pointsAllocated.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '테스터 ${payment.testersReached}명에게 지급됨',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                  if (payment.status == PaymentStatus.processing)
                    SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (payment.status == PaymentStatus.completed) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _distributePoints(payment),
                icon: const Icon(Icons.send),
                label: const Text('포인트 지급하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(PaymentStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case PaymentStatus.pending:
        color = Colors.orange;
        text = '대기';
        break;
      case PaymentStatus.completed:
        color = Colors.blue;
        text = '완료';
        break;
      case PaymentStatus.processing:
        color = Colors.purple;
        text = '지급중';
        break;
      case PaymentStatus.distributed:
        color = Colors.green;
        text = '지급완료';
        break;
      case PaymentStatus.failed:
        color = Colors.red;
        text = '실패';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 결제'),
        content: const Text('결제 기능을 구현하시겠습니까?\n• 카드결제, 계좌이체, PayPal 등 다양한 결제 방법\n• 안전한 PG사 연동\n• 자동 영수증 발행'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('결제 시스템 연동 중... (개발 중)')),
              );
            },
            child: const Text('결제하기'),
          ),
        ],
      ),
    );
  }

  void _showPointDistributionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('포인트 즉시 지급'),
        content: const Text('선택된 테스터들에게 포인트를 즉시 지급하시겠습니까?\n\n• 테스터 선택\n• 지급 포인트 설정\n• 지급 사유 입력\n• 즉시 알림 발송'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('포인트 지급 시스템 연동 중... (개발 중)')),
              );
            },
            child: const Text('지급하기'),
          ),
        ],
      ),
    );
  }

  void _showFullPaymentHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('전체 결제 내역 화면으로 이동 (개발 중)')),
    );
  }

  void _showSettlementReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('정산 리포트 화면으로 이동 (개발 중)')),
    );
  }

  void _distributePoints(PaymentInfo payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${payment.appName} 포인트 지급'),
        content: Text(
          '결제금액: ₩${payment.amount.toStringAsFixed(0)}\n'
          '수수료 (7%): ₩${(payment.amount * 0.07).toStringAsFixed(0)}\n'
          '지급예정: ₩${(payment.amount * 0.93).toStringAsFixed(0)}\n\n'
          '예상 테스터 수: 40-60명\n\n'
          '포인트를 테스터들에게 지급하시겠습니까?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final index = _mockPayments.indexOf(payment);
                _mockPayments[index] = PaymentInfo(
                  id: payment.id,
                  appName: payment.appName,
                  appId: payment.appId,
                  amount: payment.amount,
                  paymentMethod: payment.paymentMethod,
                  paymentDate: payment.paymentDate,
                  status: PaymentStatus.processing,
                  pointsAllocated: payment.amount * 0.93,
                  testersReached: 52,
                );
              });
              
              // 3초 후 지급 완료로 변경
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    final index = _mockPayments.indexWhere((p) => p.id == payment.id);
                    if (index != -1) {
                      _mockPayments[index] = PaymentInfo(
                        id: payment.id,
                        appName: payment.appName,
                        appId: payment.appId,
                        amount: payment.amount,
                        paymentMethod: payment.paymentMethod,
                        paymentDate: payment.paymentDate,
                        status: PaymentStatus.distributed,
                        pointsAllocated: payment.amount * 0.93,
                        testersReached: 52,
                      );
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('포인트 지급이 완료되었습니다!')),
                  );
                }
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('포인트 지급을 시작합니다...')),
              );
            },
            child: const Text('지급시작'),
          ),
        ],
      ),
    );
  }
}