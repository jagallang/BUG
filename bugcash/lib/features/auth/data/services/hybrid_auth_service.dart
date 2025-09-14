import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';

/// Mock UserCredential (Firebase 없이 사용)
class MockUserCredential implements UserCredential {
  final TestAccount testAccount;
  late final MockUser _user;

  MockUserCredential(this.testAccount) {
    _user = MockUser(testAccount);
  }

  @override
  User? get user => _user;

  @override
  AdditionalUserInfo? get additionalUserInfo => null;

  @override
  AuthCredential? get credential => null;
}

/// Mock User (Firebase User 대신)
class MockUser implements User {
  final TestAccount testAccount;
  final String _uid;

  MockUser(this.testAccount) : _uid = 'mock_${testAccount.email.replaceAll('@', '_').replaceAll('.', '_')}';

  @override
  String get uid => _uid;

  @override
  String? get email => testAccount.email;

  @override
  String? get displayName => testAccount.displayName;

  @override
  String? get photoURL => null;

  @override
  bool get emailVerified => true;

  @override
  bool get isAnonymous => false;

  @override
  UserMetadata get metadata => MockUserMetadata();

  @override
  String? get phoneNumber => testAccount.additionalData?['phoneNumber'];

  @override
  String? get refreshToken => 'mock_refresh_token';

  @override
  String? get tenantId => null;

  @override
  List<UserInfo> get providerData => [];

  // 구현하지 않는 메서드들
  @override
  Future<void> delete() => throw UnimplementedError();

  @override
  Future<String> getIdToken([bool forceRefresh = false]) => Future.value('mock_id_token');

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) => throw UnimplementedError();

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) => throw UnimplementedError();

  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber, [RecaptchaVerifier? verifier]) => throw UnimplementedError();

  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<void> linkWithRedirect(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) => throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<void> reload() => Future.value();

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) => Future.value();

  @override
  Future<User> unlink(String providerId) => throw UnimplementedError();

  @override
  Future<void> updateDisplayName(String? displayName) => Future.value();

  @override
  Future<void> updateEmail(String newEmail) => Future.value();

  @override
  Future<void> updatePassword(String newPassword) => Future.value();

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) => Future.value();

  @override
  Future<void> updatePhotoURL(String? photoURL) => Future.value();

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) => Future.value();

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) => Future.value();

  @override
  MultiFactor get multiFactor => throw UnimplementedError();

  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) => throw UnimplementedError();
}

/// Mock UserMetadata
class MockUserMetadata implements UserMetadata {
  @override
  DateTime? get creationTime => DateTime.now().subtract(Duration(days: 30));

  @override
  DateTime? get lastSignInTime => DateTime.now();
}

/// 테스트 계정 정보
class TestAccount {
  final String email;
  final String password;
  final String displayName;
  final UserType userType;
  final Map<String, dynamic>? additionalData;

  TestAccount({
    required this.email,
    required this.password,
    required this.displayName,
    required this.userType,
    this.additionalData,
  });
}

