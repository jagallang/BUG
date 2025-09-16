import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/mission_creation_provider.dart';
import '../providers/provider_dashboard_provider.dart';
import '../../domain/models/provider_model.dart';
import '../../../../models/mission_model.dart';

class MissionCreationPage extends ConsumerStatefulWidget {
  final String providerId;
  final String? appId;

  const MissionCreationPage({
    super.key,
    required this.providerId,
    this.appId,
  });

  @override
  ConsumerState<MissionCreationPage> createState() => _MissionCreationPageState();
}

class _MissionCreationPageState extends ConsumerState<MissionCreationPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _detailsController = TextEditingController();
  final _rewardsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _completionCriteriaController = TextEditingController();
  final _notesController = TextEditingController();

  // Form values
  MissionType _selectedType = MissionType.bugReport;
  MissionPriority _selectedPriority = MissionPriority.medium;
  MissionComplexity _selectedComplexity = MissionComplexity.medium;
  String? _selectedAppId;
  int _maxParticipants = 10;
  int _estimatedMinutes = 30;
  int _rewardPoints = 100;
  bool _isRecurring = false;
  bool _requiresApproval = true;
  bool _allowMultipleSubmissions = false;
  DateTime? _deadline;
  final List<String> _requiredSkills = [];
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedAppId = widget.appId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _detailsController.dispose();
    _rewardsController.dispose();
    _instructionsController.dispose();
    _completionCriteriaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creationState = ref.watch(missionCreationProvider);
    final appListAsync = ref.watch(providerAppsProvider(widget.providerId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('새 미션 생성'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: '기본 설정'),
            Tab(text: '상세 정보'),
            Tab(text: '참여 조건'),
            Tab(text: '검토 및 생성'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicSettingsTab(appListAsync),
                  _buildDetailedInfoTab(),
                  _buildParticipationTab(),
                  _buildReviewTab(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSettingsTab(AsyncValue<List<AppModel>> appListAsync) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('미션 기본 정보'),
          SizedBox(height: 16.h),

          // Mission Title
          _buildTextFormField(
            controller: _titleController,
            label: '미션 제목',
            hint: '명확하고 구체적인 미션 제목을 입력하세요',
            isRequired: true,
            maxLength: 100,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '미션 제목을 입력해주세요';
              }
              if (value.length < 10) {
                return '미션 제목은 최소 10글자 이상이어야 합니다';
              }
              return null;
            },
          ),

          SizedBox(height: 16.h),

          // Mission Type
          _buildDropdownField<MissionType>(
            label: '미션 유형',
            value: _selectedType,
            items: MissionType.values,
            onChanged: (value) => setState(() => _selectedType = value!),
            itemBuilder: (type) => _getMissionTypeText(type),
          ),

          SizedBox(height: 16.h),

          // App Selection
          appListAsync.when(
            data: (apps) => _buildAppSelectionField(apps),
            loading: () => _buildLoadingField('앱 목록을 불러오는 중...'),
            error: (error, _) => _buildErrorField('앱 목록을 불러올 수 없습니다'),
          ),

          SizedBox(height: 16.h),

          // Mission Priority
          _buildDropdownField<MissionPriority>(
            label: '우선순위',
            value: _selectedPriority,
            items: MissionPriority.values,
            onChanged: (value) => setState(() => _selectedPriority = value!),
            itemBuilder: (priority) => _getMissionPriorityText(priority),
          ),

          SizedBox(height: 16.h),

          // Mission Complexity
          _buildDropdownField<MissionComplexity>(
            label: '난이도',
            value: _selectedComplexity,
            items: MissionComplexity.values,
            onChanged: (value) => setState(() => _selectedComplexity = value!),
            itemBuilder: (complexity) => _getMissionComplexityText(complexity),
          ),

          SizedBox(height: 16.h),

          // Basic Description
          _buildTextFormField(
            controller: _descriptionController,
            label: '미션 설명',
            hint: '미션의 목적과 수행해야 할 작업을 간단히 설명해주세요',
            isRequired: true,
            maxLines: 3,
            maxLength: 300,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '미션 설명을 입력해주세요';
              }
              if (value.length < 20) {
                return '미션 설명은 최소 20글자 이상이어야 합니다';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('상세 정보'),
          SizedBox(height: 16.h),

          // Detailed Description
          _buildTextFormField(
            controller: _detailsController,
            label: '상세 설명',
            hint: '미션의 배경, 목표, 기대 효과 등을 자세히 설명해주세요',
            isRequired: true,
            maxLines: 8,
            maxLength: 2000,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '상세 설명을 입력해주세요';
              }
              if (value.length < 100) {
                return '상세 설명은 최소 100글자 이상이어야 합니다';
              }
              return null;
            },
          ),

          SizedBox(height: 16.h),

          // Step-by-step Instructions
          _buildTextFormField(
            controller: _instructionsController,
            label: '수행 방법',
            hint: '미션을 수행하기 위한 단계별 가이드를 작성해주세요',
            isRequired: true,
            maxLines: 6,
            maxLength: 1500,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '수행 방법을 입력해주세요';
              }
              return null;
            },
          ),

          SizedBox(height: 16.h),

          // Completion Criteria
          _buildTextFormField(
            controller: _completionCriteriaController,
            label: '완료 기준',
            hint: '미션 완료로 인정되는 구체적인 기준을 명시해주세요',
            isRequired: true,
            maxLines: 4,
            maxLength: 800,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '완료 기준을 입력해주세요';
              }
              return null;
            },
          ),

          SizedBox(height: 16.h),

          // Required Skills
          _buildSkillsSection(),

          SizedBox(height: 16.h),

          // Tags
          _buildTagsSection(),

          SizedBox(height: 16.h),

          // Additional Notes
          _buildTextFormField(
            controller: _notesController,
            label: '추가 참고사항 (선택)',
            hint: '테스터가 알아야 할 추가 정보나 주의사항',
            maxLines: 3,
            maxLength: 500,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipationTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('참여 조건 및 보상'),
          SizedBox(height: 16.h),

          // Max Participants
          _buildSliderField(
            label: '최대 참여자 수',
            value: _maxParticipants.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: (value) => setState(() => _maxParticipants = value.round()),
            valueFormatter: (value) => '${value.round()}명',
          ),

          SizedBox(height: 16.h),

          // Estimated Duration
          _buildSliderField(
            label: '예상 소요시간',
            value: _estimatedMinutes.toDouble(),
            min: 5,
            max: 240,
            divisions: 47,
            onChanged: (value) => setState(() => _estimatedMinutes = value.round()),
            valueFormatter: (value) => '${value.round()}분',
          ),

          SizedBox(height: 16.h),

          // Reward Points
          _buildSliderField(
            label: '보상 포인트',
            value: _rewardPoints.toDouble(),
            min: 10,
            max: 1000,
            divisions: 99,
            onChanged: (value) => setState(() => _rewardPoints = value.round()),
            valueFormatter: (value) => '${value.round()}P',
          ),

          SizedBox(height: 16.h),

          // Reward Details
          _buildTextFormField(
            controller: _rewardsController,
            label: '보상 상세 정보',
            hint: '포인트 외 추가 보상이 있다면 설명해주세요',
            maxLines: 2,
            maxLength: 200,
          ),

          SizedBox(height: 16.h),

          // Deadline Selection
          _buildDeadlineField(),

          SizedBox(height: 16.h),

          // Mission Settings
          _buildSwitchTile(
            title: '반복 미션',
            subtitle: '정기적으로 수행되는 미션입니까?',
            value: _isRecurring,
            onChanged: (value) => setState(() => _isRecurring = value),
          ),

          _buildSwitchTile(
            title: '승인 필요',
            subtitle: '완료 시 관리자 승인이 필요합니까?',
            value: _requiresApproval,
            onChanged: (value) => setState(() => _requiresApproval = value),
          ),

          _buildSwitchTile(
            title: '중복 참여 허용',
            subtitle: '한 사용자가 여러 번 참여할 수 있습니까?',
            value: _allowMultipleSubmissions,
            onChanged: (value) => setState(() => _allowMultipleSubmissions = value),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('미션 정보 검토'),
          SizedBox(height: 16.h),

          _buildReviewCard(
            title: '기본 정보',
            items: [
              '제목: ${_titleController.text.isEmpty ? "미입력" : _titleController.text}',
              '유형: ${_getMissionTypeText(_selectedType)}',
              '우선순위: ${_getMissionPriorityText(_selectedPriority)}',
              '난이도: ${_getMissionComplexityText(_selectedComplexity)}',
            ],
            isComplete: _titleController.text.isNotEmpty && _descriptionController.text.isNotEmpty,
          ),

          SizedBox(height: 16.h),

          _buildReviewCard(
            title: '참여 조건',
            items: [
              '최대 참여자: $_maxParticipants명',
              '예상 소요시간: $_estimatedMinutes분',
              '보상 포인트: ${_rewardPoints}P',
              '마감일: ${_deadline != null ? _formatDate(_deadline!) : "설정 안함"}',
            ],
            isComplete: true,
          ),

          SizedBox(height: 16.h),

          _buildReviewCard(
            title: '상세 정보',
            items: [
              '상세 설명: ${_detailsController.text.isEmpty ? "미입력" : "입력됨"}',
              '수행 방법: ${_instructionsController.text.isEmpty ? "미입력" : "입력됨"}',
              '완료 기준: ${_completionCriteriaController.text.isEmpty ? "미입력" : "입력됨"}',
              '필요 스킬: ${_requiredSkills.length}개',
            ],
            isComplete: _detailsController.text.isNotEmpty &&
                       _instructionsController.text.isNotEmpty &&
                       _completionCriteriaController.text.isNotEmpty,
          ),

          SizedBox(height: 24.h),

          _buildMissionPreview(),

          SizedBox(height: 24.h),

          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildAppSelectionField(List<AppModel> apps) {
    if (apps.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 24.w),
            SizedBox(height: 8.h),
            Text(
              '등록된 앱이 없습니다',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '먼저 앱을 등록한 후 미션을 생성하세요',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '대상 앱 *',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: _selectedAppId,
          decoration: InputDecoration(
            hintText: '미션을 생성할 앱을 선택하세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '대상 앱을 선택해주세요';
            }
            return null;
          },
          items: apps.map((app) {
            return DropdownMenuItem<String>(
              value: app.id,
              child: Row(
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: app.iconUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6.r),
                            child: Image.network(
                              app.iconUrl!,
                              width: 24.w,
                              height: 24.w,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.apps,
                                size: 12.w,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.apps,
                            size: 12.w,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.appName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          app.packageName ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedAppId = value),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '필요한 스킬',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 120.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  ..._requiredSkills.map((skill) => _buildSkillChip(skill)),
                  _buildAddSkillChip(),
                ],
              ),
              if (_requiredSkills.isEmpty)
                Text(
                  '미션에 필요한 특별한 스킬이나 지식을 추가하세요',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '태그',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 120.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  ..._tags.map((tag) => _buildTagChip(tag)),
                  _buildAddTagChip(),
                ],
              ),
              if (_tags.isEmpty)
                Text(
                  '미션을 분류하고 검색하기 위한 태그를 추가하세요',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14.w, color: Colors.blue),
          SizedBox(width: 4.w),
          Text(
            skill,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4.w),
          InkWell(
            onTap: () => _removeSkill(skill),
            child: Icon(Icons.close, size: 14.w, color: Colors.blue.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tag, size: 14.w, color: Colors.green),
          SizedBox(width: 4.w),
          Text(
            tag,
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4.w),
          InkWell(
            onTap: () => _removeTag(tag),
            child: Icon(Icons.close, size: 14.w, color: Colors.green.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSkillChip() {
    return InkWell(
      onTap: _showAddSkillDialog,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14.w, color: Colors.grey.shade600),
            SizedBox(width: 4.w),
            Text(
              '스킬 추가',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTagChip() {
    return InkWell(
      onTap: _showAddTagDialog,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14.w, color: Colors.grey.shade600),
            SizedBox(width: 4.w),
            Text(
              '태그 추가',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '마감일',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: _selectDeadline,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12.r),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade600),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    _deadline != null
                        ? _formatDate(_deadline!)
                        : '마감일을 선택하세요 (선택사항)',
                    style: TextStyle(
                      color: _deadline != null
                          ? Colors.black87
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (_deadline != null)
                  InkWell(
                    onTap: () => setState(() => _deadline = null),
                    child: Icon(Icons.clear, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMissionPreview() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: Colors.blue, size: 20.w),
              SizedBox(width: 8.w),
              Text(
                '미션 미리보기',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _getMissionTypeColor(_selectedType).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        _getMissionTypeText(_selectedType),
                        style: TextStyle(
                          color: _getMissionTypeColor(_selectedType),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _getMissionPriorityColor(_selectedPriority).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        _getMissionPriorityText(_selectedPriority),
                        style: TextStyle(
                          color: _getMissionPriorityColor(_selectedPriority),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  _titleController.text.isNotEmpty ? _titleController.text : '미션 제목 미입력',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _descriptionController.text.isNotEmpty ? _descriptionController.text : '미션 설명 미입력',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.monetization_on, size: 14.w, color: Colors.orange),
                    SizedBox(width: 4.w),
                    Text('${_rewardPoints}P', style: TextStyle(fontSize: 12.sp)),
                    SizedBox(width: 12.w),
                    Icon(Icons.schedule, size: 14.w, color: Colors.blue),
                    SizedBox(width: 4.w),
                    Text('$_estimatedMinutes분', style: TextStyle(fontSize: 12.sp)),
                    SizedBox(width: 12.w),
                    Icon(Icons.people, size: 14.w, color: Colors.green),
                    SizedBox(width: 4.w),
                    Text('최대 $_maxParticipants명', style: TextStyle(fontSize: 12.sp)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    final isFormComplete = _isFormComplete();
    final creationState = ref.watch(missionCreationProvider);

    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton.icon(
        onPressed: isFormComplete && !creationState.isLoading ? _createMission : null,
        icon: creationState.isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.rocket_launch),
        label: Text(creationState.isLoading ? '미션 생성 중...' : '미션 생성'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  // Helper widgets and methods
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = false,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<T>(
          value: value,
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemBuilder(item)),
            );
          }).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
    required String Function(double) valueFormatter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              valueFormatter(value),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required List<String> items,
    required bool isComplete,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isComplete ? Icons.check_circle : Icons.error,
                  color: isComplete ? Colors.green : Colors.red,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isComplete ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            ...items.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Text(
                '• $item',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingField(String message) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          SizedBox(
            width: 16.w,
            height: 16.w,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12.w),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildErrorField(String message) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 16.w),
          SizedBox(width: 12.w),
          Text(
            message,
            style: TextStyle(color: Colors.red.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_tabController.index > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _tabController.animateTo(_tabController.index - 1);
                },
                child: const Text('이전'),
              ),
            ),
          if (_tabController.index > 0) SizedBox(width: 16.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _tabController.index < 3
                  ? () {
                      if (_validateCurrentTab()) {
                        _tabController.animateTo(_tabController.index + 1);
                      }
                    }
                  : null,
              child: Text(_tabController.index < 3 ? '다음' : '생성'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
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
      case MissionType.functional:
        return '기능 테스트';
      case MissionType.uiUx:
        return 'UI/UX 테스트';
      case MissionType.performance:
        return '성능 테스트';
      case MissionType.security:
        return '보안 테스트';
      case MissionType.compatibility:
        return '호환성 테스트';
      case MissionType.accessibility:
        return '접근성 테스트';
      case MissionType.localization:
        return '지역화 테스트';
    }
  }

  String _getMissionPriorityText(MissionPriority priority) {
    switch (priority) {
      case MissionPriority.low:
        return '낮음';
      case MissionPriority.medium:
        return '보통';
      case MissionPriority.high:
        return '높음';
      case MissionPriority.urgent:
        return '긴급';
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
      case MissionType.functional:
        return Colors.blueGrey;
      case MissionType.uiUx:
        return Colors.pink;
      case MissionType.performance:
        return Colors.deepOrange;
      case MissionType.security:
        return Colors.red.shade900;
      case MissionType.compatibility:
        return Colors.cyan;
      case MissionType.accessibility:
        return Colors.amber;
      case MissionType.localization:
        return Colors.lime;
    }
  }

  Color _getMissionPriorityColor(MissionPriority priority) {
    switch (priority) {
      case MissionPriority.low:
        return Colors.green;
      case MissionPriority.medium:
        return Colors.blue;
      case MissionPriority.high:
        return Colors.orange;
      case MissionPriority.urgent:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} (지남)';
    } else if (difference == 0) {
      return '오늘 (${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')})';
    } else if (difference == 1) {
      return '내일 (${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')})';
    } else {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ($difference일 후)';
    }
  }

  bool _validateCurrentTab() {
    switch (_tabController.index) {
      case 0: // Basic Settings
        return _titleController.text.isNotEmpty &&
               _descriptionController.text.isNotEmpty &&
               _selectedAppId != null;
      case 1: // Detailed Info
        return _detailsController.text.isNotEmpty &&
               _instructionsController.text.isNotEmpty &&
               _completionCriteriaController.text.isNotEmpty;
      case 2: // Participation
        return true; // All fields have default values
      case 3: // Review
        return _isFormComplete();
      default:
        return true;
    }
  }

  bool _isFormComplete() {
    return _titleController.text.isNotEmpty &&
           _descriptionController.text.isNotEmpty &&
           _detailsController.text.isNotEmpty &&
           _instructionsController.text.isNotEmpty &&
           _completionCriteriaController.text.isNotEmpty &&
           _selectedAppId != null;
  }

  void _removeSkill(String skill) {
    setState(() {
      _requiredSkills.remove(skill);
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _showAddSkillDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('필요 스킬 추가'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '필요한 스킬을 입력하세요',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty && 
                  !_requiredSkills.contains(controller.text.trim())) {
                setState(() {
                  _requiredSkills.add(controller.text.trim());
                });
              }
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('태그 추가'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '태그를 입력하세요',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty && 
                  !_tags.contains(controller.text.trim())) {
                setState(() {
                  _tags.add(controller.text.trim());
                });
              }
              Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _deadline = date;
      });
    }
  }

  void _createMission() async {
    if (!_formKey.currentState!.validate() || !_isFormComplete()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필수 정보를 입력해주세요.')),
      );
      return;
    }

    try {
      final missionData = {
        'providerId': widget.providerId,
        'appId': _selectedAppId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'details': _detailsController.text,
        'instructions': _instructionsController.text,
        'completionCriteria': _completionCriteriaController.text,
        'notes': _notesController.text,
        'rewards': _rewardsController.text,
        'type': _selectedType,
        'priority': _selectedPriority,
        'complexity': _selectedComplexity,
        'maxParticipants': _maxParticipants,
        'estimatedMinutes': _estimatedMinutes,
        'rewardPoints': _rewardPoints,
        'isRecurring': _isRecurring,
        'requiresApproval': _requiresApproval,
        'allowMultipleSubmissions': _allowMultipleSubmissions,
        'deadline': _deadline,
        'requiredSkills': _requiredSkills,
        'tags': _tags,
      };

      await ref.read(missionCreationProvider.notifier).createMission(missionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('미션이 성공적으로 생성되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('미션 생성 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}