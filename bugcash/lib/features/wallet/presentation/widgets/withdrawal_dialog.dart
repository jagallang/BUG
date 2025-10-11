import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/usecases/wallet_service.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../../admin/data/providers/platform_settings_provider.dart';

/// 출금 다이얼로그
/// - 출금 금액 입력
/// - 최소 출금 금액 검증
/// - 은행 계좌 정보 입력
/// - 출금 신청 처리
class WithdrawalDialog extends ConsumerStatefulWidget {
  final WalletEntity wallet;

  const WithdrawalDialog({
    super.key,
    required this.wallet,
  });

  @override
  ConsumerState<WithdrawalDialog> createState() => _WithdrawalDialogState();
}

class _WithdrawalDialogState extends ConsumerState<WithdrawalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _withdrawalSettings;
  bool _platformCostSystemEnabled = true; // v2.101.0: 플랫폼 비용 시스템 활성화 여부

  // 동적 설정값 (platform_settings에서 로드)
  int get _minWithdrawalAmount => _withdrawalSettings?['minAmount'] ?? 30000;
  int get _allowedUnits => _withdrawalSettings?['allowedUnits'] ?? 10000;
  double get _feeRate {
    // v2.101.0: 플랫폼 비용 시스템 비활성화 시 수수료 0%
    if (!_platformCostSystemEnabled) return 0.0;
    return (_withdrawalSettings?['feeRate'] ?? 0.18).toDouble();
  }

  int get _withdrawalAmount {
    return int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
  }

  int get _withdrawalFee {
    return (_withdrawalAmount * _feeRate).round();
  }

  int get _finalAmount {
    return _withdrawalAmount - _withdrawalFee;
  }

  @override
  void initState() {
    super.initState();
    _loadWithdrawalSettings();
    _loadPlatformCostSystemSettings(); // v2.101.0
  }

  Future<void> _loadWithdrawalSettings() async {
    try {
      final settings = await ref.read(withdrawalSettingsProvider.future);
      if (mounted) {
        setState(() {
          _withdrawalSettings = settings;
        });
        debugPrint('✅ 출금 설정 로드 완료: 최소 ${_minWithdrawalAmount}P, 수수료 ${(_feeRate * 100).toInt()}%');
      }
    } catch (e) {
      debugPrint('❌ 출금 설정 로드 실패: $e (기본값 사용)');
    }
  }

  // v2.101.0: 플랫폼 비용 시스템 활성화 여부 로드
  Future<void> _loadPlatformCostSystemSettings() async {
    try {
      final platformSettings = await ref.read(platformSettingsProvider.notifier).getPlatformSettings();
      final pointValidation = platformSettings['pointValidation'] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _platformCostSystemEnabled = pointValidation?['enabled'] ?? true;
        });
        debugPrint('✅ 플랫폼 비용 시스템: ${_platformCostSystemEnabled ? "활성화" : "비활성화"}');
      }
    } catch (e) {
      debugPrint('❌ 플랫폼 비용 시스템 설정 로드 실패: $e (기본값: 활성화)');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  children: [
                    Icon(
                      Icons.arrow_circle_up,
                      color: Colors.green[700],
                      size: 28.w,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      '출금 신청',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  '출금 가능 금액: ${_formatAmount(widget.wallet.balance)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24.h),

                // 출금 금액 입력
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: '출금 금액',
                    hintText: '출금할 금액을 입력하세요',
                    suffix: const Text('P'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    setState(() {}); // 수수료 계산 업데이트
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '출금 금액을 입력하세요';
                    }
                    final amount = int.tryParse(value) ?? 0;
                    if (amount < _minWithdrawalAmount) {
                      return '최소 출금 금액은 ${_formatAmount(_minWithdrawalAmount)}입니다';
                    }
                    // 출금 단위 검증
                    if (amount % _allowedUnits != 0) {
                      return '${_formatAmount(_allowedUnits)} 단위로 입력해주세요';
                    }
                    if (amount > widget.wallet.balance) {
                      return '출금 가능 금액을 초과했습니다';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                // 수수료 및 실제 입금액 표시
                if (_withdrawalAmount > 0) ...[
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        _buildAmountRow('출금 요청', _withdrawalAmount),
                        SizedBox(height: 8.h),
                        _buildAmountRow(
                          '수수료 (${(_feeRate * 100).toInt()}%)',
                          _withdrawalFee,
                          color: Colors.red,
                        ),
                        Divider(height: 16.h),
                        _buildAmountRow(
                          '실제 입금액',
                          _finalAmount,
                          isBold: true,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // 은행 정보
                TextFormField(
                  controller: _bankNameController,
                  decoration: InputDecoration(
                    labelText: '은행명',
                    hintText: '예: 국민은행',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '은행명을 입력하세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                TextFormField(
                  controller: _accountNumberController,
                  decoration: InputDecoration(
                    labelText: '계좌번호',
                    hintText: '- 없이 입력',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '계좌번호를 입력하세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),

                TextFormField(
                  controller: _accountHolderController,
                  decoration: InputDecoration(
                    labelText: '예금주',
                    hintText: '예금주명을 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '예금주명을 입력하세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.h),

                // 버튼
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleWithdrawal,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          backgroundColor: Colors.green,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('출금 신청'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    int amount, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16.sp : 14.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          _formatAmount(amount),
          style: TextStyle(
            fontSize: isBold ? 16.sp : 14.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _handleWithdrawal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final walletService = WalletService(WalletRepositoryImpl());

      // 출금 신청
      await walletService.withdrawPoints(
        widget.wallet.userId,
        _withdrawalAmount,
        '출금 신청',
        metadata: {
          'bankName': _bankNameController.text,
          'accountNumber': _accountNumberController.text,
          'accountHolder': _accountHolderController.text,
          'fee': _withdrawalFee,
          'finalAmount': _finalAmount,
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 출금 신청이 완료되었습니다.\n영업일 기준 1-3일 내 처리됩니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('출금 신청 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}P';
  }
}
