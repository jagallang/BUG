import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/user_entity.dart';
import '../pages/login_page.dart';
import '../../../tester_dashboard/presentation/pages/tester_dashboard_page.dart';
import '../../../provider_dashboard/presentation/pages/provider_dashboard_page.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // 디버깅을 위한 로그 (프로덕션에서는 제거)
    if (kDebugMode) {
      debugPrint('AuthWrapper - authState.isLoading: ${authState.isLoading}');
      debugPrint('AuthWrapper - authState.user: ${authState.user?.email}');
    }

    if (authState.isLoading) {
      debugPrint('AuthWrapper - Showing loading...');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authState.user == null) {
      if (kDebugMode) {
        debugPrint('AuthWrapper - Showing login page (user is null)');
      }
      return const LoginPage();
    }

    final userData = authState.user!;
    if (kDebugMode) {
      debugPrint('AuthWrapper - Navigating to dashboard for ${userData.userType}');
    }

    switch (userData.userType) {
      case UserType.tester:
        return TesterDashboardPage(testerId: userData.uid);
      case UserType.provider:
        return ProviderDashboardPage(providerId: userData.uid);
      case UserType.admin:
        // Admin Dashboard 구현 예정
        return Scaffold(
          appBar: AppBar(
            title: const Text('Provider Dashboard'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.construction, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  'Provider Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '현재 수정 중입니다.\n테스터 계정으로 로그인하여 테스트해주세요.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('로그아웃'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}


// Unused widget - commented out for now
// class _UserDataMissingPage extends ConsumerWidget {
//   const _UserDataMissingPage();
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.person_off,
//               size: 64,
//               color: Colors.orange,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               '사용자 정보를 찾을 수 없습니다',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               '계정 설정을 다시 완료해주세요.',
//               textAlign: TextAlign.center,
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 color: Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: () async {
//                 await ref.read(mockAuthProvider.notifier).signOut();
//               },
//               child: const Text('로그아웃'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }