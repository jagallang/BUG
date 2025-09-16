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
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    if (kDebugMode) {
      debugPrint('🟦 AuthProvider._initializeAuthState() - 초기화 시작');
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
        final userData = await _authService.getUserData(userCredential.user!.uid);
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

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final userData = await _authService.getUserData(userCredential.user!.uid);
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
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential?.user != null) {
        final userData = await _authService.getUserData(userCredential!.user!.uid);
        state = state.copyWith(user: userData, isLoading: false);
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
      // 즉시 상태를 null로 설정
      state = state.copyWith(user: null, isLoading: false, errorMessage: null);

      // Firebase Auth 스트림 구독 취소
      await _authSubscription?.cancel();
      _authSubscription = null;

      // Firebase 로그아웃
      await _authService.signOut();

      // 추가 안전장치: Firebase Auth 강제 로그아웃
      await FirebaseAuth.instance.signOut();

      if (kDebugMode) {
        debugPrint('✅ AuthProvider.signOut() - 완료');
      }

      // 스트림 구독 재시작 (null 상태로 재설정을 위해)
      _initializeAuthState();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AuthProvider.signOut() - 실패: $e');
      }
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