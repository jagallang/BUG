import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// 스크린샷 안내 서비스
///
/// 브라우저의 기본 스크린샷 기능을 사용하도록 안내합니다.
class ScreenshotService {
  /// 스크린샷 안내 다이얼로그 표시
  Future<void> showScreenshotGuide(BuildContext context) async {
    if (!kIsWeb) {
      // 모바일은 시스템 스크린샷 사용
      _showMobileGuide(context);
      return;
    }

    // 웹 브라우저 스크린샷 안내
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Text(
              '스크린샷 촬영 방법',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '브라우저 개발자 도구를 사용하여 스크린샷을 촬영할 수 있습니다.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              _buildPlatformInstructions(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chrome 안내
        _buildInstructionItem(
          icon: Icons.laptop_chromebook,
          title: 'Chrome / Edge',
          steps: [
            '1. F12 또는 우클릭 → "검사" 클릭',
            '2. Ctrl+Shift+P (Mac: Cmd+Shift+P)',
            '3. "screenshot" 입력',
            '4. "Capture full size screenshot" 선택',
          ],
        ),
        SizedBox(height: 16),
        // Firefox 안내
        _buildInstructionItem(
          icon: Icons.web,
          title: 'Firefox',
          steps: [
            '1. Shift+F2',
            '2. ":screenshot --fullpage" 입력',
          ],
        ),
        SizedBox(height: 16),
        // 시스템 스크린샷 안내
        _buildInstructionItem(
          icon: Icons.computer,
          title: '시스템 스크린샷',
          steps: [
            'Windows: Win+Shift+S',
            'Mac: Cmd+Shift+4',
          ],
        ),
      ],
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String title,
    required List<String> steps,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...steps.map((step) => Padding(
                padding: EdgeInsets.only(left: 26, top: 4),
                child: Text(
                  step,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _showMobileGuide(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('기기의 스크린샷 기능을 사용해주세요 (전원 + 볼륨 다운)'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
