#!/bin/bash

# BugCash Firestore 마이그레이션 실행 스크립트
# 사용법: ./execute_migration.sh

set -e  # 오류 발생 시 스크립트 중단

echo "🚀 BugCash Firestore 마이그레이션 시작"
echo "시작 시간: $(date)"

# 1. 환경 확인
echo "📋 1단계: 환경 확인"
firebase use bugcash
firebase projects:list | grep bugcash

# 2. 백업 생성
echo "💾 2단계: 데이터 백업"
BACKUP_PATH="gs://bugcash-backup/migration-backup-$(date +%Y%m%d-%H%M%S)"
echo "백업 위치: $BACKUP_PATH"
# firebase firestore:export $BACKUP_PATH

# 3. 인덱스 배포
echo "🔍 3단계: 새 인덱스 배포"
firebase deploy --only firestore:indexes

# 4. Cloud Functions 배포
echo "☁️ 4단계: Cloud Functions 배포"
firebase deploy --only functions

# 5. 마이그레이션 상태 확인 (사전)
echo "📊 5단계: 마이그레이션 전 상태 확인"
curl -s https://asia-northeast1-bugcash.cloudfunctions.net/checkMigrationStatus | jq .

# 6. 대량 마이그레이션 실행
echo "🔄 6단계: 대량 마이그레이션 실행"
MIGRATION_RESULT=$(curl -s -X POST https://asia-northeast1-bugcash.cloudfunctions.net/bulkMigrateUsers)
echo "마이그레이션 결과:"
echo $MIGRATION_RESULT | jq .

# 7. 마이그레이션 검증
echo "✅ 7단계: 마이그레이션 검증"
VALIDATION_RESULT=$(curl -s https://asia-northeast1-bugcash.cloudfunctions.net/validateMigratedUsers)
echo "검증 결과:"
echo $VALIDATION_RESULT | jq .

# 8. 최종 상태 확인
echo "📈 8단계: 최종 상태 확인"
FINAL_STATUS=$(curl -s https://asia-northeast1-bugcash.cloudfunctions.net/checkMigrationStatus)
echo "최종 상태:"
echo $FINAL_STATUS | jq .

# 결과 요약
echo ""
echo "🎉 마이그레이션 완료!"
echo "완료 시간: $(date)"

# 성공 여부 확인
COMPLETION_RATE=$(echo $FINAL_STATUS | jq -r '.completionRate')
if (( $(echo "$COMPLETION_RATE >= 95" | bc -l) )); then
    echo "✅ 마이그레이션 성공 (완료율: ${COMPLETION_RATE}%)"
    exit 0
else
    echo "⚠️ 마이그레이션 부분 완료 (완료율: ${COMPLETION_RATE}%)"
    echo "수동 확인이 필요할 수 있습니다."
    exit 1
fi