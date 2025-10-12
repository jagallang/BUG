import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 일일 상호작용 모델
class DailyInteraction {
  final String id;
  final String applicationId;
  final String date;
  final int dayNumber;
  final TesterAction tester;
  final ProviderAction provider;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyInteraction({
    required this.id,
    required this.applicationId,
    required this.date,
    required this.dayNumber,
    required this.tester,
    required this.provider,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyInteraction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final testerData = data['tester'] as Map<String, dynamic>? ?? {};
    final providerData = data['provider'] as Map<String, dynamic>? ?? {};

    return DailyInteraction(
      id: doc.id,
      applicationId: data['applicationId'] ?? '',
      date: data['date'] ?? '',
      dayNumber: data['dayNumber'] ?? 1,
      tester: TesterAction.fromMap(testerData),
      provider: ProviderAction.fromMap(providerData),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'applicationId': applicationId,
      'date': date,
      'dayNumber': dayNumber,
      'tester': tester.toMap(),
      'provider': provider.toMap(),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

// 테스터 액션 모델
class TesterAction {
  final bool submitted;
  final DateTime? submittedAt;
  final String feedback;
  final List<String> screenshots;
  final List<String> bugReports;
  final int sessionDuration;
  final int? appRating;

  const TesterAction({
    this.submitted = false,
    this.submittedAt,
    this.feedback = '',
    this.screenshots = const [],
    this.bugReports = const [],
    this.sessionDuration = 0,
    this.appRating,
  });

  factory TesterAction.fromMap(Map<String, dynamic> map) {
    return TesterAction(
      submitted: map['submitted'] ?? false,
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate(),
      feedback: map['feedback'] ?? '',
      screenshots: List<String>.from(map['screenshots'] ?? []),
      bugReports: List<String>.from(map['bugReports'] ?? []),
      sessionDuration: map['sessionDuration'] ?? 0,
      appRating: map['appRating'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'submitted': submitted,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'feedback': feedback,
      'screenshots': screenshots,
      'bugReports': bugReports,
      'sessionDuration': sessionDuration,
      'appRating': appRating,
    };
  }

  TesterAction copyWith({
    bool? submitted,
    DateTime? submittedAt,
    String? feedback,
    List<String>? screenshots,
    List<String>? bugReports,
    int? sessionDuration,
    int? appRating,
  }) {
    return TesterAction(
      submitted: submitted ?? this.submitted,
      submittedAt: submittedAt ?? this.submittedAt,
      feedback: feedback ?? this.feedback,
      screenshots: screenshots ?? this.screenshots,
      bugReports: bugReports ?? this.bugReports,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      appRating: appRating ?? this.appRating,
    );
  }
}

// 공급자 액션 모델
class ProviderAction {
  final bool reviewed;
  final DateTime? reviewedAt;
  final bool approved;
  final int pointsAwarded;
  final String providerComment;
  final bool needsImprovement;

  const ProviderAction({
    this.reviewed = false,
    this.reviewedAt,
    this.approved = false,
    this.pointsAwarded = 0,
    this.providerComment = '',
    this.needsImprovement = false,
  });

  factory ProviderAction.fromMap(Map<String, dynamic> map) {
    return ProviderAction(
      reviewed: map['reviewed'] ?? false,
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      approved: map['approved'] ?? false,
      pointsAwarded: map['pointsAwarded'] ?? 0,
      providerComment: map['providerComment'] ?? '',
      needsImprovement: map['needsImprovement'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewed': reviewed,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'approved': approved,
      'pointsAwarded': pointsAwarded,
      'providerComment': providerComment,
      'needsImprovement': needsImprovement,
    };
  }

  ProviderAction copyWith({
    bool? reviewed,
    DateTime? reviewedAt,
    bool? approved,
    int? pointsAwarded,
    String? providerComment,
    bool? needsImprovement,
  }) {
    return ProviderAction(
      reviewed: reviewed ?? this.reviewed,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      approved: approved ?? this.approved,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      providerComment: providerComment ?? this.providerComment,
      needsImprovement: needsImprovement ?? this.needsImprovement,
    );
  }
}

// 일일 상호작용 StreamProvider
final dailyInteractionsStreamProvider = StreamProvider.family<List<DailyInteraction>, String>((ref, applicationId) {
  debugPrint('📅 DAILY_INTERACTION: 신청($applicationId) 일일 상호작용 조회');

  return FirebaseFirestore.instance
      .collection('daily_interactions')
      .where('applicationId', isEqualTo: applicationId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        debugPrint('📅 DAILY_INTERACTION: ${snapshot.docs.length}개 일일 상호작용 발견');

        return snapshot.docs.map((doc) => DailyInteraction.fromFirestore(doc)).toList();
      });
});

// 오늘 상호작용 Provider
final todayInteractionProvider = Provider.family<AsyncValue<DailyInteraction?>, String>((ref, applicationId) {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final interactions = ref.watch(dailyInteractionsStreamProvider(applicationId));

  return interactions.when(
    data: (interactions) {
      final todayInteraction = interactions.firstWhere(
        (interaction) => interaction.date == today,
        orElse: () => DailyInteraction(
          id: '',
          applicationId: applicationId,
          date: today,
          dayNumber: 1,
          tester: const TesterAction(),
          provider: const ProviderAction(),
          status: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      return AsyncValue.data(todayInteraction);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// 일일 상호작용 관리 StateNotifier
final dailyInteractionNotifierProvider = StateNotifierProvider<DailyInteractionNotifier, DailyInteractionState>((ref) {
  return DailyInteractionNotifier(ref);
});

class DailyInteractionState {
  final bool isLoading;
  final String? error;

  const DailyInteractionState({
    this.isLoading = false,
    this.error,
  });

  DailyInteractionState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return DailyInteractionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DailyInteractionNotifier extends StateNotifier<DailyInteractionState> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DailyInteractionNotifier(this._ref) : super(const DailyInteractionState());

  // 📝 테스터 활동 제출
  Future<void> submitTesterActivity({
    required String applicationId,
    required String date,
    required String feedback,
    required int sessionDuration,
    int? appRating,
    List<String> screenshots = const [],
    List<String> bugReports = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('📝 DAILY_INTERACTION: 테스터 활동 제출 - $applicationId ($date)');

      final documentId = '${applicationId}_$date';
      final now = DateTime.now();

      final updateData = {
        'applicationId': applicationId,
        'date': date,
        'tester.submitted': true,
        'tester.submittedAt': Timestamp.fromDate(now),
        'tester.feedback': feedback,
        'tester.sessionDuration': sessionDuration,
        'tester.appRating': appRating,
        'tester.screenshots': screenshots,
        'tester.bugReports': bugReports,
        'status': 'submitted',
        'updatedAt': Timestamp.fromDate(now),
      };

      await _firestore.collection('daily_interactions').doc(documentId).set(updateData, SetOptions(merge: true));

      debugPrint('✅ DAILY_INTERACTION: 테스터 활동 제출 성공');
      state = state.copyWith(isLoading: false);

    } catch (e) {
      debugPrint('🚨 DAILY_INTERACTION: 테스터 활동 제출 실패 - $e');
      state = state.copyWith(isLoading: false, error: '활동 제출에 실패했습니다: $e');
      rethrow;
    }
  }

  // ✅ 공급자 검토 및 승인
  Future<void> providerReviewActivity({
    required String applicationId,
    required String date,
    required bool approved,
    required int pointsAwarded,
    String providerComment = '',
    bool needsImprovement = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('✅ DAILY_INTERACTION: 공급자 검토 - $applicationId ($date) - 승인: $approved');

      final documentId = '${applicationId}_$date';
      final now = DateTime.now();

      final updateData = {
        'applicationId': applicationId,
        'date': date,
        'provider.reviewed': true,
        'provider.reviewedAt': Timestamp.fromDate(now),
        'provider.approved': approved,
        'provider.pointsAwarded': pointsAwarded,
        'provider.providerComment': providerComment,
        'provider.needsImprovement': needsImprovement,
        'status': approved ? 'approved' : 'rejected',
        'updatedAt': Timestamp.fromDate(now),
      };

      await _firestore.collection('daily_interactions').doc(documentId).set(updateData, SetOptions(merge: true));

      debugPrint('✅ DAILY_INTERACTION: 공급자 검토 완료');
      state = state.copyWith(isLoading: false);

    } catch (e) {
      debugPrint('🚨 DAILY_INTERACTION: 공급자 검토 실패 - $e');
      state = state.copyWith(isLoading: false, error: '검토 처리에 실패했습니다: $e');
      rethrow;
    }
  }

  // 📊 일일 상호작용 통계 계산
  Map<String, int> calculateInteractionStats(List<DailyInteraction> interactions) {
    return {
      'total': interactions.length,
      'submitted': interactions.where((i) => i.tester.submitted).length,
      'reviewed': interactions.where((i) => i.provider.reviewed).length,
      'approved': interactions.where((i) => i.provider.approved).length,
      'rejected': interactions.where((i) => i.provider.reviewed && !i.provider.approved).length,
      'pending': interactions.where((i) => !i.tester.submitted).length,
    };
  }
}