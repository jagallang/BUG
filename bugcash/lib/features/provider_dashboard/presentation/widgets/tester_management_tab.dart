import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../generated/l10n/app_localizations.dart';

class TesterManagementTab extends ConsumerStatefulWidget {
  final String providerId;

  const TesterManagementTab({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<TesterManagementTab> createState() => _TesterManagementTabState();
}

class _TesterManagementTabState extends ConsumerState<TesterManagementTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = '전체';
  String _selectedSort = '가입일순';
  String _selectedTagFilter = '전체';
  Set<String> _expandedTesters = {};
  
  // 사용 가능한 모든 태그 목록
  final List<String> _allTags = ['UI/UX', '성능테스트', '버그발견', '기능테스트', '보안테스트', '사용성테스트', '호환성테스트'];
  
  // Mock 테스터 데이터
  final List<TesterInfo> _mockTesters = [
    TesterInfo(
      id: 'tester_001',
      name: '김테스터',
      email: 'kim.tester@email.com',
      joinDate: DateTime.now().subtract(const Duration(days: 30)),
      completedMissions: 15,
      successRate: 0.92,
      rating: 4.5,
      status: TesterStatus.active,
      specialties: ['UI/UX', '성능테스트'],
      memo: '매우 꼼꼼하고 신뢰할만한 테스터. UI 개선 제안을 자주 해줌.',
      tags: ['우수', 'UI전문가', '신뢰성'],
    ),
    TesterInfo(
      id: 'tester_002',
      name: '이버그헌터',
      email: 'lee.bughunter@email.com',
      joinDate: DateTime.now().subtract(const Duration(days: 60)),
      completedMissions: 28,
      successRate: 0.89,
      rating: 4.3,
      status: TesterStatus.active,
      specialties: ['버그발견', '기능테스트'],
      memo: '버그 발견 능력이 뛰어남. 상세한 리포트 작성.',
      tags: ['버그마스터', '우수', '상세리포트'],
    ),
    TesterInfo(
      id: 'tester_003',
      name: '박프로테스터',
      email: 'park.protester@email.com',
      joinDate: DateTime.now().subtract(const Duration(days: 90)),
      completedMissions: 42,
      successRate: 0.95,
      rating: 4.8,
      status: TesterStatus.active,
      specialties: ['보안테스트', '성능테스트', 'API테스트'],
      memo: '최고 등급 테스터. 보안 취약점 발견의 전문가.',
      tags: ['전문가', '보안전문', '최고등급'],
    ),
    TesterInfo(
      id: 'tester_004',
      name: '최모바일',
      email: 'choi.mobile@email.com',
      joinDate: DateTime.now().subtract(const Duration(days: 15)),
      completedMissions: 8,
      successRate: 0.75,
      rating: 4.0,
      status: TesterStatus.active,
      specialties: ['모바일테스트'],
      memo: '모바일 환경에 특화된 테스터. 다양한 디바이스 테스트 가능.',
      tags: ['모바일전문', '디바이스테스트'],
    ),
    TesterInfo(
      id: 'tester_005',
      name: '정퍼포먼스',
      email: 'jung.performance@email.com',
      joinDate: DateTime.now().subtract(const Duration(days: 120)),
      completedMissions: 35,
      successRate: 0.91,
      rating: 4.6,
      status: TesterStatus.inactive,
      specialties: ['성능테스트', '로드테스트'],
      memo: '최근 활동 저조. 연락 필요.',
      tags: ['비활성', '연락필요', '성능전문'],
    ),
  ];

  List<TesterInfo> get _filteredTesters {
    List<TesterInfo> filtered = List.from(_mockTesters);
    
    // 검색 필터링
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((tester) =>
        tester.name.toLowerCase().contains(query) ||
        tester.email.toLowerCase().contains(query) ||
        tester.specialties.any((specialty) => specialty.toLowerCase().contains(query))
      ).toList();
    }
    
    // 상태 필터링
    if (_selectedFilter != '전체') {
      filtered = filtered.where((tester) {
        switch (_selectedFilter) {
          case '활성':
            return tester.status == TesterStatus.active;
          case '비활성':
            return tester.status == TesterStatus.inactive;
          case '신규':
            return tester.joinDate.isAfter(DateTime.now().subtract(const Duration(days: 30)));
          default:
            return true;
        }
      }).toList();
    }
    
    // 정렬
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case '가입일순':
          return b.joinDate.compareTo(a.joinDate);
        case '이름순':
          return a.name.compareTo(b.name);
        case '완료미션순':
          return b.completedMissions.compareTo(a.completedMissions);
        case '평점순':
          return b.rating.compareTo(a.rating);
        case '성공률순':
          return b.successRate.compareTo(a.successRate);
        default:
          return 0;
      }
    });
    
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Padding(
          padding: EdgeInsets.all(16.w),
          child: _buildAdvancedHeader(),
        ),
        
        // 검색 및 필터
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: _buildAdvancedSearchAndFilter(),
        ),
        
        SizedBox(height: 16.h),
        
        // 확장 가능한 테스터 리스트
        Expanded(
          child: _buildExpandableTesterList(),
        ),
      ],
    );
  }

  Widget _buildAdvancedHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '테스터 관리',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '등록된 테스터들을 관리하고 성과를 확인해보세요',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSearchAndFilter() {
    return Column(
      children: [
        // 검색 바
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '이름, 이메일, 전문분야, 태그로 검색',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          ),
        ),
        SizedBox(height: 12.h),
        
        // 필터 버튼들
        Row(
          children: [
            // 상태 필터
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: InputDecoration(
                  labelText: '상태',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                ),
                items: ['전체', '활성', '비활성'].map((filter) {
                  return DropdownMenuItem(value: filter, child: Text(filter));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedFilter = value);
                  }
                },
              ),
            ),
            SizedBox(width: 12.w),
            
            // 태그 필터
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedTagFilter,
                decoration: InputDecoration(
                  labelText: '태그',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                ),
                items: ['전체', ..._allTags].map((tag) {
                  return DropdownMenuItem(value: tag, child: Text(tag));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedTagFilter = value);
                  }
                },
              ),
            ),
            SizedBox(width: 12.w),
            
            // 정렬
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedSort,
                decoration: InputDecoration(
                  labelText: '정렬',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                ),
                items: ['가입일순', '이름순', '완료미션순', '평점순', '성공률순'].map((sort) {
                  return DropdownMenuItem(value: sort, child: Text(sort));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSort = value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandableTesterList() {
    final filteredTesters = _getFilteredAndSortedTesters();
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: filteredTesters.length,
      itemBuilder: (context, index) {
        final tester = filteredTesters[index];
        final isExpanded = _expandedTesters.contains(tester.id);
        
        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 한 줄 요약 (항상 표시)
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedTesters.remove(tester.id);
                    } else {
                      _expandedTesters.add(tester.id);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      // 아바타
                      CircleAvatar(
                        radius: 16.r,
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          tester.name[0],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      
                      // 이름과 이메일
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tester.name,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              tester.email,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 빠른 정보
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '미션 ${tester.completedMissions}건',
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                            ),
                            Text(
                              '평점 ${tester.rating}',
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      
                      // 상태와 확장 버튼
                      Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: tester.status == TesterStatus.active ? Colors.green[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              tester.status == TesterStatus.active ? '활성' : '비활성',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: tester.status == TesterStatus.active ? Colors.green[800] : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 20.w,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // 확장된 내용 (클릭시에만 표시)
              if (isExpanded) ...[
                Divider(height: 1.h, color: Colors.grey[200]),
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상세 성능 지표
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem('성공률', '${(tester.successRate * 100).toInt()}%'),
                          ),
                          Expanded(
                            child: _buildStatItem('완료 미션', '${tester.completedMissions}건'),
                          ),
                          Expanded(
                            child: _buildStatItem('가입일', '${tester.joinDate.year}.${tester.joinDate.month}.${tester.joinDate.day}'),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      
                      // 전문분야
                      if (tester.specialties.isNotEmpty) ...[
                        Text(
                          '전문분야',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 4.h,
                          children: tester.specialties.map((specialty) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              specialty,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.blue[700],
                              ),
                            ),
                          )).toList(),
                        ),
                        SizedBox(height: 12.h),
                      ],
                      
                      // 태그
                      if (tester.tags.isNotEmpty) ...[
                        Text(
                          '태그',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 4.h,
                          children: tester.tags.map((tag) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.orange[700],
                              ),
                            ),
                          )).toList(),
                        ),
                        SizedBox(height: 12.h),
                      ],
                      
                      // 메모
                      if (tester.memo.isNotEmpty) ...[
                        Text(
                          '메모',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            tester.memo,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                      ],
                      
                      // 액션 버튼들
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showEditTesterDialog(tester),
                              icon: Icon(Icons.edit, size: 16.w),
                              label: const Text('편집'),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showContactTesterDialog(tester),
                              icon: Icon(Icons.email, size: 16.w),
                              label: const Text('연락'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
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
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  List<TesterInfo> _getFilteredAndSortedTesters() {
    List<TesterInfo> filtered = List.from(_mockTesters);
    
    // 검색 필터링 (이름, 이메일, 전문분야, 태그 포함)
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((tester) =>
        tester.name.toLowerCase().contains(query) ||
        tester.email.toLowerCase().contains(query) ||
        tester.specialties.any((specialty) => specialty.toLowerCase().contains(query)) ||
        tester.tags.any((tag) => tag.toLowerCase().contains(query))
      ).toList();
    }
    
    // 상태 필터링
    if (_selectedFilter != '전체') {
      filtered = filtered.where((tester) {
        switch (_selectedFilter) {
          case '활성':
            return tester.status == TesterStatus.active;
          case '비활성':
            return tester.status == TesterStatus.inactive;
          default:
            return true;
        }
      }).toList();
    }
    
    // 태그 필터링
    if (_selectedTagFilter != '전체') {
      filtered = filtered.where((tester) =>
        tester.tags.contains(_selectedTagFilter)
      ).toList();
    }
    
    // 정렬
    switch (_selectedSort) {
      case '이름순':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case '완료미션순':
        filtered.sort((a, b) => b.completedMissions.compareTo(a.completedMissions));
        break;
      case '평점순':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case '성공률순':
        filtered.sort((a, b) => b.successRate.compareTo(a.successRate));
        break;
      case '가입일순':
      default:
        filtered.sort((a, b) => b.joinDate.compareTo(a.joinDate));
        break;
    }
    
    return filtered;
  }

  void _showEditTesterDialog(TesterInfo tester) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${tester.name} 편집'),
        content: const Text('테스터 편집 기능 (개발 예정)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showContactTesterDialog(TesterInfo tester) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${tester.name}에게 연락'),
        content: Text('이메일: ${tester.email}\n\n연락 기능 (개발 예정)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '테스터 관리',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '등록된 테스터들을 관리하고 성과를 확인해보세요',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        ElevatedButton.icon(
          onPressed: () => _showInviteTesterDialog(),
          icon: Icon(Icons.person_add, size: 18.w),
          label: const Text('테스터 초대'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        // 검색 필드
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '이름, 이메일, 전문분야로 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        
        // 필터 드롭다운
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedFilter,
            decoration: InputDecoration(
              labelText: '상태 필터',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            ),
            items: ['전체', '활성', '비활성', '신규'].map((filter) {
              return DropdownMenuItem(value: filter, child: Text(filter));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedFilter = value);
              }
            },
          ),
        ),
        SizedBox(width: 12.w),
        
        // 정렬 드롭다운
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedSort,
            decoration: InputDecoration(
              labelText: '정렬',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            ),
            items: ['가입일순', '이름순', '완료미션순', '평점순', '성공률순'].map((sort) {
              return DropdownMenuItem(value: sort, child: Text(sort));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedSort = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    final activeTesters = _mockTesters.where((t) => t.status == TesterStatus.active).length;
    final avgRating = _mockTesters.fold(0.0, (sum, t) => sum + t.rating) / _mockTesters.length;
    final totalMissions = _mockTesters.fold(0, (sum, t) => sum + t.completedMissions);
    
    return Row(
      children: [
        Expanded(child: _buildStatCard('총 테스터', '${_mockTesters.length}명', Icons.people, Colors.blue)),
        SizedBox(width: 12.w),
        Expanded(child: _buildStatCard('활성 테스터', '${activeTesters}명', Icons.person, Colors.green)),
        SizedBox(width: 12.w),
        Expanded(child: _buildStatCard('평균 평점', avgRating.toStringAsFixed(1), Icons.star, Colors.orange)),
        SizedBox(width: 12.w),
        Expanded(child: _buildStatCard('총 완료 미션', '${totalMissions}건', Icons.assignment_turned_in, Colors.purple)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24.w),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTesterList() {
    final filteredTesters = _filteredTesters;
    
    if (filteredTesters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48.w, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              '조건에 맞는 테스터가 없습니다',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredTesters.length,
      itemBuilder: (context, index) {
        return _buildTesterCard(filteredTesters[index]);
      },
    );
  }

  Widget _buildTesterCard(TesterInfo tester) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () => _showTesterDetails(tester),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // 프로필 아바타
              CircleAvatar(
                radius: 24.w,
                backgroundColor: tester.status == TesterStatus.active 
                    ? Colors.green.shade100 
                    : Colors.grey.shade200,
                child: Text(
                  tester.name.substring(0, 1),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: tester.status == TesterStatus.active 
                        ? Colors.green.shade700 
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              
              // 기본 정보
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tester.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: tester.status == TesterStatus.active 
                                ? Colors.green.shade100 
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            tester.status == TesterStatus.active ? '활성' : '비활성',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: tester.status == TesterStatus.active 
                                  ? Colors.green.shade700 
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      tester.email,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Wrap(
                      spacing: 4.w,
                      children: tester.specialties.take(3).map((specialty) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            specialty,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              // 성과 지표
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '완료미션',
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                    ),
                    Text(
                      '${tester.completedMissions}건',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: Colors.orange, size: 14.w),
                        SizedBox(width: 2.w),
                        Text(
                          tester.rating.toStringAsFixed(1),
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 성공률
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '성공률',
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                    ),
                    Text(
                      '${(tester.successRate * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14.sp, 
                        fontWeight: FontWeight.bold,
                        color: tester.successRate >= 0.9 ? Colors.green : 
                               tester.successRate >= 0.8 ? Colors.orange : Colors.red,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '가입일: ${_formatDate(tester.joinDate)}',
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              
              // 액션 버튼
              PopupMenuButton<String>(
                onSelected: (value) => _handleTesterAction(tester, value),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'view', child: Text('상세보기')),
                  PopupMenuItem(value: 'message', child: Text('메시지 보내기')),
                  PopupMenuItem(
                    value: tester.status == TesterStatus.active ? 'deactivate' : 'activate',
                    child: Text(tester.status == TesterStatus.active ? '비활성화' : '활성화'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInviteTesterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테스터 초대'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: '이메일 주소',
                hintText: 'tester@email.com',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              decoration: InputDecoration(
                labelText: '초대 메시지 (선택사항)',
                hintText: '초대 메시지를 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('초대 메일을 발송했습니다!')),
              );
            },
            child: const Text('초대 보내기'),
          ),
        ],
      ),
    );
  }

  void _showTesterDetails(TesterInfo tester) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${tester.name} 상세정보'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('이메일', tester.email),
              _buildDetailRow('가입일', _formatDate(tester.joinDate)),
              _buildDetailRow('상태', tester.status == TesterStatus.active ? '활성' : '비활성'),
              _buildDetailRow('완료미션', '${tester.completedMissions}건'),
              _buildDetailRow('성공률', '${(tester.successRate * 100).toInt()}%'),
              _buildDetailRow('평균평점', '${tester.rating}/5.0'),
              SizedBox(height: 8.h),
              const Text('전문분야:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4.h),
              Wrap(
                spacing: 4.w,
                children: tester.specialties.map((specialty) {
                  return Chip(label: Text(specialty), backgroundColor: Colors.blue.shade100);
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _handleTesterAction(TesterInfo tester, String action) {
    switch (action) {
      case 'view':
        _showTesterDetails(tester);
        break;
      case 'message':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tester.name}에게 메시지를 보냈습니다')),
        );
        break;
      case 'activate':
      case 'deactivate':
        final newStatus = action == 'activate' ? '활성화' : '비활성화';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tester.name}을(를) ${newStatus}했습니다')),
        );
        break;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// 테스터 정보 모델
class TesterInfo {
  final String id;
  final String name;
  final String email;
  final DateTime joinDate;
  final int completedMissions;
  final double successRate;
  final double rating;
  final TesterStatus status;
  final List<String> specialties;
  final String memo;
  final List<String> tags;

  TesterInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.joinDate,
    required this.completedMissions,
    required this.successRate,
    required this.rating,
    required this.status,
    required this.specialties,
    this.memo = '',
    this.tags = const [],
  });
}

enum TesterStatus { active, inactive }