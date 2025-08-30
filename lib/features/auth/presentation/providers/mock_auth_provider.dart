import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/mock_auth_service.dart';
import '../../domain/entities/user_entity.dart';

final mockAuthServiceProvider = Provider<MockAuthService>((ref) {
  return MockAuthService();
});

class MockAuthState {
  final MockUser? currentUser;
  final UserEntity? userData;
  final bool isLoading;
  final String? errorMessage;

  const MockAuthState({
    this.currentUser,
    this.userData,
    this.isLoading = false,
    this.errorMessage,
  });

  MockAuthState copyWith({
    MockUser? currentUser,
    UserEntity? userData,
    bool? isLoading,
    String? errorMessage,
    bool clearCurrentUser = false,
    bool clearUserData = false,
  }) {
    return MockAuthState(
      currentUser: clearCurrentUser ? null : (currentUser ?? this.currentUser),
      userData: clearUserData ? null : (userData ?? this.userData),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MockAuthNotifier extends StateNotifier<MockAuthState> {
  final MockAuthService _authService;
  StreamSubscription<MockUser?>? _authSubscription;

  MockAuthNotifier(this._authService) : super(const MockAuthState()) {
    _initializeAuth();
  }

  void _initializeAuth() {
    final currentUser = _authService.currentUser;
    final userData = currentUser != null ? _authService.getUserData(currentUser.uid) : null;
    
    state = state.copyWith(
      currentUser: currentUser,
      userData: userData,
      isLoading: false,
    );
    
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        final userData = _authService.getUserData(user.uid);
        state = state.copyWith(
          currentUser: user,
          userData: userData,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          clearCurrentUser: true,
          clearUserData: true,
          isLoading: false,
        );
      }
    });
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // 성공한 경우에도 로딩 상태를 해제하고 사용자 데이터를 업데이트
      if (user != null) {
        final userData = _authService.getUserData(user.uid);
        state = state.copyWith(
          currentUser: user,
          userData: userData,
          isLoading: false,
          errorMessage: null,
        );
      }
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
      await _authService.signOut();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authService.dispose();
    super.dispose();
  }
}

final mockAuthProvider = StateNotifierProvider<MockAuthNotifier, MockAuthState>((ref) {
  final authService = ref.read(mockAuthServiceProvider);
  return MockAuthNotifier(authService);
});