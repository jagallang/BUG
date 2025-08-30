import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Mock Provider Dashboard Page (Firebase 의존성 제거)
class ProviderDashboardPage extends ConsumerStatefulWidget {
  final String providerId;

  const ProviderDashboardPage({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends ConsumerState<ProviderDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Provider Dashboard',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('알림 기능 (개발 중)')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프로필 기능 (개발 중)')),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardTab(),
          _buildAppsTab(),
          _buildMissionsTab(),
          _buildReportsTab(),
          _buildAnalyticsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: '대시보드',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps),
            label: '앱 관리',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: '미션',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bug_report),
            label: '버그 리포트',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '분석',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '안녕하세요, BugCash Provider님!',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '오늘도 품질 높은 앱을 만들어 보세요.',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24.h),
          
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: '총 미션',
                  value: '15',
                  icon: Icons.assignment,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildStatCard(
                  title: '활성 미션',
                  value: '3',
                  icon: Icons.play_circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: '총 테스터',
                  value: '128',
                  icon: Icons.group,
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildStatCard(
                  title: '버그 리포트',
                  value: '89',
                  icon: Icons.bug_report,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),
          
          // Recent Activities
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 활동',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16.h),
                _buildActivityItem(
                  title: '새로운 버그 리포트',
                  subtitle: '김테스터님이 ShopApp에서 결제 오류를 발견했습니다.',
                  time: '30분 전',
                  icon: Icons.bug_report,
                  color: Colors.red,
                ),
                _buildActivityItem(
                  title: '미션 완료',
                  subtitle: 'FoodDelivery UI/UX 테스트 미션이 완료되었습니다.',
                  time: '2시간 전',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _buildActivityItem(
                  title: '새로운 테스터 참여',
                  subtitle: '박테스터님이 ShopApp 테스트에 참여했습니다.',
                  time: '4시간 전',
                  icon: Icons.person_add,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppsTab() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '등록된 앱',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('앱 등록 기능 (개발 중)')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('앱 등록'),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                final apps = [
                  {'name': 'ShopApp', 'status': '활성', 'version': '2.1.0', 'missions': 8},
                  {'name': 'FoodDelivery', 'status': '테스팅', 'version': '1.5.2', 'missions': 4},
                  {'name': 'FitnessTracker', 'status': '일시정지', 'version': '3.0.1', 'missions': 3},
                ];
                final app = apps[index];
                
                return Card(
                  margin: EdgeInsets.only(bottom: 12.h),
                  child: ListTile(
                    leading: Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.phone_android,
                        color: Colors.blue,
                        size: 24.sp,
                      ),
                    ),
                    title: Text(
                      app['name'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                    ),
                    subtitle: Text('버전 ${app['version']} • 미션 ${app['missions']}개'),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: app['status'] == '활성' ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        app['status'] as String,
                        style: TextStyle(
                          color: app['status'] == '활성' ? Colors.green : Colors.orange,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${app['name']} 상세 정보 (개발 중)')),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsTab() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '미션 관리',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('미션 생성 기능 (개발 중)')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('미션 생성'),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView.builder(
              itemCount: 2,
              itemBuilder: (context, index) {
                final missions = [
                  {
                    'title': 'ShopApp 결제 기능 테스트',
                    'app': 'ShopApp',
                    'status': '활성',
                    'testers': '7/10',
                    'reward': '250P',
                    'deadline': '5일 남음'
                  },
                  {
                    'title': 'FoodDelivery UI/UX 개선 테스트',
                    'app': 'FoodDelivery',
                    'status': '완료',
                    'testers': '15/15',
                    'reward': '180P',
                    'deadline': '완료됨'
                  },
                ];
                final mission = missions[index];
                
                return Card(
                  margin: EdgeInsets.only(bottom: 16.h),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                mission['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: mission['status'] == '활성' ? Colors.green.shade50 : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                mission['status'] as String,
                                style: TextStyle(
                                  color: mission['status'] == '활성' ? Colors.green : Colors.blue,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          mission['app'] as String,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '참여자: ${mission['testers']}',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                            Text(
                              '보상: ${mission['reward']}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              mission['deadline'] as String,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '버그 리포트',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView.builder(
              itemCount: 2,
              itemBuilder: (context, index) {
                final reports = [
                  {
                    'title': 'ShopApp 결제 버튼 클릭 안됨',
                    'app': 'ShopApp',
                    'severity': 'High',
                    'tester': '김테스터',
                    'status': '확인중',
                    'time': '6시간 전'
                  },
                  {
                    'title': 'FoodDelivery 주문 내역 표시 오류',
                    'app': 'FoodDelivery',
                    'severity': 'Medium',
                    'tester': '이테스터',
                    'status': '수정중',
                    'time': '1일 전'
                  },
                ];
                final report = reports[index];
                
                return Card(
                  margin: EdgeInsets.only(bottom: 16.h),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                report['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: report['severity'] == 'High' ? Colors.red.shade50 : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                report['severity'] as String,
                                style: TextStyle(
                                  color: report['severity'] == 'High' ? Colors.red : Colors.orange,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '${report['app']} • ${report['tester']}님',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                report['status'] as String,
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              report['time'] as String,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '분석 및 통계',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.analytics,
                  size: 48.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  '상세 분석 기능',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '앱 성능, 테스터 활동, 미션 효율성 등\n다양한 분석 데이터를 제공할 예정입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('상세 분석 기능 (개발 중)')),
                    );
                  },
                  child: const Text('상세보기'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 24.sp,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}