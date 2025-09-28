import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/user_entity.dart';
import '../pages/login_page.dart';
import '../../../tester_dashboard/presentation/pages/tester_dashboard_page.dart';
import '../../../provider_dashboard/presentation/pages/provider_dashboard_page.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';
import '../pages/role_selection_page.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();

    // 상태 변화 리스너 추가
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AuthState>(authProvider, (previous, next) {
        if (kDebugMode) {
          debugPrint('🔔 AuthWrapper - State changed: ${previous?.user?.email} → ${next.user?.email}');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
      debugPrint('AuthWrapper - User roles: ${userData.roles}');
      debugPrint('AuthWrapper - Primary role: ${userData.primaryRole}');
      debugPrint('AuthWrapper - Can switch roles: ${userData.canSwitchRoles}');
    }

    // 다중 역할 사용자는 역할 선택 화면으로 이동
    if (userData.canSwitchRoles) {
      if (kDebugMode) {
        debugPrint('AuthWrapper - Showing role selection for multi-role user');
      }
      return RoleSelectionPage(userData: userData);
    }

    // 단일 역할 사용자는 기본 역할로 대시보드 이동
    return _navigateToDashboard(userData, userData.primaryRole);
  }

  Widget _navigateToDashboard(UserEntity userData, UserType role) {
    switch (role) {
      case UserType.tester:
        return TesterDashboardPage(testerId: userData.uid);
      case UserType.provider:
        return ProviderDashboardPage(providerId: userData.uid);
      case UserType.admin:
        return const AdminDashboardPage();
    }
  }
}

