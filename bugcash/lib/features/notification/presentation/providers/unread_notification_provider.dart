/// v2.185.1: 미읽음 알림 개수 Provider
/// StreamProvider로 실시간 미읽음 알림 개수 추적

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 특정 사용자의 미읽음 알림 개수를 실시간으로 제공
final unreadNotificationCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('user_notifications')
      .where('recipientId', isEqualTo: userId)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});
