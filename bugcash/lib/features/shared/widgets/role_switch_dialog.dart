import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// v2.80.0: 역할 전환 다이얼로그
class RoleSwitchDialog extends ConsumerStatefulWidget {
  final UserEntity user;

  const RoleSwitchDialog({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<RoleSwitchDialog> createState() => _RoleSwitchDialogState();
}

class _RoleSwitchDialogState extends ConsumerState<RoleSwitchDialog> {
  UserType? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.primaryRole;
  }

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

  IconData _getRoleIcon(UserType role) {
    switch (role) {
      case UserType.tester:
        return Icons.bug_report;
      case UserType.provider:
        return Icons.business;
      case UserType.admin:
        return Icons.admin_panel_settings;
    }
  }

  Color _getRoleColor(UserType role) {
    switch (role) {
      case UserType.tester:
        return Colors.orange;
      case UserType.provider:
        return Colors.blue;
      case UserType.admin:
        return Colors.purple;
    }
  }

  Future<void> _handleSwitchRole() async {
    if (_selectedRole == null || _selectedRole == widget.user.primaryRole) {
      Navigator.of(context).pop();
      return;
    }

    try {
      await ref.read(authProvider.notifier).switchRole(_selectedRole!);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${_getRoleDisplayName(_selectedRole!)} 모드로 전환되었습니다.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.swap_horiz, color: Colors.blue),
          SizedBox(width: 12.w),
          const Text('역할 전환'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 역할: ${_getRoleDisplayName(widget.user.primaryRole)}',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            '전환할 역할을 선택하세요:',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          ...widget.user.roles.map((role) => RadioListTile<UserType>(
                value: role,
                groupValue: _selectedRole,
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
                title: Row(
                  children: [
                    Icon(
                      _getRoleIcon(role),
                      color: _getRoleColor(role),
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(_getRoleDisplayName(role)),
                  ],
                ),
                activeColor: _getRoleColor(role),
              )),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20.sp, color: Colors.blue[700]),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '역할 전환 시 해당 역할의 대시보드로 자동 이동됩니다.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _selectedRole == widget.user.primaryRole ? null : _handleSwitchRole,
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
