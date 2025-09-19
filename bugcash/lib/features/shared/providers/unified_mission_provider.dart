import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/unified_mission_model.dart';

// 🎯 중앙 집중식 통합 미션 관리 Provider
// 모든 미션 관련 상태를 단일 Provider에서 관리하여 실시간 동기화 보장

// 1. 전체 미션 StreamProvider (실시간 감시)
final unifiedMissionsStreamProvider = StreamProvider<List<UnifiedMissionModel>>((ref) {
  debugPrint('🌟 UNIFIED_PROVIDER: 전체 미션 스트림 시작');

  return FirebaseFirestore.instance
      .collection('test_sessions')
      .orderBy('appliedAt', descending: true)
      .snapshots()
      .map((snapshot) {
        debugPrint('🌟 UNIFIED_PROVIDER: ${snapshot.docs.length}개 미션 데이터 수신');

        return snapshot.docs.map((doc) {
          try {
            return UnifiedMissionModel.fromFirestore(doc);
          } catch (e) {
            debugPrint('🚨 UNIFIED_PROVIDER: 데이터 파싱 오류 - ${doc.id}: $e');
            // 기본값으로 fallback
            return UnifiedMissionModel(
              id: doc.id,
              appId: doc.data()['appId'] ?? '',
              appName: doc.data()['appName'] ?? '알 수 없는 앱',
              testerId: doc.data()['testerId'] ?? '',
              testerName: doc.data()['testerName'] ?? '',
              testerEmail: doc.data()['testerEmail'] ?? '',
              providerId: doc.data()['providerId'] ?? '',
              status: doc.data()['status'] ?? 'pending',
              experience: doc.data()['experience'] ?? '',
              motivation: doc.data()['motivation'] ?? '',
              appliedAt: DateTime.now(),
            );
          }
        }).toList();
      });
});

// 2. 공급자별 미션 필터링 Provider
final providerMissionsProvider = StreamProvider.family<List<UnifiedMissionModel>, String>((ref, providerId) {
  debugPrint('🏢 UNIFIED_PROVIDER: 공급자($providerId) 미션 필터링');

  return FirebaseFirestore.instance
      .collection('test_sessions')
      .where('providerId', isEqualTo: providerId)
      .orderBy('appliedAt', descending: true)
      .snapshots()
      .map((snapshot) {
        debugPrint('🏢 UNIFIED_PROVIDER: 공급자 $providerId - ${snapshot.docs.length}개 미션 발견');

        return snapshot.docs.map((doc) => UnifiedMissionModel.fromFirestore(doc)).toList();
      });
});

