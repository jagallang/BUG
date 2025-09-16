import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

enum MissionTestStatus {
  notStarted,       // 시작 전
  testing,          // 테스트 중
  waitingEnd,       // 종료 대기 중
  completed,        // 완료됨
  submitted,        // 제출됨
  needsRevision,    // 보완 요청됨
  revising,         // 보완 중
}

class MissionTestSession {
  final String missionId;
  final DateTime startTime;
  DateTime? endTime;
  final List<MissionScreenshot> screenshots;
  MissionTestStatus status;
  String? rejectionReason;         // 거부 이유
  String? revisionRequest;         // 보완 요청사항
  DateTime? rejectionTime;         // 거부/보완요청 받은 시간
  
  MissionTestSession({
    required this.missionId,
    required this.startTime,
    this.endTime,
    required this.screenshots,
    this.status = MissionTestStatus.notStarted,
    this.rejectionReason,
    this.revisionRequest,
    this.rejectionTime,
  });
}

class MissionScreenshot {
  final String id;
  final File? imageFile;
  final String? imagePath;
  final DateTime timestamp;
  final String type; // 'start', 'middle', 'end'
  
  MissionScreenshot({
    required this.id,
    this.imageFile,
    this.imagePath,
    required this.timestamp,
    required this.type,
  });
}

class MissionDetailPage extends StatefulWidget {
  final String missionId;
  final String missionTitle;
  final String missionDescription;
  final String appName;
  
  const MissionDetailPage({
    super.key,
    required this.missionId,
    required this.missionTitle,
    required this.missionDescription,
    required this.appName,
  });

  @override
  State<MissionDetailPage> createState() => _MissionDetailPageState();
}

class _MissionDetailPageState extends State<MissionDetailPage> {
  MissionTestSession? _currentSession;
  Timer? _testTimer;
  int _remainingSeconds = 0;
  final int _testDurationSeconds = 10 * 60; // 10분
  final ImagePicker _imagePicker = ImagePicker();
  
  // Mock data for mission details
  late Map<String, dynamic> _missionData;
  
  @override
  void initState() {
    super.initState();
    _initializeMissionData();
    _checkForRevisionRequest();
  }
  
  void _initializeMissionData() {
    _missionData = {
      'id': widget.missionId,
      'title': widget.missionTitle,
      'description': widget.missionDescription,
      'appName': widget.appName,
      'reward': '5,000P',
      'deadline': '2일 남음',
      'requirements': [
        '앱을 10분간 사용하며 주요 기능 테스트',
        '시작, 중간, 종료 시 스크린샷 3장 필수 촬영',
        '발견한 버그나 개선사항 메모',
      ],
      'instructions': [
        '1. "오늘의 앱테스트 시작" 버튼 클릭',
        '2. 앱을 다운로드하여 설치',
        '3. 첫 화면 스크린샷 촬영',
        '4. 5분 후 중간 스크린샷 촬영',
        '5. 10분 후 마지막 스크린샷 촬영',
        '6. "앱테스트 종료" 버튼 클릭하여 완료',
      ],
    };
  }
  
  void _checkForRevisionRequest() {
    // 시뮬레이션: 특정 미션 ID에 대해 보완요청이 있다고 가정
    if (widget.missionTitle.contains('채팅앱')) {
      setState(() {
        _currentSession = MissionTestSession(
          missionId: widget.missionId,
          startTime: DateTime.now().subtract(const Duration(hours: 2)),
          screenshots: [],
          status: MissionTestStatus.needsRevision,
          rejectionReason: '스크린샷 품질 부족',
          revisionRequest: '스크린샷이 흐릿하고 텍스트가 잘 보이지 않습니다. 더 선명한 스크린샷을 다시 촬영해 주세요. 특히 알림 기능 테스트 과정을 단계별로 명확하게 보여주시기 바랍니다.',
          rejectionTime: DateTime.now().subtract(const Duration(hours: 1)),
        );
      });
    }
  }
  
  @override
  void dispose() {
    _testTimer?.cancel();
    super.dispose();
  }
  
