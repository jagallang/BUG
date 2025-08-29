import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/firebase_service.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/models/point_transaction.dart';
import 'package:intl/intl.dart';

class PointHistoryPage extends ConsumerStatefulWidget {
  final String userId;

  const PointHistoryPage({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<PointHistoryPage> createState() => _PointHistoryPageState();
}

class _PointHistoryPageState extends ConsumerState<PointHistoryPage> {
  List<PointTransaction> transactions = [];
  bool isLoading = true;
  int currentPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadPointHistory();
  }

  Future<void> _loadPointHistory() async {
    try {
      // 사용자 현재 포인트 가져오기
      final userData = await FirebaseService.getUserData(widget.userId);
      if (userData != null) {
        currentPoints = userData['totalPoints'] ?? 0;
      }

      // 포인트 히스토리 가져오기
      final transactionData = await FirebaseService.getPointTransactions(
        widget.userId,
        limit: 50,
      );

      final List<PointTransaction> loadedTransactions = transactionData
          .map((data) => PointTransaction.fromJson(data))
          .toList();

      if (mounted) {
        setState(() {
          transactions = loadedTransactions;
          isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load point history', 'PointHistory', e);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('포인트 내역'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildPointSummary(),
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPointSummary() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.goldStart,
            AppColors.goldEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.goldText,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '보유 포인트',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.goldText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(currentPoints)} P',
                      style: TextStyle(
                        fontSize: 24.sp,
                        color: AppColors.goldText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (transactions.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                _buildStatItem(
                  '이번 달 획득',
                  _getMonthlyEarned(),
                  AppColors.success,
                ),
                SizedBox(width: 16.w),
                _buildStatItem(
                  '총 거래 건수',
                  '${transactions.length}',
                  AppColors.info,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.goldText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.goldText,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64.sp,
              color: AppColors.textHint,
            ),
            SizedBox(height: 16.h),
            Text(
              '포인트 내역이 없습니다',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textHint,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '미션을 완료하고 포인트를 획득해보세요!',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPointHistory,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return _buildTransactionTile(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionTile(PointTransaction transaction) {
    final isPositive = transaction.type != 'spent';
    final color = isPositive ? AppColors.success : AppColors.error;
    final icon = _getTransactionIcon(transaction.source);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayDescription,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _formatDate(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction.displayAmount,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(String source) {
    switch (source) {
      case 'mission_complete':
        return Icons.flag;
      case 'bug_report':
        return Icons.bug_report;
      case 'daily_bonus':
        return Icons.card_giftcard;
      case 'referral':
        return Icons.group_add;
      case 'purchase':
        return Icons.shopping_cart;
      default:
        return Icons.monetization_on;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('MM월 dd일').format(date);
    }
  }

  String _getMonthlyEarned() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    
    final monthlyTransactions = transactions.where((t) {
      return t.createdAt.isAfter(currentMonth) && t.type == 'earned';
    });
    
    final total = monthlyTransactions.fold<int>(0, (sum, t) => sum + t.amount);
    return '${NumberFormat('#,###').format(total)} P';
  }
}