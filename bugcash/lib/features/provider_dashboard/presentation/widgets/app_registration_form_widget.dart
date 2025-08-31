import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/app_registration_provider.dart';
import '../../domain/models/provider_model.dart';

class AppRegistrationFormWidget extends ConsumerWidget {
  final String providerId;
  final VoidCallback? onRegistrationComplete;

  const AppRegistrationFormWidget({
    super.key,
    required this.providerId,
    this.onRegistrationComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: 16.h),
            _buildQuickStartForm(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.add_circle_outline,
          color: Theme.of(context).colorScheme.primary,
          size: 24.w,
        ),
        SizedBox(width: 8.w),
        Text(
          '빠른 앱 등록',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _showFullRegistrationForm(context),
          icon: const Icon(Icons.open_in_new),
          label: const Text('전체 폼'),
        ),
      ],
    );
  }

  Widget _buildQuickStartForm(BuildContext context, WidgetRef ref) {
    final registrationState = ref.watch(appRegistrationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '앱의 기본 정보만 입력하여 빠르게 등록을 시작하세요.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 16.h),
        
        // App Name Field
        TextFormField(
          decoration: InputDecoration(
            labelText: '앱 이름',
            hintText: '마켓에 표시될 앱 이름',
            prefixIcon: const Icon(Icons.apps),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // Package Name Field
        TextFormField(
          decoration: InputDecoration(
            labelText: '패키지명',
            hintText: 'com.example.myapp',
            prefixIcon: const Icon(Icons.code),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // App Type Dropdown
        DropdownButtonFormField<AppType>(
          decoration: InputDecoration(
            labelText: '앱 타입',
            prefixIcon: const Icon(Icons.devices),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          value: AppType.android,
          items: AppType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getAppTypeText(type)),
            );
          }).toList(),
          onChanged: (value) {
            // Handle app type change
          },
        ),
        
        SizedBox(height: 16.h),
        
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showFullRegistrationForm(context),
                icon: const Icon(Icons.edit),
                label: const Text('상세 등록'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: registrationState.isLoading 
                    ? null 
                    : () => _quickRegister(context, ref),
                icon: registrationState.isLoading 
                    ? SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rocket_launch),
                label: Text(registrationState.isLoading ? '등록중...' : '빠른 등록'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        
        if (registrationState.error != null) ...[
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    registrationState.error!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => ref.read(appRegistrationProvider.notifier).clearError(),
                  icon: const Icon(Icons.close),
                  iconSize: 16.w,
                  color: Colors.red.shade400,
                ),
              ],
            ),
          ),
        ],
        
        // Registration Tips
        SizedBox(height: 16.h),
        _buildRegistrationTips(context),
      ],
    );
  }

  Widget _buildRegistrationTips(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue,
                size: 16.w,
              ),
              SizedBox(width: 6.w),
              Text(
                '등록 팁',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _buildTipItem('빠른 등록 후에도 언제든 상세 정보를 추가할 수 있습니다'),
          _buildTipItem('패키지명은 고유해야 하며, 나중에 변경할 수 없습니다'),
          _buildTipItem('앱 아이콘과 스크린샷은 상세 등록에서 업로드하세요'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4.w,
            height: 4.w,
            margin: EdgeInsets.only(top: 6.h, right: 8.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAppTypeText(AppType type) {
    switch (type) {
      case AppType.android:
        return 'Android';
      case AppType.ios:
        return 'iOS';
      case AppType.web:
        return 'Web';
      case AppType.desktop:
        return 'Desktop';
    }
  }

  void _showFullRegistrationForm(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('전체 앱 등록 폼으로 이동합니다.'),
        action: SnackBarAction(
          label: '이동',
          onPressed: () {
            // Navigate to full registration form
            // Navigator.pushNamed(context, '/app-registration', arguments: providerId);
          },
        ),
      ),
    );
  }

  void _quickRegister(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('빠른 등록 기능이 곧 구현될 예정입니다.'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}