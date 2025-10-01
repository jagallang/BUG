import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/logger.dart';

/// 미션 제출용 이미지 업로드 위젯
/// 최대 5장 이미지 선택 및 미리보기
class ImageUploadWidget extends StatefulWidget {
  final List<File> selectedImages;
  final ValueChanged<List<File>> onImagesChanged;
  final int maxImages;
  final String emptyStateText;

  const ImageUploadWidget({
    super.key,
    required this.selectedImages,
    required this.onImagesChanged,
    this.maxImages = 5,
    this.emptyStateText = '이미지를 추가해주세요 (최대 5장)',
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  /// 갤러리에서 이미지 선택
  Future<void> _pickImages() async {
    try {
      final remainingSlots = widget.maxImages - widget.selectedImages.length;

      if (remainingSlots <= 0) {
        _showMessage('최대 ${widget.maxImages}장까지만 선택 가능합니다.');
        return;
      }

      setState(() => _isUploading = true);

      // 여러 이미지 선택
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isEmpty) {
        setState(() => _isUploading = false);
        return;
      }

      // 최대 개수 제한 확인
      final imagesToAdd = images.take(remainingSlots).toList();

      if (images.length > remainingSlots) {
        _showMessage('${remainingSlots}장만 추가됩니다.');
      }

      // File 리스트로 변환
      final newFiles = <File>[];
      for (var xfile in imagesToAdd) {
        if (kIsWeb) {
          // 웹 환경에서는 XFile을 직접 사용 (추후 웹 대응 필요)
          AppLogger.warning('Web platform image upload needs implementation', 'ImageUploadWidget');
        } else {
          newFiles.add(File(xfile.path));
        }
      }

      // 업데이트된 리스트 전달
      final updatedList = [...widget.selectedImages, ...newFiles];
      widget.onImagesChanged(updatedList);

      AppLogger.info('Images selected: ${newFiles.length} added, total: ${updatedList.length}', 'ImageUploadWidget');

    } catch (e) {
      AppLogger.error('Failed to pick images: $e', 'ImageUploadWidget');
      _showMessage('이미지 선택 중 오류가 발생했습니다.');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// 이미지 제거
  void _removeImage(int index) {
    final updatedList = [...widget.selectedImages];
    updatedList.removeAt(index);
    widget.onImagesChanged(updatedList);

    AppLogger.info('Image removed at index $index, remaining: ${updatedList.length}', 'ImageUploadWidget');
  }

  /// 메시지 표시
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더: 타이틀 + 선택 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '스크린샷 (${widget.selectedImages.length}/${widget.maxImages})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.selectedImages.length < widget.maxImages)
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickImages,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate),
                label: const Text('이미지 추가'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // 이미지 썸네일 그리드
        if (widget.selectedImages.isEmpty)
          // 빈 상태
          Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    widget.emptyStateText,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          // 썸네일 그리드
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: widget.selectedImages.length,
            itemBuilder: (context, index) {
              final file = widget.selectedImages[index];
              return _buildThumbnail(file, index);
            },
          ),
      ],
    );
  }

  /// 썸네일 카드 빌드
  Widget _buildThumbnail(File file, int index) {
    return Stack(
      children: [
        // 이미지
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            image: DecorationImage(
              image: FileImage(file),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // 삭제 버튼
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),

        // 인덱스 표시
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
