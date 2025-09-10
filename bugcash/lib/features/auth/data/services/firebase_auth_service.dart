import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/domain/entities/user_entity.dart';

class FirebaseAuthService {
  // Mock 데이터 저장용 메모리 캐시
  static final Map<String, UserEntity> _mockUserCache = {};
  
  // Mock 현재 사용자
  static User? _mockCurrentUser;
  
  // Mock auth state stream controller
  static final _mockAuthController = StreamController<User?>.broadcast();
  
  // Combined auth stream
  // ignore: unused_field
  late Stream<User?> _combinedAuthStream;

  FirebaseAuthService() {
    // Mock 계정 데이터 초기화
    _initializeMockAccounts();
    
    // Mock 전용 스트림 사용
    _combinedAuthStream = _mockAuthController.stream;
    
    // 즉시 초기 상태를 null로 설정 (로그아웃 상태)
    _mockCurrentUser = null;
    _mockAuthController.add(null);
  }

  User? get currentUser {
    return _mockCurrentUser;
  }

  Stream<User?> get authStateChanges {
    // 컨트롤러에서 스트림 반환 (이미 초기값이 추가됨)
    return _mockAuthController.stream;
  }

  // Mock 계정 초기화
  void _initializeMockAccounts() {
    const mockAccounts = {
      'admin@techcorp.com': {
        'uid': 'mock_admin_001',
        'email': 'admin@techcorp.com',
        'password': 'admin123',
        'displayName': '김관리자',
        'userType': 'provider',
        'companyName': 'TechCorp Ltd.',
      },
      'provider@gamedev.com': {
        'uid': 'mock_provider_001',
        'email': 'provider@gamedev.com',
        'password': 'provider123',
        'displayName': '이공급자',
        'userType': 'provider',
        'companyName': 'GameDev Studio',
      },
      'company@fintech.com': {
        'uid': 'mock_company_001',
        'email': 'company@fintech.com',
        'password': 'company123',
        'displayName': '박기업',
        'userType': 'provider',
        'companyName': 'FinTech Solutions',
      },
      'tester1@gmail.com': {
        'uid': 'mock_tester_001',
        'email': 'tester1@gmail.com',
        'password': 'tester123',
        'displayName': '김테스터',
        'userType': 'tester',
      },
      'tester2@gmail.com': {
        'uid': 'mock_tester_002',
        'email': 'tester2@gmail.com',
        'password': 'test456',
        'displayName': '이사용자',
        'userType': 'tester',
      },
      'tester3@gmail.com': {
        'uid': 'mock_tester_003',
        'email': 'tester3@gmail.com',
        'password': 'tester789',
        'displayName': '박검증자',
        'userType': 'tester',
      },
      'tester4@gmail.com': {
        'uid': 'mock_tester_004',
        'email': 'tester4@gmail.com',
        'password': 'test999',
        'displayName': '최버그헌터',
        'userType': 'tester',
      },
      'tester5@gmail.com': {
        'uid': 'mock_tester_005',
        'email': 'tester5@gmail.com',
        'password': 'tester555',
        'displayName': '정모바일테스터',
        'userType': 'tester',
      },
      'tester6@naver.com': {
        'uid': 'mock_tester_006',
        'email': 'tester6@naver.com',
        'password': 'naver123',
        'displayName': '강웹테스터',
        'userType': 'tester',
      },
      'developer@startup.com': {
        'uid': 'mock_provider_002',
        'email': 'developer@startup.com',
        'password': 'dev123',
        'displayName': '임개발자',
        'userType': 'provider',
        'companyName': 'Startup Inc.',
      },
      'qa@enterprise.com': {
        'uid': 'mock_provider_003',
        'email': 'qa@enterprise.com',
        'password': 'qa456',
        'displayName': '황품질관리자',
        'userType': 'provider',
        'companyName': 'Enterprise Solutions',
      },
    };

    // Mock 사용자 엔티티 생성 및 캐시에 저장
    for (final account in mockAccounts.entries) {
      final accountData = account.value;
      final now = DateTime.now();
      
      final userEntity = UserEntity(
        uid: accountData['uid']!,
        email: accountData['email']!,
        displayName: accountData['displayName']!,
        photoUrl: null,
        userType: accountData['userType'] == 'provider' 
            ? UserType.provider 
            : UserType.tester,
        country: 'South Korea',
        timezone: 'Asia/Seoul',
        phoneNumber: null,
        // companyName: accountData['companyName'],
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
        lastLoginAt: now,
      );
      
      _mockUserCache[accountData['uid']!] = userEntity;
    }
  }

