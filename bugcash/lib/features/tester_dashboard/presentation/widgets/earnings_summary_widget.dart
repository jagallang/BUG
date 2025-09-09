import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/tester_dashboard_provider.dart';

class EarningsSummaryWidget extends ConsumerWidget {
  final String testerId;

  const EarningsSummaryWidget({
    super.key,
    required this.testerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(testerDashboardProvider);
    final earningsData = dashboardState.earningsData;

    if (earningsData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.green.shade50, // 연한 녹색 배경
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
          // Total Earnings Card
          _buildTotalEarningsCard(context, earningsData),
          
          SizedBox(height: 16.h),
          
          // Period Earnings
          _buildPeriodEarnings(context, earningsData),
          
          SizedBox(height: 16.h),
          
          // Earnings by Type
          _buildEarningsByType(context, earningsData),
          
          SizedBox(height: 16.h),
          
          // Recent History
          _buildRecentHistory(context, earningsData),
          
          SizedBox(height: 16.h),
          
          // Payout Info
          _buildPayoutInfo(context, earningsData),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalEarningsCard(BuildContext context, EarningsData earnings) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 32.w,
          ),
          SizedBox(height: 8.h),
          Text(
            '총 수익',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${earnings.totalEarnings}P',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '미지급: ${earnings.pendingPayments}P',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodEarnings(BuildContext context, EarningsData earnings) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기간별 수익',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildPeriodItem(
                    '오늘',
                    '${earnings.todayEarnings}P',
                    Icons.today,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildPeriodItem(
                    '이번 주',
                    '${earnings.thisWeekEarnings}P',
                    Icons.date_range,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildPeriodItem(
                    '이번 달',
                    '${earnings.thisMonthEarnings}P',
                    Icons.calendar_month,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodItem(String label, String amount, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(height: 8.h),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsByType(BuildContext context, EarningsData earnings) {
    final total = earnings.earningsByType.values.reduce((a, b) => a + b);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '유형별 수익',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            ...earnings.earningsByType.entries.map((entry) {
              final percentage = (entry.value / total * 100);
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getMissionTypeText(entry.key),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${entry.value}P (${percentage.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: _getMissionTypeColor(entry.key),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 6.h,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(_getMissionTypeColor(entry.key)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHistory(BuildContext context, EarningsData earnings) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '최근 수익 내역',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Show full history
                  },
                  child: const Text('전체보기'),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...earnings.recentHistory.map((history) => 
              _buildHistoryItem(context, history)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, EarningHistory history) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: _getEarningTypeColor(history.type).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getEarningTypeIcon(history.type),
              color: _getEarningTypeColor(history.type),
              size: 20.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.missionTitle,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDateTime(history.earnedAt),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${history.points}P',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: history.isPaid 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  history.isPaid ? '지급완료' : '대기중',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: history.isPaid ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutInfo(BuildContext context, EarningsData earnings) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '정산 정보',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.pending, color: Colors.orange, size: 20.w),
                        SizedBox(height: 4.h),
                        Text(
                          '${earnings.pendingPayments}P',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          '미지급 금액',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.schedule, color: Colors.blue, size: 20.w),
                        SizedBox(height: 4.h),
                        Text(
                          earnings.lastPayoutDate != null
                              ? _formatDate(earnings.lastPayoutDate!)
                              : 'N/A',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          '최근 정산일',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 16.w),
                      SizedBox(width: 6.w),
                      Text(
                        '정산 안내',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '• 매월 15일 정산 처리\n• 최소 정산 금액: 10,000P\n• 포인트는 현금으로 환전 가능',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.blue.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getMissionTypeText(String type) {
    switch (type) {
      case 'bugReport':
        return '버그 리포트';
      case 'featureTesting':
        return '기능 테스트';
      case 'usabilityTest':
        return '사용성 테스트';
      case 'survey':
        return '설문조사';
      default:
        return type;
    }
  }

  Color _getMissionTypeColor(String type) {
    switch (type) {
      case 'bugReport':
        return Colors.red;
      case 'featureTesting':
        return Colors.blue;
      case 'usabilityTest':
        return Colors.green;
      case 'survey':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getEarningTypeColor(EarningType type) {
    switch (type) {
      case EarningType.missionComplete:
        return Colors.green;
      case EarningType.bonus:
        return Colors.orange;
      case EarningType.referral:
        return Colors.blue;
      case EarningType.achievement:
        return Colors.purple;
    }
  }

  IconData _getEarningTypeIcon(EarningType type) {
    switch (type) {
      case EarningType.missionComplete:
        return Icons.check_circle;
      case EarningType.bonus:
        return Icons.card_giftcard;
      case EarningType.referral:
        return Icons.group_add;
      case EarningType.achievement:
        return Icons.emoji_events;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}