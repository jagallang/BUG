import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/mission_distribution_provider.dart';

class MissionDistributionWidget extends ConsumerWidget {
  final String missionId;
  final Map<String, dynamic> missionData;

  const MissionDistributionWidget({
    super.key,
    required this.missionId,
    required this.missionData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributionState = ref.watch(missionDistributionProvider);
    final strategies = ref.watch(distributionStrategiesProvider);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people_alt,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  '자동 테스터 배분',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (distributionState.recommendations.isNotEmpty)
                  TextButton(
                    onPressed: () => _showDetailedRecommendations(context, ref),
                    child: const Text('상세 보기'),
                  ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Strategy Selection
            _buildStrategySelector(context, ref, strategies, distributionState.strategy),
            
            SizedBox(height: 16.h),
            
            // Generate Recommendations Button
            if (distributionState.recommendations.isEmpty && !distributionState.isLoading)
              _buildGenerateButton(context, ref),
            
            // Loading State
            if (distributionState.isLoading)
              _buildLoadingState(),
            
            // Recommendations Preview
            if (distributionState.recommendations.isNotEmpty)
              _buildRecommendationsPreview(context, distributionState.recommendations),
            
            // Performance Metrics
            if (distributionState.performanceMetrics.isNotEmpty)
              _buildPerformanceMetrics(context, distributionState.performanceMetrics),
            
            // Error State
            if (distributionState.error != null)
              _buildErrorState(context, ref, distributionState.error!),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategySelector(
    BuildContext context,
    WidgetRef ref,
    List<DistributionStrategy> strategies,
    DistributionStrategy currentStrategy,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '분배 전략',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: strategies.map((strategy) {
              final strategyInfo = ref.watch(strategyInfoProvider(strategy));
              final isSelected = strategy == currentStrategy;
              
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: FilterChip(
                  label: Text(strategyInfo.name),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(missionDistributionProvider.notifier).updateStrategy(strategy);
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 8.h),
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
              Text(
                ref.watch(strategyInfoProvider(currentStrategy)).description,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ref.read(missionDistributionProvider.notifier).generateRecommendations(
            missionId: missionId,
            missionData: missionData,
          );
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text('테스터 추천 생성'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12.h),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 16.h),
          Text(
            '최적의 테스터를 찾고 있습니다...',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '• 테스터 프로필 분석 중\n• 호환성 점수 계산 중\n• 최적화 추천 생성 중',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsPreview(
    BuildContext context,
    List<TesterRecommendation> recommendations,
  ) {
    final topRecommendations = recommendations.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '추천 테스터 (상위 3명)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '총 ${recommendations.length}명 추천',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ...topRecommendations.map((recommendation) => 
          _buildRecommendationItem(context, recommendation)
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(BuildContext context, TesterRecommendation recommendation) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Tester Avatar
          CircleAvatar(
            radius: 20.w,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              recommendation.testerId.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          
          // Tester Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Tester ${recommendation.testerId.substring(6)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _getScoreColor(recommendation.compatibilityScore).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '${(recommendation.compatibilityScore * 100).round()}% 매치',
                        style: TextStyle(
                          color: _getScoreColor(recommendation.compatibilityScore),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  recommendation.recommendationReason,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 12.w, color: Colors.blue),
                    SizedBox(width: 4.w),
                    Text(
                      '${recommendation.estimatedCompletionTime.inMinutes}분 예상',
                      style: TextStyle(fontSize: 11.sp, color: Colors.blue),
                    ),
                    SizedBox(width: 12.w),
                    Icon(Icons.star, size: 12.w, color: Colors.orange),
                    SizedBox(width: 4.w),
                    Text(
                      '품질 ${(recommendation.qualityPrediction * 100).round()}%',
                      style: TextStyle(fontSize: 11.sp, color: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Confidence Indicator
          Column(
            children: [
              Text(
                '신뢰도',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
              ),
              SizedBox(height: 2.h),
              CircularProgressIndicator(
                value: recommendation.confidence,
                strokeWidth: 3,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getScoreColor(recommendation.confidence),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                '${(recommendation.confidence * 100).round()}%',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(recommendation.confidence),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(BuildContext context, Map<String, double> metrics) {
    return Container(
      margin: EdgeInsets.only(top: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.green, size: 16.w),
              SizedBox(width: 6.w),
              Text(
                '예상 성과',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  '평균 호환성',
                  '${(metrics['averageCompatibility']! * 100).round()}%',
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildMetricItem(
                  '예상 품질',
                  '${(metrics['predictedQuality']! * 100).round()}%',
                  Colors.orange,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildMetricItem(
                  '커버리지',
                  '${(metrics['coverageScore']! * 100).round()}%',
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 32.w),
          SizedBox(height: 8.h),
          Text(
            '테스터 추천 생성 실패',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          ElevatedButton(
            onPressed: () {
              ref.read(missionDistributionProvider.notifier).clearError();
              ref.read(missionDistributionProvider.notifier).generateRecommendations(
                missionId: missionId,
                missionData: missionData,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  void _showDetailedRecommendations(BuildContext context, WidgetRef ref) {
    final distributionState = ref.watch(missionDistributionProvider);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 800.w,
          height: 600.h,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Text(
                      '테스터 추천 상세보기',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: distributionState.recommendations.length,
                  itemBuilder: (context, index) {
                    final recommendation = distributionState.recommendations[index];
                    return _buildDetailedRecommendationItem(context, recommendation, index + 1);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedRecommendationItem(
    BuildContext context,
    TesterRecommendation recommendation,
    int rank,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: rank <= 3 
                        ? Colors.amber.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rank <= 3 ? Colors.amber.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tester ${recommendation.testerId.substring(6)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        recommendation.recommendationReason,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: _getScoreColor(recommendation.compatibilityScore).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${(recommendation.compatibilityScore * 100).round()}% 매치',
                    style: TextStyle(
                      color: _getScoreColor(recommendation.compatibilityScore),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // Metrics Row
            Row(
              children: [
                _buildMetricChip(
                  '신뢰도',
                  '${(recommendation.confidence * 100).round()}%',
                  Colors.blue,
                ),
                SizedBox(width: 8.w),
                _buildMetricChip(
                  '예상 품질',
                  '${(recommendation.qualityPrediction * 100).round()}%',
                  Colors.green,
                ),
                SizedBox(width: 8.w),
                _buildMetricChip(
                  '완료 예상',
                  '${recommendation.estimatedCompletionTime.inMinutes}분',
                  Colors.orange,
                ),
              ],
            ),
            
            if (recommendation.riskFactors.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '주의사항',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    ...recommendation.riskFactors.map((factor) => Text(
                      '• $factor',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.orange.shade600,
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }
}