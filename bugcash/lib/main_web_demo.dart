import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'shared/theme/app_theme.dart';
import 'features/auth/domain/entities/user_entity.dart';

void main() {
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
        return BlocProvider(
          create: (_) => MockAuthBloc(),
          child: MaterialApp(
            title: 'BugCash - Web Demo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const HomePage(),
          ),
        );
      },
    );
  }
}

// Mock Auth Bloc for web demo
class MockAuthBloc extends Cubit<MockAuthState> {
  MockAuthBloc() : super(MockAuthState(
    user: UserEntity(
      uid: 'demo-user',
      email: 'demo@bugcash.com',
      displayName: '데모 사용자',
      photoUrl: null,
      points: 75000,
      level: 3,
      completedMissions: 12,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userType: UserType.tester,
      country: 'KR',
      timezone: 'Asia/Seoul',
    ),
  ));
}

class MockAuthState {
  final UserEntity user;
  MockAuthState({required this.user});
}

// Simple demo pages
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const MissionListView(),
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
                _buildNavItem(
                  icon: Icons.bug_report,
                  label: '미션',
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _buildNavItem(
                  icon: Icons.account_balance_wallet,
                  label: '지갑',
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _buildNavItem(
                  icon: Icons.person,
                  label: '프로필',
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24.w,
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple Mission List View
class MissionListView extends StatelessWidget {
  const MissionListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('미션 목록'),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'BugCash 미션 목록',
          style: TextStyle(fontSize: 20.sp),
        ),
      ),
    );
  }
}

// Simple Wallet View
class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지갑'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 80.w, color: Theme.of(context).colorScheme.primary),
            SizedBox(height: 20.h),
            Text(
              '75,000 포인트',
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple Profile View
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 80.w, color: Theme.of(context).colorScheme.primary),
            SizedBox(height: 20.h),
            Text(
              '데모 사용자',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.h),
            Text(
              'demo@bugcash.com',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}