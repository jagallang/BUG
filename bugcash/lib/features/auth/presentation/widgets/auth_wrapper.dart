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
import '../../../mission/presentation/providers/mission_providers.dart';

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

    // v2.13.5: ref.listen으로 상태 변경 시에만 실행 (중복 호출 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AuthState>(authProvider, (previous, current) {
        if (previous?.user?.uid != current.user?.uid) {
          _handleAuthStateChange(current.user);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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
        // v2.13.4: 실시간 동기화 비활성화 (Firestore 400 에러 방지)
        // RealtimeSyncService.startRealtimeSync();
        AppLogger.info('User logged in: ${currentUser.email} - RealtimeSyncService disabled (v2.13.4)', 'AuthWrapper');

        // 로그인 후 기존 데이터 강제 동기화 (수동 동기화만 사용)
        Future.delayed(const Duration(seconds: 3), () {
          AppLogger.info('Force syncing all mission_workflows after login', 'AuthWrapper');
          RealtimeSyncService.forceSyncAll();
        });
      } else {
        // v2.14.0: 로그아웃 시 - 모든 폴링 중지
        AppLogger.info('🔴 User logged out - Stopping all services', 'AuthWrapper');

        // RealtimeSyncService 중지
        RealtimeSyncService.stopRealtimeSync();

        // v2.14.0: MissionStateNotifier 폴링 중지
        try {
          ref.read(missionStateNotifierProvider.notifier).stopPolling();
          AppLogger.info('✅ MissionStateNotifier polling stopped', 'AuthWrapper');
        } catch (e) {
          AppLogger.warning('⚠️ Failed to stop MissionStateNotifier: $e', 'AuthWrapper');
        }
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

