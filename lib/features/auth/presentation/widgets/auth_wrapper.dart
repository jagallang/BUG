import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mock_auth_provider.dart';
import '../../domain/entities/user_entity.dart';
import '../pages/login_page.dart';
import '../../../tester_dashboard/presentation/pages/tester_dashboard_page.dart';
import '../../../provider_dashboard/presentation/pages/provider_dashboard_page.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(mockAuthProvider);

    // 디버깅을 위한 로그
    print('AuthWrapper - authState.isLoading: ${authState.isLoading}');
    print('AuthWrapper - authState.currentUser: ${authState.currentUser?.email}');
    print('AuthWrapper - authState.userData: ${authState.userData?.email}');

    if (authState.isLoading) {
      print('AuthWrapper - Showing loading...');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authState.currentUser == null || authState.userData == null) {
      print('AuthWrapper - Showing login page (user: ${authState.currentUser}, userData: ${authState.userData})');
      return const LoginPage();
    }

    final userData = authState.userData!;
    print('AuthWrapper - Navigating to dashboard for ${userData.userType}');

    switch (userData.userType) {
      case UserType.tester:
        return TesterDashboardPage(testerId: userData.uid);
      case UserType.provider:
        return ProviderDashboardPage(providerId: userData.uid);
    }
  }
}

class _UserDataMissingPage extends ConsumerWidget {
  const _UserDataMissingPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              '사용자 정보를 찾을 수 없습니다',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '계정 설정을 다시 완료해주세요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await ref.read(mockAuthProvider.notifier).signOut();
              },
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}