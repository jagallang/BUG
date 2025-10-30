import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize sample data (commented out as method doesn't exist)
  // final firestoreService = FirestoreService();
  // await firestoreService.initializeDatabase();
  
  runApp(const BugCashWebDemo());
}

class BugCashWebDemo extends StatelessWidget {
  const BugCashWebDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'BugCash - Web Demo',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          home: const HomePage(),
        );
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF00BFA5),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00BFA5),
        secondary: Color(0xFF4EDBC5),
        error: Color(0xFFF44336),
        surface: Colors.white,
      ),
      
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: const Color(0xFF212121),
        displayColor: const Color(0xFF212121),
      ),
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF212121),
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF212121),
        ),
      ),
      
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        color: Colors.white,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF00BFA5),
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 52.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const MissionListView(),
    const MissionSearchView(),
    const RankingView(),
    const WalletView(),
    const ProfileView(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.bug_report,
                  label: '미션',
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavItem(
                  icon: Icons.search,
                  label: '검색',
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _NavItem(
                  icon: Icons.leaderboard,
                  label: '랭킹',
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _NavItem(
                  icon: Icons.account_balance_wallet,
                  label: '지갑',
                  isSelected: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                _NavItem(
                  icon: Icons.person,
                  label: '프로필',
                  isSelected: _selectedIndex == 4,
                  onTap: () => setState(() => _selectedIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00BFA5) : const Color(0xFF757575),
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: isSelected ? const Color(0xFF00BFA5) : const Color(0xFF757575),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MissionListView extends StatefulWidget {
  const MissionListView({super.key});

  @override
  State<MissionListView> createState() => _MissionListViewState();
}

class _MissionListViewState extends State<MissionListView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('BugCash'),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16.sp,
                  color: const Color(0xFF00C853),
                ),
                SizedBox(width: 4.w),
                Text(
                  '75,000',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00C853),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00BFA5),
          unselectedLabelColor: const Color(0xFF757575),
          indicatorColor: const Color(0xFF00BFA5),
          labelStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: '진행중인 미션'),
            Tab(text: '스케줄표'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 진행중인 미션 탭
          ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              const MissionCard(
                appName: '쇼핑앱 A',
                currentDay: 7,
                totalDays: 14,
                dailyPoints: 5000,
                todayCompleted: true,
              ),
              SizedBox(height: 12.h),
              const MissionCard(
                appName: '게임앱 B',
                currentDay: 3,
                totalDays: 14,
                dailyPoints: 5000,
                todayCompleted: false,
              ),
              SizedBox(height: 12.h),
              const MissionCard(
                appName: '유틸리티앱 C',
                currentDay: 10,
                totalDays: 14,
                dailyPoints: 5000,
                todayCompleted: false,
              ),
            ],
          ),
          // 스케줄표 탭
          const MissionScheduleView(),
        ],
      ),
    );
  }
}

