import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../lib/utils/migration_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('🔄 사용자 데이터 마이그레이션 도구 시작');

  try {
    // 1. 현재 데이터 분석
    debugPrint('\n📊 1단계: 현재 사용자 데이터 분석');
    final analysis = await MigrationHelper.analyzeCurrentUsers();

    if (analysis.containsKey('error')) {
      debugPrint('❌ 분석 실패: ${analysis['error']}');
      return;
    }

    debugPrint('총 사용자: ${analysis['totalUsers']}명');
    debugPrint('새 형식: ${analysis['newFormat']}명');
    debugPrint('기존 형식: ${analysis['oldFormat']}명');
    debugPrint('사용자 유형: ${analysis['userTypes']}');

    if (analysis['oldFormat'] == 0) {
      debugPrint('✅ 모든 사용자가 이미 새 형식입니다. 마이그레이션이 불필요합니다.');
      return;
    }

    // 2. 마이그레이션 시뮬레이션
    debugPrint('\n🧪 2단계: 마이그레이션 시뮬레이션');
    final dryRunResult = await MigrationHelper.migrateUsers(dryRun: true);

    if (dryRunResult.containsKey('error')) {
      debugPrint('❌ 시뮬레이션 실패: ${dryRunResult['error']}');
      return;
    }

    debugPrint('시뮬레이션 결과:');
    debugPrint('  총 사용자: ${dryRunResult['totalUsers']}명');
    debugPrint('  마이그레이션 대상: ${dryRunResult['migrated']}명');
    debugPrint('  건너뛸 사용자: ${dryRunResult['skipped']}명');
    debugPrint('  오류: ${dryRunResult['errors'].length}개');

    if (dryRunResult['errors'].length > 0) {
      debugPrint('시뮬레이션 오류 목록:');
      for (var error in dryRunResult['errors']) {
        debugPrint('  - $error');
      }
      debugPrint('⚠️ 오류가 있어 실제 마이그레이션을 중단합니다.');
      return;
    }

    // 3. 실제 마이그레이션 실행
    debugPrint('\n🚀 3단계: 실제 마이그레이션 실행');
    final migrationResult = await MigrationHelper.migrateUsers(dryRun: false);

    if (migrationResult.containsKey('error')) {
      debugPrint('❌ 마이그레이션 실패: ${migrationResult['error']}');
      return;
    }

    debugPrint('마이그레이션 완료!');
    debugPrint('  총 사용자: ${migrationResult['totalUsers']}명');
    debugPrint('  마이그레이션: ${migrationResult['migrated']}명');
    debugPrint('  건너뜀: ${migrationResult['skipped']}명');
    debugPrint('  오류: ${migrationResult['errors'].length}개');

    // 4. 검증
    debugPrint('\n✅ 4단계: 마이그레이션 결과 검증');
    final isValid = await MigrationHelper.verifyMigration();

    if (isValid) {
      debugPrint('🎉 마이그레이션이 성공적으로 완료되었습니다!');
    } else {
      debugPrint('❌ 마이그레이션 검증 실패. 수동 확인이 필요합니다.');
    }

    // 5. 최종 분석
    debugPrint('\n📊 5단계: 최종 데이터 상태 확인');
    final finalAnalysis = await MigrationHelper.analyzeCurrentUsers();
    debugPrint('최종 상태:');
    debugPrint('  총 사용자: ${finalAnalysis['totalUsers']}명');
    debugPrint('  새 형식: ${finalAnalysis['newFormat']}명');
    debugPrint('  기존 형식: ${finalAnalysis['oldFormat']}명');

  } catch (e) {
    debugPrint('❌ 마이그레이션 도구 실행 중 오류: $e');
  }
}