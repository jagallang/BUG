# Flutter 레이아웃 제약 조건 가이드

> BoxConstraints 에러 방지 및 해결 방법

## 📐 Flutter 레이아웃 제약의 기본 원리

Flutter의 레이아웃은 **제약 조건(Constraints)이 아래로 내려가고, 크기(Size)가 위로 올라간다**는 원칙을 따릅니다:

```
Parent Widget
  ↓ Constraints (BoxConstraints)
Child Widget
  ↑ Size (실제 크기)
Parent Widget
```

### BoxConstraints란?

```dart
BoxConstraints(
  minWidth: 0,
  maxWidth: double.infinity,  // 무한대
  minHeight: 0,
  maxHeight: double.infinity,
)
```

- `minWidth/minHeight`: 최소 크기
- `maxWidth/maxHeight`: 최대 크기
- **무한 제약**: `double.infinity`는 "원하는 만큼 커도 된다"는 의미

---

## ⚠️ 자주 발생하는 에러 패턴

### 1. BoxConstraints forces an infinite width

**에러 메시지**:
```
BoxConstraints forces an infinite width.
BoxConstraints(w=Infinity, 57.1<=h<=Infinity)
```

**원인**: Row 안에 제약 없는 위젯이 있음

**잘못된 코드**:
```dart
Row(
  children: [
    TextField(),              // ❌ 무한 너비!
    Container(width: 100),
    ElevatedButton(...),      // ❌ 무한 너비!
  ],
)
```

**해결 방법 1**: Expanded/Flexible 사용
```dart
Row(
  children: [
    Expanded(
      child: TextField(),     // ✅ 남은 공간 차지
    ),
    SizedBox(width: 12),
    Flexible(
      child: ElevatedButton(...), // ✅ 유연한 크기
    ),
  ],
)
```

**해결 방법 2**: 고정 너비 지정
```dart
Row(
  children: [
    SizedBox(
      width: 200,
      child: TextField(),     // ✅ 고정 너비
    ),
    SizedBox(width: 12),
    ElevatedButton(...),      // ✅ 내용에 맞게 크기 조절
  ],
)
```

**해결 방법 3**: Column으로 변경 (v2.155.0 해결책)
```dart
Column(
  children: [
    TextField(),              // ✅ 전체 너비 사용
    SizedBox(height: 12),
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(...), // ✅ 전체 너비 사용
    ),
  ],
)
```

---

### 2. RenderFlex overflowed

**에러 메시지**:
```
A RenderFlex overflowed by 123 pixels on the right.
```

**원인**: Column/Row의 크기가 화면을 넘어섬

**잘못된 코드**:
```dart
Column(
  children: [
    VeryLongWidget(),
    VeryLongWidget(),
    VeryLongWidget(),
    // ... 너무 많음
  ],
)
```

**해결 방법**: SingleChildScrollView 사용
```dart
SingleChildScrollView(
  child: Column(
    children: [
      VeryLongWidget(),
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
Incorrect use of ParentDataWidget. Expanded widgets must be placed inside Flex widgets.
```

**원인**: Expanded를 Row/Column 밖에서 사용

**잘못된 코드**:
```dart
Container(
  child: Expanded(      // ❌ Container 안에 Expanded
    child: Text('Hello'),
  ),
)
```

**올바른 코드**:
```dart
Row(                   // ✅ Row 안에 Expanded
  children: [
    Expanded(
      child: Text('Hello'),
    ),
  ],
)
```

---

## 🎯 Row/Column 사용 규칙

### Row 안에서

| 위젯 타입 | 제약 필요 여부 | 사용 방법 |
|----------|--------------|----------|
| Text | ❌ 불필요 | 그대로 사용 |
| Icon | ❌ 불필요 | 그대로 사용 |
| Image | ✅ 필요 | `SizedBox(width:...)` 또는 `Expanded` |
| TextField | ✅ 필수! | `Expanded` 또는 `SizedBox(width:...)` |
| DropdownButton | ✅ 필수! | `Expanded(child: DropdownButton(isExpanded: true))` |
| ElevatedButton | ⚠️ 권장 | `Flexible` 또는 내용에 맞게 |
| Container (크기 미지정) | ✅ 필요 | `Expanded` 또는 고정 크기 |

### Column 안에서

| 위젯 타입 | 제약 필요 여부 | 사용 방법 |
|----------|--------------|----------|
| Text | ❌ 불필요 | 그대로 사용 |
| ListView | ✅ 필수! | `Expanded` 또는 `SizedBox(height:...)` |
| GridView | ✅ 필수! | `Expanded` 또는 `SizedBox(height:...)` |
| SingleChildScrollView | ✅ 필수! | `Expanded` 또는 고정 높이 |
| Container (크기 미지정) | ⚠️ 권장 | `Expanded` 또는 `Flexible` |

---

## 🛠️ Expanded vs Flexible vs SizedBox

### Expanded

```dart
Row(
  children: [
    Expanded(
      flex: 2,                // 2/3 차지
      child: Container(...),
    ),
    Expanded(
      flex: 1,                // 1/3 차지
      child: Container(...),
    ),
  ],
)
```

