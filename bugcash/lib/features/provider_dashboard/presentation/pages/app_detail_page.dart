import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/constants/app_colors.dart';
import 'app_management_page.dart';

// v2.172.0: 앱게시관리 페이지 대폭 단순화
// - 읽기 전용: 앱 등록 시 입력한 모든 정보 (이름, 카테고리, 테스터 수, 기간, 포인트 등)
// - 수정 가능: 앱 URL, 테스팅 가이드라인만 수정 가능

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
  // v2.172.0: 수정 가능한 필드만 컨트롤러 유지
  late TextEditingController _appNameController;
  late TextEditingController _appUrlController;
  late TextEditingController _testingGuidelinesController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // 수정 가능한 필드 초기화
    _appNameController = TextEditingController(text: widget.app.appName);
    _appUrlController = TextEditingController(text: widget.app.appUrl);

    final metadata = widget.app.metadata;
    _testingGuidelinesController = TextEditingController(
      text: metadata['testingGuidelines'] ?? '',
    );
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _appUrlController.dispose();
    _testingGuidelinesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    // v2.172.0: 앱 이름, URL, 가이드라인 검증
    if (_appNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('앱 이름을 입력해주세요')),
      );
      return;
    }

    if (_appUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('앱 URL을 입력해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // v2.172.0: 앱 이름, URL, 가이드라인만 업데이트
      final updatedData = {
        'appName': _appNameController.text,
        'appUrl': _appUrlController.text,
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': {
          ...widget.app.metadata,
          'testingGuidelines': _testingGuidelinesController.text,
        },
      };

      final docRef =
          FirebaseFirestore.instance.collection('projects').doc(widget.app.id);

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception('문서를 찾을 수 없습니다. ID: ${widget.app.id}');
      }

      await docRef.update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('앱 정보가 성공적으로 업데이트되었습니다')),
        );
        Navigator.of(context).pop(true);
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
        backgroundColor: AppColors.providerBluePrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppColors.providerBluePrimary.withValues(alpha: 0.3),
        title: Text(
          '앱 게시 관리',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
            letterSpacing: -0.5,
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
                  _buildReadOnlyInfoSection(),
                  SizedBox(height: 24.h),
                  _buildEditableSection(),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
    );
  }

  // v2.172.0: 읽기 전용 정보 섹션 (앱 등록 시 입력한 정보)
  Widget _buildReadOnlyInfoSection() {
    final metadata = widget.app.metadata;
    final rewards = metadata['rewards'] ?? {};

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.providerBlueDark, size: 24.sp),
                SizedBox(width: 8.w),
                Text(
                  '앱 등록 정보',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.providerBlueDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              '아래 정보는 앱 등록 시 설정되었으며 수정할 수 없습니다',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 16.h),
            Divider(),
            SizedBox(height: 16.h),

            // 앱 기본 정보
            _buildInfoRow('카테고리', widget.app.category, Icons.category),
            SizedBox(height: 12.h),
            _buildInfoRow('앱 설명', widget.app.description, Icons.description),

            SizedBox(height: 16.h),
            Divider(),
            SizedBox(height: 16.h),

            // 테스트 설정
            Row(
              children: [
                Icon(Icons.settings, color: Colors.indigo[700], size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  '테스트 설정',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(child: _buildInfoChip('테스터 수', '${widget.app.maxTesters ?? 10}명', Icons.people)),
                SizedBox(width: 8.w),
                Expanded(child: _buildInfoChip('테스트 기간', '${widget.app.testPeriodDays ?? 14}일', Icons.calendar_today)),
                SizedBox(width: 8.w),
                Expanded(child: _buildInfoChip('테스트 시간', '${widget.app.testTimeMinutes ?? 30}분', Icons.timer)),
              ],
            ),

            SizedBox(height: 16.h),
            Divider(),
            SizedBox(height: 16.h),

            // 리워드 정보
            Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.green[700], size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  '리워드 지급',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    '최종 완료 포인트',
                    '${(metadata['finalCompletionPoints'] ?? rewards['finalCompletionPoints'] ?? 0)}P',
                    Icons.check_circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _buildInfoChip(
                    '보너스 포인트',
                    '${metadata['bonusPoints'] ?? rewards['bonusPoints'] ?? 0}P',
                    Icons.card_giftcard,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // v2.172.0: 수정 가능한 섹션 (URL + 가이드라인)
  Widget _buildEditableSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: AppColors.providerBlueDark, size: 24.sp),
                SizedBox(width: 8.w),
                Text(
                  '수정 가능한 정보',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.providerBlueDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              '앱 이름, URL, 테스팅 가이드라인을 수정할 수 있습니다',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16.h),

            // 앱 이름
            TextField(
              controller: _appNameController,
              decoration: InputDecoration(
                labelText: '앱 이름 *',
                hintText: '앱 이름을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.apps),
                filled: true,
                fillColor: Colors.blue[50],
              ),
            ),
            SizedBox(height: 16.h),

            // 앱 URL
            TextField(
              controller: _appUrlController,
              decoration: InputDecoration(
                labelText: '앱 URL *',
                hintText: 'https://play.google.com/store/apps/details?id=...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.link),
                filled: true,
                fillColor: Colors.blue[50],
              ),
            ),
            SizedBox(height: 16.h),

            // 테스팅 가이드라인
            TextField(
              controller: _testingGuidelinesController,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: '테스팅 가이드라인',
                hintText: '테스터가 따라야 할 구체적인 테스팅 지침을 작성하세요\n\n예시:\n1. 앱 설치 후 회원가입 진행\n2. 모든 메뉴 탐색\n3. 주요 기능 5개 이상 테스트\n4. 발견한 버그 스크린샷과 함께 제출',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.assignment),
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.blue[50],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 헬퍼: 정보 행 (아이콘 + 라벨 + 값)
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.sp, color: Colors.grey[600]),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 헬퍼: 정보 칩 (작은 박스 형태)
  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: Colors.grey[700]),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
