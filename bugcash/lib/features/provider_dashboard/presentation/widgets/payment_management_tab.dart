import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Firebase Provider for payment information
final providerPaymentsProvider = StreamProvider.family<List<PaymentInfo>, String>((ref, providerId) {
  return FirebaseFirestore.instance
      .collection('payments')
      .where('providerId', isEqualTo: providerId)
      .orderBy('paymentDate', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
    final List<PaymentInfo> payments = [];
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      
      // Get app details
      final appDoc = await FirebaseFirestore.instance
          .collection('apps')
          .doc(data['appId'])
          .get();
      
      if (appDoc.exists) {
        final appData = appDoc.data()!;
        
        payments.add(PaymentInfo(
          id: doc.id,
          appName: appData['appName'] ?? 'Unknown App',
          appId: data['appId'],
          amount: (data['amount'] as num).toDouble(),
          paymentMethod: data['paymentMethod'] ?? 'Unknown',
          paymentDate: (data['paymentDate'] as Timestamp).toDate(),
          status: _parsePaymentStatus(data['status'] ?? 'pending'),
          pointsAllocated: (data['pointsAllocated'] as num?)?.toDouble() ?? 0.0,
          testersReached: data['testersReached'] ?? 0,
        ));
      }
    }
    
    return payments;
  });
});

PaymentStatus _parsePaymentStatus(String status) {
  switch (status) {
    case 'completed':
      return PaymentStatus.completed;
    case 'processing':
      return PaymentStatus.processing;
    case 'distributed':
      return PaymentStatus.distributed;
    case 'failed':
      return PaymentStatus.failed;
    default:
      return PaymentStatus.pending;
  }
}

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
  double _calculateTotalBudget(List<PaymentInfo> payments) {
    return payments
        .where((payment) => payment.status != PaymentStatus.failed)
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double _calculateTotalAllocated(List<PaymentInfo> payments) {
    return payments.fold(0.0, (sum, payment) => sum + payment.pointsAllocated);
  }

  double _calculateRemainingBudget(List<PaymentInfo> payments) {
    return _calculateTotalBudget(payments) - _calculateTotalAllocated(payments);
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(providerPaymentsProvider(widget.providerId));
    
    return paymentsAsync.when(
      data: (payments) => SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildHeader(),
            SizedBox(height: 20.h),
            _buildSummaryCards(payments),
            SizedBox(height: 20.h),
            _buildPaymentList(payments),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            SizedBox(height: 16.h),
            Text(
              '결제 정보를 불러올 수 없습니다',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 8.h),
            Text(
              error.toString(),
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.payment, size: 24.w, color: Colors.indigo[700]),
        SizedBox(width: 12.w),
        Text(
          '결제 관리',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Add payment functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('결제 추가 기능 (개발 중)')),
            );
          },
          icon: Icon(Icons.add, size: 16.w),
          label: const Text('결제 추가'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[700],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(List<PaymentInfo> payments) {
    final totalBudget = _calculateTotalBudget(payments);
    final totalAllocated = _calculateTotalAllocated(payments);
    final remainingBudget = _calculateRemainingBudget(payments);

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            '총 예산',
            '₩${_formatCurrency(totalBudget)}',
            Icons.account_balance_wallet,
            Colors.indigo[600]!,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildSummaryCard(
            '지급된 포인트',
            '${_formatCurrency(totalAllocated)}P',
            Icons.monetization_on,
            Colors.orange,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildSummaryCard(
            '잔여 예산',
            '₩${_formatCurrency(remainingBudget)}',
            Icons.savings,
            remainingBudget >= 0 ? Colors.indigo[600]! : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20.w),
              const Spacer(),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(List<PaymentInfo> payments) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          children: [
            SizedBox(height: 40.h),
            Icon(Icons.payment_outlined, size: 64.w, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              '결제 내역이 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '첫 결제를 추가해보세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '결제 내역',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            return _buildPaymentCard(payments[index]);
          },
        ),
      ],
    );
  }

  Widget _buildPaymentCard(PaymentInfo payment) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
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
                      ),
                    ),
                    SizedBox(height: 4.h),
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(payment.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _getStatusText(payment.status),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(payment.status),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Payment details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('결제 금액', '₩${_formatCurrency(payment.amount)}'),
              ),
              Expanded(
                child: _buildDetailItem('지급 포인트', '${_formatCurrency(payment.pointsAllocated)}P'),
              ),
              Expanded(
                child: _buildDetailItem('도달 테스터', '${payment.testersReached}명'),
              ),
            ],
          ),

          // Action button for processing payments
          if (payment.status == PaymentStatus.completed) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _processPayment(payment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('포인트 지급 처리'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _processPayment(PaymentInfo payment) async {
    try {
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(payment.id)
          .update({
        'status': 'processing',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('포인트 지급 처리를 시작했습니다'),
            backgroundColor: Colors.indigo[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('처리 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.indigo[600]!;
      case PaymentStatus.processing:
        return Colors.orange;
      case PaymentStatus.distributed:
        return Colors.indigo[700]!;
      case PaymentStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return '결제완료';
      case PaymentStatus.processing:
        return '처리중';
      case PaymentStatus.distributed:
        return '지급완료';
      case PaymentStatus.failed:
        return '실패';
      default:
        return '대기중';
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}