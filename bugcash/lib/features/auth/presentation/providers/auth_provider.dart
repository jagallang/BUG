import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/hybrid_auth_service.dart';
import '../../domain/entities/user_entity.dart';

final hybridAuthServiceProvider = Provider<HybridAuthService>((ref) {
  return HybridAuthService();
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, User?>((ref) {
  return AuthStateNotifier();
});

final userDataProvider = StateNotifierProvider.family<UserDataNotifier, UserEntity?, String>((ref, uid) {
  return UserDataNotifier(uid);
});

class AuthStateNotifier extends StateNotifier<User?> {
  StreamSubscription<User?>? _authSubscription;

  AuthStateNotifier() : super(null) {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    state = HybridAuthService.currentUser;
    _authSubscription = HybridAuthService.authStateChanges().listen((user) {
      state = user;
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

class UserDataNotifier extends StateNotifier<UserEntity?> {
  final String _uid;

  UserDataNotifier(this._uid) : super(null) {
    _loadUserData();
  }

  void _loadUserData() async {
    try {
      final userData = await HybridAuthService.getUserData(_uid);
      state = userData;
    } catch (e) {
      state = null;
    }
  }

  void updateUser(UserEntity user) {
    state = user;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    HybridAuthService.authStateChanges().listen((user) async {
      if (user != null) {
        try {
          final userData = await HybridAuthService.getUserData(user.uid);
          state = state.copyWith(user: userData, isLoading: false);
        } catch (e) {
          state = state.copyWith(
            user: null,
            isLoading: false,
            errorMessage: e.toString(),
          );
        }
      } else {
        state = state.copyWith(user: null, isLoading: false);
      }
    });
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserType userType,
    required String country,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // HybridAuthService는 현재 회원가입 기능을 제공하지 않으므로
      // Firebase Auth를 직접 사용하거나 별도 구현이 필요
      throw UnimplementedError('회원가입 기능은 현재 미구현 상태입니다.');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userCredential = await HybridAuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential?.user != null) {
        final userData = await HybridAuthService.getUserData(userCredential!.user!.uid);
        state = state.copyWith(user: userData, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // HybridAuthService는 Google 로그인을 지원하지 않음
      throw UnimplementedError('Google 로그인은 현재 지원되지 않습니다.');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // HybridAuthService는 비밀번호 재설정을 지원하지 않음
      throw UnimplementedError('비밀번호 재설정은 현재 지원되지 않습니다.');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await HybridAuthService.signOut();
      state = state.copyWith(user: null, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> updateUserData(UserEntity user) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // HybridAuthService에서는 사용자 데이터 업데이트를 지원하지 않음
      throw UnimplementedError('사용자 데이터 업데이트는 현재 지원되지 않습니다.');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // HybridAuthService에서는 계정 삭제를 지원하지 않음
      throw UnimplementedError('계정 삭제는 현재 지원되지 않습니다.');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// 테스트 계정으로 직접 로그인 (백엔드 처리)
  Future<void> signInWithTestAccount(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 이메일로 테스트 계정 찾기
      final testAccount = HybridAuthService.findTestAccountByEmail(email);
      if (testAccount == null) {
        throw Exception('테스트 계정을 찾을 수 없습니다: $email');
      }

      // 테스트 계정으로 직접 로그인
      final userCredential = await HybridAuthService.signInWithTestAccount(testAccount);

      if (userCredential?.user != null) {
        final userData = await HybridAuthService.getUserData(userCredential!.user!.uid);
        state = state.copyWith(user: userData, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}