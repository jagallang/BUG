import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class AppDeletionDialog extends StatefulWidget {
  final String appName;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const AppDeletionDialog({
    super.key,
    required this.appName,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  State<AppDeletionDialog> createState() => _AppDeletionDialogState();
}

class _AppDeletionDialogState extends State<AppDeletionDialog> {
  final TextEditingController _confirmController = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(_checkCanDelete);
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  void _checkCanDelete() {
    final canDelete = _confirmController.text.trim() == widget.appName;
    if (_canDelete != canDelete) {
      setState(() {
        _canDelete = canDelete;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.red,
            size: 24.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            '앱 삭제 확인',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이 작업은 되돌릴 수 없습니다. 다음 앱을 영구적으로 삭제하시겠습니까?',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              widget.appName,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            '확인하려면 앱 이름을 정확히 입력해주세요:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _confirmController,
            decoration: InputDecoration(
              hintText: widget.appName,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14.sp,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: _canDelete ? Colors.red : AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 12.h,
              ),
            ),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (widget.onCancel != null) {
              widget.onCancel!();
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Text(
            '취소',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _canDelete
              ? () {
                  Navigator.of(context).pop();
                  widget.onConfirm();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.grey[500],
            padding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 12.h,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            '삭제',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}