import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/mission_model.dart';
import '../providers/mission_creation_provider.dart';

class MissionDifficultyAnalyzerWidget extends ConsumerWidget {
  final Map<String, dynamic> missionData;

  const MissionDifficultyAnalyzerWidget({
    super.key,
    required this.missionData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficulty = ref.watch(missionDifficultyProvider(missionData));

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  '미션 난이도 분석',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(difficulty.difficultyScore).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _getDifficultyColor(difficulty.difficultyScore).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${difficulty.difficultyScore.toStringAsFixed(1)} / 5.0',
                    style: TextStyle(
                      color: _getDifficultyColor(difficulty.difficultyScore),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Difficulty Metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    '복잡도',
                    _getMissionComplexityText(difficulty.complexity),
                    _getMissionComplexityColor(difficulty.complexity),
                    Icons.layers,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    '필요 스킬',
                    '${difficulty.skillRequirements}개',
                    _getSkillRequirementColor(difficulty.skillRequirements),
                    Icons.star,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    '소요시간',
                    '${difficulty.timeCommitment}분',
                    _getTimeCommitmentColor(difficulty.timeCommitment),
                    Icons.schedule,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Difficulty Bar
            _buildDifficultyBar(context, difficulty.difficultyScore),
            
            SizedBox(height: 16.h),
            
            // Recommendation
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue, size: 16.w),
                      SizedBox(width: 6.w),
                      Text(
                        '권장사항',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    difficulty.recommendation,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 13.sp,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Optimization Suggestions
            _buildOptimizationSuggestions(context, difficulty),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18.w),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBar(BuildContext context, double score) {
    final percentage = (score / 5.0).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '전체 난이도',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _getDifficultyLevelText(score),
              style: TextStyle(
                color: _getDifficultyColor(score),
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          height: 8.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: FractionallySizedBox(
            widthFactor: percentage,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: _getDifficultyColor(score),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('쉬움', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
            Text('보통', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
            Text('어려움', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
            Text('전문가', style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildOptimizationSuggestions(BuildContext context, MissionDifficulty difficulty) {
    final suggestions = _generateOptimizationSuggestions(difficulty);
    
    if (suggestions.isEmpty) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: Colors.orange, size: 16.w),
              SizedBox(width: 6.w),
              Text(
                '최적화 제안',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...suggestions.map((suggestion) => Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4.w,
                  height: 4.w,
                  margin: EdgeInsets.only(top: 6.h, right: 8.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12.sp,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  List<String> _generateOptimizationSuggestions(MissionDifficulty difficulty) {
    final List<String> suggestions = [];
    
    // High difficulty suggestions
    if (difficulty.difficultyScore > 3.5) {
      suggestions.add('난이도가 높습니다. 보상을 늘리거나 참여자 수를 제한하는 것을 고려해보세요');
      if (difficulty.skillRequirements > 5) {
        suggestions.add('필요 스킬이 많습니다. 핵심 스킬 3-5개로 줄여보세요');
      }
      if (difficulty.timeCommitment > 120) {
        suggestions.add('소요시간이 깁니다. 미션을 여러 단계로 나누는 것을 고려해보세요');
      }
    }
    
    // Low difficulty suggestions
    if (difficulty.difficultyScore < 1.5) {
      suggestions.add('난이도가 낮습니다. 더 도전적인 요소를 추가해보세요');
      if (difficulty.skillRequirements == 0) {
        suggestions.add('특별한 스킬이 필요하지 않습니다. 품질 향상을 위해 관련 스킬을 추가해보세요');
      }
    }
    
    // Time commitment suggestions
    if (difficulty.timeCommitment < 15) {
      suggestions.add('소요시간이 짧습니다. 더 깊이 있는 테스트를 위해 시간을 늘려보세요');
    } else if (difficulty.timeCommitment > 180) {
      suggestions.add('소요시간이 너무 깁니다. 참여율 향상을 위해 시간을 단축해보세요');
    }
    
    // Skills suggestions
    if (difficulty.skillRequirements > 8) {
      suggestions.add('필요 스킬이 너무 많습니다. 전문가만 참여 가능할 수 있습니다');
    }
    
    return suggestions;
  }

  // Helper methods
  String _getMissionComplexityText(MissionComplexity complexity) {
    switch (complexity) {
      case MissionComplexity.easy:
        return '쉬움';
      case MissionComplexity.medium:
        return '보통';
      case MissionComplexity.hard:
        return '어려움';
      case MissionComplexity.expert:
        return '전문가';
    }
  }

  Color _getMissionComplexityColor(MissionComplexity complexity) {
    switch (complexity) {
      case MissionComplexity.easy:
        return Colors.green;
      case MissionComplexity.medium:
        return Colors.blue;
      case MissionComplexity.hard:
        return Colors.orange;
      case MissionComplexity.expert:
        return Colors.red;
    }
  }

  Color _getSkillRequirementColor(int skillCount) {
    if (skillCount == 0) return Colors.green;
    if (skillCount <= 3) return Colors.blue;
    if (skillCount <= 6) return Colors.orange;
    return Colors.red;
  }

  Color _getTimeCommitmentColor(int minutes) {
    if (minutes <= 30) return Colors.green;
    if (minutes <= 60) return Colors.blue;
    if (minutes <= 120) return Colors.orange;
    return Colors.red;
  }

  Color _getDifficultyColor(double score) {
    if (score < 1.5) return Colors.green;
    if (score < 2.5) return Colors.blue;
    if (score < 3.5) return Colors.orange;
    return Colors.red;
  }

  String _getDifficultyLevelText(double score) {
    if (score < 1.5) return '초급';
    if (score < 2.5) return '중급';
    if (score < 3.5) return '고급';
    return '전문가';
  }
}