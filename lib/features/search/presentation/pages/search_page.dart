import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/search_provider.dart';
import '../../domain/models/search_history.dart';
import '../../../mission/presentation/widgets/mission_card.dart';

class SearchPage extends ConsumerStatefulWidget {
  final String? initialQuery;
  
  const SearchPage({
    super.key,
    this.initialQuery,
  });

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late TextEditingController _searchController;
  bool _isFilterExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    
    // Perform initial search if query provided
    if (widget.initialQuery?.isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchProvider.notifier).search(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchSection(),
          if (_isFilterExpanded) _buildFilterSection(),
          Expanded(child: _buildContent(searchState)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.w),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '미션 검색',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFilterExpanded ? Icons.filter_list : Icons.filter_list_outlined,
            color: Colors.black,
            size: 24.w,
          ),
          onPressed: () {
            setState(() {
              _isFilterExpanded = !_isFilterExpanded;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    ref.read(searchProvider.notifier).search(value.trim());
                  }
                },
                decoration: InputDecoration(
                  hintText: '미션을 검색해보세요',
                  hintStyle: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF6C757D),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20.w,
                    color: const Color(0xFF6C757D),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 20.w,
                            color: const Color(0xFF6C757D),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchProvider.notifier).clearResults();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            height: 44.h,
            width: 44.w,
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              icon: Icon(
                Icons.search,
                color: Colors.white,
                size: 20.w,
              ),
              onPressed: () {
                final query = _searchController.text.trim();
                if (query.isNotEmpty) {
                  ref.read(searchProvider.notifier).search(query);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final searchState = ref.watch(searchProvider);
    final filter = searchState.filter;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: Colors.white,
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFE9ECEF)),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterRow(
                  '카테고리',
                  filter.categories,
                  ['웹사이트', '모바일앱', '게임', 'API', '데스크톱'],
                  (selected) {
                    ref.read(searchProvider.notifier).updateFilter(
                      filter.copyWith(categories: selected),
                    );
                  },
                ),
                SizedBox(height: 16.h),
                _buildFilterRow(
                  '난이도',
                  filter.difficulties,
                  ['쉬움', '보통', '어려움'],
                  (selected) {
                    ref.read(searchProvider.notifier).updateFilter(
                      filter.copyWith(difficulties: selected),
                    );
                  },
                ),
                SizedBox(height: 16.h),
                _buildRewardFilter(filter),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        ref.read(searchProvider.notifier).clearFilter();
                      },
                      child: Text(
                        '초기화',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF6C757D),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isFilterExpanded = false;
                        });
                        final query = _searchController.text.trim();
                        if (query.isNotEmpty) {
                          ref.read(searchProvider.notifier).search(query);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 8.h,
                        ),
                      ),
                      child: Text(
                        '적용',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
    String title,
    List<String> selected,
    List<String> options,
    Function(List<String>) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(
                option,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isSelected ? Colors.white : const Color(0xFF6C757D),
                ),
              ),
              selected: isSelected,
              onSelected: (isSelectedChip) {
                final newSelected = isSelectedChip ? 
                  [...selected, option] : 
                  selected.where((item) => item != option).toList();
                onChanged(newSelected);
              },
              selectedColor: const Color(0xFF007AFF),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE9ECEF)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRewardFilter(SearchFilter filter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '보상 범위',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '최소',
                  hintStyle: TextStyle(fontSize: 12.sp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                ),
                onChanged: (value) {
                  final minReward = int.tryParse(value);
                  ref.read(searchProvider.notifier).updateFilter(
                    filter.copyWith(minReward: minReward),
                  );
                },
              ),
            ),
            SizedBox(width: 12.w),
            Text('~', style: TextStyle(fontSize: 14.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '최대',
                  hintStyle: TextStyle(fontSize: 12.sp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                ),
                onChanged: (value) {
                  final maxReward = int.tryParse(value);
                  ref.read(searchProvider.notifier).updateFilter(
                    filter.copyWith(maxReward: maxReward),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(SearchState searchState) {
    if (searchState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF007AFF),
        ),
      );
    }

    if (searchState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.w,
              color: const Color(0xFF6C757D),
            ),
            SizedBox(height: 16.h),
            Text(
              '검색 중 오류가 발생했습니다',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF6C757D),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              searchState.error!,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF6C757D),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (searchState.query.isNotEmpty && searchState.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48.w,
              color: const Color(0xFF6C757D),
            ),
            SizedBox(height: 16.h),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF6C757D),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '다른 키워드로 검색해보세요',
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF6C757D),
              ),
            ),
          ],
        ),
      );
    }

    if (searchState.query.isNotEmpty && searchState.results.isNotEmpty) {
      return _buildSearchResults(searchState.results);
    }

    return _buildSearchSuggestions(searchState);
  }

  Widget _buildSearchResults(List<Map<String, dynamic>> results) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final mission = results[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: MissionCard(
            missionId: mission['id'],
            title: mission['title'] ?? '',
            reward: '${mission['reward'] ?? 0}P',
            deadline: mission['endDate']?.toDate().toString().split(' ')[0] ?? '2024-12-31',
            progress: (mission['currentParticipants'] ?? 0) / (mission['maxParticipants'] ?? 1),
            color: const Color(0xFFE3F2FD),
            missionData: mission,
          ),
        );
      },
    );
  }

  Widget _buildSearchSuggestions(SearchState searchState) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (searchState.history.isNotEmpty) ...[
            _buildSectionHeader('최근 검색', () {
              ref.read(searchProvider.notifier).clearHistory();
            }),
            SizedBox(height: 12.h),
            _buildHistoryList(searchState.history),
            SizedBox(height: 24.h),
          ],
          _buildSectionHeader('인기 검색어', null),
          SizedBox(height: 12.h),
          _buildPopularTerms(searchState.popularTerms),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onClear) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        if (onClear != null)
          TextButton(
            onPressed: onClear,
            child: Text(
              '전체 삭제',
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF6C757D),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryList(List<String> history) {
    return Column(
      children: history.map((query) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.history,
            size: 20.w,
            color: const Color(0xFF6C757D),
          ),
          title: Text(
            query,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.close,
              size: 16.w,
              color: const Color(0xFF6C757D),
            ),
            onPressed: () {
              ref.read(searchProvider.notifier).removeFromHistory(query);
            },
          ),
          onTap: () {
            _searchController.text = query;
            ref.read(searchProvider.notifier).search(query);
          },
        );
      }).toList(),
    );
  }

  Widget _buildPopularTerms(List<String> terms) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: terms.map((term) {
        return ActionChip(
          label: Text(
            term,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF007AFF),
            ),
          ),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF007AFF)),
          onPressed: () {
            _searchController.text = term;
            ref.read(searchProvider.notifier).search(term);
          },
        );
      }).toList(),
    );
  }
}