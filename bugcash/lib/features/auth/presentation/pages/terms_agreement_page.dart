import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/terms.dart';
import '../../domain/models/user_consent.dart';
import 'terms_detail_page.dart';

/// 약관 동의 페이지
class TermsAgreementPage extends StatefulWidget {
  const TermsAgreementPage({super.key});

  @override
  State<TermsAgreementPage> createState() => _TermsAgreementPageState();
}

class _TermsAgreementPageState extends State<TermsAgreementPage> {
  bool _allAgreed = false;
  bool _termsOfService = false;
  bool _privacyPolicy = false;
  bool _ageConfirmation = false;
  bool _marketingConsent = false;
  bool _pushNotificationConsent = false;

  /// 전체 동의 체크박스 처리
  void _handleAllAgreement(bool? value) {
    setState(() {
      _allAgreed = value ?? false;
      _termsOfService = _allAgreed;
      _privacyPolicy = _allAgreed;
      _ageConfirmation = _allAgreed;
      _marketingConsent = _allAgreed;
      _pushNotificationConsent = _allAgreed;
    });
  }

  /// 개별 체크박스 변경 시 전체 동의 상태 업데이트
  void _updateAllAgreedState() {
    setState(() {
      _allAgreed = _termsOfService &&
          _privacyPolicy &&
          _ageConfirmation &&
          _marketingConsent &&
          _pushNotificationConsent;
    });
  }

  /// 필수 동의 항목이 모두 체크되었는지 확인
  bool get _hasAllRequiredConsents =>
      _termsOfService && _privacyPolicy && _ageConfirmation;

  /// 다음 버튼 클릭
  void _handleNext() {
    if (!_hasAllRequiredConsents) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('필수 약관에 모두 동의해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final consent = UserConsent(
      termsOfService: _termsOfService,
      privacyPolicy: _privacyPolicy,
      ageConfirmation: _ageConfirmation,
      marketingConsent: _marketingConsent,
      pushNotificationConsent: _pushNotificationConsent,
      consentedAt: DateTime.now(),
      appVersion: '2.62.0', // TODO: 실제 앱 버전으로 교체
    );

    Navigator.pop(context, consent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('약관 동의'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더
                    Text(
                      '벅스리워드 서비스 이용을 위해\n약관에 동의해주세요',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '필수 약관에 동의하지 않으면 서비스를 이용할 수 없습니다.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // 전체 동의
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple[50],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.deepPurple[100]!,
                          width: 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: _allAgreed,
                        onChanged: _handleAllAgreement,
                        title: Text(
                          '전체 동의',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple[700],
                          ),
                        ),
                        subtitle: Text(
                          '선택 항목 포함',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.deepPurple[400],
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.deepPurple,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // 필수 약관
                    Text(
                      '필수 약관',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    _buildConsentItem(
                      title: '서비스 이용약관',
                      isRequired: true,
                      value: _termsOfService,
                      onChanged: (value) {
                        setState(() => _termsOfService = value ?? false);
                        _updateAllAgreedState();
                      },
                      onDetailPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsDetailPage(
                              title: '서비스 이용약관',
                              content: Terms.serviceTerms,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 8.h),

                    _buildConsentItem(
                      title: '개인정보 처리방침',
                      isRequired: true,
                      value: _privacyPolicy,
                      onChanged: (value) {
                        setState(() => _privacyPolicy = value ?? false);
                        _updateAllAgreedState();
                      },
                      onDetailPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsDetailPage(
                              title: '개인정보 처리방침',
                              content: Terms.privacyPolicy,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 8.h),

                    _buildConsentItem(
                      title: '만 14세 이상입니다',
                      isRequired: true,
                      value: _ageConfirmation,
                      onChanged: (value) {
                        setState(() => _ageConfirmation = value ?? false);
                        _updateAllAgreedState();
                      },
                      onDetailPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsDetailPage(
                              title: '만 14세 이상 확인',
                              content: Terms.ageConfirmation,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24.h),

                    // 선택 약관
                    Text(
                      '선택 약관',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    _buildConsentItem(
                      title: '마케팅 정보 수신 동의',
                      isRequired: false,
                      value: _marketingConsent,
                      onChanged: (value) {
                        setState(() => _marketingConsent = value ?? false);
                        _updateAllAgreedState();
                      },
                      onDetailPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsDetailPage(
                              title: '마케팅 정보 수신 동의',
                              content: Terms.marketingConsent,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 8.h),

                    _buildConsentItem(
                      title: '푸시 알림 수신 동의',
                      isRequired: false,
                      value: _pushNotificationConsent,
                      onChanged: (value) {
                        setState(
                            () => _pushNotificationConsent = value ?? false);
                        _updateAllAgreedState();
                      },
                      onDetailPressed: null, // 상세보기 없음
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),

            // 하단 버튼
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _hasAllRequiredConsents ? _handleNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    '다음',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 동의 항목 위젯 빌드
  Widget _buildConsentItem({
    required String title,
    required bool isRequired,
    required bool value,
    required ValueChanged<bool?> onChanged,
    VoidCallback? onDetailPressed,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.deepPurple,
          ),
          Expanded(
            child: Row(
              children: [
                if (isRequired)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      '필수',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onDetailPressed != null)
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
                size: 20.sp,
              ),
              onPressed: onDetailPressed,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
