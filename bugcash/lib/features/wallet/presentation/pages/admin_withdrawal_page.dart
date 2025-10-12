import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/withdrawal_provider.dart';
import '../widgets/withdrawal_detail_dialog.dart';

/// 관리자 출금 신청 관리 페이지
class AdminWithdrawalPage extends ConsumerStatefulWidget {
  const AdminWithdrawalPage({super.key});

  @override
  ConsumerState<AdminWithdrawalPage> createState() => _AdminWithdrawalPageState();
}

class _AdminWithdrawalPageState extends ConsumerState<AdminWithdrawalPage> {
  TransactionStatus _selectedStatus = TransactionStatus.pending;

  @override
  Widget build(BuildContext context) {
    final withdrawalsAsync = ref.watch(withdrawalsByStatusProvider(_selectedStatus));

    return Scaffold(
      appBar: AppBar(
        title: const Text('출금 신청 관리'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 상태 필터 탭
          _buildStatusTabs(),

          // 출금 신청 목록
          Expanded(
            child: withdrawalsAsync.when(
              data: (withdrawals) {
                if (withdrawals.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildWithdrawalList(withdrawals);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48.w, color: Colors.red),
                    SizedBox(height: 16.h),
                    Text(
                      '출금 신청 목록을 불러올 수 없습니다',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      error.toString(),
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 상태 필터 탭
  Widget _buildStatusTabs() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _buildStatusTab(
            label: '대기중',
            status: TransactionStatus.pending,
            color: Colors.orange,
          ),
          _buildStatusTab(
            label: '승인완료',
            status: TransactionStatus.completed,
            color: Colors.green,
          ),
          _buildStatusTab(
            label: '거부됨',
            status: TransactionStatus.cancelled,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab({
    required String label,
    required TransactionStatus status,
    required Color color,
  }) {
    final isSelected = _selectedStatus == status;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStatus = status;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? color : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  /// 빈 상태
  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedStatus) {
      case TransactionStatus.pending:
        message = '대기 중인 출금 신청이 없습니다';
        icon = Icons.inbox_outlined;
        break;
      case TransactionStatus.completed:
        message = '승인된 출금 신청이 없습니다';
        icon = Icons.check_circle_outline;
        break;
      case TransactionStatus.cancelled:
        message = '거부된 출금 신청이 없습니다';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = '출금 신청이 없습니다';
        icon = Icons.inbox_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.w, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 출금 신청 목록
  Widget _buildWithdrawalList(List<TransactionEntity> withdrawals) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(withdrawalsByStatusProvider(_selectedStatus));
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: withdrawals.length,
        itemBuilder: (context, index) {
          final withdrawal = withdrawals[index];
          return _buildWithdrawalCard(withdrawal);
        },
      ),
    );
  }

  /// 출금 신청 카드
  Widget _buildWithdrawalCard(TransactionEntity withdrawal) {
    final bankInfo = withdrawal.metadata;
    final userName = bankInfo['userName'] as String? ?? '알 수 없음';
    final bankName = bankInfo['bankName'] as String? ?? '정보 없음';
    final accountNumber = bankInfo['accountNumber'] as String? ?? '정보 없음';

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => WithdrawalDetailDialog(
              withdrawal: withdrawal,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 사용자명 + 날짜
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 20.w,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatDate(withdrawal.createdAt),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // 금액
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '출금 요청 금액',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '${_formatAmount(withdrawal.amount)}원',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // 은행 정보
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.account_balance, bankName),
                    SizedBox(height: 4.h),
                    _buildInfoRow(Icons.credit_card, accountNumber),
                    SizedBox(height: 4.h),
                    _buildInfoRow(
                      Icons.person_outline,
                      bankInfo['accountHolder'] as String? ?? '정보 없음',
                    ),
                  ],
                ),
              ),

              // 상태에 따른 버튼 표시
              if (_selectedStatus == TransactionStatus.pending) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectWithdrawal(withdrawal),
                        icon: const Icon(Icons.close),
                        label: const Text('거부'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _approveWithdrawal(withdrawal),
                        icon: const Icon(Icons.check),
                        label: const Text('승인'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // 완료/거부 상태 표시
              if (_selectedStatus != TransactionStatus.pending) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(
                      _selectedStatus == TransactionStatus.completed
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 16.w,
                      color: _selectedStatus == TransactionStatus.completed
                          ? Colors.green
                          : Colors.red,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _selectedStatus == TransactionStatus.completed
                          ? '승인 완료 ${withdrawal.completedAt != null ? _formatDate(withdrawal.completedAt!) : ""}'
                          : '거부됨',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: _selectedStatus == TransactionStatus.completed
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16.w, color: Colors.grey[600]),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  /// 출금 승인
  Future<void> _approveWithdrawal(TransactionEntity withdrawal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('출금 승인'),
        content: Text(
          '${_formatAmount(withdrawal.amount)}원 출금을 승인하시겠습니까?\n\n'
          '은행: ${withdrawal.metadata['bankName']}\n'
          '계좌: ${withdrawal.metadata['accountNumber']}\n'
          '예금주: ${withdrawal.metadata['accountHolder']}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('승인'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ref.read(approveWithdrawalProvider(withdrawal.id).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('출금이 승인되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('출금 승인 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 출금 거부
  Future<void> _rejectWithdrawal(TransactionEntity withdrawal) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('출금 거부'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('거부 사유를 입력해주세요'),
              SizedBox(height: 12.h),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '거부 사유',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('거부'),
            ),
          ],
        );
      },
    );

    if (reason == null || reason.isEmpty || !mounted) return;

    try {
      await ref.read(rejectWithdrawalProvider(
        RejectWithdrawalParams(
          transactionId: withdrawal.id,
          reason: reason,
        ),
      ).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('출금이 거부되었습니다'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('출금 거부 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }
}
