import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/navigation_provider.dart';
import '../../../mission/presentation/pages/mission_page.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../ranking/presentation/pages/ranking_page.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../widgets/nav_item.dart';

class BugCashHomePage extends ConsumerWidget {
  final bool isFirebaseAvailable;
  
  const BugCashHomePage({super.key, required this.isFirebaseAvailable});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabProvider);
    
    final pages = [
      MissionPage(isFirebaseAvailable: isFirebaseAvailable),
      const SearchPage(),
      const RankingPage(),
      const WalletPage(),
      const ProfilePage(),
    ];
    
    return Scaffold(
      body: pages[selectedIndex],
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
                NavItem(
                  icon: Icons.bug_report,
                  label: '미션',
                  isSelected: selectedIndex == 0,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 0,
                ),
                NavItem(
                  icon: Icons.search,
                  label: '검색',
                  isSelected: selectedIndex == 1,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
                ),
                NavItem(
                  icon: Icons.leaderboard,
                  label: '랭킹',
                  isSelected: selectedIndex == 2,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
                ),
                NavItem(
                  icon: Icons.account_balance_wallet,
                  label: '지갑',
                  isSelected: selectedIndex == 3,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
                ),
                NavItem(
                  icon: Icons.person,
                  label: '프로필',
                  isSelected: selectedIndex == 4,
                  onTap: () => ref.read(selectedTabProvider.notifier).state = 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}