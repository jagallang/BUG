import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'core/utils/logger.dart';
import 'core/config/app_config.dart';
import 'features/home/presentation/pages/home_page.dart';

// 웹용 반응형 크기 헬퍼 - 깔끔한 크기로 조정
extension ResponsiveText on num {
  double get rsp => kIsWeb ? (this * 1.1).toDouble() : sp;
  double get rw => kIsWeb ? (this * 0.9).w : w;
  double get rh => kIsWeb ? (this * 0.9).h : h;
  double get rr => kIsWeb ? (this * 0.9).r : r;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 앱 설정 초기화
  await AppConfig.initialize();
  
  bool isFirebaseAvailable = false;
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseAvailable = true;
    AppLogger.info('Firebase initialized successfully', 'Main');
    
    // 데모 데이터 초기화 (디버그 모드에서만)
    if (kDebugMode) {
      try {
        await FirebaseService.initializeDemoData().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            AppLogger.warning('Demo data initialization timed out', 'Main');
          },
        );
      } catch (demoError) {
        AppLogger.error('Demo data initialization failed', 'Main', demoError);
      }
    }
  } catch (e) {
    AppLogger.error('Firebase initialization failed', 'Main', e);
    AppLogger.info('Running in offline mode with fallback data', 'Main');
  }
  
  runApp(BugCashWebApp(isFirebaseAvailable: isFirebaseAvailable));
}

class BugCashWebApp extends StatelessWidget {
  final bool isFirebaseAvailable;
  
  const BugCashWebApp({super.key, required this.isFirebaseAvailable});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: kIsWeb ? const Size(800, 600) : const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'BugCash - 웹 앱 테스트 플랫폼',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.teal,
            primaryColor: const Color(0xFF00BFA5),
            fontFamily: GoogleFonts.roboto().fontFamily,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00BFA5),
              brightness: Brightness.light,
            ).copyWith(
              primary: const Color(0xFF00BFA5),
              secondary: const Color(0xFF4EDBC5),
            ),
            useMaterial3: true,
          ),
          home: BugCashHomePage(isFirebaseAvailable: isFirebaseAvailable),
        );
      },
    );
  }
}

class BugCashHomePage extends StatefulWidget {
  final bool isFirebaseAvailable;
  
  const BugCashHomePage({super.key, required this.isFirebaseAvailable});

  @override
  State<BugCashHomePage> createState() => _BugCashHomePageState();
}

class _BugCashHomePageState extends State<BugCashHomePage> {
  int _selectedIndex = 0;
  
  late final List<Widget> _pages = [
    MissionPage(isFirebaseAvailable: widget.isFirebaseAvailable),
    const SearchPage(),
    const RankingPage(),
    const WalletPage(),
    const ProfilePage(),
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.rw, vertical: 8.rh),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF00BFA5).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? const Color(0xFF00BFA5)
                  : const Color(0xFF757575),
              size: 24.rsp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? const Color(0xFF00BFA5)
                    : const Color(0xFF757575),
                fontSize: 12.rsp,
                fontWeight: isSelected 
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 각 페이지들 - 파스텔톤 컬러로 구성
class MissionPage extends StatefulWidget {
  final bool isFirebaseAvailable;
  
  const MissionPage({super.key, required this.isFirebaseAvailable});

