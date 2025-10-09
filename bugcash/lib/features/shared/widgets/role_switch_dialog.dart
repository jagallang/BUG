import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// v2.80.2: 역할 전환 다이얼로그 (간소화)
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
      await ref.read(authProvider.notifier).switchRole(targetRole);

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${_getRoleDisplayName(targetRole)} 모드로 전환되었습니다.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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
