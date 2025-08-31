import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImagePicker extends StatelessWidget {
  final String? imageUrl;
  final bool isUploading;
  final Function(File) onImageSelected;
  final VoidCallback? onImageDeleted;

  const ProfileImagePicker({
    super.key,
    this.imageUrl,
    this.isUploading = false,
    required this.onImageSelected,
    this.onImageDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE9ECEF),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: isUploading
                ? _buildLoadingIndicator()
                : imageUrl != null
                    ? _buildNetworkImage()
                    : _buildPlaceholder(),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _showImageOptions(context),
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 18.w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF007AFF),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildNetworkImage() {
    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingIndicator();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Icon(
        Icons.person,
        size: 60.w,
        color: const Color(0xFF6C757D),
      ),
    );
  }

  void _showImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              child: Text(
                '프로필 사진 변경',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.photo_camera,
                color: const Color(0xFF007AFF),
                size: 24.w,
              ),
              title: Text(
                '카메라로 촬영',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: const Color(0xFF007AFF),
                size: 24.w,
              ),
              title: Text(
                '갤러리에서 선택',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (imageUrl != null && onImageDeleted != null) ...[
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: 24.w,
                ),
                title: Text(
                  '사진 삭제',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onImageDeleted!();
                },
              ),
            ],
            ListTile(
              leading: Icon(
                Icons.close,
                color: const Color(0xFF6C757D),
                size: 24.w,
              ),
              title: Text(
                '취소',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: const Color(0xFF6C757D),
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        onImageSelected(File(image.path));
      }
    } catch (e) {
      // Handle error silently or show error message
    }
  }
}