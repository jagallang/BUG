import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction_entity.dart';

/// 출금 신청 상세 다이얼로그
class WithdrawalDetailDialog extends StatelessWidget {
  final TransactionEntity withdrawal;

  const WithdrawalDetailDialog({
    super.key,
    required this.withdrawal,
  });

  @override
  Widget build(BuildContext context) {
    final bankInfo = withdrawal.metadata;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '출금 신청 상세',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // 상태 뱃지
              _buildStatusBadge(),
              SizedBox(height: 24.h),

              // 금액 정보
              _buildSection(
                title: '출금 금액',
                children: [
                  _buildDetailRow('요청 금액', '${_formatAmount(withdrawal.amount)}원'),
                  if (bankInfo['fee'] != null) ...[
                    SizedBox(height: 8.h),
                    _buildDetailRow(
                      '수수료',
                      '${_formatAmount(bankInfo['fee'] as int)}원',
                      valueColor: Colors.red,
                    ),
                    SizedBox(height: 8.h),
                    Divider(),
                    SizedBox(height: 8.h),
                    _buildDetailRow(
                      '실 수령액',
                      '${_formatAmount((bankInfo['finalAmount'] as int?) ?? withdrawal.amount)}원',
                      valueStyle: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 24.h),

              // 은행 정보
              _buildSection(
                title: '계좌 정보',
                children: [
                  _buildCopyableRow(
                    Icons.account_balance,
                    '은행',
                    bankInfo['bankName'] as String? ?? '정보 없음',
                  ),
                  SizedBox(height: 12.h),
                  _buildCopyableRow(
                    Icons.credit_card,
                    '계좌번호',
                    bankInfo['accountNumber'] as String? ?? '정보 없음',
                    copyable: true,
                  ),
                  SizedBox(height: 12.h),
                  _buildCopyableRow(
                    Icons.person_outline,
                    '예금주',
                    bankInfo['accountHolder'] as String? ?? '정보 없음',
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // 사용자 정보
              _buildSection(
                title: '신청자 정보',
                children: [
                  _buildCopyableRow(
                    Icons.person,
                    '이름',
                    bankInfo['userName'] as String? ?? '알 수 없음',
                  ),
                  SizedBox(height: 12.h),
                  _buildCopyableRow(
                    Icons.fingerprint,
                    '사용자 ID',
                    withdrawal.userId,
                    copyable: true,
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // 일시 정보
              _buildSection(
                title: '처리 정보',
                children: [
                  _buildDetailRow(
                    '신청일시',
                    _formatDateTime(withdrawal.createdAt),
                  ),
                  if (withdrawal.completedAt != null) ...[
                    SizedBox(height: 8.h),
                    _buildDetailRow(
                      '처리일시',
                      _formatDateTime(withdrawal.completedAt!),
                    ),
                  ],
                  if (bankInfo['rejectReason'] != null) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 16.w, color: Colors.red),
                              SizedBox(width: 6.w),
                              Text(
                                '거부 사유',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            bankInfo['rejectReason'] as String,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.red[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String label;
    IconData icon;

    switch (withdrawal.status) {
      case TransactionStatus.pending:
        color = Colors.orange;
        label = '대기중';
        icon = Icons.schedule;
        break;
      case TransactionStatus.completed:
        color = Colors.green;
        label = '승인완료';
        icon = Icons.check_circle;
        break;
      case TransactionStatus.cancelled:
        color = Colors.red;
        label = '거부됨';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = '알 수 없음';
        icon = Icons.help_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.w, color: color),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
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
          style: valueStyle ??
              TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
        ),
      ],
    );
  }

  Widget _buildCopyableRow(
    IconData icon,
    String label,
    String value, {
    bool copyable = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18.w, color: Colors.grey[600]),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
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
          ),
        ),
        if (copyable)
          IconButton(
            icon: Icon(Icons.copy, size: 18.w),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
            },
            tooltip: '복사',
          ),
      ],
    );
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }
}