  @override
  State<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends State<MissionPage> {
  List<Map<String, dynamic>> missions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    List<Map<String, dynamic>> loadedMissions;
    
    if (widget.isFirebaseAvailable) {
      loadedMissions = await FirebaseService.getMissions();
    } else {
      // 오프라인 모드 - 더미 데이터 제공
      loadedMissions = _getFallbackMissions();
    }
    
    if (mounted) {
      setState(() {
        missions = loadedMissions;
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFallbackMissions() {
    return [
      {
        'id': 'offline_1',
        'title': '인스타그램 클론 앱 테스트',
        'reward': 5000,
        'deadline': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        'participantCount': 8,
        'maxParticipants': 15,
      },
      {
        'id': 'offline_2',
        'title': '배달앱 주문 플로우 테스트',
        'reward': 3000,
        'deadline': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'participantCount': 12,
        'maxParticipants': 20,
      },
      {
        'id': 'offline_3',
        'title': '온라인 쇼핑몰 결제 테스트',
        'reward': 7000,
        'deadline': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'participantCount': 5,
        'maxParticipants': 10,
      },
    ];
  }

  String _formatDate(dynamic date) {
    if (date == null) return '날짜 미정';
    
    try {
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else {
        dateTime = DateTime.parse(date.toString());
      }
      return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '날짜 미정';
    }
  }

  double _calculateProgress(Map<String, dynamic> mission) {
    final participants = mission['participantCount'] ?? 0;
    final maxParticipants = mission['maxParticipants'] ?? 1;
    return (participants / maxParticipants).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('🎯 미션'),
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF00BFA5).withOpacity(0.1),
                    const Color(0xFF4EDBC5).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.bug_report,
                    size: 64.rsp,
                    color: const Color(0xFF00BFA5),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    '미션 센터',
                    style: TextStyle(
                      fontSize: 24.rsp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00BFA5),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    '다양한 앱 테스트 미션에 참여하여 리워드를 획득하세요',
                    style: TextStyle(
                      fontSize: 16.rsp,
                      color: const Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              '📱 진행 중인 미션',
              style: TextStyle(
                fontSize: 20.rsp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 16.h),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                ),
              )
            else if (missions.isEmpty)
              Center(
                child: Text(
                  '미션이 없습니다',
                  style: TextStyle(
                    fontSize: 16.rsp,
                    color: const Color(0xFF757575),
                  ),
                ),
              )
            else
              ...missions.asMap().entries.map((entry) {
                final index = entry.key;
                final mission = entry.value;
                final colors = [
                  const Color(0xFFFFE4E1),
                  const Color(0xFFE6F3FF),
                  const Color(0xFFF0FFF0),
                  const Color(0xFFFFF8DC),
                ];
                
                return _MissionCard(
                  title: mission['title'] ?? 'Unknown Mission',
                  reward: '${mission['reward'] ?? 0} 포인트',
                  deadline: _formatDate(mission['deadline']),
                  progress: _calculateProgress(mission),
                  color: colors[index % colors.length],
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final String title;
  final String reward;
  final String deadline;
  final double progress;
  final Color color;

  const _MissionCard({
    required this.title,
    required this.reward,
    required this.deadline,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                title,
                style: TextStyle(
                  fontSize: 16.rsp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              Text(
                reward,
                style: TextStyle(
                  fontSize: 14.rsp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF00BFA5),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '마감: $deadline',
            style: TextStyle(
              fontSize: 12.rsp,
              color: const Color(0xFF757575),
            ),
          ),
          SizedBox(height: 12.h),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.5),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
          ),
          SizedBox(height: 8.h),
          Text(
            '진행률: ${(progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12.rsp,
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('🔍 검색'),
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF757575)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '미션을 검색하세요',
                        hintStyle: TextStyle(
                          fontSize: 16.rsp,
                          color: const Color(0xFF757575),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 64.rsp,
                      color: const Color(0xFF00BFA5),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      '미션 검색',
                      style: TextStyle(
                        fontSize: 24.rsp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00BFA5),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      '원하는 조건의 미션을 검색하고 신청하세요',
                      style: TextStyle(
                        fontSize: 16.rsp,
                        color: const Color(0xFF757575),
                      ),
                      textAlign: TextAlign.center,
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

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('🏆 랭킹'),
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard,
              size: 64.rsp,
              color: const Color(0xFF00BFA5),
            ),
            SizedBox(height: 20.h),
            Text(
              '테스터 랭킹',
              style: TextStyle(
                fontSize: 24.rsp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00BFA5),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              '다른 테스터들과 실력을 겨뤄보세요',
              style: TextStyle(
                fontSize: 16.rsp,
                color: const Color(0xFF757575),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('💰 지갑'),
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFD700),
                    Color(0xFFFFF8DC),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 48.rsp,
                    color: const Color(0xFF333333),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '내 포인트',
                    style: TextStyle(
                      fontSize: 16.rsp,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '15,500 P',
                    style: TextStyle(
                      fontSize: 32.rsp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BFA5),
                        padding: EdgeInsets.symmetric(
                          horizontal: 32.w,
                          vertical: 16.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        '출금하기',
                        style: TextStyle(
                          fontSize: 16.rsp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('👤 프로필'),
        backgroundColor: const Color(0xFF00BFA5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _showProviderManagement(context);
            },
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 20.rsp,
              ),
            ),
            tooltip: '앱 공급자 관리',
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50.r,
              backgroundColor: const Color(0xFF00BFA5),
              child: Icon(
                Icons.person,
                size: 50.rsp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              '데모 사용자',
              style: TextStyle(
                fontSize: 24.rsp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'GOLD 테스터',
                style: TextStyle(
                  fontSize: 14.rsp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB8860B),
                ),
              ),
            ),
            SizedBox(height: 40.h),
            Text(
              '우상단 관리자 아이콘을 클릭해보세요!',
              style: TextStyle(
                fontSize: 16.rsp,
                color: const Color(0xFF00BFA5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProviderManagement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.all(20.w),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉 앱 공급자 관리',
              style: TextStyle(
                fontSize: 20.rsp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00BFA5),
              ),
            ),
            SizedBox(height: 20.h),
            const _ManagementItem(
              icon: Icons.assignment,
              title: '미션 생성 및 관리',
            ),
            const _ManagementItem(
              icon: Icons.monitor_heart,
              title: '테스터 현황 모니터링',
            ),
            const _ManagementItem(
              icon: Icons.bug_report,
              title: '버그 리포트 확인',
            ),
            const _ManagementItem(
              icon: Icons.analytics,
              title: '통계 및 분석',
            ),
            const _ManagementItem(
              icon: Icons.payments,
              title: '리워드 지급 관리',
            ),
            SizedBox(height: 20.h),
            Text(
              '완전한 관리 대시보드를 제공합니다!',
              style: TextStyle(
                fontSize: 14.rsp,
                color: const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ManagementItem({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF00BFA5),
            size: 20.rsp,
          ),
          SizedBox(width: 12.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.rsp,
              color: const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}