import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/mission_workflow_service.dart' show missionWorkflowServiceProvider;
import '../../../../shared/widgets/image_upload_widget.dart';
import '../../../../core/utils/logger.dart';

/// 일일 미션 제출 페이지
/// 테스터가 하루 미션을 완료하고 피드백과 스크린샷을 제출하는 페이지
class DailyMissionSubmissionPage extends ConsumerStatefulWidget {
  final String workflowId;
  final int dayNumber;
  final String missionTitle;

  const DailyMissionSubmissionPage({
    super.key,
    required this.workflowId,
    required this.dayNumber,
    required this.missionTitle,
  });

  @override
  ConsumerState<DailyMissionSubmissionPage> createState() =>
      _DailyMissionSubmissionPageState();
}

class _DailyMissionSubmissionPageState
    extends ConsumerState<DailyMissionSubmissionPage> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final List<File> _selectedImages = [];

  bool _isSubmitting = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  /// 미션 제출 처리
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      _showMessage('최소 1장 이상의 스크린샷을 업로드해주세요.');
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

      // 2. Firestore에 제출 데이터 저장
      final missionService = ref.read(missionWorkflowServiceProvider);
      await missionService.submitDailyMission(
        workflowId: widget.workflowId,
        dayNumber: widget.dayNumber,
        feedback: _feedbackController.text.trim(),
        screenshots: uploadedUrls,
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 미션 정보 카드
              _buildInfoCard(),
              const SizedBox(height: 24),

              // 피드백 입력
              _buildFeedbackSection(),
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
              'Day ${widget.dayNumber} 미션을 완료하고 피드백과 스크린샷을 제출해주세요.',
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

  /// 피드백 입력 섹션
  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '피드백 *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _feedbackController,
          maxLines: 6,
          maxLength: 1000,
          enabled: !_isSubmitting,
          decoration: const InputDecoration(
            hintText: '오늘 미션을 수행하면서 발견한 버그, 개선 사항, 사용 경험 등을 자유롭게 작성해주세요.',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '피드백을 입력해주세요.';
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
      emptyStateText: '미션 수행 스크린샷을 업로드해주세요 (최대 5장)',
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
        disabledBackgroundColor: Colors.grey.shade300,
      ),
      child: _isSubmitting
          ? _buildSubmittingWidget()
          : const Text(
              '미션 제출하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  /// 제출 중 위젯 (로딩 + 진행률)
  Widget _buildSubmittingWidget() {
    return Row(
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
              ? '업로드 중... ${(_uploadProgress * 100).toStringAsFixed(0)}%'
              : '제출 중...',
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
