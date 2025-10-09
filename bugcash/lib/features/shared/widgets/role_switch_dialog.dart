import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../tester_dashboard/presentation/pages/tester_dashboard_page.dart';
import '../../provider_dashboard/presentation/pages/provider_dashboard_page.dart';

/// v2.80.3: 역할 전환 다이얼로그 (자동 화면 전환 추가)
class RoleSwitchDialog extends ConsumerWidget {
  final UserEntity user;
  final UserType targetRole;

  const RoleSwitchDialog({
    super.key,
    required this.user,
    required this.targetRole,
  });

  String _getRoleDisplayName(UserType role) {
    switch (role) {
      case UserType.tester:
        return '테스터';
      case UserType.provider:
        return '공급자';
      case UserType.admin:
        return '관리자';
    }
  }

  Future<void> _handleSwitchRole(BuildContext context, WidgetRef ref) async {
    try {
      // 역할 전환
      await ref.read(authProvider.notifier).switchRole(targetRole);

      if (context.mounted) {
        // 다이얼로그 닫기
        Navigator.of(context).pop();

        // v2.80.3: 대시보드로 자동 이동
        Widget targetPage;
        switch (targetRole) {
          case UserType.tester:
            targetPage = TesterDashboardPage(testerId: user.uid);
            break;
          case UserType.provider:
            targetPage = ProviderDashboardPage(providerId: user.uid);
            break;
          case UserType.admin:
            // 관리자 전환은 현재 지원하지 않음
            return;
        }

        // 현재 화면을 대체하여 뒤로가기 방지
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => targetPage),
        );

        // 스넥바는 새 화면에서 표시
        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${_getRoleDisplayName(targetRole)} 모드로 전환되었습니다.'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 역할 전환 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.swap_horiz, color: Colors.blue),
          SizedBox(width: 12.w),
          const Text('역할 전환'),
        ],
      ),
      content: Text(
        '${_getRoleDisplayName(targetRole)}로 전환하시겠습니까?',
        style: TextStyle(fontSize: 16.sp),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => _handleSwitchRole(context, ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('전환'),
        ),
      ],
    );
  }
}
