import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';

class PlatformSettingsPage extends StatefulWidget {
  const PlatformSettingsPage({super.key});

  @override
  State<PlatformSettingsPage> createState() => _PlatformSettingsPageState();
}

class _PlatformSettingsPageState extends State<PlatformSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? _currentSettings;
  String _currentTab = 'rewards';

  // Cloud Functions 인스턴스
  final _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTab = _getTabType(_tabController.index);
          _loadSettings(_currentTab);
        });
      }
    });
    _loadSettings('rewards');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getTabType(int index) {
    switch (index) {
      case 0:
        return 'rewards';
      case 1:
        return 'withdrawal';
      case 2:
        return 'platform';
      case 3:
        return 'abuse_prevention';
      default:
        return 'rewards';
    }
  }

  Future<void> _loadSettings(String settingType) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final callable = _functions.httpsCallable('getPlatformSettings');
      final result = await callable.call({'settingType': settingType});

      setState(() {
        _currentSettings = Map<String, dynamic>.from(result.data);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('설정 로드 실패: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings(
      String settingType, Map<String, dynamic> updates, String reason) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final callable = _functions.httpsCallable('updatePlatformSettings');
      await callable.call({
        'settingType': settingType,
        'updates': updates,
        'reason': reason,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 설정이 저장되었습니다')),
        );
        await _loadSettings(settingType);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 저장 실패: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('플랫폼 설정 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '보상 설정'),
            Tab(text: '출금 설정'),
            Tab(text: '플랫폼 수수료'),
            Tab(text: '어뷰징 방지'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRewardsTab(),
                _buildWithdrawalTab(),
                _buildPlatformTab(),
                _buildAbusePreventionTab(),
              ],
            ),
    );
  }

  // 보상 설정 탭
  Widget _buildRewardsTab() {
    if (_currentSettings == null) return const SizedBox();

    final signupBonus = _currentSettings!['signupBonus'] ?? {};
    final projectBonus = _currentSettings!['projectCompletionBonus'] ?? {};
    final dailyMission = _currentSettings!['dailyMissionReward'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('🎁 회원가입 보너스'),
          _buildSwitchTile(
            '가입 보너스 활성화',
            signupBonus['enabled'] ?? true,
            (value) => _updateNestedField('signupBonus', 'enabled', value),
          ),
          _buildNumberField(
            '보너스 포인트',
            signupBonus['amount'] ?? 5000,
            (value) => _updateNestedField('signupBonus', 'amount', value),
          ),
          const Divider(height: 32),
          _buildSectionHeader('🏆 프로젝트 완료 보너스'),
          _buildSwitchTile(
            '완료 보너스 활성화',
            projectBonus['enabled'] ?? true,
            (value) =>
                _updateNestedField('projectCompletionBonus', 'enabled', value),
          ),
          _buildNumberField(
            '테스터 보너스 (P)',
            projectBonus['testerAmount'] ?? 1000,
            (value) =>
                _updateNestedField('projectCompletionBonus', 'testerAmount', value),
          ),
          _buildNumberField(
            '공급자 보너스 (P)',
            projectBonus['providerAmount'] ?? 1000,
            (value) => _updateNestedField(
                'projectCompletionBonus', 'providerAmount', value),
          ),
          if (projectBonus['conditions'] != null) ...[
            const SizedBox(height: 8),
            Text(
              '조건: 최소 ${projectBonus['conditions']['minDays'] ?? 14}일 프로젝트',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const Divider(height: 32),
          _buildSectionHeader('📅 일일 미션 보상'),
          _buildSwitchTile(
            '일일 미션 활성화',
            dailyMission['enabled'] ?? true,
            (value) => _updateNestedField('dailyMissionReward', 'enabled', value),
          ),
          _buildNumberField(
            '기본 보상 (P)',
            dailyMission['baseAmount'] ?? 50,
            (value) =>
                _updateNestedField('dailyMissionReward', 'baseAmount', value),
          ),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  // 출금 설정 탭
  Widget _buildWithdrawalTab() {
    if (_currentSettings == null) return const SizedBox();

    final minAmount = _currentSettings!['minAmount'] ?? 30000;
    final allowedUnits = _currentSettings!['allowedUnits'] ?? 10000;
    final feeRate = _currentSettings!['feeRate'] ?? 0.18;
    final autoApprove = _currentSettings!['autoApprove'] ?? false;
    final processingDays = _currentSettings!['processingDays'] ?? 5;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('💰 출금 기본 설정'),
          _buildNumberField(
            '최소 출금 금액 (P)',
            minAmount,
            (value) => _updateDirectField('minAmount', value),
          ),
          _buildNumberField(
            '출금 단위 (P)',
            allowedUnits,
            (value) => _updateDirectField('allowedUnits', value),
          ),
          _buildPercentageField(
            '출금 수수료 (%)',
            (feeRate * 100).toInt(),
            (value) => _updateDirectField('feeRate', value / 100),
          ),
          const Divider(height: 32),
          _buildSectionHeader('⚙️ 출금 처리 설정'),
          _buildSwitchTile(
            '자동 승인',
            autoApprove,
            (value) => _updateDirectField('autoApprove', value),
          ),
          _buildNumberField(
            '처리 기간 (일)',
            processingDays,
            (value) => _updateDirectField('processingDays', value),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '출금 설정 미리보기',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('• 최소 출금: ${_formatNumber(minAmount)}P'),
                Text('• 출금 단위: ${_formatNumber(allowedUnits)}P'),
                Text('• 수수료: ${(feeRate * 100).toStringAsFixed(0)}%'),
                const SizedBox(height: 8),
                const Divider(),
                Text(
                  '예시: 50,000P 출금 시',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '  수수료: ${_formatNumber((50000 * feeRate).toInt())}P',
                  style: const TextStyle(color: Colors.red),
                ),
                Text(
                  '  실수령액: ${_formatNumber((50000 * (1 - feeRate)).toInt())}P',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  // 플랫폼 수수료 탭
  Widget _buildPlatformTab() {
    if (_currentSettings == null) return const SizedBox();

    final appReg = _currentSettings!['appRegistration'] ?? {};
    final missionCreate = _currentSettings!['missionCreation'] ?? {};
    final commission = _currentSettings!['commissionRate'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('📱 앱 등록 비용'),
          _buildNumberField(
            '등록 비용 (P)',
            appReg['cost'] ?? 5000,
            (value) => _updateNestedField('appRegistration', 'cost', value),
          ),
          const Divider(height: 32),
          _buildSectionHeader('📝 미션 생성 비용'),
          _buildNumberField(
            '생성 비용 (P)',
            missionCreate['cost'] ?? 1000,
            (value) => _updateNestedField('missionCreation', 'cost', value),
          ),
          _buildNumberField(
            '무료 체험 횟수',
            missionCreate['freeTrials'] ?? 3,
            (value) => _updateNestedField('missionCreation', 'freeTrials', value),
          ),
          const Divider(height: 32),
          _buildSectionHeader('💵 플랫폼 수수료율'),
          _buildPercentageField(
            '테스터 수수료 (%)',
            ((commission['tester'] ?? 0.03) * 100).toInt(),
            (value) =>
                _updateNestedField('commissionRate', 'tester', value / 100),
          ),
          _buildPercentageField(
            '공급자 수수료 (%)',
            ((commission['provider'] ?? 0.03) * 100).toInt(),
            (value) =>
                _updateNestedField('commissionRate', 'provider', value / 100),
          ),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  // 어뷰징 방지 탭
  Widget _buildAbusePreventionTab() {
    if (_currentSettings == null) return const SizedBox();

    final multiAccount = _currentSettings!['multiAccountDetection'] ?? {};
    final withdrawalRestrict = _currentSettings!['withdrawalRestrictions'] ?? {};
    final pointAbuse = _currentSettings!['pointAbuseDetection'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('🔍 다중 계정 탐지'),
          _buildSwitchTile(
            '다중 계정 탐지 활성화',
            multiAccount['enabled'] ?? true,
            (value) =>
                _updateNestedField('multiAccountDetection', 'enabled', value),
          ),
          _buildSwitchTile(
            '디바이스 ID 체크',
            multiAccount['checkDeviceId'] ?? true,
            (value) =>
                _updateNestedField('multiAccountDetection', 'checkDeviceId', value),
          ),
          _buildSwitchTile(
            'IP 주소 체크',
            multiAccount['checkIpAddress'] ?? true,
            (value) => _updateNestedField(
                'multiAccountDetection', 'checkIpAddress', value),
          ),
          _buildNumberField(
            '디바이스당 최대 계정 수',
            multiAccount['maxAccountsPerDevice'] ?? 1,
            (value) => _updateNestedField(
                'multiAccountDetection', 'maxAccountsPerDevice', value),
          ),
          const Divider(height: 32),
          _buildSectionHeader('🚫 출금 제한'),
          _buildNumberField(
            '일일 최대 출금 횟수',
            withdrawalRestrict['maxDailyWithdrawals'] ?? 3,
            (value) => _updateNestedField(
                'withdrawalRestrictions', 'maxDailyWithdrawals', value),
          ),
          _buildNumberField(
            '일일 최대 출금 금액 (P)',
            withdrawalRestrict['maxDailyAmount'] ?? 500000,
            (value) => _updateNestedField(
                'withdrawalRestrictions', 'maxDailyAmount', value),
          ),
          const Divider(height: 32),
          _buildSectionHeader('⚠️ 포인트 어뷰징 탐지'),
          _buildSwitchTile(
            '포인트 어뷰징 탐지 활성화',
            pointAbuse['enabled'] ?? true,
            (value) => _updateNestedField('pointAbuseDetection', 'enabled', value),
          ),
          _buildNumberField(
            '일일 최대 포인트 획득 (P)',
            pointAbuse['maxPointsPerDay'] ?? 10000,
            (value) =>
                _updateNestedField('pointAbuseDetection', 'maxPointsPerDay', value),
          ),
          _buildNumberField(
            '자동 정지 기준 (P)',
            pointAbuse['autoSuspendThreshold'] ?? 50000,
            (value) => _updateNestedField(
                'pointAbuseDetection', 'autoSuspendThreshold', value),
          ),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  // UI 헬퍼 메서드들
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  // v2.91.0: 숫자 입력 필드 (새로운 StatefulWidget 사용)
  Widget _buildNumberField(String label, int value, Function(int) onChanged) {
    return _NumberInputField(
      label: label,
      initialValue: value,
      onChanged: onChanged,
    );
  }

  // v2.91.0: 퍼센트 입력 필드 (새로운 StatefulWidget 사용)
  Widget _buildPercentageField(
      String label, int value, Function(int) onChanged) {
    return _NumberInputField(
      label: label,
      initialValue: value,
      onChanged: onChanged,
      suffixText: '%',
      minValue: 0,
      maxValue: 100,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showSaveDialog,
        icon: const Icon(Icons.save),
        label: const Text('변경사항 저장'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  // 데이터 업데이트 헬퍼
  void _updateNestedField(String parent, String field, dynamic value) {
    setState(() {
      if (_currentSettings![parent] == null) {
        _currentSettings![parent] = {};
      }
      _currentSettings![parent][field] = value;
    });
  }

  void _updateDirectField(String field, dynamic value) {
    setState(() {
      _currentSettings![field] = value;
    });
  }

  // 저장 다이얼로그
  void _showSaveDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('설정 변경 사유'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: '변경 사유를 입력하세요',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('변경 사유를 입력해주세요')),
                );
                return;
              }

              Navigator.pop(context);
              _saveSettings(
                _currentTab,
                _currentSettings!,
                reasonController.text.trim(),
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // 숫자 포맷팅
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

// v2.91.0: StatefulWidget으로 분리된 숫자 입력 필드 (입력 버그 수정)
class _NumberInputField extends StatefulWidget {
  final String label;
  final int initialValue;
  final ValueChanged<int> onChanged;
  final String? suffixText;
  final int? minValue;
  final int? maxValue;

  const _NumberInputField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.suffixText,
    this.minValue,
    this.maxValue,
  });

  @override
  State<_NumberInputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends State<_NumberInputField> {
  late TextEditingController _controller;
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _controller = TextEditingController(text: _currentValue.toString());
  }

  @override
  void didUpdateWidget(_NumberInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부에서 값이 변경된 경우에만 컨트롤러 업데이트
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _currentValue) {
      _currentValue = widget.initialValue;
      _controller.text = _currentValue.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _increment() {
    final newValue = _currentValue + 1;
    if (widget.maxValue == null || newValue <= widget.maxValue!) {
      _updateValue(newValue);
    }
  }

  void _decrement() {
    final newValue = _currentValue - 1;
    if (widget.minValue == null || newValue >= widget.minValue!) {
      _updateValue(newValue);
    }
  }

  void _updateValue(int value) {
    setState(() {
      _currentValue = value;
      _controller.text = value.toString();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: widget.label,
                border: const OutlineInputBorder(),
                suffixText: widget.suffixText,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (text) {
                if (text.isNotEmpty) {
                  final value = int.tryParse(text);
                  if (value != null) {
                    _currentValue = value;
                    widget.onChanged(value);
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // 상하 버튼
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 32,
                child: IconButton(
                  onPressed: _increment,
                  icon: const Icon(Icons.arrow_drop_up, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 40,
                height: 32,
                child: IconButton(
                  onPressed: _decrement,
                  icon: const Icon(Icons.arrow_drop_down, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
