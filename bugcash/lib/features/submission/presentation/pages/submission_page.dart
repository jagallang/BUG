import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class SubmissionPage extends StatefulWidget {
  final String missionId;
  final String appName;
  final int currentDay;
  
  const SubmissionPage({
    super.key,
    required this.missionId,
    required this.appName,
    required this.currentDay,
  });

  @override
  State<SubmissionPage> createState() => _SubmissionPageState();
}

class _SubmissionPageState extends State<SubmissionPage> {
  final _formKey = GlobalKey<FormState>();
  final _videoUrlController = TextEditingController();
  final _q1Controller = TextEditingController();
  final _q2Controller = TextEditingController();
  final _q3Controller = TextEditingController();
  final _bugReportController = TextEditingController();
  
  bool _hasFoundBug = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _videoUrlController.dispose();
    _q1Controller.dispose();
    _q2Controller.dispose();
    _q3Controller.dispose();
    _bugReportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('미션 제출'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mission Info Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.assignment,
                            color: AppColors.primary,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.appName} - Day ${widget.currentDay}',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '미션 완료 후 아래 정보를 입력해주세요',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Video URL Section
                    _SectionHeader(
                      icon: Icons.videocam,
                      title: '사용 영상 업로드',
                      isRequired: true,
                    ),
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: _videoUrlController,
                      decoration: const InputDecoration(
                        hintText: 'Google Drive 링크를 입력하세요',
                        prefixIcon: Icon(Icons.link),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '영상 링크를 입력해주세요';
                        }
                        if (!value.contains('drive.google.com')) {
                          return 'Google Drive 링크를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      AppStrings.uploadGuide,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Q&A Section
                    _SectionHeader(
                      icon: Icons.quiz,
                      title: '간단한 Q&A',
                      isRequired: true,
                    ),
                    SizedBox(height: 16.h),
                    
                    _QuestionField(
                      question: '1. 앱의 전반적인 사용감은 어떠셨나요?',
                      controller: _q1Controller,
                      hintText: '앱의 디자인, 속도, 사용성 등에 대한 의견을 자유롭게 작성해주세요',
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    _QuestionField(
                      question: '2. 가장 유용하거나 인상깊었던 기능은 무엇인가요?',
                      controller: _q2Controller,
                      hintText: '특별히 좋았던 기능이나 특징을 설명해주세요',
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    _QuestionField(
                      question: '3. 개선되었으면 하는 점이 있다면?',
                      controller: _q3Controller,
                      hintText: '불편했던 점이나 개선사항에 대한 의견을 작성해주세요',
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Bug Report Section
                    _SectionHeader(
                      icon: Icons.bug_report,
                      title: '버그 발견 보고 (선택)',
                      subtitle: '발견시 추가 +2,000P',
                    ),
                    SizedBox(height: 12.h),
                    
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            value: _hasFoundBug,
                            onChanged: (value) {
                              setState(() {
                                _hasFoundBug = value ?? false;
                                if (!_hasFoundBug) {
                                  _bugReportController.clear();
                                }
                              });
                            },
                            title: Text(
                              '버그나 문제점을 발견했습니다',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            activeColor: AppColors.primary,
                          ),
                          if (_hasFoundBug) ...[
                            Divider(height: 1.h),
                            Padding(
                              padding: EdgeInsets.all(16.w),
                              child: TextFormField(
                                controller: _bugReportController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: '발견한 버그나 문제점을 자세히 설명해주세요\n(예: 로그인 버튼을 눌러도 반응이 없음)',
                                  border: InputBorder.none,
                                ),
                                validator: _hasFoundBug ? (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '버그 내용을 입력해주세요';
                                  }
                                  return null;
                                } : null,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 32.h),
                    
                    // Reward Info
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.cashGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.cashGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.cashGreen,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '예상 적립 포인트',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  '${_hasFoundBug ? '7,000' : '5,000'} P',
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.cashGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_hasFoundBug)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                '+버그 보너스',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Submit Button
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitMission,
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            const Text('제출 중...'),
                          ],
                        )
                      : const Text('미션 제출하기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitMission() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Submit to Firebase
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('미션이 성공적으로 제출되었습니다!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('제출 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isRequired;
  
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 20.sp,
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isRequired) ...[
          SizedBox(width: 4.w),
          Text(
            '*',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        if (subtitle != null) ...[
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 6.w,
              vertical: 2.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuestionField extends StatelessWidget {
  final String question;
  final TextEditingController controller;
  final String hintText;
  
  const _QuestionField({
    required this.question,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hintText,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '답변을 입력해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }
}