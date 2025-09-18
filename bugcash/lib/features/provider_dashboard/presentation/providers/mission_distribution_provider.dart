import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/mission_model.dart';
import '../../../../core/utils/logger.dart';

// Mission distribution state
class MissionDistributionState {
  final bool isLoading;
  final String? error;
  final List<TesterRecommendation> recommendations;
  final DistributionStrategy strategy;
  final Map<String, double> performanceMetrics;

  const MissionDistributionState({
    this.isLoading = false,
    this.error,
    this.recommendations = const [],
    this.strategy = DistributionStrategy.balanced,
    this.performanceMetrics = const {},
  });

  MissionDistributionState copyWith({
    bool? isLoading,
    String? error,
    List<TesterRecommendation>? recommendations,
    DistributionStrategy? strategy,
    Map<String, double>? performanceMetrics,
  }) {
    return MissionDistributionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      recommendations: recommendations ?? this.recommendations,
      strategy: strategy ?? this.strategy,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
    );
  }
}

enum DistributionStrategy {
  balanced,      // 균형잡힌 분배
  performance,   // 성능 기반
  experience,    // 경험 기반
  availability,  // 가용성 기반
  diversity,     // 다양성 기반
}

// Mission distribution notifier
class MissionDistributionNotifier extends StateNotifier<MissionDistributionState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MissionDistributionNotifier() : super(const MissionDistributionState());

  // Generate tester recommendations for a mission
  Future<void> generateRecommendations({
    required String missionId,
    required Map<String, dynamic> missionData,
    DistributionStrategy? strategy,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final distributionStrategy = strategy ?? state.strategy;
      
      // Step 1: Get available testers
      final availableTesters = await _getAvailableTesters();
      
      // Step 2: Analyze mission requirements
      final requirements = _analyzeMissionRequirements(missionData);
      
      // Step 3: Calculate compatibility scores
      final compatibilityScores = await _calculateCompatibilityScores(
        availableTesters,
        requirements,
        distributionStrategy,
      );
      
      // Step 4: Generate recommendations
      final recommendations = _generateRecommendations(
        compatibilityScores,
        requirements,
        distributionStrategy,
      );
      
      // Step 5: Calculate performance metrics
      final metrics = _calculatePerformanceMetrics(recommendations);

      state = state.copyWith(
        isLoading: false,
        recommendations: recommendations,
        strategy: distributionStrategy,
        performanceMetrics: metrics,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Update distribution strategy
  void updateStrategy(DistributionStrategy strategy) {
    state = state.copyWith(strategy: strategy);
  }

  // Get available testers from Firestore
  Future<List<TesterProfile>> _getAvailableTesters() async {
    try {
      final querySnapshot = await _firestore
          .collection('testers')
          .where('status', isEqualTo: 'active')
          .limit(50)
          .get();

      final List<TesterProfile> testers = [];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        // Get tester stats
        final statsDoc = await _firestore
            .collection('testers')
            .doc(doc.id)
            .collection('stats')
            .doc('summary')
            .get();

        final stats = statsDoc.data() ?? {};

        testers.add(TesterProfile(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          level: _parseTesterLevel(data['level'] ?? 'beginner'),
          skills: List<String>.from(data['skills'] ?? []),
          averageRating: (stats['averageRating'] ?? 0.0).toDouble(),
          completedMissions: stats['completedMissions'] ?? 0,
          successRate: (stats['successRate'] ?? 0.0).toDouble(),
          avgResponseTime: (stats['avgResponseTime'] ?? 0.0).toDouble(),
          lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          preferredCategories: List<String>.from(data['preferredCategories'] ?? []),
          deviceTypes: List<String>.from(data['deviceTypes'] ?? []),
          availabilityScore: (stats['availabilityScore'] ?? 0.0).toDouble(),
          qualityScore: (stats['qualityScore'] ?? 0.0).toDouble(),
          speedScore: (stats['speedScore'] ?? 0.0).toDouble(),
        ));
      }

      return testers;
    } catch (e) {
      AppLogger.error('Error getting testers', 'MissionDistribution', e);
      return [];
    }
  }

  TesterLevel _parseTesterLevel(String level) {
    switch (level.toLowerCase()) {
      case 'expert':
        return TesterLevel.expert;
      case 'advanced':
        return TesterLevel.advanced;
      case 'intermediate':
        return TesterLevel.intermediate;
      case 'beginner':
      default:
        return TesterLevel.beginner;
    }
  }

  // Analyze mission requirements
  MissionRequirements _analyzeMissionRequirements(Map<String, dynamic> missionData) {
    final type = missionData['type'] as MissionType;
    final complexity = missionData['complexity'] as MissionComplexity;
    final requiredSkills = List<String>.from(missionData['requiredSkills'] ?? []);
    final estimatedMinutes = missionData['estimatedMinutes'] as int? ?? 30;
    final maxParticipants = missionData['maxParticipants'] as int? ?? 10;
    
    return MissionRequirements(
      type: type,
      complexity: complexity,
      requiredSkills: requiredSkills,
      estimatedMinutes: estimatedMinutes,
      maxParticipants: maxParticipants,
      urgencyLevel: _calculateUrgencyLevel(missionData),
      qualityThreshold: _calculateQualityThreshold(complexity),
      diversityNeeded: _assessDiversityNeeds(type),
    );
  }

  // Calculate compatibility scores between testers and mission
  Future<Map<String, double>> _calculateCompatibilityScores(
    List<TesterProfile> testers,
    MissionRequirements requirements,
    DistributionStrategy strategy,
  ) async {
    final Map<String, double> scores = {};

    for (final tester in testers) {
      double score = 0.0;
      
      switch (strategy) {
        case DistributionStrategy.balanced:
          score = _calculateBalancedScore(tester, requirements);
          break;
        case DistributionStrategy.performance:
          score = _calculatePerformanceScore(tester, requirements);
          break;
        case DistributionStrategy.experience:
          score = _calculateExperienceScore(tester, requirements);
          break;
        case DistributionStrategy.availability:
          score = _calculateAvailabilityScore(tester, requirements);
          break;
        case DistributionStrategy.diversity:
          score = _calculateDiversityScore(tester, requirements);
          break;
      }
      
      scores[tester.id] = score.clamp(0.0, 1.0);
    }

    return scores;
  }

  // Generate final recommendations
  List<TesterRecommendation> _generateRecommendations(
    Map<String, double> compatibilityScores,
    MissionRequirements requirements,
    DistributionStrategy strategy,
  ) {
    final sortedEntries = compatibilityScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final recommendations = <TesterRecommendation>[];
    
    for (final entry in sortedEntries.take(requirements.maxParticipants * 2)) {
      final testerId = entry.key;
      final score = entry.value;
      
      final confidence = _calculateConfidence(score, strategy);
      final estimatedCompletionTime = _estimateCompletionTime(testerId, requirements);
      final qualityPrediction = _predictQuality(testerId, requirements);
      
      recommendations.add(TesterRecommendation(
        testerId: testerId,
        compatibilityScore: score,
        confidence: confidence,
        estimatedCompletionTime: estimatedCompletionTime,
        qualityPrediction: qualityPrediction,
        recommendationReason: _generateRecommendationReason(testerId, score, strategy),
        riskFactors: _identifyRiskFactors(testerId, requirements),
      ));
    }

    return recommendations;
  }

  // Scoring algorithms
  double _calculateBalancedScore(TesterProfile tester, MissionRequirements requirements) {
    double score = 0.0;
    
    // Skill match (30%)
    final skillMatch = _calculateSkillMatch(tester.skills, requirements.requiredSkills);
    score += skillMatch * 0.3;
    
    // Experience level (25%)
    final experienceMatch = _calculateExperienceMatch(tester.level, requirements.complexity);
    score += experienceMatch * 0.25;
    
    // Quality score (20%)
    score += tester.qualityScore * 0.2;
    
    // Availability (15%)
    score += tester.availabilityScore * 0.15;
    
    // Speed (10%)
    score += tester.speedScore * 0.1;
    
    return score;
  }

  double _calculatePerformanceScore(TesterProfile tester, MissionRequirements requirements) {
    double score = 0.0;
    
    // Quality heavily weighted
    score += tester.qualityScore * 0.4;
    score += tester.successRate * 0.3;
    score += (tester.averageRating / 5.0) * 0.2;
    
    // Skill match
    final skillMatch = _calculateSkillMatch(tester.skills, requirements.requiredSkills);
    score += skillMatch * 0.1;
    
    return score;
  }

  double _calculateExperienceScore(TesterProfile tester, MissionRequirements requirements) {
    double score = 0.0;
    
    // Experience heavily weighted
    final experienceScore = (tester.completedMissions / 200.0).clamp(0.0, 1.0);
    score += experienceScore * 0.4;
    
    final experienceMatch = _calculateExperienceMatch(tester.level, requirements.complexity);
    score += experienceMatch * 0.3;
    
    // Quality and skill
    score += tester.qualityScore * 0.2;
    final skillMatch = _calculateSkillMatch(tester.skills, requirements.requiredSkills);
    score += skillMatch * 0.1;
    
    return score;
  }

  double _calculateAvailabilityScore(TesterProfile tester, MissionRequirements requirements) {
    double score = 0.0;
    
    // Availability heavily weighted
    score += tester.availabilityScore * 0.5;
    
    // Response time (faster is better)
    final responseScore = 1.0 - (tester.avgResponseTime / 24.0).clamp(0.0, 1.0);
    score += responseScore * 0.3;
    
    // Recent activity
    final hoursSinceActive = DateTime.now().difference(tester.lastActiveAt).inHours;
    final recentActivityScore = (1.0 - (hoursSinceActive / 168.0)).clamp(0.0, 1.0); // 1 week
    score += recentActivityScore * 0.2;
    
    return score;
  }

  double _calculateDiversityScore(TesterProfile tester, MissionRequirements requirements) {
    // This would be more complex in real implementation,
    // considering current team composition
    double score = 0.0;
    
    // Device diversity
    final deviceDiversityScore = tester.deviceTypes.length / 3.0; // Assuming max 3 types
    score += deviceDiversityScore * 0.3;
    
    // Skill diversity
    final skillDiversityScore = tester.skills.length / 10.0; // Assuming max 10 skills
    score += skillDiversityScore * 0.3;
    
    // Level diversity (intermediate levels preferred for diversity)
    final levelDiversityScore = tester.level == TesterLevel.intermediate ? 1.0 : 0.7;
    score += levelDiversityScore * 0.2;
    
    // Base quality
    score += tester.qualityScore * 0.2;
    
    return score;
  }

  // Helper scoring methods
  double _calculateSkillMatch(List<String> testerSkills, List<String> requiredSkills) {
    if (requiredSkills.isEmpty) return 1.0;
    
    int matches = 0;
    for (final skill in requiredSkills) {
      if (testerSkills.any((ts) => ts.toLowerCase().contains(skill.toLowerCase()))) {
        matches++;
      }
    }
    
    return matches / requiredSkills.length;
  }

  double _calculateExperienceMatch(TesterLevel testerLevel, MissionComplexity complexity) {
    final levelMap = {
      TesterLevel.beginner: 1,
      TesterLevel.intermediate: 2,
      TesterLevel.advanced: 3,
      TesterLevel.expert: 4,
    };
    
    final complexityMap = {
      MissionComplexity.easy: 1,
      MissionComplexity.medium: 2,
      MissionComplexity.hard: 3,
      MissionComplexity.expert: 4,
    };
    
    final testerValue = levelMap[testerLevel] ?? 1;
    final requiredValue = complexityMap[complexity] ?? 2;
    
    // Perfect match gets 1.0, one level difference gets 0.8, etc.
    final difference = (testerValue - requiredValue).abs();
    return (1.0 - (difference * 0.2)).clamp(0.0, 1.0);
  }

  // Utility methods
  double _calculateUrgencyLevel(Map<String, dynamic> missionData) {
    final priority = missionData['priority'] as MissionPriority? ?? MissionPriority.medium;
    final deadline = missionData['deadline'] as DateTime?;
    
    double urgency = 0.5; // Default medium urgency
    
    switch (priority) {
      case MissionPriority.low:
        urgency = 0.2;
        break;
      case MissionPriority.medium:
        urgency = 0.5;
        break;
      case MissionPriority.high:
        urgency = 0.8;
        break;
      case MissionPriority.urgent:
        urgency = 1.0;
        break;
    }
    
    if (deadline != null) {
      final hoursUntilDeadline = deadline.difference(DateTime.now()).inHours;
      if (hoursUntilDeadline < 24) {
        urgency = 1.0;
      } else if (hoursUntilDeadline < 72) {
        urgency = (urgency + 0.3).clamp(0.0, 1.0);
      }
    }
    
    return urgency;
  }

  double _calculateQualityThreshold(MissionComplexity complexity) {
    switch (complexity) {
      case MissionComplexity.easy:
        return 0.6;
      case MissionComplexity.medium:
        return 0.75;
      case MissionComplexity.hard:
        return 0.85;
      case MissionComplexity.expert:
        return 0.95;
    }
  }

  bool _assessDiversityNeeds(MissionType type) {
    switch (type) {
      case MissionType.usabilityTest:
      case MissionType.survey:
        return true; // These benefit from diverse perspectives
      case MissionType.bugReport:
      case MissionType.performanceTest:
        return false; // These need specific expertise
      default:
        return true;
    }
  }

  double _calculateConfidence(double score, DistributionStrategy strategy) {
    // Higher scores generally mean higher confidence, but also consider strategy
    double baseConfidence = score;
    
    switch (strategy) {
      case DistributionStrategy.performance:
      case DistributionStrategy.experience:
        baseConfidence *= 1.1; // More confident in proven performers
        break;
      case DistributionStrategy.availability:
      case DistributionStrategy.diversity:
        baseConfidence *= 0.9; // Slightly less confident in these strategies
        break;
      default:
        break;
    }
    
    return baseConfidence.clamp(0.0, 1.0);
  }

  Duration _estimateCompletionTime(String testerId, MissionRequirements requirements) {
    // This would use historical data in real implementation
    final baseMinutes = requirements.estimatedMinutes;
    final adjustedMinutes = (baseMinutes * (0.8 + (0.4 * (1.0 - 0.8)))); // Mock calculation
    return Duration(minutes: adjustedMinutes.round());
  }

  double _predictQuality(String testerId, MissionRequirements requirements) {
    // This would use ML models in real implementation
    return 0.85 + (0.1 * (requirements.qualityThreshold - 0.5));
  }

  String _generateRecommendationReason(String testerId, double score, DistributionStrategy strategy) {
    if (score > 0.9) {
      return '완벽한 매치입니다. 모든 요구사항을 충족합니다.';
    } else if (score > 0.8) {
      return '매우 적합합니다. 대부분의 요구사항을 만족합니다.';
    } else if (score > 0.7) {
      return '적합합니다. 주요 요구사항을 충족합니다.';
    } else if (score > 0.6) {
      return '어느정도 적합합니다. 일부 보완이 필요할 수 있습니다.';
    } else {
      return '기본적인 요구사항은 충족하지만 주의가 필요합니다.';
    }
  }

  List<String> _identifyRiskFactors(String testerId, MissionRequirements requirements) {
    // This would analyze historical data for risk factors
    return [
      '새로운 미션 유형',
      '짧은 응답 시간 기록',
    ];
  }

  Map<String, double> _calculatePerformanceMetrics(List<TesterRecommendation> recommendations) {
    if (recommendations.isEmpty) return {};
    
    final avgCompatibility = recommendations
        .map((r) => r.compatibilityScore)
        .reduce((a, b) => a + b) / recommendations.length;
    
    final avgConfidence = recommendations
        .map((r) => r.confidence)
        .reduce((a, b) => a + b) / recommendations.length;
    
    final avgQuality = recommendations
        .map((r) => r.qualityPrediction)
        .reduce((a, b) => a + b) / recommendations.length;
    
    return {
      'averageCompatibility': avgCompatibility,
      'averageConfidence': avgConfidence,
      'predictedQuality': avgQuality,
      'coverageScore': _calculateCoverageScore(recommendations),
    };
  }

  double _calculateCoverageScore(List<TesterRecommendation> recommendations) {
    // Mock calculation for how well the recommendations cover the requirements
    return 0.85;
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Reset state
  void reset() {
    state = const MissionDistributionState();
  }
}

// Data models
class TesterProfile {
  final String id;
  final String name;
  final String email;
  final TesterLevel level;
  final List<String> skills;
  final double averageRating;
  final int completedMissions;
  final double successRate;
  final double avgResponseTime; // in hours
  final DateTime lastActiveAt;
  final List<String> preferredCategories;
  final List<String> deviceTypes;
  final double availabilityScore;
  final double qualityScore;
  final double speedScore;

  const TesterProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.level,
    required this.skills,
    required this.averageRating,
    required this.completedMissions,
    required this.successRate,
    required this.avgResponseTime,
    required this.lastActiveAt,
    required this.preferredCategories,
    required this.deviceTypes,
    required this.availabilityScore,
    required this.qualityScore,
    required this.speedScore,
  });
}

