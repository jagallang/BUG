import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/api_key_service.dart';
import '../../../../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _hasCustomApiKey = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await ApiKeyService.getFirebaseApiKey();
    final hasCustom = await ApiKeyService.hasCustomApiKey();

    setState(() {
      _apiKeyController.text = apiKey;
      _hasCustomApiKey = hasCustom;
    });
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API 키를 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiKeyService.setFirebaseApiKey(_apiKeyController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API 키가 저장되었습니다. 앱을 재시작해주세요.'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _hasCustomApiKey = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API 키 저장 실패: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetApiKey() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ApiKeyService.clearFirebaseApiKey();
      final defaultKey = await ApiKeyService.getFirebaseApiKey();

      setState(() {
        _apiKeyController.text = defaultKey;
        _hasCustomApiKey = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기본 API 키로 초기화되었습니다'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API 키 초기화 실패: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Firebase API 키 설정',
              style: TextStyle(
                fontSize: 18.rsp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Firebase 인증을 위한 API 키를 설정합니다.',
              style: TextStyle(
                fontSize: 14.rsp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20.h),

            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'Firebase API 키',
                hintText: 'AIzaSy...',
                border: const OutlineInputBorder(),
                suffixIcon: _hasCustomApiKey
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : Icon(Icons.warning, color: Colors.orange),
                helperText: _hasCustomApiKey
                  ? '사용자 정의 API 키 사용 중'
                  : '기본 API 키 사용 중',
              ),
              maxLines: 3,
              enabled: !_isLoading,
            ),

            SizedBox(height: 20.h),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveApiKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('저장'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _resetApiKey,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: const Text('초기화'),
                  ),
                ),
              ],
            ),

            SizedBox(height: 30.h),

            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'API 키 설정 가이드',
                        style: TextStyle(
                          fontSize: 16.rsp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '1. Firebase Console에서 프로젝트 설정 > 일반 탭으로 이동\n'
                    '2. "웹 API 키" 또는 "API 키" 복사\n'
                    '3. 위 입력 필드에 붙여넣고 저장\n'
                    '4. 앱 재시작 후 로그인 테스트',
                    style: TextStyle(
                      fontSize: 14.rsp,
                      color: Colors.blue[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}