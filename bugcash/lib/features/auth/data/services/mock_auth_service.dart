import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';

class MockUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  
  MockUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
  });
}

class MockAuthService {
  static final Map<String, UserEntity> _userCache = {};
  static MockUser? _currentUser;
  static final _authController = StreamController<MockUser?>.broadcast();

  MockAuthService() {
    _initializeMockData();
    _currentUser = null;
    _authController.add(null);
  }

  MockUser? get currentUser => _currentUser;

  Stream<MockUser?> get authStateChanges => _authController.stream;

  void _initializeMockData() {
    final mockAccounts = [
      {
        'uid': 'mock_admin_001',
        'email': 'admin@techcorp.com',
        'password': 'admin123',
        'displayName': '김관리자',
        'userType': 'provider',
        'companyName': 'TechCorp Ltd.',
      },
      {
        'uid': 'mock_provider_001',
        'email': 'provider@gamedev.com',
        'password': 'provider123',
        'displayName': '이공급자',
        'userType': 'provider',
        'companyName': 'GameDev Studio',
      },
      {
        'uid': 'mock_company_001',
        'email': 'company@fintech.com',
        'password': 'company123',
        'displayName': '박기업',
        'userType': 'provider',
        'companyName': 'FinTech Solutions',
      },
      {
        'uid': 'mock_tester_001',
        'email': 'tester1@gmail.com',
        'password': 'tester123',
        'displayName': '김테스터',
        'userType': 'tester',
      },
      {
        'uid': 'mock_tester_002',
        'email': 'tester2@gmail.com',
        'password': 'test456',
        'displayName': '이사용자',
        'userType': 'tester',
      },
      {
        'uid': 'mock_tester_003',
        'email': 'tester3@gmail.com',
        'password': 'tester789',
        'displayName': '박검증자',
        'userType': 'tester',
      },
      {
        'uid': 'mock_tester_004',
        'email': 'tester4@gmail.com',
        'password': 'test999',
        'displayName': '최버그헌터',
        'userType': 'tester',
      },
    ];

    final now = DateTime.now();
    
    for (final account in mockAccounts) {
      final userEntity = UserEntity(
        uid: account['uid']!,
        email: account['email']!,
        displayName: account['displayName']!,
        photoUrl: null,
        userType: account['userType'] == 'provider' 
            ? UserType.provider 
            : UserType.tester,
        country: 'South Korea',
        timezone: 'Asia/Seoul',
        phoneNumber: null,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
        lastLoginAt: now,
      );
      
      _userCache[account['uid']!] = userEntity;
    }
  }

  Future<MockUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    debugPrint('MockAuthService - signInWithEmailAndPassword called with email: $email');
    await Future.delayed(const Duration(milliseconds: 500));

    final mockCredentials = {
      'admin@techcorp.com': {'password': 'admin123', 'uid': 'mock_admin_001'},
      'provider@gamedev.com': {'password': 'provider123', 'uid': 'mock_provider_001'},
      'company@fintech.com': {'password': 'company123', 'uid': 'mock_company_001'},
      'tester1@gmail.com': {'password': 'tester123', 'uid': 'mock_tester_001'},
      'tester2@gmail.com': {'password': 'test456', 'uid': 'mock_tester_002'},
      'tester3@gmail.com': {'password': 'tester789', 'uid': 'mock_tester_003'},
      'tester4@gmail.com': {'password': 'test999', 'uid': 'mock_tester_004'},
    };

    final account = mockCredentials[email];
    if (account == null || account['password'] != password) {
      debugPrint('MockAuthService - Login failed for email: $email');
      throw Exception('잘못된 이메일 또는 비밀번호입니다.');
    }

    final userData = _userCache[account['uid']!];
    if (userData == null) {
      debugPrint('MockAuthService - User data not found for uid: ${account['uid']}');
      throw Exception('사용자 데이터를 찾을 수 없습니다.');
    }

    debugPrint('MockAuthService - Login successful for: ${userData.email}, userType: ${userData.userType}');

    final mockUser = MockUser(
      uid: userData.uid,
      email: userData.email,
      displayName: userData.displayName,
    );

    _currentUser = mockUser;
    _authController.add(mockUser);
    
    return mockUser;
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _authController.add(null);
  }

  UserEntity? getUserData(String uid) {
    return _userCache[uid];
  }

  Future<void> updateUserData(UserEntity user) async {
    _userCache[user.uid] = user.copyWith(updatedAt: DateTime.now());
  }

  static List<Map<String, String>> getMockAccountList() {
    return [
      {
        'type': '🏢 관리자',
        'name': '김관리자 (TechCorp)',
        'email': 'admin@techcorp.com',
        'password': 'admin123',
        'description': '앱 공급자 대시보드 접근',
      },
      {
        'type': '👨‍💼 앱 공급자',
        'name': '이공급자 (GameDev)',
        'email': 'provider@gamedev.com',
        'password': 'provider123',
        'description': '게임 개발사 담당자',
      },
      {
        'type': '🏭 기업 담당자',
        'name': '박기업 (FinTech)',
        'email': 'company@fintech.com',
        'password': 'company123',
        'description': '핀테크 솔루션 담당자',
      },
      {
        'type': '👤 테스터',
        'name': '김테스터',
        'email': 'tester1@gmail.com',
        'password': 'tester123',
        'description': '일반 앱 테스터',
      },
      {
        'type': '👤 테스터',
        'name': '이사용자',
        'email': 'tester2@gmail.com',
        'password': 'test456',
        'description': 'UI/UX 전문 테스터',
      },
      {
        'type': '👤 테스터',
        'name': '박검증자',
        'email': 'tester3@gmail.com',
        'password': 'tester789',
        'description': '보안 전문 테스터',
      },
      {
        'type': '👤 테스터',
        'name': '최버그헌터',
        'email': 'tester4@gmail.com',
        'password': 'test999',
        'description': '버그 헌팅 전문가',
      },
    ];
  }

  void dispose() {
    _authController.close();
  }
}