class TesterRecommendation {
  final String testerId;
  final double compatibilityScore;
  final double confidence;
  final Duration estimatedCompletionTime;
  final double qualityPrediction;
  final String recommendationReason;
  final List<String> riskFactors;

  const TesterRecommendation({
    required this.testerId,
    required this.compatibilityScore,
    required this.confidence,
    required this.estimatedCompletionTime,
    required this.qualityPrediction,
    required this.recommendationReason,
    required this.riskFactors,
  });
}

class MissionRequirements {
  final MissionType type;
  final MissionComplexity complexity;
  final List<String> requiredSkills;
  final int estimatedMinutes;
  final int maxParticipants;
  final double urgencyLevel;
  final double qualityThreshold;
  final bool diversityNeeded;

  const MissionRequirements({
    required this.type,
    required this.complexity,
    required this.requiredSkills,
    required this.estimatedMinutes,
    required this.maxParticipants,
    required this.urgencyLevel,
    required this.qualityThreshold,
    required this.diversityNeeded,
  });
}

enum TesterLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

// Providers
final missionDistributionProvider = StateNotifierProvider<MissionDistributionNotifier, MissionDistributionState>((ref) {
  return MissionDistributionNotifier();
});

// Distribution strategies provider
final distributionStrategiesProvider = Provider<List<DistributionStrategy>>((ref) {
  return DistributionStrategy.values;
});

