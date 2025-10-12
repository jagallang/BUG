#!/bin/bash

# BugCash 웹 앱 빌드 스크립트 - 환경변수 포함
# 사용법: ./scripts/build_web_with_env.sh

echo "🔥 BugCash 웹 앱 빌드 시작 (환경변수 포함)..."

# Flutter 웹 빌드 - 환경변수 주입
flutter build web --release \
  --dart-define=FIREBASE_API_KEY=AIzaSyAeMQcgKwJR5smPY6t6tnDtNdqaPoCamk0 \
  --dart-define=FIREBASE_PROJECT_ID=bugcash \
  --dart-define=FIREBASE_MEASUREMENT_ID=G-M1DT15JR9G

if [ $? -eq 0 ]; then
  echo "✅ 웹 빌드 성공!"
  echo "📁 빌드 결과: build/web/"
  echo "🚀 Firebase 배포 준비 완료"
  echo ""
  echo "다음 단계:"
  echo "  firebase deploy --only hosting"
else
  echo "❌ 웹 빌드 실패!"
  exit 1
fi