  Future<UserEntity?> getUserData(String uid) async {
    // Mock 캐시에서 사용자 데이터 반환
    return _mockUserCache[uid];
  }

  Stream<UserEntity?> getUserStream(String uid) {
    // Mock 캐시에 있으면 Mock 데이터를 스트림으로 반환
    if (_mockUserCache.containsKey(uid)) {
      return Stream.value(_mockUserCache[uid]);
    }
    
    // 없으면 빈 스트림 반환
    return Stream.value(null);
  }

  Future<void> updateUserData(UserEntity user) async {
    // Mock 캐시에 업데이트
    _mockUserCache[user.uid] = user.copyWith(updatedAt: DateTime.now());
  }

  // 사용자 검색 기능 추가
  Future<List<UserEntity>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final searchQuery = query.toLowerCase();
    final matchedUsers = _mockUserCache.values.where((user) {
      return user.displayName.toLowerCase().contains(searchQuery) ||
             user.email.toLowerCase().contains(searchQuery);
    }).take(limit).toList();

    // 관련도 순으로 정렬 (이름이 먼저 일치하는 것을 우선)
    matchedUsers.sort((a, b) {
      final aNameMatch = a.displayName.toLowerCase().startsWith(searchQuery);
      final bNameMatch = b.displayName.toLowerCase().startsWith(searchQuery);
      
      if (aNameMatch && !bNameMatch) return -1;
      if (!aNameMatch && bNameMatch) return 1;
      
      return a.displayName.compareTo(b.displayName);
    });