class MissionScheduleView extends StatelessWidget {
  const MissionScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];
    
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // 이번주 달력
        Container(
          padding: EdgeInsets.all(16.w),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '이번주 스케줄',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${today.month}월 ${_getWeekRange(today)}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              
              // 요일 헤더
              Row(
                children: weekDays.map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ),
                )).toList(),
              ),
              
              SizedBox(height: 12.h),
              
              // 날짜 및 미션 상태
              Row(
                children: List.generate(7, (index) {
                  final date = today.subtract(Duration(days: today.weekday - 1 - index));
                  final isToday = _isSameDay(date, today);
                  final dayStatus = _getDayStatus(index);
                  
                  return Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: isToday 
                                ? const Color(0xFF00BFA5)
                                : dayStatus['color'].withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isToday 
                                  ? const Color(0xFF00BFA5)
                                  : dayStatus['color'].withValues(alpha: 0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              date.day.toString(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: isToday 
                                    ? Colors.white 
                                    : dayStatus['color'],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: dayStatus['color'],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          dayStatus['text'],
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: dayStatus['color'],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20.h),
        
        // 오늘의 미션
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '오늘의 미션 (${today.month}/${today.day})',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              
              const _TodayMissionItem(
                appName: '쇼핑앱 A',
                missionDay: 7,
                totalDays: 14,
                status: 'completed',
                points: 5000,
                completedAt: '오전 10:30',
              ),
              
              const _TodayMissionItem(
                appName: '게임앱 B',
                missionDay: 3,
                totalDays: 14,
                status: 'pending',
                points: 5000,
              ),
              
              const _TodayMissionItem(
                appName: '유틸리티앱 C',
                missionDay: 10,
                totalDays: 14,
                status: 'in_progress',
                points: 5000,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20.h),
        
        // 이번주 통계
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '이번주 통계',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              
              Row(
                children: [
                  const Expanded(
                    child: _MissionStatCard(
                      title: '완료한 미션',
                      value: '12',
                      unit: '개',
                      color: Color(0xFF4CAF50),
                      icon: Icons.check_circle,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  const Expanded(
                    child: _MissionStatCard(
                      title: '적립 포인트',
                      value: '35,000',
                      unit: 'P',
                      color: Color(0xFF00C853),
                      icon: Icons.account_balance_wallet,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  const Expanded(
                    child: _MissionStatCard(
                      title: '발견 버그',
                      value: '2',
                      unit: '개',
                      color: Color(0xFFFF9800),
                      icon: Icons.bug_report,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getWeekRange(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${startOfWeek.day}~${endOfWeek.day}일';
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  Map<String, dynamic> _getDayStatus(int dayIndex) {
    // 요일별 미션 완료 상태 (예시 데이터)
    final statuses = [
      {'color': const Color(0xFF4CAF50), 'text': '완료'},  // 월
      {'color': const Color(0xFF4CAF50), 'text': '완료'},  // 화
      {'color': const Color(0xFF4CAF50), 'text': '완료'},  // 수
      {'color': const Color(0xFF00BFA5), 'text': '진행'},  // 목 (오늘)
      {'color': const Color(0xFF757575), 'text': '예정'},  // 금
      {'color': const Color(0xFF757575), 'text': '예정'},  // 토
      {'color': const Color(0xFF757575), 'text': '예정'},  // 일
    ];
    return statuses[dayIndex];
  }
}

class _TodayMissionItem extends StatelessWidget {
  final String appName;
  final int missionDay;
  final int totalDays;
  final String status; // completed, pending, in_progress
  final int points;
  final String? completedAt;
  
  const _TodayMissionItem({
    required this.appName,
    required this.missionDay,
    required this.totalDays,
    required this.status,
    required this.points,
    this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'completed':
        statusColor = const Color(0xFF4CAF50);
        statusText = '완료';
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = const Color(0xFF00BFA5);
        statusText = '진행중';
        statusIcon = Icons.play_circle;
        break;
      default:
        statusColor = const Color(0xFF757575);
        statusText = '대기';
        statusIcon = Icons.schedule;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Icon(
                statusIcon,
                size: 20.sp,
                color: statusColor,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Day $missionDay/$totalDays',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF757575),
                  ),
                ),
                if (completedAt != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    '$completedAt 완료',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: statusColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '+${points}P',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00C853),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  
  const _MissionStatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: color,
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              color: const Color(0xFF757575),
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
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
                unit,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MissionSearchView extends StatefulWidget {
  const MissionSearchView({super.key});

  @override
  State<MissionSearchView> createState() => _MissionSearchViewState();
}

class _MissionSearchViewState extends State<MissionSearchView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '전체';
  String _searchQuery = '';
  
  final List<String> _categories = [
    '전체', '쇼핑', '게임', '유틸리티', '소셜', '금융', '교육', '건강', '음식', '여행'
  ];
  
  final List<AvailableMission> _allMissions = [
    AvailableMission(
      id: 'shopping_01',
      appName: '쇼핑몰 앱 A',
      category: '쇼핑',
      description: '새로운 쇼핑몰 앱의 주문부터 결제까지 전체 플로우를 테스트해보세요.',
      dailyPoints: 5000,
      totalDays: 14,
      difficulty: '쉬움',
      participants: 245,
      rating: 4.8,
      requirements: ['Android 8.0+', '20분 이상 테스트', '결제 기능 필수'],
      companyName: '이커머스코리아',
      isHot: true,
    ),
    AvailableMission(
      id: 'game_01',
      appName: '캐주얼 퍼즐 게임',
      category: '게임',
      description: '중독성 있는 퍼즐 게임의 레벨 진행과 보상 시스템을 체험해보세요.',
      dailyPoints: 6000,
      totalDays: 10,
      difficulty: '보통',
      participants: 189,
      rating: 4.6,
      requirements: ['iOS 14.0+', '30분 이상 플레이', '인앱구매 테스트'],
      companyName: '게임스튜디오',
      isNew: true,
    ),
    AvailableMission(
      id: 'utility_01', 
      appName: '생산성 도구 앱',
      category: '유틸리티',
      description: '업무 효율성을 높이는 다양한 도구들의 사용성을 평가해주세요.',
      dailyPoints: 4500,
      totalDays: 14,
      difficulty: '어려움',
      participants: 87,
      rating: 4.9,
      requirements: ['Android 10.0+', '업무 시나리오 테스트', '클라우드 동기화'],
      companyName: '프로덕티비티',
      isHot: false,
    ),
    AvailableMission(
      id: 'social_01',
      appName: '새로운 SNS 플랫폼',
      category: '소셜',
      description: '차세대 소셜 네트워크의 커뮤니티 기능과 콘텐츠 공유를 테스트해보세요.',
      dailyPoints: 7000,
      totalDays: 21,
      difficulty: '보통',
      participants: 312,
      rating: 4.2,
      requirements: ['iOS 15.0+', '콘텐츠 업로드', '친구 초대 기능'],
      companyName: '소셜테크',
      isNew: true,
    ),
    AvailableMission(
      id: 'finance_01',
      appName: '디지털 뱅킹 앱',
      category: '금융',
      description: '혁신적인 모바일 뱅킹 서비스의 보안과 편의성을 검증해주세요.',
      dailyPoints: 8000,
      totalDays: 14,
      difficulty: '어려움',
      participants: 156,
      rating: 4.7,
      requirements: ['본인인증 필수', '계좌 연동 테스트', '보안 기능 점검'],
      companyName: '핀테크뱅크',
      isHot: true,
    ),
    AvailableMission(
      id: 'education_01',
      appName: 'AI 학습 도우미',
      category: '교육',
      description: 'AI가 도와주는 개인 맞춤형 학습 경험을 체험하고 피드백해주세요.',
      dailyPoints: 5500,
      totalDays: 12,
      difficulty: '쉬움',
      participants: 203,
      rating: 4.5,
      requirements: ['학습자 프로필 설정', 'AI 튜터 상호작용', '진도 관리'],
      companyName: '에듀테크',
      isNew: false,
    ),
  ];
  
  List<AvailableMission> get _filteredMissions {
    return _allMissions.where((mission) {
      final matchesCategory = _selectedCategory == '전체' || mission.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || 
          mission.appName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          mission.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          mission.companyName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('미션 검색'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: '앱 이름, 회사명으로 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 50.h,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Center(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFF00BFA5)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isSelected 
                                ? const Color(0xFF00BFA5)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? Colors.white : const Color(0xFF757575),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Results
          Expanded(
            child: _filteredMissions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64.sp,
                          color: const Color(0xFF757575),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '검색 결과가 없습니다',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF757575),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '다른 키워드로 검색해보세요',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _filteredMissions.length,
                    itemBuilder: (context, index) {
                      final mission = _filteredMissions[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: MissionSearchCard(
                          mission: mission,
                          onApply: () => _applyToMission(mission),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _applyToMission(AvailableMission mission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          '미션 신청',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${mission.appName} 미션에 신청하시겠습니까?',
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '미션 정보',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00BFA5),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text('• 일일 포인트: ${mission.dailyPoints.toStringAsFixed(0)}P'),
                  Text('• 총 기간: ${mission.totalDays}일'),
                  Text('• 예상 총 포인트: ${(mission.dailyPoints * mission.totalDays).toStringAsFixed(0)}P'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${mission.appName} 미션 신청이 완료되었습니다!'),
                  backgroundColor: const Color(0xFF4CAF50),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('신청하기'),
          ),
        ],
      ),
    );
  }
}

class AvailableMission {
  final String id;
  final String appName;
  final String category;
  final String description;
  final double dailyPoints;
  final int totalDays;
  final String difficulty;
  final int participants;
  final double rating;
  final List<String> requirements;
  final String companyName;
  final bool isHot;
  final bool isNew;

  AvailableMission({
    required this.id,
    required this.appName,
    required this.category,
    required this.description,
    required this.dailyPoints,
    required this.totalDays,
    required this.difficulty,
    required this.participants,
    required this.rating,
    required this.requirements,
    required this.companyName,
    this.isHot = false,
    this.isNew = false,
  });
}

class MissionSearchCard extends StatelessWidget {
  final AvailableMission mission;
  final VoidCallback onApply;

  const MissionSearchCard({
    super.key,
    required this.mission,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: InkWell(
        onTap: () => _showMissionDetail(context),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // App Icon
                  Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00BFA5).withValues(alpha: 0.8),
                          const Color(0xFF4EDBC5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(
                        _getCategoryIcon(mission.category),
                        style: TextStyle(fontSize: 24.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  
                  // App Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                mission.appName,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (mission.isHot)
                              Container(
                                margin: EdgeInsets.only(left: 8.w),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5722),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  'HOT',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (mission.isNew)
                              Container(
                                margin: EdgeInsets.only(left: 8.w),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          mission.companyName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF757575),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: _getDifficultyColor(mission.difficulty).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                mission.difficulty,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                  color: _getDifficultyColor(mission.difficulty),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.star,
                              size: 14.sp,
                              color: const Color(0xFFFFD700),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              mission.rating.toString(),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.people,
                              size: 14.sp,
                              color: const Color(0xFF757575),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              '${mission.participants}명',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Points
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '+${mission.dailyPoints.toStringAsFixed(0)}P',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00C853),
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${mission.totalDays}일',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // Description
              Text(
                mission.description,
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.4,
                  color: const Color(0xFF424242),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 12.h),
              
              // Requirements (첫 2개만 표시)
              Wrap(
                spacing: 8.w,
                runSpacing: 4.h,
                children: mission.requirements.take(2).map((req) => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    req,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: const Color(0xFF757575),
                    ),
                  ),
                )).toList(),
              ),
              
              SizedBox(height: 12.h),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 36.h,
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    '미션 신청하기',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMissionDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Container(
                    width: 60.w,
                    height: 60.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00BFA5).withValues(alpha: 0.8),
                          const Color(0xFF4EDBC5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Center(
                      child: Text(
                        _getCategoryIcon(mission.category),
                        style: TextStyle(fontSize: 28.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.appName,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          mission.companyName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF757575),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16.sp,
                              color: const Color(0xFFFFD700),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${mission.rating} (${mission.participants}명)',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            title: '일일 포인트',
                            value: '+${mission.dailyPoints.toStringAsFixed(0)}P',
                            color: const Color(0xFF00C853),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _StatBox(
                            title: '총 기간',
                            value: '${mission.totalDays}일',
                            color: const Color(0xFF2196F3),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _StatBox(
                            title: '난이도',
                            value: mission.difficulty,
                            color: _getDifficultyColor(mission.difficulty),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Description
                    Text(
                      '미션 설명',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      mission.description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.5,
                        color: const Color(0xFF424242),
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Requirements
                    Text(
                      '테스트 요구사항',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ...mission.requirements.map((req) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Container(
                            width: 6.w,
                            height: 6.h,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00BFA5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              req,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF424242),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    
                    SizedBox(height: 24.h),
                    
                    // Expected Earnings
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(0xFF00C853).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: const Color(0xFF00C853),
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                '예상 총 적립 포인트',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF00C853),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '${(mission.dailyPoints * mission.totalDays).toStringAsFixed(0)} P',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00C853),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '버그 발견시 추가 보상 가능',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
            
            // Apply Button
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onApply();
                },
                child: const Text('미션 신청하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case '쇼핑': return '🛍️';
      case '게임': return '🎮';
      case '유틸리티': return '🔧';
      case '소셜': return '👥';
      case '금융': return '💳';
      case '교육': return '📚';
      case '건강': return '🏥';
      case '음식': return '🍽️';
      case '여행': return '✈️';
      default: return '📱';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case '쉬움': return const Color(0xFF4CAF50);
      case '보통': return const Color(0xFFFF9800);
      case '어려움': return const Color(0xFFF44336);
      default: return const Color(0xFF757575);
    }
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF757575),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class MissionCard extends StatelessWidget {
  final String appName;
  final int currentDay;
  final int totalDays;
  final int dailyPoints;
  final bool todayCompleted;
  
  const MissionCard({
    super.key,
    required this.appName,
    required this.currentDay,
    required this.totalDays,
    required this.dailyPoints,
    required this.todayCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MissionDetailPage(
                appName: appName,
                currentDay: currentDay,
                totalDays: totalDays,
                dailyPoints: dailyPoints,
                todayCompleted: todayCompleted,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00BFA5).withValues(alpha: 0.8),
                          const Color(0xFF4EDBC5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(
                        appName.contains('쇼핑') ? '🛍️' : 
                        appName.contains('게임') ? '🎮' : '🔧',
                        style: TextStyle(fontSize: 24.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Day $currentDay/$totalDays',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '+${dailyPoints}P',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00C853),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: LinearProgressIndicator(
                      value: currentDay / totalDays,
                      minHeight: 8.h,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00BFA5),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(currentDay / totalDays * 100).toInt()}% 완료',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF757575),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            todayCompleted
                                ? Icons.check_circle
                                : Icons.schedule,
                            size: 16.sp,
                            color: todayCompleted
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF9800),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            todayCompleted ? '오늘 완료' : '오늘 미션 대기',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: todayCompleted
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF9800),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MissionDetailPage extends StatelessWidget {
  final String appName;
  final int currentDay;
  final int totalDays;
  final int dailyPoints;
  final bool todayCompleted;
  
  const MissionDetailPage({
    super.key,
    required this.appName,
    required this.currentDay,
    required this.totalDays,
    required this.dailyPoints,
    required this.todayCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('미션 가이드를 확인하세요!'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00BFA5), Color(0xFF4EDBC5)],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60.w,
                              height: 60.h,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Center(
                                child: Text(
                                  appName.contains('쇼핑') ? '🛍️' : 
                                  appName.contains('게임') ? '🎮' : '🔧',
                                  style: TextStyle(fontSize: 32.sp),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appName,
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Day $currentDay/$totalDays',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                '+${dailyPoints}P',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: LinearProgressIndicator(
                            value: currentDay / totalDays,
                            minHeight: 8.h,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '${(currentDay / totalDays * 100).toInt()}% 완료',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Mission Description
                  _SectionCard(
                    title: '미션 설명',
                    child: Text(
                      '$appName 앱을 체험하고 사용자 경험을 공유해주세요. 다양한 기능을 탐색하며 앱의 장단점을 발견해보세요.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.5,
                        color: const Color(0xFF212121),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Daily Tasks
                  _SectionCard(
                    title: '오늘의 할 일',
                    child: Column(
                      children: [
                        _TaskItem(
                          icon: Icons.download,
                          title: '1. 앱 다운로드 및 설치',
                          isCompleted: true,
                          onTap: () => _launchUrl('https://play.google.com/store'),
                        ),
                        _TaskItem(
                          icon: Icons.timer,
                          title: '2. 20분 이상 앱 사용',
                          subtitle: '다양한 기능을 체험해보세요',
                          isCompleted: currentDay > 1,
                        ),
                        const _TaskItem(
                          icon: Icons.videocam,
                          title: '3. 사용 영상 녹화',
                          subtitle: 'Google Drive에 업로드',
                          isCompleted: false,
                        ),
                        const _TaskItem(
                          icon: Icons.quiz,
                          title: '4. 간단한 Q&A 답변',
                          subtitle: '앱 사용 경험 공유',
                          isCompleted: false,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Today Status
                  if (todayCompleted)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: const Color(0xFF4CAF50),
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '오늘 미션 완료!',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF4CAF50),
                                  ),
                                ),
                                Text(
                                  '${dailyPoints}P가 적립되었습니다.',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF757575),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Bottom Action Button
          if (!todayCompleted)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubmissionPage(appName: appName),
                      ),
                    );
                  },
                  child: const Text('미션 제출하기'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  
  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final VoidCallback? onTap;
  
  const _TaskItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: isCompleted 
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.1) 
                    : const Color(0xFF00BFA5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: isCompleted ? const Color(0xFF4CAF50) : const Color(0xFF00BFA5),
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
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? const Color(0xFF757575) : const Color(0xFF212121),
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 14.sp,
                color: const Color(0xFF757575),
              ),
          ],
        ),
      ),
    );
  }
}

class SubmissionPage extends StatefulWidget {
  final String appName;
  
  const SubmissionPage({
    super.key,
    required this.appName,
  });

  @override
  State<SubmissionPage> createState() => _SubmissionPageState();
}

class _SubmissionPageState extends State<SubmissionPage> {
  final _formKey = GlobalKey<FormState>();
  final _videoUrlController = TextEditingController();
  final _q1Controller = TextEditingController();
  final _q2Controller = TextEditingController();
  final _q3Controller = TextEditingController();
  final _bugReportController = TextEditingController();
  
  bool _hasFoundBug = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _videoUrlController.dispose();
    _q1Controller.dispose();
    _q2Controller.dispose();
    _q3Controller.dispose();
    _bugReportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('미션 제출'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mission Info Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.assignment,
                            color: const Color(0xFF00BFA5),
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.appName} - 미션 제출',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF00BFA5),
                                  ),
                                ),
                                Text(
                                  '미션 완료 후 아래 정보를 입력해주세요',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF757575),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Video URL Section
                    const _SectionHeader(
                      icon: Icons.videocam,
                      title: '사용 영상 업로드',
                      isRequired: true,
                    ),
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: _videoUrlController,
                      decoration: const InputDecoration(
                        hintText: 'Google Drive 링크를 입력하세요',
                        prefixIcon: Icon(Icons.link),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '영상 링크를 입력해주세요';
                        }
                        if (!value.contains('drive.google.com')) {
                          return 'Google Drive 링크를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Google Drive에 업로드 후 링크를 입력해주세요',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF757575),
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Q&A Section
                    const _SectionHeader(
                      icon: Icons.quiz,
                      title: '간단한 Q&A',
                      isRequired: true,
                    ),
                    SizedBox(height: 16.h),
                    
                    _QuestionField(
                      question: '1. 앱의 전반적인 사용감은 어떠셨나요?',
                      controller: _q1Controller,
                      hintText: '앱의 디자인, 속도, 사용성 등에 대한 의견을 자유롭게 작성해주세요',
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    _QuestionField(
                      question: '2. 가장 유용하거나 인상깊었던 기능은 무엇인가요?',
                      controller: _q2Controller,
                      hintText: '특별히 좋았던 기능이나 특징을 설명해주세요',
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    _QuestionField(
                      question: '3. 개선되었으면 하는 점이 있다면?',
                      controller: _q3Controller,
                      hintText: '불편했던 점이나 개선사항에 대한 의견을 작성해주세요',
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Bug Report Section
                    const _SectionHeader(
                      icon: Icons.bug_report,
                      title: '버그 발견 보고 (선택)',
                      subtitle: '발견시 추가 +2,000P',
                    ),
                    SizedBox(height: 12.h),
                    
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            value: _hasFoundBug,
                            onChanged: (value) {
                              setState(() {
                                _hasFoundBug = value ?? false;
                                if (!_hasFoundBug) {
                                  _bugReportController.clear();
                                }
                              });
                            },
                            title: Text(
                              '버그나 문제점을 발견했습니다',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            activeColor: const Color(0xFF00BFA5),
                          ),
                          if (_hasFoundBug) ...[
                            Divider(height: 1.h),
                            Padding(
                              padding: EdgeInsets.all(16.w),
                              child: TextFormField(
                                controller: _bugReportController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: '발견한 버그나 문제점을 자세히 설명해주세요\n(예: 로그인 버튼을 눌러도 반응이 없음)',
                                  border: InputBorder.none,
                                ),
                                validator: _hasFoundBug ? (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '버그 내용을 입력해주세요';
                                  }
                                  return null;
                                } : null,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 32.h),
                    
                    // Reward Info
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(0xFF00C853).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: const Color(0xFF00C853),
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '예상 적립 포인트',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF757575),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '${_hasFoundBug ? '7,000' : '5,000'} P',
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF00C853),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_hasFoundBug)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                '+버그 보너스',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Submit Button
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitMission,
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            const Text('제출 중...'),
                          ],
                        )
                      : const Text('미션 제출하기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitMission() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('미션이 성공적으로 제출되었습니다!'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('제출 중 오류가 발생했습니다: $e'),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isRequired;
  
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF00BFA5),
          size: 20.sp,
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isRequired) ...[
          SizedBox(width: 4.w),
          Text(
            '*',
            style: TextStyle(
              fontSize: 16.sp,
              color: const Color(0xFFF44336),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        if (subtitle != null) ...[
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 6.w,
              vertical: 2.h,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF9800),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuestionField extends StatelessWidget {
  final String question;
  final TextEditingController controller;
  final String hintText;
  
  const _QuestionField({
    required this.question,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hintText,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '답변을 입력해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class RankingView extends StatefulWidget {
  const RankingView({super.key});

  @override
  State<RankingView> createState() => _RankingViewState();
}

class _RankingViewState extends State<RankingView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<RankingUser> _weeklyRanking = [
    RankingUser(
      rank: 1,
      name: '테스터킹',
      points: 125000,
      level: 'Diamond',
      completedMissions: 28,
      avatar: '👑',
      isCurrentUser: false,
    ),
    RankingUser(
      rank: 2,
      name: 'BugHunter99',
      points: 98500,
      level: 'Gold',
      completedMissions: 24,
      avatar: '🏆',
      isCurrentUser: false,
    ),
    RankingUser(
      rank: 3,
      name: '미션마스터',
      points: 87300,
      level: 'Gold',
      completedMissions: 22,
      avatar: '🥉',
      isCurrentUser: false,
    ),
    RankingUser(
      rank: 15,
      name: '데모 사용자',
      points: 75000,
      level: 'Gold',
      completedMissions: 12,
      avatar: '😊',
      isCurrentUser: true,
    ),
  ];

  final List<RankingUser> _monthlyRanking = [
    RankingUser(
      rank: 1,
      name: 'MegaTester',
      points: 485000,
      level: 'Diamond',
      completedMissions: 98,
      avatar: '👑',
      isCurrentUser: false,
    ),
    RankingUser(
      rank: 2,
      name: '버그파인더',
      points: 432000,
      level: 'Diamond',
      completedMissions: 89,
      avatar: '🏆',
      isCurrentUser: false,
    ),
    RankingUser(
      rank: 3,
      name: 'QA전문가',
      points: 398500,
      level: 'Gold',
      completedMissions: 82,
      avatar: '🥉',
      isCurrentUser: false,
    ),
    RankingUser(
      rank: 23,
      name: '데모 사용자',
      points: 275000,
      level: 'Gold',
      completedMissions: 45,
      avatar: '😊',
      isCurrentUser: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('랭킹'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00BFA5),
          unselectedLabelColor: const Color(0xFF757575),
          indicatorColor: const Color(0xFF00BFA5),
          labelStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: '주간 랭킹'),
            Tab(text: '월간 랭킹'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRankingList(_weeklyRanking, '이번주'),
          _buildRankingList(_monthlyRanking, '이번달'),
        ],
      ),
    );
  }

  Widget _buildRankingList(List<RankingUser> rankings, String period) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // 상위 3명 포디움
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00BFA5),
                Color(0xFF4EDBC5),
              ],
            ),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            children: [
              Text(
                '$period TOP 3',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2등
                  if (rankings.length > 1) _buildPodiumItem(rankings[1], false),
                  // 1등
                  if (rankings.isNotEmpty) _buildPodiumItem(rankings[0], true),
                  // 3등
                  if (rankings.length > 2) _buildPodiumItem(rankings[2], false),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // 내 랭킹
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: const Color(0xFF00BFA5).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '내 랭킹',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00BFA5),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(
                        '😊',
                        style: TextStyle(fontSize: 24.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '데모 사용자',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Gold 테스터',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFFFFD700),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFA5),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          '${rankings.firstWhere((u) => u.isCurrentUser).rank}등',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${rankings.firstWhere((u) => u.isCurrentUser).points.toStringAsFixed(0)}P',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00C853),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // 전체 랭킹
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  '$period 전체 랭킹',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...rankings.where((user) => user.rank <= 10).map((user) => 
                _buildRankingItem(user)
              ),
              if (rankings.any((u) => u.isCurrentUser && u.rank > 10)) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: const Divider(),
                ),
                _buildRankingItem(rankings.firstWhere((u) => u.isCurrentUser)),
              ],
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // 레벨 정보
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '테스터 등급',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              const _LevelInfoItem(
                level: 'Bronze',
                color: Color(0xFFCD7F32),
                requirement: '0 - 49,999P',
                icon: '🥉',
              ),
              const _LevelInfoItem(
                level: 'Silver',
                color: Color(0xFFC0C0C0),
                requirement: '50,000 - 99,999P',
                icon: '🥈',
              ),
              const _LevelInfoItem(
                level: 'Gold',
                color: Color(0xFFFFD700),
                requirement: '100,000 - 299,999P',
                icon: '🥇',
                isCurrentLevel: true,
              ),
              const _LevelInfoItem(
                level: 'Diamond',
                color: Color(0xFF00BFA5),
                requirement: '300,000P+',
                icon: '💎',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumItem(RankingUser user, bool isFirst) {
    return Column(
      children: [
        Container(
          width: isFirst ? 80.w : 60.w,
          height: isFirst ? 80.h : 60.h,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              user.avatar,
              style: TextStyle(fontSize: isFirst ? 32.sp : 24.sp),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          user.name,
          style: TextStyle(
            fontSize: isFirst ? 14.sp : 12.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${user.points.toStringAsFixed(0)}P',
          style: TextStyle(
            fontSize: isFirst ? 12.sp : 10.sp,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: isFirst ? 60.w : 40.w,
          height: isFirst ? 80.h : 60.h,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
          ),
          child: Center(
            child: Text(
              '${user.rank}',
              style: TextStyle(
                fontSize: isFirst ? 24.sp : 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingItem(RankingUser user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: user.isCurrentUser 
            ? const Color(0xFF00BFA5).withValues(alpha: 0.05)
            : Colors.transparent,
        border: user.isCurrentUser 
            ? Border.all(color: const Color(0xFF00BFA5).withValues(alpha: 0.2))
            : null,
        borderRadius: user.isCurrentUser ? BorderRadius.circular(8.r) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30.w,
            height: 30.h,
            decoration: BoxDecoration(
              color: _getRankColor(user.rank).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.rank.toString(),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: _getRankColor(user.rank),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: _getLevelColor(user.level).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                user.avatar,
                style: TextStyle(fontSize: 20.sp),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (user.isCurrentUser) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFA5),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '나',
                          style: TextStyle(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      '${user.level} 테스터',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: _getLevelColor(user.level),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${user.completedMissions}개 완료',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.points.toStringAsFixed(0)}P',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00C853),
                ),
              ),
              if (user.rank <= 3) ...[
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getRankColor(user.rank),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    user.rank == 1 ? '🥇' : user.rank == 2 ? '🥈' : '🥉',
                    style: TextStyle(fontSize: 10.sp),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return const Color(0xFF00BFA5);
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Bronze': return const Color(0xFFCD7F32);
      case 'Silver': return const Color(0xFFC0C0C0);
      case 'Gold': return const Color(0xFFFFD700);
      case 'Diamond': return const Color(0xFF00BFA5);
      default: return const Color(0xFF757575);
    }
  }
}

class RankingUser {
  final int rank;
  final String name;
  final double points;
  final String level;
  final int completedMissions;
  final String avatar;
  final bool isCurrentUser;

  RankingUser({
    required this.rank,
    required this.name,
    required this.points,
    required this.level,
    required this.completedMissions,
    required this.avatar,
    required this.isCurrentUser,
  });
}

class _LevelInfoItem extends StatelessWidget {
  final String level;
  final Color color;
  final String requirement;
  final String icon;
  final bool isCurrentLevel;
  
  const _LevelInfoItem({
    required this.level,
    required this.color,
    required this.requirement,
    required this.icon,
    this.isCurrentLevel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isCurrentLevel ? color.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.r),
        border: isCurrentLevel 
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(fontSize: 20.sp),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$level 테스터',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    if (isCurrentLevel) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '현재 등급',
                          style: TextStyle(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  requirement,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('내 지갑'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF4EDBC5)],
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  Text(
                    '보유 포인트',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '75,000 P',
                    style: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('출금 신청이 접수되었습니다!'),
                          backgroundColor: Color(0xFF4CAF50),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF00BFA5),
                    ),
                    child: const Text('출금 신청'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '포인트 내역',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Expanded(
                      child: ListView(
                        children: const [
                          _PointHistoryItem(
                            title: '쇼핑앱 A - Day 7 완료',
                            points: '+5,000',
                            date: '2024-01-15',
                            isPositive: true,
                          ),
                          _PointHistoryItem(
                            title: '버그 발견 보너스',
                            points: '+2,000',
                            date: '2024-01-14',
                            isPositive: true,
                          ),
                          _PointHistoryItem(
                            title: '게임앱 B - Day 3 완료',
                            points: '+5,000',
                            date: '2024-01-13',
                            isPositive: true,
                          ),
                          _PointHistoryItem(
                            title: '유틸리티앱 C - Day 10 완료',
                            points: '+5,000',
                            date: '2024-01-12',
                            isPositive: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointHistoryItem extends StatelessWidget {
  final String title;
  final String points;
  final String date;
  final bool isPositive;
  
  const _PointHistoryItem({
    required this.title,
    required this.points,
    required this.date,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          Text(
            points,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AppProviderManagementView(),
                ),
              );
            },
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.admin_panel_settings,
                color: const Color(0xFF00BFA5),
                size: 24.sp,
              ),
            ),
            tooltip: '앱 공급자 관리',
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40.r,
                    backgroundColor: const Color(0xFF00BFA5),
                    child: Icon(Icons.person, size: 40.sp, color: Colors.white),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '데모 사용자',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Text(
                      'GOLD 테스터',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  const _StatItem(
                    label: '완료한 미션',
                    value: '12개',
                  ),
                  Divider(height: 32.h),
                  const _StatItem(
                    label: '총 적립 포인트',
                    value: '75,000 P',
                  ),
                  Divider(height: 32.h),
                  const _StatItem(
                    label: '발견한 버그',
                    value: '3개',
                  ),
                  Divider(height: 32.h),
                  ListTile(
                    leading: const Icon(Icons.info, color: Color(0xFF00BFA5)),
                    title: const Text('앱 정보'),
                    subtitle: const Text('BugCash v1.0.0'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('BugCash - 버그를 찾고, 캐시를 받자!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  
  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF757575),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class AppProviderManagementView extends StatefulWidget {
  const AppProviderManagementView({super.key});

  @override
  State<AppProviderManagementView> createState() => _AppProviderManagementViewState();
}

class _AppProviderManagementViewState extends State<AppProviderManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<AppMission> _missions = [
    AppMission(
      id: '1',
      title: '쇼핑앱 결제 테스트',
      appName: 'ShopEasy',
      category: 'E-commerce',
      status: 'active',
      testers: 15,
      maxTesters: 20,
      reward: 8000,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      bugs: 3,
    ),
    AppMission(
      id: '2', 
      title: '음식 주문 앱 UI 테스트',
      appName: 'FoodDelivery',
      category: 'Food & Drink',
      status: 'completed',
      testers: 25,
      maxTesters: 25,
      reward: 6000,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      bugs: 7,
    ),
    AppMission(
      id: '3',
      title: '게임 앱 성능 테스트',
      appName: 'PuzzleGame',
      category: 'Games',
      status: 'draft',
      testers: 0,
      maxTesters: 30,
      reward: 12000,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      bugs: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.admin_panel_settings,
                color: const Color(0xFF00BFA5),
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            const Text('앱 공급자 관리'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00BFA5),
          unselectedLabelColor: const Color(0xFF757575),
          indicatorColor: const Color(0xFF00BFA5),
          labelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: '미션 관리'),
            Tab(text: '통계'),
            Tab(text: '테스터'),
            Tab(text: '설정'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMissionManagement(),
          _buildStatistics(),
          _buildTesterManagement(),
          _buildSettings(),
        ],
      ),
      floatingActionButton: _tabController.index == 0 ? FloatingActionButton(
        heroTag: "web_demo_fab",
        onPressed: _showCreateMissionDialog,
        backgroundColor: const Color(0xFF00BFA5),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildMissionManagement() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: '활성 미션',
                value: _missions.where((m) => m.status == 'active').length.toString(),
                icon: Icons.play_circle,
                color: const Color(0xFF00BFA5),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _StatCard(
                title: '완료된 미션',
                value: _missions.where((m) => m.status == 'completed').length.toString(),
                icon: Icons.check_circle,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  '내 미션 목록',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ..._missions.map((mission) => _MissionManagementItem(
                mission: mission,
                onEdit: () => _showEditMissionDialog(mission),
                onDelete: () => _showDeleteMissionDialog(mission),
                onViewReports: () => _showBugReportsDialog(mission),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: '총 미션',
                value: _missions.length.toString(),
                icon: Icons.assignment,
                color: const Color(0xFF2196F3),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _StatCard(
                title: '총 테스터',
                value: _missions.fold(0, (sum, mission) => sum + mission.testers).toString(),
                icon: Icons.group,
                color: const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: '발견된 버그',
                value: _missions.fold(0, (sum, mission) => sum + mission.bugs).toString(),
                icon: Icons.bug_report,
                color: const Color(0xFFF44336),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _StatCard(
                title: '지급된 리워드',
                value: '${(_missions.where((m) => m.status == 'completed').fold(0, (sum, mission) => sum + (mission.reward * mission.testers)) / 1000).toStringAsFixed(0)}K',
                icon: Icons.monetization_on,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 20.h),
        
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '월간 통계',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.h),
              _buildStatRow('새 미션 생성', '${_missions.where((m) => m.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))).length}개'),
              SizedBox(height: 12.h),
              _buildStatRow('평균 테스터 수', '${(_missions.fold(0, (sum, mission) => sum + mission.testers) / _missions.length).toStringAsFixed(1)}명'),
              SizedBox(height: 12.h),
              _buildStatRow('버그 발견율', '${((_missions.fold(0, (sum, mission) => sum + mission.bugs) / _missions.fold(1, (sum, mission) => sum + mission.testers)) * 100).toStringAsFixed(1)}%'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTesterManagement() {
    final List<TesterInfo> testers = [
      TesterInfo(name: '테스터킹', level: 'Diamond', completedMissions: 28, rating: 4.9, isActive: true),
      TesterInfo(name: 'BugHunter99', level: 'Gold', completedMissions: 24, rating: 4.8, isActive: true),
      TesterInfo(name: '미션마스터', level: 'Gold', completedMissions: 22, rating: 4.7, isActive: false),
      TesterInfo(name: 'QA전문가', level: 'Silver', completedMissions: 18, rating: 4.6, isActive: true),
      TesterInfo(name: '버그파인더', level: 'Diamond', completedMissions: 35, rating: 4.9, isActive: true),
    ];

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: '활성 테스터',
                value: testers.where((t) => t.isActive).length.toString(),
                icon: Icons.person,
                color: const Color(0xFF4CAF50),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _StatCard(
                title: '평균 평점',
                value: (testers.fold(0.0, (sum, tester) => sum + tester.rating) / testers.length).toStringAsFixed(1),
                icon: Icons.star,
                color: const Color(0xFFFFD700),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 20.h),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  '테스터 목록',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...testers.map((tester) => _TesterItem(tester: tester)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  '앱 공급자 설정',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications, color: Color(0xFF00BFA5)),
                title: const Text('알림 설정'),
                subtitle: const Text('미션 상태 변경 알림'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: const Color(0xFF00BFA5),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: Color(0xFF00BFA5)),
                title: const Text('자동 승인'),
                subtitle: const Text('테스터 신청 자동 승인'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                  activeColor: const Color(0xFF00BFA5),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.security, color: Color(0xFF00BFA5)),
                title: const Text('보안 설정'),
                subtitle: const Text('앱 파일 보안 설정'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.payment, color: Color(0xFF00BFA5)),
                title: const Text('결제 설정'),
                subtitle: const Text('리워드 지급 설정'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.help, color: Color(0xFF00BFA5)),
                title: const Text('도움말'),
                subtitle: const Text('앱 공급자 가이드'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF757575),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showCreateMissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 미션 생성'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: '미션 제목',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.h),
            const TextField(
              decoration: InputDecoration(
                labelText: '앱 이름',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.h),
            const TextField(
              decoration: InputDecoration(
                labelText: '리워드 포인트',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
                const SnackBar(content: Text('미션이 생성되었습니다!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            child: const Text('생성', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditMissionDialog(AppMission mission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${mission.title} 수정'),
        content: const Text('미션 수정 기능은 개발 중입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showDeleteMissionDialog(AppMission mission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('미션 삭제'),
        content: Text('${mission.title}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('미션이 삭제되었습니다!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBugReportsDialog(AppMission mission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${mission.title} - 버그 리포트'),
        content: SizedBox(
          width: double.maxFinite,
          child: mission.bugs > 0 
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(mission.bugs, (index) => 
                  ListTile(
                    leading: const Icon(Icons.bug_report, color: Colors.red),
                    title: Text('버그 #${index + 1}'),
                    subtitle: Text('심각도: ${index == 0 ? '높음' : index == 1 ? '중간' : '낮음'}'),
                  ),
                ),
              )
            : const Text('아직 발견된 버그가 없습니다.'),
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
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24.sp),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24.sp,
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
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionManagementItem extends StatelessWidget {
  final AppMission mission;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewReports;

  const _MissionManagementItem({
    required this.mission,
    required this.onEdit,
    required this.onDelete,
    required this.onViewReports,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    
    switch (mission.status) {
      case 'active':
        statusColor = const Color(0xFF4CAF50);
        statusText = '진행중';
        break;
      case 'completed':
        statusColor = const Color(0xFF2196F3);
        statusText = '완료';
        break;
      case 'draft':
        statusColor = const Color(0xFF757575);
        statusText = '임시저장';
        break;
      default:
        statusColor = const Color(0xFF757575);
        statusText = '알 수 없음';
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mission.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            mission.appName,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF757575),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(Icons.group, size: 16.sp, color: const Color(0xFF757575)),
              SizedBox(width: 4.w),
              Text(
                '${mission.testers}/${mission.maxTesters}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF757575),
                ),
              ),
              SizedBox(width: 16.w),
              Icon(Icons.bug_report, size: 16.sp, color: Colors.red),
              SizedBox(width: 4.w),
              Text(
                '${mission.bugs}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF757575),
                ),
              ),
              const Spacer(),
              Text(
                '${mission.reward}P',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00C853),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onViewReports,
                icon: const Icon(Icons.assignment, size: 16),
                label: const Text('리포트', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00BFA5),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('수정', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF757575),
                ),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('삭제', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TesterItem extends StatelessWidget {
  final TesterInfo tester;

  const _TesterItem({required this.tester});

  @override
  Widget build(BuildContext context) {
    Color levelColor;
    switch (tester.level) {
      case 'Diamond':
        levelColor = const Color(0xFF00BFA5);
        break;
      case 'Gold':
        levelColor = const Color(0xFFFFD700);
        break;
      case 'Silver':
        levelColor = const Color(0xFFC0C0C0);
        break;
      default:
        levelColor = const Color(0xFFCD7F32);
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: levelColor.withValues(alpha: 0.1),
        child: Text(
          tester.name[0],
          style: TextStyle(
            color: levelColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(tester.name),
          SizedBox(width: 8.w),
          if (tester.isActive)
            Container(
              width: 8.w,
              height: 8.h,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      subtitle: Text('${tester.level} • ${tester.completedMissions}개 완료'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: const Color(0xFFFFD700), size: 16.sp),
          SizedBox(width: 4.w),
          Text(
            tester.rating.toString(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AppMission {
  final String id;
  final String title;
  final String appName;
  final String category;
  final String status;
  final int testers;
  final int maxTesters;
  final int reward;
  final DateTime createdAt;
  final int bugs;

  AppMission({
    required this.id,
    required this.title,
    required this.appName,
    required this.category,
    required this.status,
    required this.testers,
    required this.maxTesters,
    required this.reward,
    required this.createdAt,
    required this.bugs,
  });
}

class TesterInfo {
  final String name;
  final String level;
  final int completedMissions;
  final double rating;
  final bool isActive;

  TesterInfo({
    required this.name,
    required this.level,
    required this.completedMissions,
    required this.rating,
    required this.isActive,
  });
}