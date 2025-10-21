import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/transaction_entity.dart';

/// 거래 내역 리스트 아이템 위젯
/// - 거래 타입별 아이콘 (💳충전, 📤사용, 💰적립, 🏦출금)
/// - 거래 금액 (+/-) 표시
/// - 거래 설명
/// - 거래 시간
/// - 상태 (pending/completed/failed/cancelled)
class TransactionListItem extends StatelessWidget {
  final TransactionEntity transaction;

  const TransactionListItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        // 거래 타입 아이콘
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              transaction.iconEmoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),

        // 거래 정보
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                transaction.description,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              transaction.amountWithSign,
              style: TextStyle(
                color: _getAmountColor(),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 거래 시간
              Text(
                _formatDateTime(transaction.createdAt),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),

              // 거래 상태
              _buildStatusChip(),
            ],
          ),
        ),

        // TODO: 상세 보기 / 영수증 기능
        trailing: transaction.status == TransactionStatus.completed
            ? Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 20,
              )
            : null,

        onTap: () {
          // TODO: 거래 상세 정보 표시
          _showTransactionDetails(context);
        },
      ),
    );
  }

  /// 거래 타입별 색상
  Color _getTypeColor() {
    switch (transaction.type) {
      case TransactionType.charge:
        return Colors.blue;
      case TransactionType.spend:
        return Colors.orange;
      case TransactionType.earn:
        return Colors.green;
      case TransactionType.withdraw:
        return Colors.purple;
    }
  }

  /// 금액 색상 (수입: 녹색, 지출: 빨간색)
  Color _getAmountColor() {
    final isCredit = transaction.type == TransactionType.charge ||
                     transaction.type == TransactionType.earn;
    return isCredit ? Colors.green : Colors.red;
  }

  /// 상태 칩
  Widget _buildStatusChip() {
    Color chipColor;
    String statusText;

    switch (transaction.status) {
      case TransactionStatus.pending:
        chipColor = Colors.orange;
        statusText = '처리중';
        break;
      case TransactionStatus.completed:
        chipColor = Colors.green;
        statusText = '완료';
        break;
      case TransactionStatus.failed:
        chipColor = Colors.red;
        statusText = '실패';
        break;
      case TransactionStatus.cancelled:
        chipColor = Colors.grey;
        statusText = '취소됨';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 날짜/시간 포맷팅
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // 1분 미만
    if (difference.inMinutes < 1) {
      return '방금 전';
    }
    // 1시간 미만
    else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    }
    // 24시간 미만
    else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    }
    // 오늘
    else if (dateTime.day == now.day &&
             dateTime.month == now.month &&
             dateTime.year == now.year) {
      return DateFormat('HH:mm').format(dateTime);
    }
    // 이번 년도
    else if (dateTime.year == now.year) {
      return DateFormat('MM.dd HH:mm').format(dateTime);
    }
    // 그 외
    else {
      return DateFormat('yyyy.MM.dd').format(dateTime);
    }
  }

  /// 거래 상세 정보 다이얼로그
  /// TODO: 영수증 표시, 환불 기능 등 추가
  void _showTransactionDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(transaction.iconEmoji),
            const SizedBox(width: 8),
            const Expanded(child: Text('거래 상세')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('거래 ID', transaction.id),
              const Divider(),
              _buildDetailRow('거래 타입', _getTypeText()),
              _buildDetailRow('금액', transaction.amountWithSign),
              _buildDetailRow('상태', _getStatusText()),
              const Divider(),
              _buildDetailRow('설명', transaction.description),
              _buildDetailRow(
                '거래 시간',
                DateFormat('yyyy-MM-dd HH:mm:ss').format(transaction.createdAt),
              ),
              if (transaction.completedAt != null)
                _buildDetailRow(
                  '완료 시간',
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(transaction.completedAt!),
                ),

              // Metadata 표시 (있는 경우)
              if (transaction.metadata.isNotEmpty) ...[
                const Divider(),
                const Text(
                  '추가 정보',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...transaction.metadata.entries.map(
                  (entry) => _buildDetailRow(entry.key, entry.value.toString()),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // TODO: 환불 버튼 (특정 조건일 때만 표시)
          // if (transaction.status == TransactionStatus.completed &&
          //     transaction.type == TransactionType.charge)
          //   TextButton(
          //     onPressed: () {
          //       // TODO: 환불 처리
          //     },
          //     child: const Text('환불 요청', style: TextStyle(color: Colors.red)),
          //   ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  /// 상세 정보 행
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 거래 타입 텍스트
  String _getTypeText() {
    switch (transaction.type) {
      case TransactionType.charge:
        return '포인트 충전';
      case TransactionType.spend:
        return '포인트 사용';
      case TransactionType.earn:
        return '포인트 적립';
      case TransactionType.withdraw:
        return '포인트 출금';
    }
  }

  /// 상태 텍스트
  String _getStatusText() {
    switch (transaction.status) {
      case TransactionStatus.pending:
        return '처리 중';
      case TransactionStatus.completed:
        return '완료';
      case TransactionStatus.failed:
        return '실패';
      case TransactionStatus.cancelled:
        return '취소됨';
    }
  }
}
