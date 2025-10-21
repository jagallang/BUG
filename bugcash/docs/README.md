# BugCash 개발 문서

> Flutter 개발 시 참고할 수 있는 디버깅 가이드 및 베스트 프랙티스

## 📚 문서 목록

### 🔍 디버깅 가이드
**[DEBUGGING_GUIDE.md](./DEBUGGING_GUIDE.md)**

Flutter 앱 디버깅 시 참고할 체크리스트 및 절차:
- 빈 화면/흰 화면 발생 시 체크리스트
- 에러 로그 읽는 방법
- Hot Reload 검증 프로토콜
- 디버깅 로그 추가 시 주의사항

**주요 내용**:
- 렌더링 에러 우선 확인
- 데이터 로딩 상태 확인
- Firebase 권한 확인
- Hot Reload 실패 대응

---

### 📐 레이아웃 규칙
**[LAYOUT_RULES.md](./LAYOUT_RULES.md)**

Flutter 레이아웃 제약 조건 및 BoxConstraints 에러 해결:
- Flutter 레이아웃의 기본 원리
- 자주 발생하는 에러 패턴
- Row/Column 사용 규칙
- Expanded vs Flexible vs SizedBox

**주요 내용**:
- BoxConstraints forces an infinite width 해결
- RenderFlex overflowed 해결
- Row/Column 내부 위젯 제약 조건
- 반응형 레이아웃 패턴

---

### 🚨 에러 패턴
**[ERROR_PATTERNS.md](./ERROR_PATTERNS.md)**

실전에서 자주 만나는 Flutter 에러와 즉시 적용 가능한 해결책:
- 레이아웃 에러
- 상태 관리 에러 (Riverpod)
- Firebase 에러
- 빌드 에러
- 런타임 에러

**주요 내용**:
- 에러 메시지별 해결 방법
- 에러 빈도 순위
- 긴급 대응 가이드
- 디버깅 플로우차트

---

## 🎯 빠른 참조

### 문제 발생 시 즉시 확인

1. **흰 화면/빈 화면이 나올 때**
   ```
   → DEBUGGING_GUIDE.md의 "빈 화면/흰 화면 발생 시 체크리스트" 참조
   ```

2. **BoxConstraints 에러가 날 때**
   ```
   → LAYOUT_RULES.md의 "BoxConstraints forces an infinite width" 참조
   → ERROR_PATTERNS.md의 "레이아웃 에러" 섹션 참조
   ```

3. **Firebase permission-denied 에러**
   ```
   → ERROR_PATTERNS.md의 "Firebase 에러 > permission-denied" 참조
   ```

4. **Hot Reload가 작동하지 않을 때**
   ```
   → DEBUGGING_GUIDE.md의 "Hot Reload 검증 프로토콜" 참조
   ```

---

## 📋 이번 케이스 스터디 (v2.147.0 - v2.155.0)

### 문제
- 증상: "내 지갑" 클릭 시 흰 화면만 표시
- 기간: v2.147.0부터 v2.155.0까지 (10개 버전)

### 원인
```dart
// 문제가 된 코드
Row(
  children: [
    Expanded(child: DropdownButton(...)),
    SizedBox(width: 12.w),
    ElevatedButton.icon(...),  // ❌ 무한 너비 제약!
  ],
)
```

**에러**: `BoxConstraints forces an infinite width`

### 해결책 (v2.155.0)
```dart
// Row → Column으로 변경
Column(
  children: [
    Container(child: DropdownButton(...)),  // 전체 너비
    SizedBox(height: 12.h),
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(...),     // 전체 너비
    ),
  ],
)
```

### 교훈
1. **에러 로그를 끝까지 읽자** - BoxConstraints는 처음부터 나와 있었음
2. **증상만 보지 말고 에러 메시지를 먼저 보자**
3. **Hot reload 실패는 생각보다 흔하다** - 검증 필수
4. **디버깅 코드도 버그를 만들 수 있다** - ref.watch() 타이밍 주의
5. **Flutter 레이아웃 제약을 이해하자** - Row/Column 규칙

자세한 분석은 각 문서를 참고하세요.

---

## 🔗 외부 참고 자료

- [Flutter 공식 문서 - Understanding constraints](https://docs.flutter.dev/ui/layout/constraints)
- [Flutter 공식 문서 - Box constraints](https://api.flutter.dev/flutter/rendering/BoxConstraints-class.html)
- [Flutter 공식 에러 가이드](https://docs.flutter.dev/testing/errors)
- [Riverpod 공식 문서](https://riverpod.dev/)

---

## 📝 문서 업데이트 가이드

새로운 에러 패턴을 발견하면:

1. **ERROR_PATTERNS.md**에 에러 추가
   - 에러 메시지
   - 원인
   - 발생 위치 (코드 예시)
   - 해결 방법

2. **DEBUGGING_GUIDE.md** 업데이트 (필요 시)
   - 새로운 체크리스트 항목
   - 새로운 디버깅 절차

3. **LAYOUT_RULES.md** 업데이트 (레이아웃 관련 시)
   - 새로운 제약 조건 패턴
   - 새로운 해결 방법

---

## ⚡ 긴급 상황 대응

**앱 크래시 / 빌드 실패 / 흰 화면**

1. 에러 로그 확인 (30초)
2. ERROR_PATTERNS.md에서 유사 패턴 검색 (1분)
3. 해결 방법 시도 (5분)
4. 안 되면 재설치 (2분)

```bash
# 재설치 커맨드
killall -9 dart flutter
flutter clean
flutter run -d <device-id>
```

**원칙**: 에러 로그가 답을 알고 있다!

---

생성일: 2025-10-21
최종 업데이트: v2.155.0
