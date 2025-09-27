import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../../tester_dashboard/presentation/pages/tester_dashboard_page.dart';
import '../../../provider_dashboard/presentation/pages/provider_dashboard_page.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';

class RoleSelectionPage extends ConsumerStatefulWidget {
  final UserEntity userData;

  const RoleSelectionPage({
    super.key,
    required this.userData,
  });

  @override
  ConsumerState<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends ConsumerState<RoleSelectionPage> {
  UserType? selectedRole;

  @override
  void initState() {
    super.initState();
    selectedRole = widget.userData.primaryRole;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('역할 선택'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 사용자 정보 표시
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: widget.userData.photoUrl != null
                            ? NetworkImage(widget.userData.photoUrl!)
                            : null,
                        child: widget.userData.photoUrl == null
                            ? Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.blue.shade600,
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.userData.displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        widget.userData.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 역할 선택 제목
              Text(
                '어떤 역할로 접속하시겠습니까?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // 역할 선택 카드들
              ...widget.userData.availableRoles.map((role) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildRoleCard(role),
                );
              }).toList(),

              const SizedBox(height: 32),

              // 확인 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: selectedRole != null ? _navigateToSelectedRole : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '${_getRoleName(selectedRole!)} 대시보드로 이동',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 역할 전환 안내
              Text(
                '※ 언제든지 설정에서 역할을 변경할 수 있습니다',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(UserType role) {
    final isSelected = selectedRole == role;
    final roleInfo = _getRoleInfo(role);

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedRole = role;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 역할 아이콘
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: roleInfo['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  roleInfo['icon'],
                  color: roleInfo['color'],
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // 역할 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roleInfo['name'],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Theme.of(context).primaryColor : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roleInfo['description'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),

              // 선택 표시
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getRoleInfo(UserType role) {
    switch (role) {
      case UserType.tester:
        return {
          'name': '앱 테스터',
          'description': '앱을 테스트하고 버그를 신고하여 포인트를 획득하세요',
          'icon': Icons.bug_report,
          'color': Colors.green,
        };
      case UserType.provider:
        return {
          'name': '앱 공급자',
          'description': '앱을 등록하고 테스터들로부터 피드백을 받으세요',
          'icon': Icons.upload,
          'color': Colors.blue,
        };
      case UserType.admin:
        return {
          'name': '관리자',
          'description': '플랫폼을 관리하고 사용자들을 도와주세요',
          'icon': Icons.admin_panel_settings,
          'color': Colors.purple,
        };
    }
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

  void _navigateToSelectedRole() {
    if (selectedRole == null) return;

    Widget targetPage;
    switch (selectedRole!) {
      case UserType.tester:
        targetPage = TesterDashboardPage(testerId: widget.userData.uid);
        break;
      case UserType.provider:
        targetPage = ProviderDashboardPage(providerId: widget.userData.uid);
        break;
      case UserType.admin:
        targetPage = const AdminDashboardPage();
        break;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => targetPage),
    );
  }
}