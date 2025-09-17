import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/logger.dart';
import 'app_management_page.dart';

class AppDetailPage extends ConsumerStatefulWidget {
  final ProviderAppModel app;

  const AppDetailPage({
    super.key,
    required this.app,
  });

  @override
  ConsumerState<AppDetailPage> createState() => _AppDetailPageState();
}

class _AppDetailPageState extends ConsumerState<AppDetailPage> {
  late TextEditingController _appNameController;
  late TextEditingController _appUrlController;
  late TextEditingController _descriptionController;
  late TextEditingController _announcementController;
  late TextEditingController _priceController;
  late TextEditingController _requirementsController;

  late String _selectedCategory;
  bool _hasAnnouncement = false;
  bool _isActive = true;
  bool _isLoading = false;

  final List<String> _categories = [
    'Productivity',
    'Social',
    'Entertainment',
    'Education',
    'Health & Fitness',
    'Finance',
    'Shopping',
    'Travel',
    'Food & Drink',
    'Games',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _appNameController = TextEditingController(text: widget.app.appName);
    _appUrlController = TextEditingController(text: widget.app.appUrl);
    _descriptionController = TextEditingController(text: widget.app.description);
    _selectedCategory = widget.app.category;

    // 기존 메타데이터에서 정보 가져오기
    final metadata = widget.app.metadata;
    _hasAnnouncement = metadata['hasAnnouncement'] ?? false;
    _isActive = metadata['isActive'] ?? true;
    _announcementController = TextEditingController(text: metadata['announcement'] ?? '');
    _priceController = TextEditingController(text: (metadata['price'] ?? 0).toString());
    _requirementsController = TextEditingController(text: metadata['requirements'] ?? '');
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _appUrlController.dispose();
    _descriptionController.dispose();
    _announcementController.dispose();
    _priceController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_appNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 필드를 모두 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 가격 검증
      final price = double.tryParse(_priceController.text);
      if (price == null || price < 0) {
        throw Exception('올바른 가격을 입력해주세요');
      }

      final updatedData = {
        'appName': _appNameController.text,
        'appUrl': _appUrlController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': {
          ...widget.app.metadata,
          'hasAnnouncement': _hasAnnouncement,
          'announcement': _hasAnnouncement ? _announcementController.text : '',
          'price': price,
          'requirements': _requirementsController.text,
          'isActive': _isActive,
        },
      };

      await FirebaseFirestore.instance
          .collection('provider_apps')
          .doc(widget.app.id)
          .update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('앱 정보가 성공적으로 업데이트되었습니다')),
        );
        Navigator.of(context).pop(true); // 변경사항이 있음을 알림
      }
    } catch (e) {
      AppLogger.error('Failed to update app', e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업데이트 실패: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        title: Text(
          '앱 상세 관리',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: Text(
              '저장',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppInfoSection(),
                  SizedBox(height: 24.h),
                  _buildStatusSection(),
                  SizedBox(height: 24.h),
                  _buildAnnouncementSection(),
                  SizedBox(height: 24.h),
                  _buildPricingSection(),
                  SizedBox(height: 24.h),
                  _buildRequirementsSection(),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '🎯 앱 게시 상태',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  activeColor: Colors.green[700],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              _isActive
                  ? '현재 앱이 활성화되어 테스터들에게 표시됩니다'
                  : '현재 앱이 비활성화되어 테스터들에게 표시되지 않습니다',
              style: TextStyle(
                fontSize: 14.sp,
                color: _isActive ? Colors.green[600] : Colors.red[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📱 앱 기본 정보',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _appNameController,
              decoration: InputDecoration(
                labelText: '앱 이름 *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.apps),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _appUrlController,
              decoration: InputDecoration(
                labelText: '앱 URL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.link),
              ),
            ),
            SizedBox(height: 16.h),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '앱 설명 *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '📢 앱 공지사항',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _hasAnnouncement,
                  onChanged: (value) {
                    setState(() {
                      _hasAnnouncement = value;
                      if (!value) {
                        _announcementController.clear();
                      }
                    });
                  },
                  activeColor: Colors.indigo[700],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              _hasAnnouncement
                  ? '테스터들에게 보여질 공지사항을 작성하세요'
                  : '공지사항 기능을 활성화하려면 스위치를 켜세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            if (_hasAnnouncement) ...[
              SizedBox(height: 16.h),
              TextField(
                controller: _announcementController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: '공지사항 내용',
                  hintText: '테스터들에게 전달할 중요한 정보를 입력하세요...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  prefixIcon: const Icon(Icons.announcement),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💰 단가 설정',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '테스터에게 지급할 포인트를 설정하세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '단가 (포인트) *',
                hintText: '예: 1000',
                suffix: Text(
                  'P',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[700],
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.monetization_on),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 기타 요구사항',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '테스터가 알아야 할 추가 요구사항이나 특별 지시사항을 입력하세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _requirementsController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: '요구사항',
                hintText: '예: 특정 기기에서 테스트, 특정 기능 집중 테스트 등...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.checklist),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}