    return matchedUsers;
  }

  // 모든 사용자 목록 가져오기 (관리용)
  Future<List<UserEntity>> getAllUsers() async {
    return _mockUserCache.values.toList();
  }

  // Mock 사용자를 현재 사용자로 설정 (테스트용)
  Future<void> setMockUser(UserEntity user) async {
    // Mock user cache에 추가
    _mockUserCache[user.uid] = user;
    
    // Mock Firebase User 생성
    _mockCurrentUser = _MockUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoUrl,
    );
    
    // Auth state 업데이트
    _mockAuthController.add(_mockCurrentUser);
  }

  // Mock 로그인 메서드들
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Mock 계정 확인
    if (_isMockAccount(email, password)) {
      return await _mockSignIn(email, password);
    }
    
    // Mock 계정이 아니면 실제 Firebase 로그인 시도 (현재는 비활성화)
    throw FirebaseAuthException(
      code: 'user-not-found',
      message: 'Mock 모드에서는 테스트 계정만 사용 가능합니다.',
    );
  }

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserType userType,
    required String country,
    String? phoneNumber,
  }) async {
    // Mock 모드에서는 회원가입을 지원하지 않음
    throw FirebaseAuthException(
      code: 'operation-not-allowed',
      message: 'Mock 모드에서는 회원가입이 지원되지 않습니다.',
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    // Mock 모드에서는 Google 로그인을 지원하지 않음
    throw FirebaseAuthException(
      code: 'operation-not-allowed',
      message: 'Mock 모드에서는 Google 로그인이 지원되지 않습니다.',
    );
  }

  Future<void> signOut() async {
    _mockCurrentUser = null;
    _mockAuthController.add(null);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    // Mock 모드에서는 실제 이메일을 보내지 않음
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> deleteAccount() async {
    // Mock 모드에서는 계정 삭제를 지원하지 않음
    throw FirebaseAuthException(
      code: 'operation-not-allowed',
      message: 'Mock 모드에서는 계정 삭제가 지원되지 않습니다.',
    );
  }

  // Mock 계정 확인
  bool _isMockAccount(String email, String password) {
    const mockAccounts = {
      'admin@techcorp.com': 'admin123',
      'provider@gamedev.com': 'provider123', 
      'company@fintech.com': 'company123',
      'tester1@gmail.com': 'tester123',
      'tester2@gmail.com': 'test456',
      'tester3@gmail.com': 'tester789',
      'tester4@gmail.com': 'test999',
    };
    
    return mockAccounts[email] == password;
  }

  // Mock 로그인 실행
  Future<UserCredential?> _mockSignIn(String email, String password) async {
    const mockAccounts = {
      'admin@techcorp.com': {
        'uid': 'mock_admin_001',
        'email': 'admin@techcorp.com',
        'displayName': '김관리자',
      },
      'provider@gamedev.com': {
        'uid': 'mock_provider_001',
        'email': 'provider@gamedev.com',
        'displayName': '이공급자',
      },
      'company@fintech.com': {
        'uid': 'mock_company_001',
        'email': 'company@fintech.com',
        'displayName': '박기업',
      },
      'tester1@gmail.com': {
        'uid': 'mock_tester_001',
        'email': 'tester1@gmail.com',
        'displayName': '김테스터',
      },
      'tester2@gmail.com': {
        'uid': 'mock_tester_002',
        'email': 'tester2@gmail.com',
        'displayName': '이사용자',
      },
      'tester3@gmail.com': {
        'uid': 'mock_tester_003',
        'email': 'tester3@gmail.com',
        'displayName': '박검증자',
      },
      'tester4@gmail.com': {
        'uid': 'mock_tester_004',
        'email': 'tester4@gmail.com',
        'displayName': '최버그헌터',
      },
    };

    final userData = mockAccounts[email]!;
    
    // Mock User 생성
    final mockUser = _MockUser(
      uid: userData['uid']!,
      email: userData['email']!,
      displayName: userData['displayName']!,
      photoURL: null,
    );
    
    _mockCurrentUser = mockUser;
    _mockAuthController.add(mockUser);
    
    // UserCredential 반환
    return _MockUserCredential(user: mockUser);
  }

  // Mock 계정 목록 조회
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
}

// Mock User 클래스
class _MockUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final String? photoURL;

  _MockUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
  });

  @override
  bool get emailVerified => true;

  @override
  UserMetadata get metadata => throw UnimplementedError();

  @override
  String? get phoneNumber => null;

  @override
  List<UserInfo> get providerData => [];

  @override
  String? get refreshToken => null;

  @override
  String? get tenantId => null;

  @override
  bool get isAnonymous => false;

  @override
  Future<void> delete() => throw UnimplementedError();

  @override
  Future<String> getIdToken([bool forceRefresh = false]) => throw UnimplementedError();

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) => throw UnimplementedError();

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) => throw UnimplementedError();

  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber, [RecaptchaVerifier? applicationVerifier]) => throw UnimplementedError();

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
  Future<void> reload() => throw UnimplementedError();

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) => throw UnimplementedError();

  @override
  Future<User> unlink(String providerId) => throw UnimplementedError();

  @override
  Future<void> updateDisplayName(String? displayName) => throw UnimplementedError();

  @override
  Future<void> updateEmail(String newEmail) => throw UnimplementedError();

  @override
  Future<void> updatePassword(String newPassword) => throw UnimplementedError();

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) => throw UnimplementedError();

  @override
  Future<void> updatePhotoURL(String? photoURL) => throw UnimplementedError();

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) => throw UnimplementedError();

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) => throw UnimplementedError();

  @override
  MultiFactor get multiFactor => throw UnimplementedError();

  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) => throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) => throw UnimplementedError();
}

// Mock UserCredential 클래스
class _MockUserCredential implements UserCredential {
  @override
  final User? user;

  _MockUserCredential({required this.user});

  @override
  AdditionalUserInfo? get additionalUserInfo => null;

  @override
  AuthCredential? get credential => null;
}