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

  /// 미션 제출 처리
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

    try {
      // 1. 이미지 업로드
      final storageService = StorageService();
      final uploadedUrls = <String>[];

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

      // 2. v2.9.0: 공급자 질문 답변 맵 생성
      final questionAnswers = <String, String>{};
      for (int i = 0; i < _dailyQuestions.length; i++) {
        questionAnswers[_dailyQuestions[i]] =
            _answerControllers['question_$i']!.text.trim();
      }

      // 3. Firestore에 제출 데이터 저장
      final missionService = ref.read(missionWorkflowServiceProvider);
      await missionService.submitDailyMission(
        workflowId: widget.workflowId,
        dayNumber: widget.dayNumber,
        feedback: _feedbackController.text.trim(),
        screenshots: uploadedUrls,
        bugReport: _bugReportController.text.trim(), // v2.9.0
        questionAnswers: questionAnswers, // v2.9.0
      );

      if (mounted) {
        AppLogger.info(
          'Daily mission submitted: workflow=${widget.workflowId}, day=${widget.dayNumber}',
          'DailyMissionSubmission',
        );

        // 성공 메시지 및 뒤로 가기
        _showMessage('✅ 미션이 제출되었습니다!');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop(true); // true를 반환하여 새로고침 트리거
        }
      }
    } catch (e) {
      AppLogger.error('Failed to submit mission: $e', 'DailyMissionSubmission');
      if (mounted) {
        _showMessage('제출 실패: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
          ? Center(child: CircularProgressIndicator())
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
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
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
        }).toList(),
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

  /// 스크린샷 섹션
  Widget _buildScreenshotSection() {
    return ImageUploadWidget(
      selectedImages: _selectedImages,
      onImagesChanged: (images) {
        setState(() {
          _selectedImages.clear();
          _selectedImages.addAll(images);
        });
      },
      maxImages: 5,
      emptyStateText: '미션 수행 스크린샷을 업로드해주세요 (최소 3장, 최대 5장)',
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
