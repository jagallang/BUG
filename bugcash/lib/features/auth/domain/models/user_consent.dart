import 'package:cloud_firestore/cloud_firestore.dart';

/// 사용자 동의 정보 모델
class UserConsent {
  /// 서비스 이용약관 동의 (필수)
  final bool termsOfService;

  /// 개인정보 처리방침 동의 (필수)
  final bool privacyPolicy;

  /// 만 14세 이상 확인 (필수)
  final bool ageConfirmation;

  /// 마케팅 정보 수신 동의 (선택)
  final bool marketingConsent;

  /// 푸시 알림 수신 동의 (선택)
  final bool pushNotificationConsent;

  /// 동의 일시
  final DateTime consentedAt;

  /// 동의 시 IP 주소 (법적 근거)
  final String? ipAddress;

  /// 동의 시 앱 버전
  final String? appVersion;

  const UserConsent({
    required this.termsOfService,
    required this.privacyPolicy,
    required this.ageConfirmation,
    this.marketingConsent = false,
    this.pushNotificationConsent = false,
    required this.consentedAt,
    this.ipAddress,
    this.appVersion,
  });

  /// 필수 동의 항목이 모두 동의되었는지 확인
  bool get hasAllRequiredConsents =>
      termsOfService && privacyPolicy && ageConfirmation;

  /// Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'termsOfService': termsOfService,
      'privacyPolicy': privacyPolicy,
      'ageConfirmation': ageConfirmation,
      'marketingConsent': marketingConsent,
      'pushNotificationConsent': pushNotificationConsent,
      'consentedAt': Timestamp.fromDate(consentedAt),
      'ipAddress': ipAddress,
      'appVersion': appVersion,
    };
  }

  /// Firestore 문서에서 변환
  factory UserConsent.fromFirestore(Map<String, dynamic> data) {
    return UserConsent(
      termsOfService: data['termsOfService'] as bool? ?? false,
      privacyPolicy: data['privacyPolicy'] as bool? ?? false,
      ageConfirmation: data['ageConfirmation'] as bool? ?? false,
      marketingConsent: data['marketingConsent'] as bool? ?? false,
      pushNotificationConsent:
          data['pushNotificationConsent'] as bool? ?? false,
      consentedAt: (data['consentedAt'] as Timestamp).toDate(),
      ipAddress: data['ipAddress'] as String?,
      appVersion: data['appVersion'] as String?,
    );
  }

  /// 복사 생성자
  UserConsent copyWith({
    bool? termsOfService,
    bool? privacyPolicy,
    bool? ageConfirmation,
    bool? marketingConsent,
    bool? pushNotificationConsent,
    DateTime? consentedAt,
    String? ipAddress,
    String? appVersion,
  }) {
    return UserConsent(
      termsOfService: termsOfService ?? this.termsOfService,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      ageConfirmation: ageConfirmation ?? this.ageConfirmation,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      pushNotificationConsent:
          pushNotificationConsent ?? this.pushNotificationConsent,
      consentedAt: consentedAt ?? this.consentedAt,
      ipAddress: ipAddress ?? this.ipAddress,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  @override
  String toString() {
    return 'UserConsent('
        'termsOfService: $termsOfService, '
        'privacyPolicy: $privacyPolicy, '
        'ageConfirmation: $ageConfirmation, '
        'marketingConsent: $marketingConsent, '
        'pushNotificationConsent: $pushNotificationConsent, '
        'consentedAt: $consentedAt'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserConsent &&
        other.termsOfService == termsOfService &&
        other.privacyPolicy == privacyPolicy &&
        other.ageConfirmation == ageConfirmation &&
        other.marketingConsent == marketingConsent &&
        other.pushNotificationConsent == pushNotificationConsent &&
        other.consentedAt == consentedAt;
  }

  @override
  int get hashCode {
    return termsOfService.hashCode ^
        privacyPolicy.hashCode ^
        ageConfirmation.hashCode ^
        marketingConsent.hashCode ^
        pushNotificationConsent.hashCode ^
        consentedAt.hashCode;
  }
}
