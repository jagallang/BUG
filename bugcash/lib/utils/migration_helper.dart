import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../features/auth/domain/entities/user_entity.dart';

class MigrationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 현재 Firestore의 사용자 데이터 구조 분석
  static Future<Map<String, dynamic>> analyzeCurrentUsers() async {
    try {
      debugPrint('🔍 사용자 데이터 구조 분석 시작...');

      final usersSnapshot = await _firestore.collection('users').get();

      Map<String, dynamic> analysis = {
        'totalUsers': usersSnapshot.docs.length,
        'newFormat': 0,
        'oldFormat': 0,
        'userTypes': <String, int>{},
        'samples': <Map<String, dynamic>>[],
      };

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();

        // 데이터 형식 분석
        if (data.containsKey('roles') && data.containsKey('primaryRole')) {
          analysis['newFormat']++;
          // 새 형식 역할 통계
          final roles = List<String>.from(data['roles'] ?? []);
          for (var role in roles) {
            analysis['userTypes'][role] = (analysis['userTypes'][role] ?? 0) + 1;
          }
        } else if (data.containsKey('userType')) {
          analysis['oldFormat']++;
          // 기존 형식 유형 통계
          final userType = data['userType'];
          analysis['userTypes'][userType] = (analysis['userTypes'][userType] ?? 0) + 1;
        }

        // 샘플 데이터 수집 (처음 5개)
        if (analysis['samples'].length < 5) {
          analysis['samples'].add({
            'id': doc.id,
            'email': data['email'],
            'userType': data['userType'],
            'roles': data['roles'],
            'primaryRole': data['primaryRole'],
            'isAdmin': data['isAdmin'],
          });
        }
      }

      debugPrint('📊 분석 완료: $analysis');
      return analysis;

    } catch (e) {
      debugPrint('❌ 분석 중 오류: $e');
      return {'error': e.toString()};
    }
  }

  /// 사용자 데이터 마이그레이션 실행
  static Future<Map<String, dynamic>> migrateUsers({bool dryRun = true}) async {
    try {
      debugPrint('🔄 사용자 데이터 마이그레이션 ${dryRun ? '시뮬레이션' : '실행'} 시작...');

      final usersSnapshot = await _firestore.collection('users').get();

      int migratedCount = 0;
      int skippedCount = 0;
      List<String> errors = [];

      for (var doc in usersSnapshot.docs) {
        try {
          final data = doc.data();
          final userId = doc.id;

          // 이미 새 형식인지 확인
          if (data.containsKey('roles') && data.containsKey('primaryRole')) {
            debugPrint('⏭️ 사용자 $userId: 이미 새 형식');
            skippedCount++;
            continue;
          }

          // 기존 userType 기반으로 새 구조 생성
          final oldUserType = data['userType'] ?? 'tester';
          final List<String> roles = [oldUserType];
          final String primaryRole = oldUserType;
          final bool isAdmin = oldUserType == 'admin';

          // 업데이트할 데이터 준비
          Map<String, dynamic> updateData = {
            'roles': roles,
            'primaryRole': primaryRole,
            'isAdmin': isAdmin,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // 역할별 기본 프로필 추가
          if (oldUserType == 'tester') {
            updateData['testerProfile'] = {
              'preferredCategories': [],
              'devices': [],
              'experience': null,
              'rating': 0.0,
              'completedTests': data['completedMissions'] ?? 0,
              'testingPreferences': {},
              'verificationStatus': 'pending',
            };
          } else if (oldUserType == 'provider') {
            updateData['providerProfile'] = {
              'companyName': null,
              'website': null,
              'businessType': null,
              'appCategories': [],
              'contactInfo': null,
              'rating': 0.0,
              'publishedApps': 0,
              'businessInfo': {},
              'verificationStatus': 'pending',
            };
          }

          if (!dryRun) {
            // 실제 업데이트 실행
            await doc.reference.update(updateData);
          }

          debugPrint('✅ 사용자 $userId ($oldUserType): 마이그레이션 ${dryRun ? '시뮬레이션' : '완료'}');
          migratedCount++;

        } catch (e) {
          final error = '사용자 ${doc.id} 마이그레이션 실패: $e';
          errors.add(error);
          debugPrint('❌ $error');
        }
      }

      final result = {
        'dryRun': dryRun,
        'totalUsers': usersSnapshot.docs.length,
        'migrated': migratedCount,
        'skipped': skippedCount,
        'errors': errors,
      };

      debugPrint('📊 마이그레이션 ${dryRun ? '시뮬레이션' : ''} 완료: $result');
      return result;

    } catch (e) {
      debugPrint('❌ 마이그레이션 중 오류: $e');
      return {'error': e.toString()};
    }
  }

  /// 마이그레이션 후 검증
  static Future<bool> verifyMigration() async {
    try {
      debugPrint('🔍 마이그레이션 결과 검증 중...');

      final usersSnapshot = await _firestore.collection('users').get();

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();

        // 새 형식 필수 필드 확인
        if (!data.containsKey('roles') || !data.containsKey('primaryRole')) {
          debugPrint('❌ 사용자 ${doc.id}: 새 형식 필드 누락');
          return false;
        }

        // UserEntity로 파싱 테스트
        try {
          UserEntity.fromFirestore(doc.id, data);
        } catch (e) {
          debugPrint('❌ 사용자 ${doc.id}: UserEntity 파싱 실패 - $e');
          return false;
        }
      }

      debugPrint('✅ 모든 사용자 데이터 검증 완료');
      return true;

    } catch (e) {
      debugPrint('❌ 검증 중 오류: $e');
      return false;
    }
  }
}