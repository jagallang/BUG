import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../domain/entities/user_entity.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

final userDataProvider = FutureProvider.family<UserEntity?, String>((ref, uid) async {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return await authService.getUserData(uid);
});

final userStreamProvider = StreamProvider.family<UserEntity?, String>((ref, uid) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.getUserStream(uid);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return AuthNotifier(authService);
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
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => user.hashCode ^ isLoading.hashCode ^ errorMessage.hashCode;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  AuthNotifier(this._authService) : super(const AuthState()) {
    // Auth state 모니터링 시작
    _initializeAuthState();
  }

  void _initializeAuthState() {
    if (kDebugMode) {
      debugPrint('🟦 AuthProvider._initializeAuthState() - 초기화 시작');
    }

    // 기존 subscription이 있으면 취소
    if (_authSubscription != null) {
      if (kDebugMode) {
        debugPrint('🟦 AuthProvider._initializeAuthState() - 기존 subscription 취소');
      }
      _authSubscription?.cancel();
      _authSubscription = null;
    }

    _authSubscription = _authService.authStateChanges.listen(
      (user) async {
        if (kDebugMode) {
          debugPrint('🔍 AuthProvider - Auth state changed: user=${user?.email ?? 'null'}');
        }

        if (user != null) {
          try {
            final userData = await _authService.getUserData(user.uid);
            if (kDebugMode) {
              debugPrint('✅ AuthProvider - User data loaded: ${userData?.email}');
            }
            state = state.copyWith(user: userData, isLoading: false);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('❌ AuthProvider - Failed to load user data: $e');
            }
            state = state.copyWith(
              user: null,
              isLoading: false,
              errorMessage: e.toString(),
            );
          }
        } else {
          if (kDebugMode) {
            debugPrint('✅ AuthProvider - User logged out');
          }
          state = state.copyWith(user: null, isLoading: false);
        }
      },
      onError: (error) {
        if (kDebugMode) {
          debugPrint('❌ AuthProvider - Auth state stream error: $error');
        }
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
      },
    );
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
      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        userType: userType,
        country: country,
        phoneNumber: phoneNumber,
      );

      if (userCredential.user != null) {
        // Auth stream listener가 자동으로 사용자 데이터를 로드할 것이므로 여기서는 loading 상태만 해제
        state = state.copyWith(isLoading: false);
      }
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
    if (kDebugMode) {
      debugPrint('🔵 AuthProvider.signInWithEmailAndPassword() - 시작: $email');
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        debugPrint('🔵 AuthProvider.signInWithEmailAndPassword() - Firebase 로그인 성공: ${userCredential.user?.email}');
      }

      if (userCredential.user != null) {
        // Auth stream listener가 자동으로 사용자 데이터를 로드할 것이므로 여기서는 loading 상태만 해제
        state = state.copyWith(isLoading: false);

        if (kDebugMode) {
          debugPrint('🔵 AuthProvider.signInWithEmailAndPassword() - 완료, Auth stream이 사용자 로드 중...');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AuthProvider.signInWithEmailAndPassword() - 실패: $e');
      }

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
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential?.user != null) {
        // Auth stream listener가 자동으로 사용자 데이터를 로드할 것이므로 여기서는 loading 상태만 해제
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
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
      await _authService.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (kDebugMode) {
      debugPrint('🔴 AuthProvider.signOut() - 시작');
    }

    try {
      // Auth subscription 취소 (새로운 상태 변화 차단)
      _authSubscription?.cancel();
      _authSubscription = null;

      // 즉시 로그아웃 상태로 설정 (clearUser 플래그 사용)
      state = state.copyWith(clearUser: true, isLoading: false, errorMessage: null);

      if (kDebugMode) {
        debugPrint('🔄 AuthProvider.signOut() - 상태 즉시 초기화됨 (user: ${state.user})');
      }

      // Firebase 로그아웃 실행
      await _authService.signOut();

      // 다시 한번 확실히 상태 초기화
      state = state.copyWith(clearUser: true, isLoading: false, errorMessage: null);

      if (kDebugMode) {
        debugPrint('✅ AuthProvider.signOut() - 완료, Firebase 로그아웃 및 상태 초기화됨');
      }

      // Auth state 모니터링 재시작 (새 사용자 로그인을 위해)
      _initializeAuthState();

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AuthProvider.signOut() - 실패: $e');
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      // Auth state 모니터링 재시작 (에러 상황에서도)
      _initializeAuthState();
      rethrow;
    }
  }

  /// v2.13.2: 로컬 AuthState만 업데이트 (Firestore 미포함)
  /// RoleSelectionPage에서 역할 변경 후 즉시 반영용
  void setUser(UserEntity user) {
    state = state.copyWith(user: user, isLoading: false, errorMessage: null);
  }

  Future<void> updateUserData(UserEntity user) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authService.updateUserData(user);
      state = state.copyWith(user: user, isLoading: false);
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
      await _authService.deleteAccount();
      state = state.copyWith(user: null, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}