// 3. 앱별 테스터 신청 Provider
final appTestersStreamProvider = StreamProvider.family<List<UnifiedMissionModel>, String>((ref, appId) {
  debugPrint('📱 UNIFIED_PROVIDER: 앱($appId) 테스터 신청 조회');
  debugPrint('🔍 QUERY_DEBUG: appId로 검색 = $appId');
  debugPrint('🔍 현재 시간: ${DateTime.now()}');

  return FirebaseFirestore.instance
      .collection('tester_applications')
      .where('appId', isEqualTo: appId)
      .snapshots()
      .map((snapshot) {
        debugPrint('📱 UNIFIED_PROVIDER: 앱 $appId - ${snapshot.docs.length}개 테스터 신청');

        if (snapshot.docs.isEmpty) {
          debugPrint('🔍 NO_RESULTS: appId "$appId"에 대한 결과 없음');

          // 🔧 다양한 변형으로 재검색 시도
          final searchVariants = [
            appId,
            'provider_app_$appId',
            appId.replaceAll('provider_app_', ''),
            '앱$appId',
            appId.replaceAll('앱', ''),
          ].toSet().toList(); // 중복 제거

          debugPrint('🔍 ALTERNATIVE_SEARCH: 다음 변형들로 검색 시도: $searchVariants');

          // 전체 컬렉션에서 샘플 확인
          FirebaseFirestore.instance
              .collection('tester_applications')
              .limit(10)
              .get()
              .then((allDocs) {
                debugPrint('🔍 COLLECTION_SAMPLE: 전체 컬렉션에 ${allDocs.docs.length}개 문서');
                for (var doc in allDocs.docs) {
                  final data = doc.data();
                  final storedAppId = data['appId']?.toString() ?? '';
                  final isMatch = searchVariants.any((variant) => storedAppId.contains(variant) || variant.contains(storedAppId));
                  debugPrint('🔍 SAMPLE_DOC: ID=${doc.id}');
                  debugPrint('🔍   - appId="${data['appId']}"');
                  debugPrint('🔍   - testerId="${data['testerId']}"');
                  debugPrint('🔍   - status="${data['status']}"');
                  debugPrint('🔍   - joinedAt="${data['joinedAt']}"');
                  debugPrint('🔍   - deviceInfo="${data['deviceInfo']}"');
                  debugPrint('🔍   - ${isMatch ? "🎯 POTENTIAL_MATCH" : "❌ NO_MATCH"}');
                  debugPrint('🔍   ---');
                }
              });
        } else {
          for (var doc in snapshot.docs) {
            final data = doc.data();
            debugPrint('📱 문서 ID: ${doc.id}');
            debugPrint('📱 저장된 appId: "${data['appId']}"');
            debugPrint('📱 테스터ID: ${data['testerId']}, 상태: ${data['status']}, 가입일: ${data['joinedAt']}');
          }
        }

        return snapshot.docs.map((doc) => UnifiedMissionModel.fromTesterApplications(doc)).toList();
      });
});

// 4. 테스터별 미션 Provider
final testerMissionsProvider = StreamProvider.family<List<UnifiedMissionModel>, String>((ref, testerId) {
  debugPrint('👤 UNIFIED_PROVIDER: 테스터($testerId) 미션 조회');

  return FirebaseFirestore.instance
      .collection('test_sessions')
      .where('testerId', isEqualTo: testerId)
      .orderBy('appliedAt', descending: true)
      .snapshots()
      .map((snapshot) {
        debugPrint('👤 UNIFIED_PROVIDER: 테스터 $testerId - ${snapshot.docs.length}개 미션');

        return snapshot.docs.map((doc) => UnifiedMissionModel.fromFirestore(doc)).toList();
      });
});

// 5. 상태별 필터링 Provider (FutureProvider로 변경)
final missionsByStatusProvider = Provider.family<AsyncValue<List<UnifiedMissionModel>>, MissionStatusFilter>((ref, status) {
  debugPrint('🏷️ UNIFIED_PROVIDER: 상태별 필터링 - $status');

  final allMissions = ref.watch(unifiedMissionsStreamProvider);

  return allMissions.when(
    data: (missions) {
      List<UnifiedMissionModel> filtered;
      switch (status) {
        case MissionStatusFilter.pending:
          filtered = missions.where((m) => m.status == 'pending').toList();
          break;
        case MissionStatusFilter.approved:
          filtered = missions.where((m) => m.status == 'approved').toList();
          break;
        case MissionStatusFilter.inProgress:
          filtered = missions.where((m) => m.status == 'in_progress').toList();
          break;
        case MissionStatusFilter.completed:
          filtered = missions.where((m) => m.status == 'completed').toList();
          break;
        case MissionStatusFilter.rejected:
          filtered = missions.where((m) => m.status == 'rejected').toList();
          break;
        case MissionStatusFilter.all:
          filtered = missions;
          break;
      }

      debugPrint('🏷️ UNIFIED_PROVIDER: $status 상태 미션 ${filtered.length}개');
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) {
      debugPrint('🚨 UNIFIED_PROVIDER: 상태별 필터링 오류 - $error');
      return AsyncValue.error(error, stack);
    },
  );
});

// 6. 통합 미션 관리 StateNotifier
final unifiedMissionNotifierProvider = StateNotifierProvider<UnifiedMissionNotifier, UnifiedMissionState>((ref) {
  return UnifiedMissionNotifier(ref);
});

