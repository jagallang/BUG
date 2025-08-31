import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/mission_model.dart';
import '../providers/mission_creation_provider.dart';

class MissionTemplateSelectorWidget extends ConsumerWidget {
  final ValueChanged<MissionTemplate> onTemplateSelected;
  final MissionType selectedType;

  const MissionTemplateSelectorWidget({
    super.key,
    required this.onTemplateSelected,
    required this.selectedType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final template = ref.watch(missionTemplateProvider(selectedType));

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  '템플릿 적용',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _showTemplatePreview(context, template),
                  child: const Text('미리보기'),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              '선택한 미션 유형에 맞는 템플릿을 적용할 수 있습니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 16.h),
            
            // Template Preview Card
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
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: _getMissionTypeColor(selectedType).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          _getMissionTypeText(selectedType),
                          style: TextStyle(
                            color: _getMissionTypeColor(selectedType),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: _getMissionComplexityColor(template.suggestedComplexity).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          _getMissionComplexityText(template.suggestedComplexity),
                          style: TextStyle(
                            color: _getMissionComplexityColor(template.suggestedComplexity),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    template.titleSuggestion,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    template.descriptionTemplate,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.monetization_on, size: 14.w, color: Colors.orange),
                      SizedBox(width: 4.w),
                      Text('${template.suggestedReward}P', style: TextStyle(fontSize: 12.sp)),
                      SizedBox(width: 12.w),
                      Icon(Icons.schedule, size: 14.w, color: Colors.blue),
                      SizedBox(width: 4.w),
                      Text('${template.suggestedDuration}분', style: TextStyle(fontSize: 12.sp)),
                      SizedBox(width: 12.w),
                      Icon(Icons.star, size: 14.w, color: Colors.green),
                      SizedBox(width: 4.w),
                      Text('${template.suggestedSkills.length}개 스킬', style: TextStyle(fontSize: 12.sp)),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Apply Template Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  onTemplateSelected(template);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_getMissionTypeText(selectedType)} 템플릿이 적용되었습니다'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('템플릿 적용하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
            
            SizedBox(height: 8.h),
            
            // Template Benefits
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16.w),
                      SizedBox(width: 6.w),
                      Text(
                        '템플릿 장점',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  _buildBenefitItem('검증된 구조로 빠른 미션 생성'),
                  _buildBenefitItem('해당 유형에 최적화된 내용'),
                  _buildBenefitItem('적절한 보상과 난이도 설정'),
                  _buildBenefitItem('필요한 스킬과 태그 자동 제안'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            benefit,
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  void _showTemplatePreview(BuildContext context, MissionTemplate template) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600.w,
          constraints: BoxConstraints(maxHeight: 800.h),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        '템플릿 미리보기',
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
                  SizedBox(height: 16.h),
                  
                  _buildPreviewSection('제목 제안', template.titleSuggestion),
                  _buildPreviewSection('설명 템플릿', template.descriptionTemplate),
                  _buildPreviewSection('수행 방법', template.instructionsTemplate),
                  _buildPreviewSection('완료 기준', template.completionCriteriaTemplate),
                  
                  SizedBox(height: 16.h),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          '예상 소요시간',
                          '${template.suggestedDuration}분',
                          Icons.schedule,
                          Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildInfoCard(
                          '제안 보상',
                          '${template.suggestedReward}P',
                          Icons.monetization_on,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  if (template.suggestedSkills.isNotEmpty)
                    _buildChipsSection('제안 스킬', template.suggestedSkills, Colors.blue),
                  
                  if (template.suggestedTags.isNotEmpty)
                    _buildChipsSection('제안 태그', template.suggestedTags, Colors.green),
                  
                  SizedBox(height: 24.h),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onTemplateSelected(template);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${_getMissionTypeText(selectedType)} 템플릿이 적용되었습니다'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: const Text('이 템플릿 사용하기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              content,
              style: TextStyle(fontSize: 13.sp, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(height: 6.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipsSection(String title, List<String> items, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: items.map((item) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                item,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getMissionTypeText(MissionType type) {
    switch (type) {
      case MissionType.bugReport:
        return '버그 리포트';
      case MissionType.featureTesting:
        return '기능 테스트';
      case MissionType.usabilityTest:
        return '사용성 테스트';
      case MissionType.performanceTest:
        return '성능 테스트';
      case MissionType.survey:
        return '설문조사';
      case MissionType.feedback:
        return '피드백 수집';
    }
  }

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

  Color _getMissionTypeColor(MissionType type) {
    switch (type) {
      case MissionType.bugReport:
        return Colors.red;
      case MissionType.featureTesting:
        return Colors.blue;
      case MissionType.usabilityTest:
        return Colors.green;
      case MissionType.performanceTest:
        return Colors.orange;
      case MissionType.survey:
        return Colors.purple;
      case MissionType.feedback:
        return Colors.indigo;
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
}