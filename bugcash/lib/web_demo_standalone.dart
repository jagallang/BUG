// Entry point for testing the new modular demo structure
import 'demo/main.dart' as demo;

void main() {
  demo.main();
}
  const BugCashWebDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'BugCash - 웹 데모',
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
          home: const BugCashHomePage(),
        );
      },
    );
  }
}

class BugCashHomePage extends StatefulWidget {
  const BugCashHomePage({super.key});

  @override
  State<BugCashHomePage> createState() => _BugCashHomePageState();
}

class _BugCashHomePageState extends State<BugCashHomePage> {
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF00BFA5).withValues(alpha: 0.1)
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
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? const Color(0xFF00BFA5)
                    : const Color(0xFF757575),
                fontSize: 12.sp,
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

class MissionListView extends StatelessWidget {
  const MissionListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('미션'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bug_report,
              size: 64.sp,
              color: const Color(0xFF00BFA5),
            ),
            SizedBox(height: 20.h),
            Text(
              '미션 탭',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              '앱 테스트 미션들이 표시됩니다',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MissionSearchView extends StatelessWidget {
  const MissionSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('검색'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64.sp,
              color: const Color(0xFF00BFA5),
            ),
            SizedBox(height: 20.h),
            Text(
              '검색 탭',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              '미션을 검색하고 신청할 수 있습니다',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RankingView extends StatelessWidget {
  const RankingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('랭킹'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard,
              size: 64.sp,
              color: const Color(0xFF00BFA5),
            ),
            SizedBox(height: 20.h),
            Text(
              '랭킹 탭',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              '사용자 랭킹을 확인할 수 있습니다',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF757575),
              ),
            ),
          ],
        ),
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
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64.sp,
              color: const Color(0xFF00BFA5),
            ),
            SizedBox(height: 20.h),
            Text(
              '지갑 탭',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              '포인트와 출금 내역을 확인할 수 있습니다',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF757575),
              ),
            ),
          ],
        ),
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
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('앱 공급자 관리 기능'),
                  backgroundColor: Color(0xFF00BFA5),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40.r,
              backgroundColor: const Color(0xFF00BFA5),
              child: Icon(
                Icons.person,
                size: 40.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              '데모 사용자',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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
            SizedBox(height: 30.h),
            Text(
              '우상단 관리자 아이콘을 클릭해보세요!',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF00BFA5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}