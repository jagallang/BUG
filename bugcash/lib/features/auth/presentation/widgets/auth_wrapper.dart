import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mock_auth_provider.dart';
import '../../domain/entities/user_entity.dart';
import '../pages/login_page.dart';
import '../../../tester_dashboard/presentation/pages/tester_dashboard_page.dart';

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
      
      // 개발 모드일 때만 바이패스 옵션 표시
      if (kDebugMode) {
        return const _DevBypassPage();
      }
      
      return const LoginPage();
    }

    final userData = authState.userData!;
    print('AuthWrapper - Navigating to dashboard for ${userData.userType}');

    switch (userData.userType) {
      case UserType.tester:
        return TesterDashboardPage(testerId: userData.uid);
      case UserType.provider:
        // Provider Dashboard 임시 비활성화 - 파일 수정 후 활성화 예정
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
                    await ref.read(mockAuthProvider.notifier).signOut();
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

class _DevBypassPage extends ConsumerWidget {
  const _DevBypassPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개발용 바이패스'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.developer_mode,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              '개발 모드 - 로그인 바이패스',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '테스트용으로 로그인 없이 앱에 접속할 수 있습니다.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            
            // Provider 대시보드 접속
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(mockAuthProvider.notifier).signInWithEmailAndPassword(
                  email: 'admin@techcorp.com',
                  password: 'admin123',
                );
              },
              icon: const Icon(Icons.business),
              label: const Text('공급자/관리자 대시보드 접속'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tester 대시보드 접속
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(mockAuthProvider.notifier).signInWithEmailAndPassword(
                  email: 'tester1@gmail.com',
                  password: 'tester123',
                );
              },
              icon: const Icon(Icons.person),
              label: const Text('테스터 대시보드 접속'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // 정상 로그인 페이지로 이동
            TextButton.icon(
              onPressed: () {
                // LoginPage로 이동하는 방법으로 구현
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('정상 로그인 페이지로 이동'),
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow.shade600),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.yellow.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '개발 모드에서만 표시됩니다',
                      style: TextStyle(
                        color: Colors.yellow.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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