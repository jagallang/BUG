/// v2.186.0: 통합 알림 서비스
/// 미션 워크플로우 전체에서 사용하는 자동 알림 시스템

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 사용자에게 알림 전송
  ///
  /// [recipientId]: 수신자 userId
  /// [title]: 알림 제목
  /// [message]: 알림 내용
  /// [type]: 알림 타입 (missionApplied, missionApproved, daySubmitted 등)
  /// [data]: 추가 데이터 (workflowId, testerId, dayNumber 등)
  /// v2.186.15: 로깅 및 검증 강화
  static Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // v2.186.15: recipientId 상세 검증 및 로깅
      if (recipientId.isEmpty) {
        AppLogger.warning(
          '⚠️ 알림 전송 실패: recipientId가 비어있음\n'
          '   ├─ 타입: $type\n'
          '   ├─ 제목: $title\n'
          '   └─ 메시지: $message',
          'NotificationService'
        );
        return;
      }

      AppLogger.info(
        '📤 알림 전송 시작\n'
        '   ├─ 수신자 ID: $recipientId\n'
        '   ├─ 타입: $type\n'
        '   ├─ 제목: $title\n'
        '   └─ 메시지: $message',
        'NotificationService'
      );

      final notificationData = {
        'recipientId': recipientId,
        'recipientRole': 'user', // 일반 사용자 (테스터/공급자)
        'type': type,
        'title': title,
        'message': message,
        'data': data ?? {},
        'isRead': false,
        'createdAt': Timestamp.now(),
        'readAt': null,
        'sentBy': 'system', // 시스템 자동 발송
      };

      final docRef = await _firestore.collection('user_notifications').add(notificationData);

      AppLogger.info(
        '✅ 알림 전송 성공\n'
        '   ├─ 수신자: $recipientId\n'
        '   ├─ 타입: $type\n'
        '   ├─ 제목: $title\n'
        '   └─ Firestore Doc ID: ${docRef.id}',
        'NotificationService'
      );
    } catch (e, stackTrace) {
      // v2.186.15: 에러 로깅 강화 (스택 트레이스 포함)
      AppLogger.error(
        '❌ 알림 전송 실패\n'
        '   ├─ 수신자: $recipientId\n'
        '   ├─ 타입: $type\n'
        '   ├─ 제목: $title\n'
        '   ├─ 에러: $e\n'
        '   └─ StackTrace: ${stackTrace.toString().split('\n').take(3).join('\n')}',
        'NotificationService'
      );
      // 알림 전송 실패는 메인 로직을 중단시키지 않음
    }
  }

  /// 여러 수신자에게 동일한 알림 일괄 전송
  ///
  /// [recipientIds]: 수신자 userId 목록
  /// [title]: 알림 제목
  /// [message]: 알림 내용
  /// [type]: 알림 타입
  /// [data]: 추가 데이터
  static Future<void> sendBatchNotifications({
    required List<String> recipientIds,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (recipientIds.isEmpty) {
        AppLogger.warning('Cannot send batch notifications: recipientIds is empty', 'NotificationService');
        return;
      }

      final batch = _firestore.batch();
      final now = Timestamp.now();

      for (final recipientId in recipientIds) {
        if (recipientId.isEmpty) continue;

        final notificationRef = _firestore.collection('user_notifications').doc();
        batch.set(notificationRef, {
          'recipientId': recipientId,
          'recipientRole': 'user',
          'type': type,
          'title': title,
          'message': message,
          'data': data ?? {},
          'isRead': false,
          'createdAt': now,
          'readAt': null,
          'sentBy': 'system',
        });
      }

      await batch.commit();

      AppLogger.info(
        '📧 일괄 알림 전송 완료\n'
        '   ├─ 수신자 수: ${recipientIds.length}명\n'
        '   ├─ 타입: $type\n'
        '   └─ 제목: $title',
        'NotificationService'
      );
    } catch (e) {
      AppLogger.error('Failed to send batch notifications', e.toString());
    }
  }
}
