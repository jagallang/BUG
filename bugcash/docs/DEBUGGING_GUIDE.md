# Flutter 디버깅 가이드

> BugCash 앱 개발 시 디버깅 체크리스트 및 절차

## 📋 빈 화면/흰 화면 발생 시 체크리스트

화면이 비어 보이거나 흰색만 표시될 때 다음 순서로 확인하세요:

### 1단계: 렌더링 에러 확인 (최우선!)

```bash
# 로그에서 렌더링 에러 검색
grep -E "BoxConstraints|RenderFlex|overflow|EXCEPTION" 로그파일

# 찾아야 할 키워드:
# - BoxConstraints forces an infinite width/height
# - RenderBox was not laid out
# - RenderFlex overflowed
# - EXCEPTION CAUGHT BY RENDERING LIBRARY
```

**발견 시 조치**:
- → [LAYOUT_RULES.md](./LAYOUT_RULES.md) 참고
- Row/Column 구조 점검
- Expanded/Flexible 사용 확인

### 2단계: 데이터 로딩 상태 확인

```dart
// AsyncValue 상태 디버깅 로그 추가
final dataAsync = ref.watch(someProvider);

print('🔍 hasValue: ${dataAsync.hasValue}');
print('🔍 isLoading: ${dataAsync.isLoading}');
print('🔍 hasError: ${dataAsync.hasError}');

if (dataAsync.hasValue) {
  print('🔍 value: ${dataAsync.value}');
}
if (dataAsync.hasError) {
  print('🔍 error: ${dataAsync.error}');
}
```

**체크 포인트**:
- [ ] `hasValue`가 true인가?
- [ ] `isLoading`이 무한 로딩 상태는 아닌가?
- [ ] `hasError`가 true라면 에러 내용은?

### 3단계: Firebase/Firestore 권한 확인

```bash
# 로그에서 권한 에러 검색
grep "permission-denied" 로그파일
```

**발견 시 조치**:
- Firestore Security Rules 확인
- 로그인 상태 확인 (`FirebaseAuth.instance.currentUser`)
- userId가 올바른지 확인

### 4단계: Hot Reload 성공 여부 확인

```dart
// 파일 상단에 버전 로그 추가
@override
Widget build(BuildContext context) {
  print('🔍 [v2.XXX.0] PageName build()');
  // ...
}
```

**Hot Reload 후 확인**:
1. 로그에 새 버전 번호가 보이는가?
2. 이전 버전 로그가 계속 보인다면 → Hot Reload 실패!

**Hot Reload 실패 시**:
```bash
# 1. 모든 프로세스 종료
killall -9 dart flutter

# 2. Clean build
flutter clean

# 3. 재설치
flutter run -d <device-id>
```

---

## 🔍 에러 로그 읽는 방법

### Flutter 에러 메시지 구조

```
══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═══════════
BoxConstraints forces an infinite width.        ← 핵심 에러 메시지
  BoxConstraints(w=Infinity, 57.1<=h<=Infinity) ← 상세 정보

When the exception was thrown, this was the stack:
#0  BoxConstraints.debugAssertIsValid            ← 에러 발생 지점
#1  RenderFlex._computeSizes                     ← Row/Column 크기 계산 중
#2  RenderFlex.performLayout                     ← 레이아웃 단계

The relevant error-causing widget was:           ← 문제 위젯
  Row file:///path/to/file.dart:234              ← 파일 위치!
```

### 에러 로그 읽는 순서

1. **첫 번째 줄**: 어떤 라이브러리에서 발생했는가?
   - `RENDERING LIBRARY` → 레이아웃/렌더링 문제
   - `WIDGETS LIBRARY` → 위젯 생명주기 문제
   - `GESTURES` → 터치/제스처 문제

2. **두 번째 줄**: 핵심 에러 메시지
   - 이것이 가장 중요! 이 한 줄로 문제를 파악

3. **Stack trace**: 에러 발생 경로
   - `RenderFlex`, `RenderBox` → Row/Column 문제
   - `StreamBuilder` → Stream/Future 문제
   - `ProviderScope` → Riverpod 문제

4. **The relevant error-causing widget**: 문제가 된 위젯
   - 파일 경로와 라인 번호가 나옴
   - **이 위치로 바로 이동**

---

## 🛠️ 디버깅 로그 추가 시 주의사항

### ❌ 잘못된 디버깅 방법

```dart
Widget build(BuildContext context) {
  // ❌ 위젯을 변수로 저장하면 빌드 타이밍이 깨짐
  final widget1 = _buildSomething();  // 내부에 ref.watch() 있으면 위험!
  final widget2 = _buildAnother();

  print('widget1 built');
  print('widget2 built');

  return Column(children: [widget1, widget2]);
}
```

