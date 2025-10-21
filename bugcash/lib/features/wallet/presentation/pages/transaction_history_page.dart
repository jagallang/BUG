import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/wallet_provider.dart';
import '../widgets/transaction_list_item.dart';

/// 거래 내역 페이지
/// - 전체 거래 내역 조회
/// - 타입별 필터링 (전체/충전/사용/적립/출금)
/// - 무한 스크롤
class TransactionHistoryPage extends ConsumerStatefulWidget {
  final String userId;
  final String userType; // 'provider' or 'tester'

  const TransactionHistoryPage({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  ConsumerState<TransactionHistoryPage> createState() =>
      _TransactionHistoryPageState();
}

class _TransactionHistoryPageState
    extends ConsumerState<TransactionHistoryPage> {
  TransactionType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('거래 내역'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 필터 버튼
          _buildFilterSection(),

          // 거래 내역 리스트
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                // 필터 적용
                final filteredTransactions = _selectedFilter == null
                    ? transactions
                    : transactions
                        .where((tx) => tx.type == _selectedFilter)
                        .toList();

                if (filteredTransactions.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    return TransactionListItem(transaction: transaction);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64.w,
                        color: Colors.red[400],
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '거래 내역을 불러올 수 없습니다',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[600],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.red[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 필터 섹션
  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('전체', null),
            SizedBox(width: 8.w),
            // 공급자: 충전, 사용
            if (widget.userType == 'provider') ...[
              _buildFilterChip('💳 충전', TransactionType.charge),
              SizedBox(width: 8.w),
              _buildFilterChip('📤 사용', TransactionType.spend),
            ],
            // 테스터: 적립, 출금
            if (widget.userType == 'tester') ...[
              _buildFilterChip('💰 적립', TransactionType.earn),
              SizedBox(width: 8.w),
              _buildFilterChip('🏦 출금', TransactionType.withdraw),
            ],
          ],
        ),
      ),
    );
  }

  /// 필터 칩
  Widget _buildFilterChip(String label, TransactionType? type) {
    final isSelected = _selectedFilter == type;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? type : null;
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// 빈 상태
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80.w,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24.h),
            Text(
              _selectedFilter == null
                  ? '거래 내역이 없습니다'
                  : '${_getFilterName(_selectedFilter!)} 내역이 없습니다',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _getEmptyMessage(),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterName(TransactionType type) {
    switch (type) {
      case TransactionType.charge:
        return '충전';
      case TransactionType.spend:
        return '사용';
      case TransactionType.earn:
        return '적립';
      case TransactionType.withdraw:
        return '출금';
    }
  }

  String _getEmptyMessage() {
    if (_selectedFilter == null) {
      return widget.userType == 'provider'
          ? '포인트를 충전하거나 앱을 등록하면\n거래 내역이 표시됩니다'
          : '미션을 완료하면\n포인트 적립 내역이 표시됩니다';
    }

    switch (_selectedFilter!) {
      case TransactionType.charge:
        return '포인트 충전 내역이 없습니다';
      case TransactionType.spend:
        return '앱 등록 시 포인트 사용 내역이 표시됩니다';
      case TransactionType.earn:
        return '미션 완료 시 포인트 적립 내역이 표시됩니다';
      case TransactionType.withdraw:
        return '출금 신청 내역이 없습니다';
    }
  }
}