// Strategy info provider
final strategyInfoProvider = Provider.family<StrategyInfo, DistributionStrategy>((ref, strategy) {
  return _getStrategyInfo(strategy);
});

class StrategyInfo {
  final String name;
  final String description;
  final List<String> advantages;
  final List<String> bestFor;

  const StrategyInfo({
    required this.name,
    required this.description,
    required this.advantages,
    required this.bestFor,
  });
}

StrategyInfo _getStrategyInfo(DistributionStrategy strategy) {
  switch (strategy) {
    case DistributionStrategy.balanced:
      return const StrategyInfo(
        name: '균형잡힌 분배',
        description: '모든 요소를 종합적으로 고려하여 최적의 균형점을 찾습니다.',
        advantages: ['안정적인 결과', '예측 가능한 품질', '리스크 최소화'],
        bestFor: ['일반적인 미션', '중요도가 보통인 프로젝트', '신규 앱'],
      );
    case DistributionStrategy.performance:
      return const StrategyInfo(
        name: '성능 기반',
        description: '테스터의 과거 성과와 품질 점수를 중심으로 선별합니다.',
        advantages: ['최고 품질 보장', '높은 완성도', '신뢰할 수 있는 결과'],
        bestFor: ['중요한 미션', '출시 전 최종 검증', '고품질 요구 프로젝트'],
      );
    case DistributionStrategy.experience:
      return const StrategyInfo(
        name: '경험 기반',
        description: '테스터의 경험과 전문성을 우선적으로 고려합니다.',
        advantages: ['전문적인 피드백', '깊이 있는 분석', '복잡한 이슈 발견'],
        bestFor: ['복잡한 미션', '전문 지식 필요', '기술적 검증'],
      );
    case DistributionStrategy.availability:
      return const StrategyInfo(
        name: '가용성 기반',
        description: '빠른 응답과 즉시 참여 가능한 테스터를 우선 선별합니다.',
        advantages: ['빠른 진행', '즉시 시작 가능', '타이트한 일정 대응'],
        bestFor: ['긴급 미션', '짧은 데드라인', '빠른 피드백 필요'],
      );
    case DistributionStrategy.diversity:
      return const StrategyInfo(
        name: '다양성 기반',
        description: '다양한 배경과 관점의 테스터들을 균형있게 선별합니다.',
        advantages: ['다각도 분석', '포괄적 피드백', '사용자층 대표성'],
        bestFor: ['사용성 테스트', '설문조사', '다양한 사용자 대상 앱'],
      );
  }
}