**문제점**:
- `_buildSomething()` 내부에 `ref.watch()`가 있으면 빌드 타이밍이 깨짐
- Flutter의 위젯 트리 최적화가 작동하지 않음

### ✅ 올바른 디버깅 방법

```dart
Widget build(BuildContext context) {
  print('🔍 build() START');

  return Column(
    children: [
      _buildSomething(),  // 직접 호출
      _buildAnother(),    // 직접 호출
    ],
  );
}

Widget _buildSomething() {
  print('🔍 _buildSomething() called');
  // ...
}
```

**장점**:
- 위젯이 정상적으로 빌드됨
- 로그로 호출 순서 확인 가능

---

## 🚀 Hot Reload vs Hot Restart vs 재설치

### Hot Reload (단축키: `r`)
- **용도**: 위젯, UI 변경
- **적용 범위**: `build()` 메서드 내부 변경사항
- **적용 안 되는 것**:
  - State의 `initState()` 변경
  - 전역 변수 변경
  - main() 함수 변경

### Hot Restart (단축키: `R`)
- **용도**: State 초기화 필요 시
- **적용 범위**: `initState()`, 전역 변수 등
- **적용 안 되는 것**:
  - 네이티브 코드 변경 (Android/iOS)
  - pubspec.yaml 변경

### 재설치 (필수)
- **용도**:
  - 네이티브 코드 변경
  - 패키지 추가/제거
  - Hot Reload 2회 연속 실패 시

```bash
# 완전 재설치 프로토콜
killall -9 dart flutter
flutter clean
flutter run -d <device-id>
```

---

## 📊 Hot Reload 검증 프로토콜

### 1. 버전 로그 추가

```dart
// 수정한 파일 맨 위에
@override
Widget build(BuildContext context) {
  print('🔍 [v2.155.0] UnifiedWalletPage build()');
  // ...
}
```

### 2. Hot Reload 실행

```bash
printf "r\n" | nc localhost <port>
# 또는 IDE에서 'r' 키 입력
```

### 3. 로그 확인

```bash
# 새 버전 로그가 보이는지 확인
grep "v2.155.0" 로그파일

# 이전 버전 로그가 계속 보이면 실패!
grep "v2.154.0" 로그파일  # 이게 보이면 안 됨
```

### 4. 실패 시 대응

**1회 실패**: Hot Restart 시도
```bash
printf "R\n" | nc localhost <port>
```

**2회 실패**: 즉시 재설치
```bash
# 시간 낭비 말고 바로 재설치!
killall -9 dart flutter
flutter clean
flutter run -d <device-id>
```

---

## 🎯 디버깅 우선순위

문제가 발생하면 다음 순서로 확인하세요:

1. **에러 로그 확인** (30초)
   - BoxConstraints, RenderFlex 검색
   - EXCEPTION CAUGHT 검색

2. **Hot Reload 검증** (10초)
   - 버전 로그 확인
   - 실패 시 즉시 재설치

3. **데이터 상태 확인** (1분)
   - AsyncValue 디버깅 로그
   - Firestore 권한 확인

4. **코드 검토** (5분)
   - Row/Column 구조
   - ref.watch() 위치
   - 위젯 생명주기

**원칙**: 에러 로그 먼저, 코드는 나중에!

---

## 📝 체크리스트 템플릿

문제 발생 시 이 체크리스트를 복사해서 사용하세요:

```markdown
## 디버깅 체크리스트

### 증상
- [ ] 흰 화면
- [ ] 빈 화면
- [ ] 로딩 무한 반복
- [ ] 앱 크래시
- [ ] 기타: ___________

### 1단계: 렌더링 에러
- [ ] BoxConstraints 에러 검색 완료
- [ ] RenderFlex 에러 검색 완료
- [ ] EXCEPTION 검색 완료
- [ ] 결과: ___________

### 2단계: 데이터 상태
- [ ] AsyncValue.hasValue 확인
- [ ] AsyncValue.isLoading 확인
- [ ] AsyncValue.hasError 확인
- [ ] 결과: ___________

### 3단계: Hot Reload 검증
- [ ] 버전 로그 추가
- [ ] Hot Reload 실행
- [ ] 새 버전 로그 확인
- [ ] 결과: ___________

### 4단계: 해결 방법
- [ ] 코드 수정: ___________
- [ ] 재설치 필요
- [ ] 추가 조사 필요

### 소요 시간
- 디버깅 시작: ___________
- 문제 발견: ___________
- 해결 완료: ___________
```

---

## 🔗 관련 문서

- [Flutter 레이아웃 제약 조건 가이드](./LAYOUT_RULES.md)
- [자주 발생하는 에러 패턴](./ERROR_PATTERNS.md)