  void _startTest() {
    setState(() {
      _currentSession = MissionTestSession(
        missionId: widget.missionId,
        startTime: DateTime.now(),
        screenshots: [],
        status: MissionTestStatus.testing,
      );
      _remainingSeconds = _testDurationSeconds;
    });
    
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _currentSession!.status = MissionTestStatus.waitingEnd;
          timer.cancel();
        }
      });
    });
    
    // 시작 스크린샷 촬영 안내
    _showScreenshotDialog('start');
  }
  
  void _endTest() async {
    if (_currentSession == null) return;
    
    // 마지막 스크린샷이 업로드되었는지 확인
    final endScreenshots = _currentSession!.screenshots
        .where((s) => s.type == 'end')
        .toList();
    
    if (endScreenshots.isEmpty) {
      _showScreenshotDialog('end');
      return;
    }
    
    setState(() {
      _currentSession!.endTime = DateTime.now();
      _currentSession!.status = MissionTestStatus.completed;
    });
    
    _testTimer?.cancel();
    
    // 미션 완료 처리
    await _submitMissionResult();
  }
  
  Future<void> _submitMissionResult() async {
    if (_currentSession == null) return;
    
    // 여기서 실제로는 서버에 결과를 전송
    // 지금은 Mock으로 처리
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _currentSession!.status = MissionTestStatus.submitted;
    });
    
    // 성공 메시지 표시
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('미션이 성공적으로 완료되었습니다! 공급자 승인을 기다려주세요.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  void _showScreenshotDialog(String type) {
    String title;
    String description;
    
    switch (type) {
      case 'start':
        title = '시작 스크린샷';
        description = '앱 테스트를 시작하기 전 화면을 촬영해주세요.';
        break;
      case 'middle':
        title = '중간 스크린샷';
        description = '앱 사용 중간 과정의 화면을 촬영해주세요.';
        break;
      case 'end':
        title = '종료 스크린샷';
        description = '앱 테스트 완료 후 마지막 화면을 촬영해주세요.';
        break;
      default:
        title = '스크린샷';
        description = '화면을 촬영해주세요.';
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt,
              size: 48.w,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 16.h),
            Text(description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _takeScreenshot(type);
            },
            child: const Text('촬영하기'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _takeScreenshot(String type) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        final screenshot = MissionScreenshot(
          id: '${type}_${DateTime.now().millisecondsSinceEpoch}',
          imageFile: File(image.path),
          imagePath: image.path,
          timestamp: DateTime.now(),
          type: type,
        );
        
        setState(() {
          _currentSession?.screenshots.add(screenshot);
        });
        
        // 중간 스크린샷 자동 안내 (5분 후)
        if (type == 'start') {
          Timer(const Duration(minutes: 5), () {
            if (_currentSession?.status == MissionTestStatus.testing) {
              _showScreenshotDialog('middle');
            }
          });
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_getScreenshotTypeText(type)} 스크린샷이 저장되었습니다.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('스크린샷 촬영 중 오류가 발생했습니다: $e')),
      );
    }
  }
  
  void _startRevision() {
    setState(() {
      _currentSession!.status = MissionTestStatus.revising;
      // 기존 스크린샷들을 유지하되, 새로운 스크린샷을 추가할 수 있도록 함
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('보완 작업을 시작합니다. 새로운 스크린샷을 촬영하거나 기존 내용을 수정해주세요.'),
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  Future<void> _submitRevision() async {
    if (_currentSession == null) return;
    
    // 실제로는 서버에 보완된 내용을 전송
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _currentSession!.status = MissionTestStatus.submitted;
      // 보완 관련 필드들 초기화 (선택사항)
      _currentSession!.rejectionReason = null;
      _currentSession!.revisionRequest = null;
      _currentSession!.rejectionTime = null;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('보완이 완료되어 재승인 요청이 전송되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  String _getScreenshotTypeText(String type) {
    switch (type) {
      case 'start':
        return '시작';
      case 'middle':
        return '중간';
      case 'end':
        return '종료';
      default:
        return type;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('미션 상세'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 미션 기본 정보
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _missionData['title'],
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            _missionData['reward'],
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      '앱 이름: ${_missionData['appName']}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _missionData['description'],
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16.w, color: Colors.orange),
                        SizedBox(width: 4.w),
                        Text(
                          _missionData['deadline'],
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // 테스트 상태 표시
            if (_currentSession != null) ...[
              Card(
                color: _getStatusColor(),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(),
                            color: Colors.white,
                            size: 24.w,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _getStatusText(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_currentSession!.status == MissionTestStatus.testing) ...[
                        SizedBox(height: 12.h),
                        Text(
                          '남은 시간: ${_formatTime(_remainingSeconds)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        LinearProgressIndicator(
                          value: (_testDurationSeconds - _remainingSeconds) / _testDurationSeconds,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
            
            // 스크린샷 현황
            if (_currentSession != null && _currentSession!.screenshots.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '스크린샷 현황',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      ...['start', 'middle', 'end'].map((type) {
                        final screenshot = _currentSession!.screenshots
                            .where((s) => s.type == type)
                            .firstOrNull;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Row(
                            children: [
                              Icon(
                                screenshot != null ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: screenshot != null ? Colors.green : Colors.grey,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                type == 'start' ? '시작 스크린샷' 
                                  : type == 'middle' ? '중간 스크린샷' 
                                  : '종료 스크린샷',
                                style: TextStyle(
                                  color: screenshot != null ? Colors.black : Colors.grey,
                                ),
                              ),
                              if (screenshot != null) ...[
                                const Spacer(),
                                Text(
                                  '${screenshot.timestamp.hour}:${screenshot.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
            
            // 보완 요청 피드백 (거부 사유가 있는 경우)
            if (_currentSession?.status == MissionTestStatus.needsRevision && 
                (_currentSession?.rejectionReason != null || _currentSession?.revisionRequest != null)) ...[
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.feedback,
                            color: Colors.orange.shade700,
                            size: 24.w,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '보완 요청',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      
                      if (_currentSession?.rejectionReason != null) ...[
                        Text(
                          '거부 사유:',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _currentSession!.rejectionReason!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                      ],
                      
                      if (_currentSession?.revisionRequest != null) ...[
                        Text(
                          '보완 요청사항:',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text(
                            _currentSession!.revisionRequest!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                      
                      if (_currentSession?.rejectionTime != null) ...[
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16.w,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '요청 시간: ${_currentSession!.rejectionTime!.month}/${_currentSession!.rejectionTime!.day} ${_currentSession!.rejectionTime!.hour}:${_currentSession!.rejectionTime!.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
            
            // 미션 요구사항
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '미션 요구사항',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ...(_missionData['requirements'] as List<String>).map(
                      (req) => Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check, size: 16.w, color: Colors.green),
                            SizedBox(width: 8.w),
                            Expanded(child: Text(req)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // 테스트 진행 방법
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '테스트 진행 방법',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ...(_missionData['instructions'] as List<String>).map(
                      (instruction) => Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Text(instruction),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 32.h),
          ],
        ),
      ),
      
      // 하단 액션 버튼들
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: _buildActionButtons(),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    if (_currentSession == null) {
      return ElevatedButton(
        onPressed: _startTest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          '오늘의 앱테스트 시작',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    switch (_currentSession!.status) {
      case MissionTestStatus.testing:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _takeScreenshot('middle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text('중간 스크린샷 촬영'),
            ),
            SizedBox(height: 8.h),
            OutlinedButton(
              onPressed: _remainingSeconds > 300 ? null : _endTest, // 5분 이후부터 활성화
              child: Text(
                _remainingSeconds > 300 
                  ? '앱테스트 종료 (${_formatTime(_remainingSeconds - 300)} 후 가능)'
                  : '앱테스트 종료',
              ),
            ),
          ],
        );
        
      case MissionTestStatus.waitingEnd:
        return ElevatedButton(
          onPressed: _endTest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Text(
            '앱테스트 종료',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        
      case MissionTestStatus.completed:
      case MissionTestStatus.submitted:
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24.w),
              SizedBox(width: 8.w),
              Text(
                _currentSession!.status == MissionTestStatus.completed
                  ? '미션 완료됨 - 공급자 승인 대기'
                  : '미션 제출 완료 - 승인 대기',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
        
      case MissionTestStatus.needsRevision:
        return ElevatedButton(
          onPressed: _startRevision,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Text(
            '보완 작업 시작',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        
      case MissionTestStatus.revising:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _takeScreenshot('middle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text('새 스크린샷 촬영'),
            ),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: _submitRevision,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text('보완 완료 - 재승인 요청'),
            ),
          ],
        );
        
      default:
        return const SizedBox.shrink();
    }
  }
  
  Color _getStatusColor() {
    switch (_currentSession!.status) {
      case MissionTestStatus.testing:
        return Colors.blue;
      case MissionTestStatus.waitingEnd:
        return Colors.orange;
      case MissionTestStatus.completed:
      case MissionTestStatus.submitted:
        return Colors.green;
      case MissionTestStatus.needsRevision:
        return Colors.orange;
      case MissionTestStatus.revising:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getStatusIcon() {
    switch (_currentSession!.status) {
      case MissionTestStatus.testing:
        return Icons.play_circle;
      case MissionTestStatus.waitingEnd:
        return Icons.pause_circle;
      case MissionTestStatus.completed:
      case MissionTestStatus.submitted:
        return Icons.check_circle;
      case MissionTestStatus.needsRevision:
        return Icons.feedback;
      case MissionTestStatus.revising:
        return Icons.edit;
      default:
        return Icons.radio_button_unchecked;
    }
  }
  
  String _getStatusText() {
    switch (_currentSession!.status) {
      case MissionTestStatus.testing:
        return '테스트 진행 중';
      case MissionTestStatus.waitingEnd:
        return '테스트 시간 완료 - 종료 가능';
      case MissionTestStatus.completed:
        return '미션 완료';
      case MissionTestStatus.submitted:
        return '미션 제출 완료';
      case MissionTestStatus.needsRevision:
        return '보완 요청됨';
      case MissionTestStatus.revising:
        return '보완 작업 중';
      default:
        return '준비 중';
    }
  }
}