// 통합 미션 상태 클래스
class UnifiedMissionState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> metadata;

  const UnifiedMissionState({
    this.isLoading = false,
    this.error,
    this.metadata = const {},
  });

  UnifiedMissionState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    return UnifiedMissionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      metadata: metadata ?? this.metadata,
    );
  }
}

// 통합 미션 관리 Notifier
class UnifiedMissionNotifier extends StateNotifier<UnifiedMissionState> {
  // ignore: unused_field
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UnifiedMissionNotifier(this._ref) : super(const UnifiedMissionState());

  // 🔄 테스터 미션 신청
  Future<void> applyForMission({
    required String appId,
    required String appName,
    required String testerId,
    required String testerName,
    required String testerEmail,
    required String providerId,
    required String experience,
    required String motivation,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('📝 UNIFIED_PROVIDER: 미션 신청 시작 - $appName by $testerName');

      final mission = UnifiedMissionModel(
        id: '', // Firestore가 자동 생성
        appId: appId,
        appName: appName,
        testerId: testerId,
        testerName: testerName,
        testerEmail: testerEmail,
        providerId: providerId,
        status: 'pending',
        experience: experience,
        motivation: motivation,
        appliedAt: DateTime.now(),
      );

      await _firestore.collection('tester_applications').add(mission.toFirestore());

      debugPrint('✅ UNIFIED_PROVIDER: 미션 신청 성공 - $appName');
      state = state.copyWith(isLoading: false);

    } catch (e) {
      debugPrint('🚨 UNIFIED_PROVIDER: 미션 신청 실패 - $e');
      state = state.copyWith(isLoading: false, error: '미션 신청에 실패했습니다: $e');
      rethrow;
    }
  }