**용도**:
- 남은 공간을 **모두** 차지
- 여러 위젯이 공간을 **비율로** 나눠 가짐
- **무조건 지정된 크기를 차지**

### Flexible

```dart
Row(
  children: [
    Flexible(
      flex: 1,
      fit: FlexFit.loose,     // 내용에 맞게 (기본값)
      child: Container(...),
    ),
    Flexible(
      flex: 1,
      fit: FlexFit.tight,     // Expanded와 동일
      child: Container(...),
    ),
  ],
)
```

**용도**:
- 내용에 맞게 크기 조절 가능
- 최대 크기만 제한
- **내용이 작으면 작게, 크면 크게**

### SizedBox

```dart
Row(
  children: [
    SizedBox(
      width: 100,
      height: 50,
      child: Container(...),
    ),
  ],
)
```

**용도**:
- **정확한 크기 지정**
- 반응형이 아님
- 고정된 크기가 필요할 때

---

## 📱 반응형 레이아웃 패턴

### 패턴 1: LayoutBuilder 사용

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      // 태블릿/데스크탑
      return Row(
        children: [
          Expanded(child: LeftPanel()),
          Expanded(child: RightPanel()),
        ],
      );
    } else {
      // 모바일
      return Column(
        children: [
          LeftPanel(),
          RightPanel(),
        ],
      );
    }
  },
)
```

### 패턴 2: MediaQuery 사용

```dart
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isWide = screenWidth > 600;

  return isWide
    ? Row(children: [...])
    : Column(children: [...]);
}
```

### 패턴 3: flutter_screenutil 사용 (BugCash 방식)

```dart
Row(
  children: [
    SizedBox(width: 16.w),   // 화면 너비 비례
    Text(
      'Hello',
      style: TextStyle(fontSize: 14.sp), // 화면 크기 비례
    ),
    SizedBox(height: 8.h),   // 화면 높이 비례
  ],
)
```

---

## ⚡ 실전 예제: v2.155.0 문제 해결

### 문제가 된 코드 (v2.147.0 - v2.154.0)

```dart
// 충전 금액 선택 (드롭다운 + 결제 버튼)
Row(
  children: [
    Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _selectedChargeAmount,
            isExpanded: true,   // ← 문제의 원인 중 하나
            // ...
          ),
        ),
      ),
    ),
    SizedBox(width: 12.w),
    ElevatedButton.icon(        // ❌ 무한 너비 제약!
      onPressed: () { /*...*/ },
      icon: Icon(Icons.payment, size: 20.sp),
      label: Text('결제하기'),
      // ...
    ),
  ],
)
```

**에러**:
```
BoxConstraints forces an infinite width.
BoxConstraints(w=Infinity, 57.1<=h<=Infinity)
```

**원인**:
1. `Expanded`로 감싸진 DropdownButton은 OK
2. 하지만 `ElevatedButton`은 제약이 없음
3. Row는 ElevatedButton에게 "무한 너비" 제약을 줌
4. ElevatedButton은 어떤 크기여야 할지 모름 → 에러!

### 해결 방법 1: Flexible로 감싸기

```dart
Row(
  children: [
    Expanded(
      child: Container(/*...*/),
    ),
    SizedBox(width: 12.w),
    Flexible(                   // ✅ Flexible 추가
      child: ElevatedButton.icon(/*...*/),
    ),
  ],
)
```

### 해결 방법 2: Column으로 변경 (v2.155.0 최종 해결책)

```dart
Column(
  children: [
    // 드롭다운
    Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedChargeAmount,
          isExpanded: true,     // ✅ 전체 너비 사용
          // ...
        ),
      ),
    ),
    SizedBox(height: 12.h),
    // 결제 버튼
    SizedBox(
      width: double.infinity,   // ✅ 전체 너비 명시
      child: ElevatedButton.icon(/*...*/),
    ),
  ],
)
```

**장점**:
- BoxConstraints 에러 해결
- 모바일에서 더 나은 UX (세로 배치가 터치하기 쉬움)
- 각 위젯이 전체 너비 사용

---

## 🔍 디버깅 체크리스트

BoxConstraints 에러 발생 시:

1. **에러 메시지 확인**
   - [ ] "forces an infinite width" → Row 문제
   - [ ] "forces an infinite height" → Column 문제

2. **문제 위젯 찾기**
   - [ ] "The relevant error-causing widget" 확인
   - [ ] 파일과 라인 번호로 이동

3. **Row/Column 구조 점검**
   - [ ] Row 안에 TextField/DropdownButton/Container 있는가?
   - [ ] Expanded/Flexible로 감싸져 있는가?
   - [ ] 고정 크기(SizedBox)로 지정되어 있는가?

4. **해결 방법 선택**
   - [ ] Expanded 추가
   - [ ] Flexible 추가
   - [ ] SizedBox로 고정 크기 지정
   - [ ] Row → Column 변경 검토

---

## 📚 참고 자료

- [Flutter 공식 문서 - Understanding constraints](https://docs.flutter.dev/ui/layout/constraints)
- [Flutter 공식 문서 - Box constraints](https://api.flutter.dev/flutter/rendering/BoxConstraints-class.html)
- [이번 케이스 상세 분석](./DEBUGGING_GUIDE.md#-재발-방지-방안)
