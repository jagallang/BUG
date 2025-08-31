import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'shared/theme/app_theme.dart';
import 'features/auth/domain/entities/user_entity.dart';
import 'features/mission/presentation/pages/home_page.dart';

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
    user: const UserEntity(
      uid: 'demo-user',
      email: 'demo@bugcash.com',
      displayName: '데모 사용자',
      photoUrl: null,
      points: 75000,
      level: 'gold',
      completedMissions: 12,
      createdAt: null,
    ),
  ));
}

class MockAuthState {
  final UserEntity user;
  MockAuthState({required this.user});
}

// Update HomePage to work with mock auth
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
              color: Colors.black.withOpacity(0.05),
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
                  icon: Icons.account_balance_wallet,
                  label: '지갑',
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _NavItem(
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
}