  // ✅ 테스터 승인/거부
  Future<void> updateTesterStatus({
    required String missionId,
    required String newStatus,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('🔄 UNIFIED_PROVIDER: 테스터 상태 업데이트 - $missionId -> $newStatus');

      final updateData = {
        'status': newStatus,
        'processedAt': FieldValue.serverTimestamp(),
      };

      // 승인시 시작 시간 기록
      if (newStatus == 'approved') {
        updateData['startedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('tester_applications').doc(missionId).update(updateData);

      debugPrint('✅ UNIFIED_PROVIDER: 상태 업데이트 성공 - $missionId');
      state = state.copyWith(isLoading: false);

    } catch (e) {
      debugPrint('🚨 UNIFIED_PROVIDER: 상태 업데이트 실패 - $e');
      state = state.copyWith(isLoading: false, error: '상태 업데이트에 실패했습니다: $e');
      rethrow;
    }
  }

  // 📈 진행률 업데이트
  Future<void> updateProgress({
    required String missionId,
    required int currentDay,
    required double progressPercentage,
    required bool todayCompleted,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('📈 UNIFIED_PROVIDER: 진행률 업데이트 - $missionId: $currentDay일차, $progressPercentage%');

      final updateData = {
        'currentDay': currentDay,
        'progressPercentage': progressPercentage,
        'todayCompleted': todayCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 완료 체크
      if (progressPercentage >= 100.0) {
        updateData['status'] = 'completed';
        updateData['completedAt'] = FieldValue.serverTimestamp();
      } else if (currentDay > 0) {
        updateData['status'] = 'in_progress';
      }

      await _firestore.collection('tester_applications').doc(missionId).update(updateData);

      debugPrint('✅ UNIFIED_PROVIDER: 진행률 업데이트 성공');
      state = state.copyWith(isLoading: false);

    } catch (e) {
      debugPrint('🚨 UNIFIED_PROVIDER: 진행률 업데이트 실패 - $e');
      state = state.copyWith(isLoading: false, error: '진행률 업데이트에 실패했습니다: $e');
      rethrow;
    }
  }

  // 🗑️ 미션 삭제 (관리자용)
  Future<void> deleteMission(String missionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('🗑️ UNIFIED_PROVIDER: 미션 삭제 - $missionId');

      await _firestore.collection('tester_applications').doc(missionId).delete();

      debugPrint('✅ UNIFIED_PROVIDER: 미션 삭제 성공');
      state = state.copyWith(isLoading: false);

    } catch (e) {
      debugPrint('🚨 UNIFIED_PROVIDER: 미션 삭제 실패 - $e');
      state = state.copyWith(isLoading: false, error: '미션 삭제에 실패했습니다: $e');
      rethrow;
    }
  }

  // 🧹 잘못된 데이터 정리 (빈 appId 데이터 삭제)
  Future<void> cleanupInvalidMissions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('🧹 UNIFIED_PROVIDER: 잘못된 미션 데이터 정리 시작');

      final querySnapshot = await _firestore.collection('tester_applications').get();
      int deletedCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final appId = data['appId']?.toString() ?? '';
        final testerName = data['testerName']?.toString() ?? '';
        final testerEmail = data['testerEmail']?.toString() ?? '';

        // appId가 빈 문자열이거나 testerName/Email이 없는 경우 삭제
        if (appId.isEmpty || testerName.isEmpty || testerEmail.isEmpty) {
          debugPrint('🗑️ CLEANUP: 삭제 대상 - ID=${doc.id}, appId="$appId", tester="$testerName"');
          await doc.reference.delete();
          deletedCount++;
        }
      }

      debugPrint('✅ UNIFIED_PROVIDER: 정리 완료 - $deletedCount개 문서 삭제됨');
      state = state.copyWith(isLoading: false);

    } catch (e) {
      debugPrint('🚨 UNIFIED_PROVIDER: 데이터 정리 실패 - $e');
      state = state.copyWith(isLoading: false, error: '데이터 정리에 실패했습니다: $e');
      rethrow;
    }
  }

  // 📊 통계 계산 (캐시된 결과 반환)
  Map<String, int> calculateStats(List<UnifiedMissionModel> missions) {
    final stats = {
      'total': missions.length,
      'pending': missions.where((m) => m.status == 'pending').length,
      'approved': missions.where((m) => m.status == 'approved').length,
      'inProgress': missions.where((m) => m.status == 'in_progress').length,
      'completed': missions.where((m) => m.status == 'completed').length,
      'rejected': missions.where((m) => m.status == 'rejected').length,
    };

    debugPrint('📊 UNIFIED_PROVIDER: 통계 계산 완료 - $stats');
    return stats;
  }

  // 🔍 미션 검색
  List<UnifiedMissionModel> searchMissions(List<UnifiedMissionModel> missions, String query) {
    if (query.isEmpty) return missions;

    final lowerQuery = query.toLowerCase();
    return missions.where((mission) {
      return mission.appName.toLowerCase().contains(lowerQuery) ||
             mission.testerName.toLowerCase().contains(lowerQuery) ||
             mission.testerEmail.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

// 7. 편의 Provider들 (기존 코드 호환성을 위해)

// 테스터 대시보드용 활성 미션 Provider
final activeMissionsForTesterProvider = Provider.family<AsyncValue<List<UnifiedMissionModel>>, String>((ref, testerId) {
  final testerMissions = ref.watch(testerMissionsProvider(testerId));

  return testerMissions.when(
    data: (missions) {
      final activeMissions = missions.where((m) =>
        m.status == 'pending' ||
        m.status == 'approved' ||
        m.status == 'in_progress'
      ).toList();

      debugPrint('🎯 UNIFIED_PROVIDER: 테스터 $testerId 활성 미션 ${activeMissions.length}개');
      return AsyncValue.data(activeMissions);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// 공급자 대시보드용 대기중 신청 Provider
final pendingApplicationsForProviderProvider = Provider.family<AsyncValue<List<UnifiedMissionModel>>, String>((ref, providerId) {
  final providerMissions = ref.watch(providerMissionsProvider(providerId));

  return providerMissions.when(
    data: (missions) {
      final pendingMissions = missions.where((m) => m.status == 'pending').toList();
      debugPrint('⏳ UNIFIED_PROVIDER: 공급자 $providerId 대기중 신청 ${pendingMissions.length}개');
      return AsyncValue.data(pendingMissions);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});