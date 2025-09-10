import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../domain/entities/user_entity.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, User?>((ref) {
  final authService = ref.read(firebaseAuthServiceProvider);
  return AuthStateNotifier(authService);
});

final userDataProvider = StateNotifierProvider.family<UserDataNotifier, UserEntity?, String>((ref, uid) {
  final authService = ref.read(firebaseAuthServiceProvider);
  return UserDataNotifier(authService, uid);
});

class AuthStateNotifier extends StateNotifier<User?> {
  final FirebaseAuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  AuthStateNotifier(this._authService) : super(null) {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    state = _authService.currentUser;
    _authSubscription = _authService.authStateChanges.listen((user) {
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
  final FirebaseAuthService _authService;
  final String _uid;

  UserDataNotifier(this._authService, this._uid) : super(null) {
    _loadUserData();
  }

  void _loadUserData() async {
    try {
      final userData = await _authService.getUserData(_uid);
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
  final authService = ref.read(firebaseAuthServiceProvider);
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
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        try {
          final userData = await _authService.getUserData(user.uid);
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

      if (userCredential?.user != null) {
        final userData = await _authService.getUserData(userCredential!.user!.uid);
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
        final user = userCredential!.user!;
        
        final existingUserData = await _authService.getUserData(user.uid);
        
        if (existingUserData == null) {
          final now = DateTime.now();
          final newUser = UserEntity(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName ?? 'Anonymous',
            photoUrl: user.photoURL,
            userType: UserType.tester,
            country: 'Unknown',
            timezone: DateTime.now().timeZoneName,
            createdAt: now,
            updatedAt: now,
            lastLoginAt: now,
          );
          
          await _authService.updateUserData(newUser);
          state = state.copyWith(user: newUser, isLoading: false);
        } else {
          state = state.copyWith(user: existingUserData, isLoading: false);
        }
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
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      await _authService.signOut();
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
}