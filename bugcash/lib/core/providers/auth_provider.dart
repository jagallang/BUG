import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 현재 사용자 Provider - 자동 로그인 비활성화
final currentUserProvider = StreamProvider<User?>((ref) {
  // return FirebaseAuth.instance.authStateChanges();
  return const Stream<User?>.empty(); // 빈 스트림 반환으로 자동 로그인 방지
});

// 현재 사용자 ID Provider
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.when(
    data: (user) => user?.uid,
    loading: () => null,
    error: (_, __) => null,
  );
});

// 인증 상태 Provider
final authStateProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Firebase Auth Provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});