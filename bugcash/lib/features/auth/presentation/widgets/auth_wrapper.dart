import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/user_entity.dart';
import '../pages/login_page.dart';
import '../../../tester_dashboard/presentation/pages/tester_dashboard_page.dart';
import '../../../provider_dashboard/presentation/pages/provider_dashboard_page.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';
import '../pages/role_selection_page.dart';
import '../../../../core/services/realtime_sync_service.dart';
import '../../../../core/utils/logger.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  UserEntity? _previousUser;

  @override
  void initState() {
    super.initState();
    // Riverpod 상태 관리는 build 메서드에서 처리
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // 🔥 인증 상태 변경에 따른 실시간 동기화 제어
    _handleAuthStateChange(authState.user);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authState.user == null) {
      return const LoginPage();
    }

    final userData = authState.user!;

    // 다중 역할 사용자는 역할 선택 화면으로 이동
    if (userData.canSwitchRoles) {
      return RoleSelectionPage(userData: userData);
    }

    // v2.13.2: 단일 역할 사용자 안전성 검증
    // primaryRole이 roles에 포함되지 않는 경우 roles.first 사용
    final safeRole = userData.roles.contains(userData.primaryRole)
        ? userData.primaryRole
        : userData.roles.first;

    if (safeRole != userData.primaryRole) {
      AppLogger.warning(
        '⚠️ [AuthWrapper] primaryRole mismatch detected!\n'
        '   ├─ primaryRole: ${userData.primaryRole.name}\n'
        '   ├─ roles: ${userData.roles.map((r) => r.name).toList()}\n'
        '   └─ Using safeRole: ${safeRole.name}',
        'AuthWrapper'
      );
    }

    // 단일 역할 사용자는 기본 역할로 대시보드 이동
    return _navigateToDashboard(userData, safeRole);
  }

  /// 인증 상태 변경에 따른 실시간 동기화 제어
  void _handleAuthStateChange(UserEntity? currentUser) {
    // 사용자 상태가 변경된 경우에만 처리
    if (_previousUser?.uid != currentUser?.uid) {
      if (currentUser != null) {
        // 로그인 시: 실시간 동기화 시작
        AppLogger.info('User logged in: ${currentUser.email} - Starting RealtimeSyncService', 'AuthWrapper');
        RealtimeSyncService.startRealtimeSync();

        // 로그인 후 기존 데이터 강제 동기화 (3초 지연 후 실행)
        Future.delayed(const Duration(seconds: 3), () {
          AppLogger.info('Force syncing all mission_workflows after login', 'AuthWrapper');
          RealtimeSyncService.forceSyncAll();
        });
      } else {
        // 로그아웃 시: 실시간 동기화 중지
        AppLogger.info('User logged out - Stopping RealtimeSyncService', 'AuthWrapper');
        RealtimeSyncService.stopRealtimeSync();
      }

      _previousUser = currentUser;
    }
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

