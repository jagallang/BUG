import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/role_selection_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사용자 정보 섹션
            _buildUserInfoSection(user),
            SizedBox(height: 24.h),

            // 역할 관리 섹션
            _buildRoleManagementSection(user),
            SizedBox(height: 24.h),

            // 프로필 관리 섹션
            _buildProfileManagementSection(user),
            SizedBox(height: 24.h),

            // 기타 설정 섹션
            _buildOtherSettingsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(UserEntity user) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '계정 정보',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              CircleAvatar(
                radius: 30.r,
                backgroundColor: Colors.blue[100],
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Icon(Icons.person, size: 30.sp, color: Colors.blue[600])
                    : null,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '가입일: ${_formatDate(user.createdAt)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleManagementSection(UserEntity user) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree, color: Colors.blue[600]),
              SizedBox(width: 8.w),
              Text(
                '역할 관리',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // 현재 역할 표시
          Text(
            '현재 역할',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            children: user.roles.map((role) {
              final isMain = role == user.primaryRole;
              return Chip(
                label: Text(
                  _getRoleName(role),
                  style: TextStyle(
                    color: isMain ? Colors.white : Colors.blue[800],
                    fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                backgroundColor: isMain ? Colors.blue[600] : Colors.blue[100],
                side: BorderSide(
                  color: isMain ? Colors.blue[600]! : Colors.blue[300]!,
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 16.h),

          // 역할 전환 버튼
          if (user.canSwitchRoles)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _switchRole(user),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('역할 전환'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),

          // 역할 추가 버튼
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => _addRole(user),
              icon: const Icon(Icons.add),
              label: const Text('역할 추가'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileManagementSection(UserEntity user) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: Colors.green[600]),
              SizedBox(width: 8.w),
              Text(
                '프로필 관리',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // 테스터 프로필
          if (user.isTester)
            ListTile(
              leading: Icon(Icons.bug_report, color: Colors.green[600]),
              title: const Text('테스터 프로필'),
              subtitle: Text(
                user.hasTesterProfile
                    ? '설정 완료 (${user.testerProfile?.completedTests ?? 0}회 테스트)'
                    : '프로필을 설정해주세요',
                style: TextStyle(
                  color: user.hasTesterProfile ? Colors.green[600] : Colors.orange[600],
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _manageTesterProfile(user),
            ),

          // 공급자 프로필
          if (user.isProvider)
            ListTile(
              leading: Icon(Icons.upload, color: Colors.blue[600]),
              title: const Text('공급자 프로필'),
              subtitle: Text(
                user.hasProviderProfile
                    ? '설정 완료 (${user.providerProfile?.publishedApps ?? 0}개 앱)'
                    : '프로필을 설정해주세요',
                style: TextStyle(
                  color: user.hasProviderProfile ? Colors.green[600] : Colors.orange[600],
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _manageProviderProfile(user),
            ),
        ],
      ),
    );
  }

  Widget _buildOtherSettingsSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.grey[600]),
              SizedBox(width: 8.w),
              Text(
                '기타 설정',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // 알림 설정 페이지로 이동
            },
          ),

          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('도움말'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // 도움말 페이지로 이동
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(),
          ),
        ],
      ),
    );
  }

  String _getRoleName(UserType role) {
    switch (role) {
      case UserType.tester:
        return '앱 테스터';
      case UserType.provider:
        return '앱 공급자';
      case UserType.admin:
        return '관리자';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  void _switchRole(UserEntity user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => RoleSelectionPage(userData: user),
      ),
    );
  }

  void _addRole(UserEntity user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('역할 추가'),
        content: const Text('추가할 역할을 선택해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          if (!user.isTester)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addUserRole(user, UserType.tester);
              },
              child: const Text('앱 테스터'),
            ),
          if (!user.isProvider)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addUserRole(user, UserType.provider);
              },
              child: const Text('앱 공급자'),
            ),
        ],
      ),
    );
  }

  void _addUserRole(UserEntity user, UserType newRole) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedRoles = [...user.roles, newRole];

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'roles': updatedRoles.map((role) => role.name).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getRoleName(newRole)} 역할이 추가되었습니다'),
            backgroundColor: Colors.green,
          ),
        );

        // 인증 상태 새로고침 (페이지 새로고침)
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('역할 추가 실패: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _manageTesterProfile(UserEntity user) {
    // 테스터 프로필 관리 페이지로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('테스터 프로필 관리 기능은 곧 추가될 예정입니다')),
    );
  }

  void _manageProviderProfile(UserEntity user) {
    // 공급자 프로필 관리 페이지로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('공급자 프로필 관리 기능은 곧 추가될 예정입니다')),
    );
  }

  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }
}