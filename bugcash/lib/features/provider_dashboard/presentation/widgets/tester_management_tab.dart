import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/test_session_model.dart';
import '../../../../core/utils/logger.dart';

// Firebase Provider for testers with test sessions associated with a provider
final providerTestersProvider = StreamProvider.family<List<TesterInfo>, String>((ref, providerId) {
  return FirebaseFirestore.instance
      .collection('test_sessions')
      .where('providerId', isEqualTo: providerId)
      .snapshots()
      .asyncMap((snapshot) async {
    final List<TesterInfo> testers = [];
    final Set<String> uniqueTesters = {};

    for (final doc in snapshot.docs) {
      final session = TestSession.fromFirestore(doc);
      final testerId = session.testerId;

      if (uniqueTesters.contains(testerId)) continue;
      uniqueTesters.add(testerId);

      // Get tester profile from users collection
      try {
        final testerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(testerId)
            .get();

        if (testerDoc.exists) {
          final testerData = testerDoc.data()!;

          // Calculate test session statistics for this tester
          final testerSessions = await FirebaseFirestore.instance
              .collection('test_sessions')
              .where('testerId', isEqualTo: testerId)
              .where('providerId', isEqualTo: providerId)
              .get();

          final completedSessions = testerSessions.docs.where((doc) {
            final sessionData = doc.data();
            return sessionData['status'] == TestSessionStatus.completed.name;
          }).length;
          final totalSessions = testerSessions.docs.length;
          final successRate = totalSessions > 0 ? completedSessions / totalSessions : 0.0;

          // Calculate active session info
          final activeSessions = testerSessions.docs.where((doc) {
            final sessionData = doc.data();
            return sessionData['status'] == TestSessionStatus.active.name;
          }).length;

          testers.add(TesterInfo(
            id: testerId,
            name: testerData['displayName'] ?? 'Unknown',
            email: testerData['email'] ?? '',
            joinDate: (testerData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            completedMissions: completedSessions,
            successRate: successRate,
            rating: (testerData['rating'] as num?)?.toDouble() ?? 0.0,
            status: activeSessions > 0 ? TesterStatus.active : TesterStatus.inactive,
            specialties: List<String>.from(testerData['skills'] ?? []),
            memo: testerData['memo'] ?? '',
            tags: List<String>.from(testerData['tags'] ?? []),
            activeTestSessions: activeSessions,
            pendingApplications: await _countPendingApplications(testerId, providerId),
          ));
        }
      } catch (e) {
        AppLogger.error('Error fetching tester data', 'TesterManagementTab', e);
      }
    }

    return testers;
  });
});

// Helper function to count pending applications
Future<int> _countPendingApplications(String testerId, String providerId) async {
  try {
    final pendingSessions = await FirebaseFirestore.instance
        .collection('test_sessions')
        .where('testerId', isEqualTo: testerId)
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: TestSessionStatus.pending.name)
        .get();
    return pendingSessions.docs.length;
  } catch (e) {
    return 0;
  }
}

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TesterInfo> _getFilteredTesters(List<TesterInfo> testers) {
    List<TesterInfo> filtered = List.from(testers);
    
    // 검색 필터링
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
      if (_selectedFilter == '활성') {
        filtered = filtered.where((tester) => tester.status == TesterStatus.active).toList();
      } else if (_selectedFilter == '비활성') {
        filtered = filtered.where((tester) => tester.status == TesterStatus.inactive).toList();
      }
    }

    // 정렬
    if (_selectedSort == '가입일순') {
      filtered.sort((a, b) => b.joinDate.compareTo(a.joinDate));
    } else if (_selectedSort == '완료미션순') {
      filtered.sort((a, b) => b.completedMissions.compareTo(a.completedMissions));
    } else if (_selectedSort == '성공률순') {
      filtered.sort((a, b) => b.successRate.compareTo(a.successRate));
    } else if (_selectedSort == '평점순') {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_selectedSort == '진행중순') {
      filtered.sort((a, b) => b.activeTestSessions.compareTo(a.activeTestSessions));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final testersAsync = ref.watch(providerTestersProvider(widget.providerId));
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(context),
          _buildSearchAndFilter(context),
          Expanded(
            child: testersAsync.when(
              data: (testers) {
                final filteredTesters = _getFilteredTesters(testers);
                
                if (filteredTesters.isEmpty) {
                  return _buildEmptyState();
                }
                
                return Column(
                  children: [
                    _buildStatsCards(testers),
                    Expanded(child: _buildTesterList(filteredTesters)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    SizedBox(height: 16.h),
                    Text(
                      '테스터 정보를 불러올 수 없습니다',
                      style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      error.toString(),
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.people, size: 24.w, color: Colors.indigo[700]),
          SizedBox(width: 12.w),
          Text(
            '테스터 관리',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // TODO: Export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('내보내기 기능 (개발 중)')),
              );
            },
            icon: const Icon(Icons.download),
            tooltip: '데이터 내보내기',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: Column(
        children: [
          // 검색바
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '이름, 이메일, 전문분야로 검색...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.indigo[700]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.indigo[700],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.tune, color: Colors.white, size: 20.w),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // 필터 및 정렬
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
                  items: ['전체', '활성', '비활성'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedFilter = newValue!;
                    });
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
                  items: ['가입일순', '완료미션순', '성공률순', '평점순', '진행중순'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedSort = newValue!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(List<TesterInfo> testers) {
    final totalTesters = testers.length;
    final activeTesters = testers.where((t) => t.status == TesterStatus.active).length;
    final avgRating = testers.isEmpty ? 0.0 : 
        testers.map((t) => t.rating).reduce((a, b) => a + b) / testers.length;
    final avgSuccessRate = testers.isEmpty ? 0.0 : 
        testers.map((t) => t.successRate).reduce((a, b) => a + b) / testers.length;

    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          _buildStatCard('총 테스터', totalTesters.toString(), Icons.people, Colors.indigo[600]!),
          SizedBox(width: 12.w),
          _buildStatCard('활성 테스터', activeTesters.toString(), Icons.person, Colors.indigo[500]!),
          SizedBox(width: 12.w),
          _buildStatCard('평균 평점', avgRating.toStringAsFixed(1), Icons.star, Colors.indigo[400]!),
          SizedBox(width: 12.w),
          _buildStatCard('평균 성공률', '${(avgSuccessRate * 100).toStringAsFixed(0)}%', Icons.check_circle, Colors.indigo[300]!),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20.w),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTesterList(List<TesterInfo> testers) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: testers.length,
      itemBuilder: (context, index) {
        final tester = testers[index];
        return _buildTesterCard(tester);
      },
    );
  }

  Widget _buildTesterCard(TesterInfo tester) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: tester.status == TesterStatus.active ? Colors.indigo[100] : Colors.grey[300],
                  child: Text(
                    tester.name.isNotEmpty ? tester.name[0] : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tester.status == TesterStatus.active ? Colors.indigo[800] : Colors.grey[600],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tester.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tester.email,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: tester.status == TesterStatus.active ? Colors.indigo[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    tester.status == TesterStatus.active ? '활성' : '비활성',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: tester.status == TesterStatus.active ? Colors.indigo[800] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            
            if (tester.specialties.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: tester.specialties.map((specialty) => Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.indigo[200]!),
                  ),
                  child: Text(
                    specialty,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.indigo[700],
                    ),
                  ),
                )).toList(),
              ),
            ],
            
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('완료 세션', tester.completedMissions.toString(), Icons.assignment_turned_in),
                ),
                Expanded(
                  child: _buildInfoItem('성공률', '${(tester.successRate * 100).toStringAsFixed(0)}%', Icons.trending_up),
                ),
                Expanded(
                  child: _buildInfoItem('평점', tester.rating.toStringAsFixed(1), Icons.star),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('진행 중', tester.activeTestSessions.toString(), Icons.play_circle_outline),
                ),
                Expanded(
                  child: _buildInfoItem('대기 중', tester.pendingApplications.toString(), Icons.hourglass_empty),
                ),
                Expanded(
                  child: Container(), // Empty space for alignment
                ),
              ],
            ),
            
            if (tester.memo.isNotEmpty) ...[
              SizedBox(height: 12.h),
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
                    fontSize: 12.sp,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14.w, color: Colors.grey[600]),
        SizedBox(width: 4.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64.w, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            '아직 테스터가 없습니다',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '앱을 등록하고 테스트 세션을 시작하여\n테스터들의 참여를 유도해보세요',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

enum TesterStatus { active, inactive }

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
  final int activeTestSessions;
  final int pendingApplications;

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
    required this.memo,
    required this.tags,
    this.activeTestSessions = 0,
    this.pendingApplications = 0,
  });
}