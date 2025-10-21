# Flutter 자주 발생하는 에러 패턴 및 해결법

> 실전에서 자주 만나는 Flutter 에러와 즉시 적용 가능한 해결책

## 📑 목차

1. [레이아웃 에러](#-레이아웃-에러)
2. [상태 관리 에러 (Riverpod)](#-상태-관리-에러-riverpod)
3. [Firebase 에러](#-firebase-에러)
4. [빌드 에러](#-빌드-에러)
5. [런타임 에러](#-런타임-에러)

---

## 🎨 레이아웃 에러

### 1. BoxConstraints forces an infinite width

**에러 메시지**:
```
══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═══
BoxConstraints forces an infinite width.
BoxConstraints(w=Infinity, 57.1<=h<=Infinity)
```

**원인**: Row 안에 제약 없는 위젯

**발생 위치**:
```dart
Row(
  children: [
    TextField(),          // ❌
    ElevatedButton(...),  // ❌
  ],
)
```

**해결 방법**:
```dart
Row(
  children: [
    Expanded(child: TextField()),      // ✅
    Flexible(child: ElevatedButton(...)), // ✅
  ],
)
```

**관련 문서**: [LAYOUT_RULES.md](./LAYOUT_RULES.md#1-boxconstraints-forces-an-infinite-width)

---

### 2. RenderFlex overflowed

**에러 메시지**:
```
A RenderFlex overflowed by 123 pixels on the right.
```

**원인**: Column/Row의 자식들이 화면을 넘어섬

**발생 위치**:
```dart
Column(
  children: [
    VeryLongWidget(),
    VeryLongWidget(),
    // ... 너무 많음
  ],
)
```

**해결 방법**:
```dart
SingleChildScrollView(
  child: Column(
    children: [
      VeryLongWidget(),
      VeryLongWidget(),
    ],
  ),
)
```

---

### 3. Incorrect use of ParentDataWidget

**에러 메시지**:
```
Incorrect use of ParentDataWidget.
Expanded widgets must be placed inside Flex widgets.
```

**원인**: Expanded/Flexible를 Row/Column 밖에서 사용

**발생 위치**:
```dart
Container(
  child: Expanded(      // ❌
    child: Text('Hello'),
  ),
)
```

**해결 방법**:
```dart
Row(                   // ✅
  children: [
    Expanded(
      child: Text('Hello'),
    ),
  ],
)
```

---

### 4. Vertical viewport was given unbounded height

**에러 메시지**:
```
Vertical viewport was given unbounded height.
```

**원인**: ListView/GridView를 Column 안에 제약 없이 사용

**발생 위치**:
```dart
Column(
  children: [
    ListView(              // ❌
      children: [...],
    ),
  ],
)
```

**해결 방법 1**: Expanded 사용
```dart
Column(
  children: [
    Expanded(            // ✅
      child: ListView(
        children: [...],
      ),
    ),
  ],
)
```

**해결 방법 2**: shrinkWrap 사용 (비추천 - 성능 저하)
```dart
Column(
  children: [
    ListView(
      shrinkWrap: true,  // ⚠️ 성능 저하
      children: [...],
    ),
  ],
)
```

---

## 🎯 상태 관리 에러 (Riverpod)

### 1. ProviderNotFoundException

**에러 메시지**:
```
ProviderNotFoundException (Error: Could not find the correct Provider<...>)
```

**원인**: ProviderScope 밖에서 Provider 사용

**발생 위치**:
```dart
void main() {
  runApp(MyApp());  // ❌ ProviderScope 없음
}
```

**해결 방법**:
```dart
void main() {
  runApp(
    ProviderScope(     // ✅
      child: MyApp(),
    ),
  );
}
```

---

### 2. Using ref in invalid context

**에러 메시지**:
```
Cannot use ref in a widget that is not a ConsumerWidget or ConsumerStatefulWidget
```

**원인**: StatelessWidget에서 ref 사용

**발생 위치**:
```dart
class MyWidget extends StatelessWidget {  // ❌
  @override
  Widget build(BuildContext context) {
    final value = ref.watch(someProvider);  // ❌
    // ...
  }
}
```

**해결 방법**:
```dart
class MyWidget extends ConsumerWidget {  // ✅
  @override
  Widget build(BuildContext context, WidgetRef ref) {  // ✅
    final value = ref.watch(someProvider);
    // ...
  }
}
```

---

### 3. Bad state: Stream has already been listened to

**에러 메시지**:
```
Bad state: Stream has already been listened to.
```

**원인**: Stream을 여러 번 listen

**발생 위치**:
```dart
final stream = someStream();
stream.listen(...);  // 첫 번째
stream.listen(...);  // ❌ 두 번째
```

**해결 방법 1**: StreamProvider 사용
```dart
final streamProvider = StreamProvider<T>((ref) {
  return someStream();
});

// 여러 곳에서 안전하게 사용
ref.watch(streamProvider);
```

**해결 방법 2**: broadcast stream 사용
```dart
final stream = someStream().asBroadcastStream();
stream.listen(...);  // OK
stream.listen(...);  // OK
```

---

## 🔥 Firebase 에러

### 1. permission-denied (Firestore)

**에러 메시지**:
```
[cloud_firestore/permission-denied]
The caller does not have permission to execute the specified operation.
```

**원인**: Firestore Security Rules 위반

**발생 위치**:
```dart
FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .get();  // ❌ 권한 없음
```

**해결 방법 1**: Security Rules 확인
```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**해결 방법 2**: 로그인 상태 확인
```dart
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  // 로그인 필요
  return;
}

// 로그인 후 접근
FirebaseFirestore.instance
  .collection('users')
  .doc(user.uid)  // ✅ 자신의 문서만
  .get();
```

---

### 2. No AppCheckProvider installed

**에러 메시지**:
```
com.google.firebase.FirebaseException: No AppCheckProvider installed.
```

**원인**: Firebase App Check 미설정 (경고성 메시지)

**영향**: 실제 동작에는 문제 없음 (무시 가능)

**해결 방법** (선택사항):
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // App Check 활성화 (선택)
  await FirebaseAppCheck.instance.activate(
    webRecaptchaSiteKey: 'your-recaptcha-site-key',
    androidProvider: AndroidProvider.debug,  // 개발 시
  );

  runApp(MyApp());
}
```

---

### 3. Firebase Storage upload failed

**에러 메시지**:
```
[firebase_storage/unknown] An unknown error occurred
```

**원인**: 네트워크 타임아웃, 파일 크기 제한, 권한 문제

**발생 위치**:
```dart
await FirebaseStorage.instance
  .ref('path/to/file.jpg')
  .putFile(file);  // ❌ 실패
```

**해결 방법**: 재시도 로직 + 진행상황 확인
```dart
Future<String> uploadWithRetry(File file, String path, {int maxRetries = 3}) async {
  for (int attempt = 0; attempt < maxRetries; attempt++) {
    try {
      final ref = FirebaseStorage.instance.ref(path);
      final uploadTask = ref.putFile(file);

      // 진행상황 모니터링
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask.timeout(
        Duration(seconds: 120),  // 2분 타임아웃
      );

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (attempt == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
    }
  }
  throw Exception('Upload failed after $maxRetries attempts');
}
```

---

## 🛠️ 빌드 에러

### 1. Gradle build failed (Android)

**에러 메시지**:
```
FAILURE: Build failed with an exception.
```

**원인**: 다양 (Java 버전, Gradle 버전, 의존성 충돌 등)

**해결 방법 1**: Clean 빌드
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

**해결 방법 2**: Gradle 캐시 삭제
```bash
rm -rf ~/.gradle/caches/
cd android
./gradlew clean
```

---

### 2. Pod install failed (iOS)

**에러 메시지**:
```
Error running pod install
```

**원인**: CocoaPods 의존성 문제

**해결 방법**:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter run
```

---

### 3. Version solving failed

**에러 메시지**:
```
Because every version of flutter_test depends on collection 1.15.0 and
package depends on collection ^1.16.0, flutter_test is forbidden.
```

**원인**: 패키지 버전 충돌

**해결 방법 1**: dependency_overrides 사용
```yaml
# pubspec.yaml
dependency_overrides:
  collection: ^1.16.0
```

**해결 방법 2**: 패키지 버전 다운그레이드
```yaml
dependencies:
  package_name: ^1.0.0  # 호환되는 버전으로 변경
```

---

## ⚡ 런타임 에러

### 1. setState called after dispose

**에러 메시지**:
```
setState() called after dispose()
```

**원인**: 위젯이 dispose된 후 setState 호출

**발생 위치**:
```dart
Future<void> fetchData() async {
  final data = await api.getData();
  setState(() {  // ❌ 위젯이 이미 dispose되었을 수 있음
    this.data = data;
  });
}
```

**해결 방법**:
```dart
Future<void> fetchData() async {
  final data = await api.getData();
  if (mounted) {  // ✅ mounted 체크
    setState(() {
      this.data = data;
    });
  }
}
```

---

### 2. Null check operator used on null value

**에러 메시지**:
```
Null check operator used on a null value
```

**원인**: null 값에 `!` 연산자 사용

**발생 위치**:
```dart
String? name;
print(name!.length);  // ❌ name이 null이면 에러
```

**해결 방법 1**: null 체크
```dart
String? name;
if (name != null) {  // ✅
  print(name.length);
}
```

**해결 방법 2**: ?. 연산자
```dart
String? name;
print(name?.length);  // ✅ null이면 null 반환
```

**해결 방법 3**: ?? 연산자
```dart
String? name;
print((name ?? '').length);  // ✅ null이면 빈 문자열
```

---

### 3. RangeError (index): Invalid value

**에러 메시지**:
```
RangeError (index): Invalid value: Not in inclusive range 0..2: 3
```

**원인**: 리스트 인덱스 범위 초과

**발생 위치**:
```dart
final list = [1, 2, 3];
print(list[3]);  // ❌ 인덱스 3은 없음 (0, 1, 2만 존재)
```

**해결 방법**:
```dart
final list = [1, 2, 3];
if (index < list.length) {  // ✅
  print(list[index]);
}
```

---

## 🔍 디버깅 플로우차트

문제 발생 시 이 순서로 확인하세요:

```
문제 발생
  ↓
흰 화면 / 빈 화면?
  ├─ Yes → 렌더링 에러 확인 (BoxConstraints, RenderFlex)
  └─ No  → 에러 메시지 확인
            ↓
      에러 메시지 타입?
        ├─ RENDERING LIBRARY → 레이아웃 에러
        ├─ WIDGETS LIBRARY → 상태 관리 에러
        ├─ firebase → Firebase 에러
        └─ Gradle/Pod → 빌드 에러
```

---

## 📊 에러 빈도 순위 (BugCash 프로젝트 기준)

1. **BoxConstraints forces an infinite width** ⭐⭐⭐⭐⭐
   - 가장 흔함
   - Row/Column 사용 시 항상 주의

2. **permission-denied** ⭐⭐⭐⭐
   - Firebase 작업 시 자주 발생
   - Security Rules 확인 필수

3. **setState after dispose** ⭐⭐⭐
   - 비동기 작업 많을 때 발생
   - mounted 체크 습관화

4. **Hot Reload 실패** ⭐⭐⭐
   - 백그라운드 프로세스 충돌
   - 재설치로 해결

5. **Null check operator** ⭐⭐
   - Null safety 관련
   - 타입 체크 철저히

---

## 🚨 긴급 대응 가이드

### 앱이 크래시 날 때

1. **로그 확인** (30초)
   ```bash
   flutter logs
   ```

2. **Hot Restart** (10초)
   ```bash
   flutter run
   # IDE에서 'R' 키
   ```

3. **재설치** (2분)
   ```bash
   killall -9 dart flutter
   flutter clean
   flutter run
   ```

### 빌드가 실패할 때

1. **Clean 빌드** (1분)
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Gradle 캐시 삭제** (Android, 3분)
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   ```

3. **Pod 재설치** (iOS, 5분)
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   flutter clean
   ```

---

## 📚 참고 문서

- [디버깅 가이드](./DEBUGGING_GUIDE.md)
- [레이아웃 규칙](./LAYOUT_RULES.md)
- [Flutter 공식 에러 가이드](https://docs.flutter.dev/testing/errors)

---

## 🎯 체크리스트: 새 에러 발생 시

```markdown
- [ ] 에러 메시지 전체 읽기
- [ ] Stack trace 확인
- [ ] 이 문서에서 유사 패턴 검색
- [ ] 해결 방법 시도
- [ ] 해결되면 이 문서에 추가 (새로운 패턴인 경우)
- [ ] 해결 안 되면 재설치 시도
```

**원칙**: 에러 로그가 답을 알고 있다!
