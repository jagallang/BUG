import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bugcash/utils/migration_helper.dart';
import 'package:bugcash/firebase_options.dart';

void main() async {
  debugPrint('🚀 BugCash 마이그레이션 시작');

  try {
    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase 초기화 완료');

    // 1단계: 현재 상태 분석
    debugPrint('\n📊 1단계: 현재 사용자 데이터 분석');
    final analysis = await MigrationHelper.analyzeCurrentUsers();
    debugPrint('분석 결과: $analysis');

    if (analysis.containsKey('error')) {
      debugPrint('❌ 분석 실패: ${analysis['error']}');
      return;
    }

    // 2단계: 마이그레이션 시뮬레이션
    debugPrint('\n🔄 2단계: 마이그레이션 시뮬레이션');
    final dryRunResult = await MigrationHelper.migrateUsers(dryRun: true);
    debugPrint('시뮬레이션 결과: $dryRunResult');

    if (dryRunResult.containsKey('error')) {
      debugPrint('❌ 시뮬레이션 실패: ${dryRunResult['error']}');
      return;
    }

    // 3단계: 실제 마이그레이션 실행
    debugPrint('\n✅ 3단계: 실제 마이그레이션 실행');
    final migrationResult = await MigrationHelper.migrateUsers(dryRun: false);
    debugPrint('마이그레이션 결과: $migrationResult');

    if (migrationResult.containsKey('error')) {
      debugPrint('❌ 마이그레이션 실패: ${migrationResult['error']}');
      return;
    }

    // 4단계: 검증
    debugPrint('\n🔍 4단계: 마이그레이션 검증');
    final isValid = await MigrationHelper.verifyMigration();
    debugPrint('검증 결과: ${isValid ? '✅ 성공' : '❌ 실패'}');

    // 5단계: 최종 분석
    debugPrint('\n📈 5단계: 최종 상태 분석');
    final finalAnalysis = await MigrationHelper.analyzeCurrentUsers();
    debugPrint('최종 결과: $finalAnalysis');

    debugPrint('\n🎉 마이그레이션 프로세스 완료!');

  } catch (e, stackTrace) {
    debugPrint('❌ 마이그레이션 중 전체 오류: $e');
    debugPrint('스택 트레이스: $stackTrace');
  }
}