import 'package:flutter_riverpod/flutter_riverpod.dart';

// 네비게이션 상태 관리
final selectedTabProvider = StateProvider<int>((ref) => 0);

// Firebase 상태 관리 
final firebaseAvailabilityProvider = StateProvider<bool>((ref) => false);