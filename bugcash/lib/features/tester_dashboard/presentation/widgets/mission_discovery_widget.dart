import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/tester_dashboard_provider.dart' as provider;
import '../../../../models/mission_model.dart';
import '../../../search/presentation/providers/search_provider.dart';
import 'mission_application_dialog.dart';
import 'provider_app_mission_card.dart';

class MissionDiscoveryWidget extends ConsumerStatefulWidget {
  final String testerId;

  const MissionDiscoveryWidget({
    super.key,
    required this.testerId,
  });

  @override
  ConsumerState<MissionDiscoveryWidget> createState() => _MissionDiscoveryWidgetState();
}

class _MissionDiscoveryWidgetState extends ConsumerState<MissionDiscoveryWidget> {
  final _searchController = TextEditingController();
  MissionType? _selectedType;
  MissionDifficulty? _selectedDifficulty;
  int _minReward = 0;
  int _maxReward = 1000;
  bool _showFilters = false;
  
  // 확장된 미션 카드들을 추적하는 Set
  final Set<String> _expandedMissions = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(provider.testerDashboardProvider);
    final searchState = ref.watch(searchProvider);
    
    // 검색이 활성화된 경우 검색 결과 사용, 아니면 대시보드 미션 사용
    final missions = _searchController.text.isNotEmpty && searchState.results.isNotEmpty
        ? _convertSearchResultsToMissions(searchState.results)
        : dashboardState.availableMissions;
        
    final filteredMissions = _filterMissions(missions);

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Search and Filter Header
          _buildSearchAndFilter(),
          
          SizedBox(height: 16.h),
          
          // Filter Chips (if filters are applied)
          if (_hasActiveFilters()) _buildActiveFilters(),
          
          // Mission Stats
          _buildMissionStats(dashboardState.availableMissions.length, filteredMissions.length),
          
          SizedBox(height: 16.h),
          
