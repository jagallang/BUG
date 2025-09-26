import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/user_entity.dart';
import '../pages/login_page.dart';
import '../../../tester_dashboard/presentation/pages/tester_dashboard_page.dart';
import '../../../provider_dashboard/presentation/pages/provider_dashboard_page.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';

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
        return const AdminDashboardPage();
    }
  }
}