/// Firebase Auth와 Mock 시스템을 통합한 하이브리드 인증 서비스
class HybridAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 테스트 계정 목록 (README.md와 동일)
  static final List<TestAccount> _testAccounts = [
    // Provider (앱 공급자) 계정들
    TestAccount(
      email: 'admin@techcorp.com',
      password: 'admin123',
      displayName: '김관리자',
      userType: UserType.provider,
      additionalData: {
        'companyName': 'TechCorp Ltd.',
        'role': '관리자',
      },
    ),
    TestAccount(
      email: 'provider@gamedev.com',
      password: 'provider123',
      displayName: '이공급자',
      userType: UserType.provider,
      additionalData: {
        'companyName': 'GameDev Studio',
        'role': '개발팀',
      },
    ),
    TestAccount(
      email: 'company@fintech.com',
      password: 'company123',
      displayName: '박기업',
      userType: UserType.provider,
      additionalData: {
        'companyName': 'FinTech Solutions',
        'role': '기업',
      },
    ),
    TestAccount(
      email: 'developer@startup.com',
      password: 'dev123',
      displayName: '최개발자',
      userType: UserType.provider,
      additionalData: {
        'companyName': 'Startup Inc.',
        'role': '개발자',
      },
    ),
    TestAccount(
      email: 'qa@enterprise.com',
      password: 'qa456',
      displayName: '정QA',
      userType: UserType.provider,
      additionalData: {
        'companyName': 'Enterprise Solutions',
        'role': 'QA',
      },
    ),

    // Tester (테스터) 계정들
    TestAccount(
      email: 'tester1@gmail.com',
      password: 'tester123',
      displayName: '김테스터',
      userType: UserType.tester,
      additionalData: {
        'specialization': '일반 앱 테스터',
      },
    ),
    TestAccount(
      email: 'tester2@gmail.com',
      password: 'test456',
      displayName: '이사용자',
      userType: UserType.tester,
      additionalData: {
        'specialization': 'UI/UX 전문 테스터',
      },
    ),
    TestAccount(
      email: 'tester3@gmail.com',
      password: 'tester789',
      displayName: '박검증자',
      userType: UserType.tester,
      additionalData: {
        'specialization': '보안 전문 테스터',
      },
    ),
    TestAccount(
      email: 'tester4@gmail.com',
      password: 'test999',
      displayName: '최버그헌터',
      userType: UserType.tester,
      additionalData: {
        'specialization': '버그 헌팅 전문가',
      },
    ),
    TestAccount(
      email: 'tester5@gmail.com',
      password: 'tester555',
      displayName: '정모바일테스터',
      userType: UserType.tester,
      additionalData: {
        'specialization': '모바일 앱 전문',
      },
    ),
    TestAccount(
      email: 'tester6@naver.com',
      password: 'naver123',
      displayName: '강웹테스터',
      userType: UserType.tester,
      additionalData: {
        'specialization': '웹 애플리케이션 전문',
      },
    ),
  ];

  /// 현재 사용자 스트림
  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// 현재 사용자 가져오기
  static User? get currentUser => _auth.currentUser;

  /// 이메일/비밀번호로 로그인
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Firebase 설정 확인: CONFIGURATION_NOT_FOUND 오류가 있으면 Mock 모드로 전환
      if (await _shouldUseMockMode()) {
        return await _signInWithMockAccount(email, password);
      }

      // 1. 먼저 실제 Firebase Auth로 로그인 시도
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (kDebugMode) {
          debugPrint('✅ Firebase Auth 로그인 성공: $email');
        }
        return credential;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Firebase Auth 로그인 실패, Mock 계정으로 시도: ${e.toString()}');
        }

        // CONFIGURATION_NOT_FOUND 오류인 경우 Mock 모드로 전환
        if (e.toString().contains('CONFIGURATION_NOT_FOUND')) {
          return await _signInWithMockAccount(email, password);
        }
      }

      // 2. Firebase Auth 실패 시 테스트 계정인지 확인
      final testAccount = _testAccounts.firstWhere(
        (account) => account.email == email && account.password == password,
        orElse: () => throw Exception('테스트 계정을 찾을 수 없습니다.'),
      );

      // 3. 테스트 계정을 Firebase Auth에 자동 생성
      final credential = await _createTestAccountInFirebase(testAccount);

      if (kDebugMode) {
        debugPrint('✅ 테스트 계정 자동 생성 및 로그인 성공: $email');
      }

      return credential;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 로그인 실패: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Firebase 설정 문제가 있는지 확인
  static Future<bool> _shouldUseMockMode() async {
    try {
      // 간단한 Firebase 연결 테스트
      await _auth.authStateChanges().first.timeout(Duration(seconds: 2));
      return false;
    } catch (e) {
      if (e.toString().contains('CONFIGURATION_NOT_FOUND')) {
        if (kDebugMode) {
          debugPrint('🔧 Firebase 설정 오류 감지, Mock 모드로 전환: ${e.toString()}');
        }
        return true;
      }
      return false;
    }
  }

  /// Mock 계정으로 로그인 (Firebase 없이)
  static Future<UserCredential?> _signInWithMockAccount(String email, String password) async {
    try {
      // 테스트 계정 확인
      final testAccount = _testAccounts.firstWhere(
        (account) => account.email == email && account.password == password,
        orElse: () => throw Exception('테스트 계정을 찾을 수 없습니다: $email'),
      );

      if (kDebugMode) {
        debugPrint('🎭 Mock 모드로 로그인 성공: ${testAccount.email} (${testAccount.displayName})');
      }

      // Mock 사용자 객체 생성 (Firebase User 대신)
      return MockUserCredential(testAccount);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Mock 로그인 실패: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// 테스트 계정을 Firebase Auth에 자동 생성
  static Future<UserCredential> _createTestAccountInFirebase(TestAccount testAccount) async {
    try {
      // Firebase Auth에 사용자 생성
      final credential = await _auth.createUserWithEmailAndPassword(
        email: testAccount.email,
        password: testAccount.password,
      );

      // 사용자 프로필 업데이트
      await credential.user?.updateDisplayName(testAccount.displayName);

      // Firestore에 사용자 데이터 저장
      await _createUserProfile(credential.user!, testAccount);

      return credential;
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        // 계정이 이미 존재하는 경우 로그인 시도
        return await _auth.signInWithEmailAndPassword(
          email: testAccount.email,
          password: testAccount.password,
        );
      }
      rethrow;
    }
  }

  /// Firestore에 사용자 프로필 생성
  static Future<void> _createUserProfile(User user, TestAccount testAccount) async {
    final now = FieldValue.serverTimestamp();

    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': testAccount.displayName,
      'userType': testAccount.userType.toString().split('.').last,
      'createdAt': now,
      'lastLoginAt': now,
      'isTestAccount': true, // 테스트 계정임을 표시
    };

    // 역할별 추가 데이터
    if (testAccount.userType == UserType.provider) {
      userData.addAll({
        'companyName': testAccount.additionalData?['companyName'] ?? 'Unknown Company',
        'role': testAccount.additionalData?['role'] ?? 'Developer',
        'approvedApps': 0,
        'totalTesters': 0,
      });
    } else if (testAccount.userType == UserType.tester) {
      userData.addAll({
        'specialization': testAccount.additionalData?['specialization'] ?? '일반 테스터',
        'completedMissions': 0,
        'totalPoints': 0,
        'rating': 5.0,
        'experienceYears': 1,
      });
    }

    await _firestore.collection('users').doc(user.uid).set(userData);
  }

  /// Firestore에서 사용자 데이터 가져오기
  static Future<UserEntity?> getUserData(String uid) async {
    try {
      // Mock 사용자인지 확인
      if (uid.startsWith('mock_')) {
        return await _getMockUserData(uid);
      }

      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      final now = DateTime.now();
      return UserEntity(
        uid: uid,
        email: data['email'] ?? '',
        displayName: data['displayName'] ?? '',
        photoUrl: data['photoUrl'],
        userType: _parseUserType(data['userType'] ?? 'tester'),
        country: data['country'] ?? 'KR',
        timezone: data['timezone'] ?? 'Asia/Seoul',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? now,
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? now,
        lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate() ?? now,
        points: data['totalPoints'] ?? 0,
        completedMissions: data['completedMissions'] ?? 0,
        level: data['level'] ?? 1,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 사용자 데이터 조회 실패: $e');
      }
      return null;
    }
  }

  /// Mock 사용자 데이터 생성
  static Future<UserEntity?> _getMockUserData(String uid) async {
    try {
      // UID에서 이메일 복원
      final email = uid.replaceFirst('mock_', '').replaceAll('_', '.');
      final emailWithAt = email.replaceFirst('_', '@');

      // 해당 테스트 계정 찾기
      final testAccount = _testAccounts.firstWhere(
        (account) => account.email.contains(emailWithAt.split('_')[0]),
        orElse: () => _testAccounts.first,
      );

      final now = DateTime.now();
      return UserEntity(
        uid: uid,
        email: testAccount.email,
        displayName: testAccount.displayName,
        photoUrl: null,
        userType: testAccount.userType,
        country: 'KR',
        timezone: 'Asia/Seoul',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
        lastLoginAt: now,
        points: testAccount.userType == UserType.tester ? 1500 : 0,
        completedMissions: testAccount.userType == UserType.tester ? 3 : 0,
        level: testAccount.userType == UserType.tester ? 2 : 1,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Mock 사용자 데이터 생성 실패: $e');
      }
      return null;
    }
  }

  /// 문자열을 UserType으로 변환
  static UserType _parseUserType(String userTypeString) {
    switch (userTypeString.toLowerCase()) {
      case 'provider':
        return UserType.provider;
      case 'admin':
        return UserType.admin;
      case 'tester':
      default:
        return UserType.tester;
    }
  }

  /// 로그아웃
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 테스트 계정 목록 가져오기
  static List<TestAccount> get testAccounts => List.unmodifiable(_testAccounts);

  /// 특정 이메일이 테스트 계정인지 확인
  static bool isTestAccount(String email) {
    return _testAccounts.any((account) => account.email == email);
  }

  /// 테스트 계정으로 직접 로그인 (백엔드 처리)
  static Future<UserCredential?> signInWithTestAccount(TestAccount testAccount) async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 테스트 계정으로 직접 로그인 시작: ${testAccount.email}');
      }

      // HybridAuthService의 기존 로그인 로직을 재사용
      return await signInWithEmailAndPassword(
        email: testAccount.email,
        password: testAccount.password,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 테스트 계정 직접 로그인 실패: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// 이메일로 테스트 계정 찾기
  static TestAccount? findTestAccountByEmail(String email) {
    try {
      return _testAccounts.firstWhere((account) => account.email == email);
    } catch (e) {
      return null;
    }
  }
}