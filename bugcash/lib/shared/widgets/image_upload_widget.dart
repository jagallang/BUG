import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/logger.dart';

/// v2.9.0: 웹/모바일 통합 이미지 업로드 위젯
/// XFile 기반으로 웹 환경 지원
class ImageUploadWidget extends StatefulWidget {
  final List<XFile> selectedImages;
  final ValueChanged<List<XFile>> onImagesChanged;
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

  /// v2.17.1: 갤러리에서 이미지 선택 (디버깅 로그 추가)
  Future<void> _pickImages() async {
    try {
      debugPrint('🖱️ [ImageUploadWidget] _pickImages called!');
      debugPrint('   ├─ Current images: ${widget.selectedImages.length}');
      debugPrint('   ├─ Max images: ${widget.maxImages}');
      debugPrint('   ├─ Is uploading: $_isUploading');

      final remainingSlots = widget.maxImages - widget.selectedImages.length;
      debugPrint('   └─ Remaining slots: $remainingSlots');

      if (remainingSlots <= 0) {
        debugPrint('❌ [ImageUploadWidget] Max limit reached');
        _showMessage('최대 ${widget.maxImages}장까지만 선택 가능합니다.');
        return;
      }

      setState(() => _isUploading = true);
      debugPrint('📂 [ImageUploadWidget] Opening file picker...');

      // 여러 이미지 선택
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      debugPrint('✅ [ImageUploadWidget] Files selected: ${images.length}');

      if (images.isEmpty) {
        debugPrint('ℹ️ [ImageUploadWidget] No files selected (user cancelled)');
        setState(() => _isUploading = false);
        return;
      }

      // v2.9.0: 최대 개수 제한 확인
      final imagesToAdd = images.take(remainingSlots).toList();

      if (images.length > remainingSlots) {
        debugPrint('⚠️ [ImageUploadWidget] Limiting to $remainingSlots files');
        _showMessage('$remainingSlots장만 추가됩니다.');
      }

      // v2.9.0: XFile을 그대로 사용 (웹/모바일 모두 호환)
      final updatedList = [...widget.selectedImages, ...imagesToAdd];
      widget.onImagesChanged(updatedList);

      debugPrint('✅ [ImageUploadWidget] Images added: ${imagesToAdd.length}, total: ${updatedList.length}');
      AppLogger.info('Images selected: ${imagesToAdd.length} added, total: ${updatedList.length}', 'ImageUploadWidget');

    } catch (e, stackTrace) {
      debugPrint('💥 [ImageUploadWidget] Error: $e');
      debugPrint('Stack trace: $stackTrace');
      AppLogger.error('Failed to pick images: $e', 'ImageUploadWidget');
      _showMessage('이미지 선택 중 오류가 발생했습니다.');
    } finally {
      setState(() => _isUploading = false);
      debugPrint('🏁 [ImageUploadWidget] _pickImages completed');
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
        // v2.17.1: 헤더 - 버튼 항상 표시 (UI 겹침 방지)
        Row(
          children: [
            Expanded(
              child: Text(
                '스크린샷 (${widget.selectedImages.length}/${widget.maxImages})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: (widget.selectedImages.length >= widget.maxImages || _isUploading)
                  ? null
                  : _pickImages,
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate),
              label: Text(
                widget.selectedImages.length >= widget.maxImages
                    ? '최대 ${widget.maxImages}장'
                    : '이미지 추가',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                minimumSize: const Size(100, 40),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // v2.17.1: 이미지 썸네일 그리드 (빈 상태 클릭 가능)
        if (widget.selectedImages.isEmpty)
          // 빈 상태 - 클릭 가능한 영역
          InkWell(
            onTap: _isUploading ? null : _pickImages,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blue.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.blue.shade50,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 56,
                      color: Colors.blue.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '클릭하여 이미지 추가',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.emptyStateText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
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

  /// v2.9.0: 썸네일 카드 빌드 (XFile 지원)
  Widget _buildThumbnail(XFile file, int index) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        return Stack(
          children: [
            // 이미지
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                image: snapshot.hasData
                    ? DecorationImage(
                        image: MemoryImage(snapshot.data!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: snapshot.hasData
                  ? null
                  : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
                    color: Colors.black.withOpacity(0.6),
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
                  color: Colors.black.withOpacity(0.6),
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
      },
    );
  }
}