          // Mission List
          Expanded(
            child: filteredMissions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filteredMissions.length,
                    itemBuilder: (context, index) {
                      final mission = filteredMissions[index];
                      if (mission.isProviderApp && mission.originalAppData != null) {
                        // Provider 앱 미션인 경우 ProviderAppMissionCard 사용
                        return ProviderAppMissionCard(
                          mission: {
                            'title': mission.title,
                            'description': mission.description,
                            'company': mission.appName,
                            'reward': mission.rewardPoints,
                            'currentParticipants': mission.currentParticipants,
                            'maxParticipants': mission.maxParticipants,
                            'difficulty': _getDifficultyText(mission.difficulty),
                            'isProviderApp': true,
                            'originalAppData': mission.originalAppData,
                          },
                          onTap: () => _showApplicationDialog(mission),
                        );
                      } else {
                        // 일반 미션인 경우 기존 미션 카드 사용
                        return _buildMissionCard(mission);
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '미션 검색...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.r),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  onChanged: (value) {
                    // 검색어가 입력되면 검색 실행
                    if (value.isNotEmpty) {
                      ref.read(searchProvider.notifier).search(value);
                    } else {
                      // 검색어가 비어있으면 검색 결과 초기화
                      ref.read(searchProvider.notifier).clearResults();
                    }
                    setState(() {});
                  },
                ),
              ),
              SizedBox(width: 12.w),
              // Filter Toggle Button
              Container(
                decoration: BoxDecoration(
                  color: _showFilters 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  icon: Icon(
                    Icons.tune,
                    color: _showFilters ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          
          // Expandable Filters
          if (_showFilters) ...[
            SizedBox(height: 16.h),
            _buildFilterOptions(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mission Type Filter
        Text(
          '미션 타입',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 4.h,
          children: [
            _buildFilterChip('전체', _selectedType == null, () {
              setState(() => _selectedType = null);
            }),
            ...MissionType.values.map((type) => _buildFilterChip(
              _getMissionTypeText(type),
              _selectedType == type,
              () => setState(() => _selectedType = _selectedType == type ? null : type),
            )),
          ],
        ),
        
        SizedBox(height: 16.h),
        
        // Difficulty Filter
        Text(
          '난이도',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 4.h,
          children: [
            _buildFilterChip('전체', _selectedDifficulty == null, () {
              setState(() => _selectedDifficulty = null);
            }),
            ...MissionDifficulty.values.map((difficulty) => _buildFilterChip(
              _getDifficultyText(difficulty),
              _selectedDifficulty == difficulty,
              () => setState(() => _selectedDifficulty = _selectedDifficulty == difficulty ? null : difficulty),
            )),
          ],
        ),
        
        SizedBox(height: 16.h),
        
        // Reward Range
        Text(
          '보상 범위: ${_minReward}P - ${_maxReward}P',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),
        RangeSlider(
          values: RangeValues(_minReward.toDouble(), _maxReward.toDouble()),
          min: 0,
          max: 1000,
          divisions: 20,
          labels: RangeLabels('${_minReward}P', '${_maxReward}P'),
          onChanged: (values) {
            setState(() {
              _minReward = values.start.round();
              _maxReward = values.end.round();
            });
          },
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
        fontSize: 12.sp,
      ),
    );
  }

  Widget _buildActiveFilters() {
    final activeFilters = <Widget>[];
    
    if (_selectedType != null) {
      activeFilters.add(_buildActiveFilterChip(
        _getMissionTypeText(_selectedType!),
        () => setState(() => _selectedType = null),
      ));
    }
    
    if (_selectedDifficulty != null) {
      activeFilters.add(_buildActiveFilterChip(
        _getDifficultyText(_selectedDifficulty!),
        () => setState(() => _selectedDifficulty = null),
      ));
    }
    
    if (_minReward > 0 || _maxReward < 1000) {
      activeFilters.add(_buildActiveFilterChip(
        '$_minReward-${_maxReward}P',
        () => setState(() {
          _minReward = 0;
          _maxReward = 1000;
        }),
      ));
    }
    
    if (activeFilters.isEmpty) return const SizedBox.shrink();
    
    return Container(
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
            '활성 필터',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 4.h,
            children: [
              ...activeFilters,
              TextButton(
                onPressed: () => setState(() {
                  _selectedType = null;
                  _selectedDifficulty = null;
                  _minReward = 0;
                  _maxReward = 1000;
                }),
                child: Text(
                  '모두 지우기',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      onDeleted: onRemove,
      deleteIcon: Icon(Icons.close, size: 16.w),
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 11.sp,
      ),
    );
  }

  Widget _buildMissionStats(int totalMissions, int filteredMissions) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 16.w),
          SizedBox(width: 8.w),
          Text(
            '총 $totalMissions개 미션 중 $filteredMissions개 표시',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => ref.read(provider.testerDashboardProvider.notifier).refreshData(widget.testerId),
            icon: Icon(Icons.refresh, size: 16.w),
            label: const Text('새로고침'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              textStyle: TextStyle(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(provider.MissionCard mission) {
    final isExpanded = _expandedMissions.contains(mission.id);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedMissions.remove(mission.id);
            } else {
              _expandedMissions.add(mission.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(8.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - 항상 표시
              Row(
                children: [
                  // App Icon/Type Icon
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: _getMissionTypeColor(mission.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      _getMissionTypeIcon(mission.type),
                      color: _getMissionTypeColor(mission.type),
                      size: 24.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  
                  // Title and App Name
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          mission.appName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: 8.w),
                  
                  // Reward - Flexible하게 변경
                  Flexible(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.monetization_on, color: Colors.green, size: 14.w),
                          SizedBox(width: 2.w),
                          Flexible(
                            child: Text(
                              '${mission.rewardPoints}P',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 4.w),
                  
                  // 확장/접기 아이콘
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                    size: 20.w,
                  ),
                ],
              ),
              
              SizedBox(height: 8.h),
              
              // Description - 축약 상태에서는 1줄만 표시
              Text(
                mission.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: isExpanded ? null : 1,
                overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              
              // 기본 정보 (축약 상태)
              if (!isExpanded) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    // Difficulty
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(mission.difficulty).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          _getDifficultyText(mission.difficulty),
                          style: TextStyle(
                            color: _getDifficultyColor(mission.difficulty),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    
                    // Duration
                    Icon(Icons.schedule, size: 12.w, color: Colors.grey),
                    SizedBox(width: 2.w),
                    Flexible(
                      child: Text(
                        '${mission.estimatedMinutes}분',
                        style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    
                    // Participants
                    Icon(Icons.people, size: 12.w, color: Colors.blue),
                    SizedBox(width: 2.w),
                    Flexible(
                      child: Text(
                        '${mission.currentParticipants}/${mission.maxParticipants}',
                        style: TextStyle(fontSize: 10.sp, color: Colors.blue),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Deadline
                    if (mission.deadline != null)
                      Flexible(
                        child: Text(
                          _formatDeadline(mission.deadline!),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: _isUrgent(mission.deadline!) ? Colors.red : Colors.grey,
                            fontWeight: _isUrgent(mission.deadline!) ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                  ],
                ),
              ],
              
              // 확장된 상태의 추가 정보
              if (isExpanded) ...[
                SizedBox(height: 16.h),
                
                // 상세 정보 그리드
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    children: [
                      // 첫 번째 줄
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactInfoItem(
                              '난이도', 
                              _getDifficultyText(mission.difficulty), 
                              Icons.star, 
                              _getDifficultyColor(mission.difficulty),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildCompactInfoItem(
                              '소요시간', 
                              '${mission.estimatedMinutes}분', 
                              Icons.schedule, 
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      
                      // 두 번째 줄
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactInfoItem(
                              '참여자', 
                              '${mission.currentParticipants}/${mission.maxParticipants}', 
                              Icons.people, 
                              Colors.purple,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildCompactInfoItem(
                              '마감일', 
                              mission.deadline != null 
                                  ? _formatDeadline(mission.deadline!) 
                                  : '무제한', 
                              Icons.schedule_outlined, 
                              mission.deadline != null && _isUrgent(mission.deadline!) 
                                  ? Colors.red 
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 필요 스킬 (있는 경우)
                if (mission.requiredSkills.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '필요 스킬',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: mission.requiredSkills.take(5).map((skill) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 10.sp,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
                
                SizedBox(height: 16.h),
                
                // Action Buttons
                Row(
                  children: [
                    // 테스트하기 버튼 (요구사항 확인용)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showMissionDetails(mission),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.blue.shade300),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          '상세보기',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 12.w),
                    
                    // 미션 신청하기 버튼
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: mission.currentParticipants >= mission.maxParticipants
                            ? null
                            : () => _showApplicationDialog(mission),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mission.currentParticipants >= mission.maxParticipants
                              ? Colors.grey
                              : Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          mission.currentParticipants >= mission.maxParticipants
                              ? '정원 마감'
                              : '신청',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64.w,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16.h),
          Text(
            '조건에 맞는 미션이 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '필터 조건을 조정하거나 새로고침해보세요',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () => setState(() {
              _searchController.clear();
              _selectedType = null;
              _selectedDifficulty = null;
              _minReward = 0;
              _maxReward = 1000;
            }),
            icon: const Icon(Icons.clear_all),
            label: const Text('필터 초기화'),
          ),
        ],
      ),
    );
  }

  List<provider.MissionCard> _convertSearchResultsToMissions(List<dynamic> searchResults) {
    // 검색 결과를 MissionCard 객체로 변환
    return searchResults.map<provider.MissionCard>((result) {
      // 검색 결과가 이미 MissionCard 타입인 경우
      if (result is provider.MissionCard) {
        return result;
      }
      
      // 검색 결과가 Map인 경우 MissionCard로 변환
      if (result is Map<String, dynamic>) {
        // provider_apps 컬렉션에서 온 데이터인지 확인
        final isProviderApp = result['isProviderApp'] == true;
        
        if (isProviderApp) {
          // provider_apps 데이터를 미션 카드로 변환
          final originalAppData = result['originalAppData'] as Map<String, dynamic>?;
          return provider.MissionCard(
            id: result['id'] ?? '',
            title: result['title'] ?? '',
            description: result['description'] ?? '',
            appName: originalAppData?['appName'] ?? result['title'] ?? '',
            type: MissionType.functional,
            difficulty: _parseMissionDifficulty(result['difficulty']),
            rewardPoints: result['reward'] ?? 5000,
            estimatedMinutes: 120, // 앱 테스팅은 보통 2시간 정도
            currentParticipants: result['currentParticipants'] ?? 0,
            maxParticipants: result['maxParticipants'] ?? 50,
            requiredSkills: List<String>.from(result['requirements'] ?? ['앱 설치 가능', '피드백 작성']),
            deadline: result['endDate'] != null
                ? (result['endDate'] as Timestamp).toDate()
                : DateTime.now().add(const Duration(days: 30)),
            status: MissionStatus.active,
            isProviderApp: true,
            originalAppData: originalAppData,
          );
        } else {
          // 일반 미션 데이터 변환
          return provider.MissionCard(
            id: result['id'] ?? '',
            title: result['title'] ?? '',
            description: result['description'] ?? '',
            appName: result['appName'] ?? result['company'] ?? '',
            type: _parseMissionType(result['type']),
            difficulty: _parseMissionDifficulty(result['difficulty']),
            rewardPoints: result['reward'] ?? result['rewardPoints'] ?? 0,
            estimatedMinutes: result['estimatedMinutes'] ?? 30,
            currentParticipants: result['currentParticipants'] ?? 0,
            maxParticipants: result['maxParticipants'] ?? 10,
            requiredSkills: List<String>.from(result['requirements'] ?? result['requiredSkills'] ?? []),
            deadline: result['endDate'] != null
                ? (result['endDate'] as Timestamp).toDate()
                : (result['deadline'] != null ? DateTime.parse(result['deadline']) : null),
            status: MissionStatus.active,
            isProviderApp: false,
            originalAppData: null,
          );
        }
      }
      
      // 기본값 반환
      return provider.MissionCard(
        id: 'unknown',
        title: '알 수 없는 미션',
        description: '',
        appName: '',
        type: MissionType.functional,
        difficulty: MissionDifficulty.easy,
        rewardPoints: 0,
        estimatedMinutes: 30,
        currentParticipants: 0,
        maxParticipants: 10,
        requiredSkills: [],
        deadline: null,
        status: MissionStatus.active,
        isProviderApp: false,
        originalAppData: null,
      );
    }).toList();
  }

  MissionType _parseMissionType(dynamic type) {
    if (type is MissionType) return type;
    if (type is String) {
      switch (type.toLowerCase()) {
        case 'bugreport':
        case 'bug_report':
          return MissionType.bugReport;
        case 'featuretesting':
        case 'feature_testing':
          return MissionType.featureTesting;
        case 'usabilitytest':
        case 'usability_test':
          return MissionType.usabilityTest;
        case 'performancetest':
        case 'performance_test':
          return MissionType.performanceTest;
        case 'survey':
          return MissionType.survey;
        case 'feedback':
          return MissionType.feedback;
        case 'functional':
          return MissionType.functional;
        case 'uiux':
        case 'ui_ux':
          return MissionType.uiUx;
        case 'performance':
          return MissionType.performance;
        case 'security':
          return MissionType.security;
        case 'compatibility':
          return MissionType.compatibility;
        case 'accessibility':
          return MissionType.accessibility;
        case 'localization':
          return MissionType.localization;
        default:
          return MissionType.functional;
      }
    }
    return MissionType.functional;
  }

  MissionDifficulty _parseMissionDifficulty(dynamic difficulty) {
    if (difficulty is MissionDifficulty) return difficulty;
    if (difficulty is String) {
      switch (difficulty.toLowerCase()) {
        case 'easy':
          return MissionDifficulty.easy;
        case 'medium':
          return MissionDifficulty.medium;
        case 'hard':
          return MissionDifficulty.hard;
        case 'expert':
          return MissionDifficulty.expert;
        default:
          return MissionDifficulty.easy;
      }
    }
    return MissionDifficulty.easy;
  }

  List<provider.MissionCard> _filterMissions(List<provider.MissionCard> missions) {
    return missions.where((mission) {
      // Search filter
      final searchQuery = _searchController.text.toLowerCase();
      if (searchQuery.isNotEmpty) {
        if (!mission.title.toLowerCase().contains(searchQuery) &&
            !mission.description.toLowerCase().contains(searchQuery) &&
            !mission.appName.toLowerCase().contains(searchQuery)) {
          return false;
        }
      }
      
      // Type filter
      if (_selectedType != null && mission.type != _selectedType) {
        return false;
      }
      
      // Difficulty filter
      if (_selectedDifficulty != null && mission.difficulty != _selectedDifficulty) {
        return false;
      }
      
      // Reward range filter
      if (mission.rewardPoints < _minReward || mission.rewardPoints > _maxReward) {
        return false;
      }
      
      return true;
    }).toList();
  }

  bool _hasActiveFilters() {
    return _selectedType != null ||
           _selectedDifficulty != null ||
           _minReward > 0 ||
           _maxReward < 1000 ||
           _searchController.text.isNotEmpty;
  }

  void _showMissionDetails(provider.MissionCard mission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(16.w),
                  child: _buildMissionDetailContent(mission),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionDetailContent(provider.MissionCard mission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: _getMissionTypeColor(mission.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                _getMissionTypeIcon(mission.type),
                color: _getMissionTypeColor(mission.type),
                size: 30.w,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    mission.appName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        SizedBox(height: 24.h),
        
        // Description
        Text(
          '미션 설명',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          mission.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        
        SizedBox(height: 24.h),
        
        // Mission Info
        _buildInfoGrid(mission),
        
        SizedBox(height: 24.h),
        
        // Required Skills
        if (mission.requiredSkills.isNotEmpty) ...[
          Text(
            '필요 스킬',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: mission.requiredSkills.map((skill) => Chip(
              label: Text(skill),
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12.sp,
              ),
            )).toList(),
          ),
          SizedBox(height: 24.h),
        ],
        
        // Join Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: mission.currentParticipants >= mission.maxParticipants
                ? null
                : () {
                    Navigator.of(context).pop();
                    _showApplicationDialog(mission);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: mission.currentParticipants >= mission.maxParticipants
                  ? Colors.grey
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
            ),
            child: Text(
              mission.currentParticipants >= mission.maxParticipants
                  ? '정원이 마감되었습니다'
                  : '미션 신청하기',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(provider.MissionCard mission) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 2,
      children: [
        _buildInfoItem('보상', '${mission.rewardPoints}P', Icons.monetization_on, Colors.green),
        _buildInfoItem('소요시간', '${mission.estimatedMinutes}분', Icons.schedule, Colors.blue),
        _buildInfoItem('난이도', _getDifficultyText(mission.difficulty), Icons.star, _getDifficultyColor(mission.difficulty)),
        _buildInfoItem('참여자', '${mission.currentParticipants}/${mission.maxParticipants}', Icons.people, Colors.purple),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
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

  Widget _buildCompactInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16.w),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApplicationDialog(provider.MissionCard mission) {
    showDialog(
      context: context,
      builder: (context) => MissionApplicationDialog(
        mission: mission,
        onApplicationSubmitted: () => _onApplicationSubmitted(mission),
      ),
    );
  }

  void _onApplicationSubmitted(provider.MissionCard mission) {
    // 미션 신청이 완료되었을 때의 처리
    ref.read(provider.testerDashboardProvider.notifier).refreshData(widget.testerId);
    
    // 신청 상태를 추적하거나 로컬 상태를 업데이트할 수 있음
    // 예: 신청한 미션 목록에 추가, 알림 설정 등
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
        return '피드백';
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
        return Colors.blue;
      case MissionType.uiUx:
        return Colors.teal;
      case MissionType.performance:
        return Colors.deepOrange;
      case MissionType.security:
        return Colors.redAccent;
      case MissionType.compatibility:
        return Colors.amber;
      case MissionType.accessibility:
        return Colors.cyan;
      case MissionType.localization:
        return Colors.pink;
    }
  }

  IconData _getMissionTypeIcon(MissionType type) {
    switch (type) {
      case MissionType.bugReport:
        return Icons.bug_report;
      case MissionType.featureTesting:
        return Icons.featured_play_list;
      case MissionType.usabilityTest:
        return Icons.touch_app;
      case MissionType.performanceTest:
        return Icons.speed;
      case MissionType.survey:
        return Icons.quiz;
      case MissionType.feedback:
        return Icons.feedback;
      case MissionType.functional:
        return Icons.functions;
      case MissionType.uiUx:
        return Icons.design_services;
      case MissionType.performance:
        return Icons.timeline;
      case MissionType.security:
        return Icons.security;
      case MissionType.compatibility:
        return Icons.devices;
      case MissionType.accessibility:
        return Icons.accessibility;
      case MissionType.localization:
        return Icons.language;
    }
  }

  String _getDifficultyText(MissionDifficulty difficulty) {
    switch (difficulty) {
      case MissionDifficulty.easy:
        return '쉬움';
      case MissionDifficulty.medium:
        return '보통';
      case MissionDifficulty.hard:
        return '어려움';
      case MissionDifficulty.expert:
        return '전문가';
    }
  }

  Color _getDifficultyColor(MissionDifficulty difficulty) {
    switch (difficulty) {
      case MissionDifficulty.easy:
        return Colors.green;
      case MissionDifficulty.medium:
        return Colors.blue;
      case MissionDifficulty.hard:
        return Colors.orange;
      case MissionDifficulty.expert:
        return Colors.red;
    }
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 남음';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 남음';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 남음';
    } else {
      return '마감';
    }
  }

  bool _isUrgent(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    return difference.inHours <= 24;
  }
}