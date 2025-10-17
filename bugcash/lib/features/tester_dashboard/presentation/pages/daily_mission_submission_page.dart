import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/mission_workflow_service.dart' show missionWorkflowServiceProvider;
import '../../../../shared/widgets/image_upload_widget.dart';
import '../../../../core/utils/logger.dart';

/// v2.9.0: 일일 미션 제출 페이지 (공급자 질문 + 버그리포트)
/// 테스터가 하루 미션을 완료하고 답변, 스크린샷, 버그리포트를 제출하는 페이지
class DailyMissionSubmissionPage extends ConsumerStatefulWidget {
  final String workflowId;
  final int dayNumber;
  final String missionTitle;
  final String appId; // v2.9.0: 공급자 질문 로드용

  const DailyMissionSubmissionPage({
    super.key,
    required this.workflowId,
    required this.dayNumber,
    required this.missionTitle,
    required this.appId,
  });

  @override
  ConsumerState<DailyMissionSubmissionPage> createState() =>
      _DailyMissionSubmissionPageState();
}

class _DailyMissionSubmissionPageState
    extends ConsumerState<DailyMissionSubmissionPage> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController(); // v2.9.0: 테스트 소감
  final _bugReportController = TextEditingController(); // v2.9.0: 버그 리포트
  final List<XFile> _selectedImages = []; // v2.9.0: XFile 사용

  // v2.9.0: 공급자 질문 답변
  final Map<String, TextEditingController> _answerControllers = {};
  List<String> _dailyQuestions = [];
  bool _isLoadingQuestions = true;
  String? _questionsLoadError; // v2.10.1: 질문 로드 실패 에러 메시지

  bool _isSubmitting = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDailyQuestions(); // v2.9.0: 질문 로드
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _bugReportController.dispose(); // v2.9.0
    for (var controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// v2.10.1: 공급자가 미리 입력한 일일 질문 로드 (상세 로그 + Fallback)
  Future<void> _loadDailyQuestions() async {
    AppLogger.info(
      '📝 [DailyQuestions] 질문 로드 시작\n'
      '   ├─ appId: ${widget.appId}\n'
      '   ├─ workflowId: ${widget.workflowId}\n'
      '   └─ dayNumber: ${widget.dayNumber}',
      'DailyMissionSubmission'
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.appId)
          .get();

      AppLogger.info(
        '📄 [DailyQuestions] Firestore 조회 결과\n'
        '   ├─ doc.exists: ${doc.exists}\n'
        '   └─ doc.id: ${doc.id}',
        'DailyMissionSubmission'
      );

      if (doc.exists) {
        final data = doc.data();
        AppLogger.info(
          '📦 [DailyQuestions] 문서 데이터\n'
          '   ├─ appName: ${data?['appName']}\n'
          '   ├─ hasDaily Questions: ${data?.containsKey('dailyQuestions')}\n'
          '   └─ questions count: ${(data?['dailyQuestions'] as List?)?.length ?? 0}',
          'DailyMissionSubmission'
        );

        if (data!.containsKey('dailyQuestions')) {
          final questions = List<String>.from(data['dailyQuestions'] ?? []);
          setState(() {
            _dailyQuestions = questions;
            // 각 질문에 대한 답변 컨트롤러 생성
            for (int i = 0; i < questions.length; i++) {
              _answerControllers['question_$i'] = TextEditingController();
            }
            _isLoadingQuestions = false;
            _questionsLoadError = null;
          });
          AppLogger.info('✅ [DailyQuestions] ${questions.length}개 질문 로드 완료', 'DailyMissionSubmission');
        } else {
          // v2.10.1: dailyQuestions 필드 없어도 정상 진행
          setState(() {
            _dailyQuestions = [];
            _isLoadingQuestions = false;
            _questionsLoadError = null;
          });
          AppLogger.info('ℹ️ [DailyQuestions] 사전 질문 없음 (정상)', 'DailyMissionSubmission');
        }
      } else {
        // v2.10.1: projects 문서 없을 때 에러 표시하지만 진행은 허용
        setState(() {
          _dailyQuestions = [];
          _isLoadingQuestions = false;
          _questionsLoadError = 'projects 문서를 찾을 수 없습니다 (appId: ${widget.appId})';
        });
        AppLogger.error(
          '❌ [DailyQuestions] projects 문서 없음\n'
          '   └─ appId: ${widget.appId}',
          'DailyMissionSubmission',
          null
        );
      }
    } catch (e) {
      AppLogger.error('❌ [DailyQuestions] 로드 실패: $e', 'DailyMissionSubmission', e);
      setState(() {
        _dailyQuestions = [];
        _isLoadingQuestions = false;
        _questionsLoadError = '질문 로드 실패: $e';
      });
    }
  }

  /// v2.116.0: 미션 제출 처리 (스크린샷 업로드 실패 대응)
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // v2.17.0: 최소 3장 요구사항
    if (_selectedImages.length < 3) {
      _showMessage('최소 3장 이상의 스크린샷을 업로드해주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isUploading = true;
    });

    final uploadedUrls = <String>[];

    try {
      // 1. 이미지 업로드
      AppLogger.info(
        '📤 [v2.116.0] 스크린샷 업로드 시작 (${_selectedImages.length}장)',
        'DailyMissionSubmission',
      );

      final storageService = StorageService();

      for (int i = 0; i < _selectedImages.length; i++) {
        setState(() {
          _uploadProgress = (i + 1) / _selectedImages.length;
        });

        final url = await storageService.uploadMissionScreenshot(
          workflowId: widget.workflowId,
          dayNumber: widget.dayNumber,
          file: _selectedImages[i],
        );
        uploadedUrls.add(url);

        AppLogger.info(
          'Uploaded screenshot ${i + 1}/${_selectedImages.length}: $url',
          'DailyMissionSubmission',
        );
      }

      setState(() => _isUploading = false);

      AppLogger.info(
        '✅ [v2.116.0] 스크린샷 업로드 완료 (${uploadedUrls.length}장)',
        'DailyMissionSubmission',
      );
    } catch (uploadError, uploadStackTrace) {
      // v2.116.0: 업로드 실패 시 사용자에게 확인
      setState(() => _isUploading = false);

      AppLogger.error(
        '❌ [v2.116.0] 스크린샷 업로드 실패\n'
        '   ├─ Error: $uploadError\n'
        '   ├─ StackTrace: ${uploadStackTrace.toString().split('\n').take(3).join('\n   │  ')}\n'
        '   └─ 업로드 진행률: ${(_uploadProgress * 100).toInt()}%',
        'DailyMissionSubmission',
        uploadError
      );

      // 사용자에게 선택권 제공
      final shouldContinueWithoutScreenshots = await _showUploadFailureDialog(uploadError);

      if (!shouldContinueWithoutScreenshots) {
        // 사용자가 취소 선택 → 제출 중단
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
        return;
      }

      // 사용자가 확인 선택 → 빈 배열로 진행
      uploadedUrls.clear();
      AppLogger.warning(
        '⚠️ [v2.116.0] 사용자가 스크린샷 없이 제출 선택\n'
        '   └─ Firebase Storage 장애로 인한 임시 조치',
        'DailyMissionSubmission'
      );
    }

    try {

      // 2. v2.9.0: 공급자 질문 답변 맵 생성
      final questionAnswers = <String, String>{};
      for (int i = 0; i < _dailyQuestions.length; i++) {
        questionAnswers[_dailyQuestions[i]] =
            _answerControllers['question_$i']!.text.trim();
      }

      // 3. Firestore에 제출 데이터 저장
      AppLogger.info(
        '💾 [v2.116.0] Firestore 제출 시작\n'
        '   ├─ workflowId: ${widget.workflowId}\n'
        '   ├─ dayNumber: ${widget.dayNumber}\n'
        '   ├─ screenshots: ${uploadedUrls.length}개\n'
        '   ├─ bugReport: ${_bugReportController.text.trim().isNotEmpty ? "있음" : "없음"}\n'
        '   └─ questionAnswers: ${questionAnswers.length}개',
        'DailyMissionSubmission',
      );

      final missionService = ref.read(missionWorkflowServiceProvider);
      await missionService.submitDailyMission(
        workflowId: widget.workflowId,
        dayNumber: widget.dayNumber,
        feedback: _feedbackController.text.trim(),
        screenshots: uploadedUrls, // v2.116.0: 빈 배열 가능 (업로드 실패 시)
        bugReport: _bugReportController.text.trim(), // v2.9.0
        questionAnswers: questionAnswers, // v2.9.0
      );

      if (mounted) {
        AppLogger.info(
          '✅ [v2.116.0] Daily mission submitted successfully\n'
          '   ├─ workflow: ${widget.workflowId}\n'
          '   ├─ day: ${widget.dayNumber}\n'
          '   └─ screenshots: ${uploadedUrls.length}개 ${uploadedUrls.isEmpty ? "(업로드 실패)" : ""}',
          'DailyMissionSubmission',
        );

        // 성공 메시지
        _showMessage('✅ 미션이 제출되었습니다!');

        // 1초 대기 후 페이지 닫기
        await Future.delayed(const Duration(seconds: 1));

        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop(true); // true를 반환하여 새로고침 트리거
        } else {
          AppLogger.warning('⚠️ Navigator cannot pop', 'DailyMissionSubmission');
        }
      }
    } catch (e, stackTrace) {
      // v2.116.0: Firestore 제출 실패 에러 로깅
      AppLogger.error(
        '❌ [v2.116.0] Firestore 미션 제출 실패\n'
        '   ├─ Error: $e\n'
        '   ├─ StackTrace: ${stackTrace.toString().split('\n').take(5).join('\n   │  ')}\n'
        '   └─ Screenshots count: ${uploadedUrls.length}',
        'DailyMissionSubmission',
        e
      );
      if (mounted) {
        _showMessage('Firebase 저장 실패: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// v2.116.0: 스크린샷 업로드 실패 시 확인 대화상자
  Future<bool> _showUploadFailureDialog(dynamic error) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '스크린샷 업로드 실패',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Firebase Storage 서비스 장애로 스크린샷 업로드에 실패했습니다.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '에러 정보:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '스크린샷 없이 미션을 제출하시겠습니까?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '※ Firebase Storage가 복구되면 다시 스크린샷을 업로드할 수 있습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              '스크린샷 없이 제출',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Day ${widget.dayNumber} 미션 제출'),
        elevation: 0,
      ),
      body: _isLoadingQuestions
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // v2.10.1: 질문 로드 실패 에러 배너
                    if (_questionsLoadError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade300),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '⚠️ 사전 질문을 불러올 수 없습니다',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _questionsLoadError!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '질문 없이 미션을 제출할 수 있습니다.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 미션 정보 카드
                    _buildInfoCard(),
                    const SizedBox(height: 24),

                    // v2.9.0: 공급자 사전 질문 답변 섹션
                    if (_dailyQuestions.isNotEmpty) ...[
                      _buildQuestionsSection(),
                      const SizedBox(height: 24),
                    ],

                    // 테스트 소감 입력
                    _buildFeedbackSection(),
                    const SizedBox(height: 24),

                    // v2.9.0: 버그 리포트 섹션
                    _buildBugReportSection(),
                    const SizedBox(height: 24),

                    // 스크린샷 업로드
                    _buildScreenshotSection(),
                    const SizedBox(height: 24),

                    // 제출 버튼
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  /// 미션 정보 카드
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.missionTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Day ${widget.dayNumber} 미션을 완료하고 답변, 스크린샷, 버그리포트를 제출해주세요.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// v2.9.0: 공급자 질문 답변 섹션
  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '공급자 질문 *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._dailyQuestions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q${index + 1}. $question',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _answerControllers['question_$index'],
                  maxLines: 3,
                  maxLength: 500,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    hintText: '답변을 입력해주세요',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '답변을 입력해주세요.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// v2.9.0: 테스트 소감 입력 섹션
  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '테스트 소감 *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _feedbackController,
          maxLines: 5,
          maxLength: 1000,
          enabled: !_isSubmitting,
          decoration: const InputDecoration(
            hintText: '앱을 사용하면서 느낀 점, 개선 사항, 사용 경험 등을 자유롭게 작성해주세요.',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '테스트 소감을 입력해주세요.';
            }
            if (value.trim().length < 10) {
              return '최소 10자 이상 작성해주세요.';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// v2.9.0: 버그 리포트 섹션
  Widget _buildBugReportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '버그 리포트',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bugReportController,
          maxLines: 5,
          maxLength: 1000,
          enabled: !_isSubmitting,
          decoration: const InputDecoration(
            hintText: '발견한 버그나 오류가 있다면 상세히 작성해주세요. (선택사항)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// v2.116.0: 스크린샷 섹션 (임시 안내 배너 포함)
  Widget _buildScreenshotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // v2.116.0: 임시 안내 배너
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border.all(color: Colors.orange.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ 임시 조치: Firebase Storage 장애로 업로드 실패 시 스크린샷 없이 제출 가능합니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade900,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 기존 ImageUploadWidget
        ImageUploadWidget(
          selectedImages: _selectedImages,
          onImagesChanged: (images) {
            setState(() {
              _selectedImages.clear();
              _selectedImages.addAll(images);
            });
          },
          maxImages: 5,
          emptyStateText: '미션 수행 스크린샷을 업로드해주세요 (최소 3장, 최대 5장)',
        ),
      ],
    );
  }

  /// 제출 버튼
  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _handleSubmit,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey,
      ),
      child: _isSubmitting
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isUploading
                      ? '업로드 중... ${(_uploadProgress * 100).toInt()}%'
                      : '제출 중...',
                ),
              ],
            )
          : const Text(
              '제출하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
