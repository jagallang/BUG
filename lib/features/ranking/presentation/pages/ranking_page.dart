import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/ranking_provider.dart';
import '../../domain/models/user_ranking.dart';
import '../widgets/ranking_card.dart';
import '../widgets/podium_widget.dart';
import '../widgets/ranking_stats_widget.dart';

class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'all';
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rankingState = ref.watch(rankingProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterSection(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverallTab(rankingState),
                _buildCategoryTab(rankingState),
                _buildStatsTab(rankingState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        '🏆 랭킹',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: Colors.black,
            size: 24.w,
          ),
          onPressed: () {
            ref.read(rankingProvider.notifier).refresh();
          },
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              '기간',
              _selectedPeriod,
              ['all', 'daily', 'weekly', 'monthly'],
              ['전체', '일간', '주간', '월간'],
              (value) {
                setState(() {
                  _selectedPeriod = value;
                });
                ref.read(rankingProvider.notifier).updateFilter(period: value);
              },
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildDropdown(
              '카테고리',
              _selectedCategory,
              ['all', '웹사이트', '모바일앱', '게임', 'API', '보안'],
              ['전체', '웹사이트', '모바일앱', '게임', 'API', '보안'],
              (value) {
                setState(() {
                  _selectedCategory = value;
                });
                ref.read(rankingProvider.notifier).updateFilter(category: value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> values,
    List<String> labels,
    Function(String) onChanged,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: (String? newValue) {
            if (newValue != null) onChanged(newValue);
          },
          items: values.asMap().entries.map((entry) {
            final index = entry.key;
            final val = entry.value;
            return DropdownMenuItem<String>(
              value: val,
              child: Text(
                labels[index],
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF007AFF),
        unselectedLabelColor: const Color(0xFF6C757D),
        indicatorColor: const Color(0xFF007AFF),
        labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14.sp),
        tabs: const [
          Tab(text: '전체 랭킹'),
          Tab(text: '카테고리별'),
          Tab(text: '통계'),
        ],
      ),
    );
  }

  Widget _buildOverallTab(RankingState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF007AFF),
        ),
      );
    }

    if (state.error != null) {
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
              '랭킹을 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF6C757D),
              ),
            ),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: () => ref.read(rankingProvider.notifier).refresh(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          if (state.rankings.length >= 3) ...[
            PodiumWidget(
              topThree: state.rankings.take(3).toList(),
            ),
            SizedBox(height: 24.h),
          ],
          _buildRankingList(state.rankings),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(RankingState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '카테고리별 상위 랭커',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          _buildCategoryRankings(state.rankings),
        ],
      ),
    );
  }

  Widget _buildStatsTab(RankingState state) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          RankingStatsWidget(stats: state.stats),
          SizedBox(height: 24.h),
          _buildTopContributors(state.rankings.take(5).toList()),
        ],
      ),
    );
  }

  Widget _buildRankingList(List<UserRanking> rankings) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rankings.length,
      itemBuilder: (context, index) {
        final ranking = rankings[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: RankingCard(ranking: ranking),
        );
      },
    );
  }

  Widget _buildCategoryRankings(List<UserRanking> rankings) {
    final categories = ['웹사이트', '모바일앱', '게임', 'API', '보안'];
    
    return Column(
      children: categories.map((category) {
        final categoryRankings = rankings
            .where((ranking) => ranking.categoryPoints.containsKey(category))
            .toList();
        
        if (categoryRankings.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$category 전문가',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...categoryRankings.take(3).map((ranking) {
                    final points = ranking.categoryPoints[category] ?? 0;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Container(
                            width: 24.w,
                            height: 24.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFF007AFF),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${ranking.rank}',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              ranking.username,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Text(
                            '${points}P',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF007AFF),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 16.h),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTopContributors(List<UserRanking> topUsers) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🌟 최고 기여자',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          ...topUsers.map((user) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: _getRankColor(user.rank),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.badgeEmoji,
                        style: TextStyle(fontSize: 20.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${user.completedMissions}개 미션 완료',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF6C757D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${user.totalPoints}P',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF007AFF),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color(0xFFE3F2FD); // Light blue
    }
  }
}