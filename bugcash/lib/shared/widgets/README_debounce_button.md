# DebounceButton 위젯

비동기 작업 중 중복 클릭을 자동으로 방지하는 재사용 가능한 버튼 위젯입니다.

## 제공되는 위젯

- `DebounceButton` (ElevatedButton)
- `DebounceOutlinedButton` (OutlinedButton)
- `DebounceTextButton` (TextButton)
- `DebounceIconButton` (IconButton)

## 핵심 구조

### 상태 관리

```dart
class _DebounceButtonState extends State<DebounceButton> {
  bool _isProcessing = false;  // 중복 클릭 방지 플래그

  Future<void> _handlePress() async {
    // 1. 즉시 플래그 체크 (중복 클릭 무시)
    if (_isProcessing) return;

    // 2. 즉시 플래그 설정
    setState(() => _isProcessing = true);

    try {
      // 3. 비동기 작업 실행
      await widget.onPressed!();
    } catch (e) {
      // 4. 에러 처리 (SnackBar)
      if (widget.showErrorSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      // 5. 항상 플래그 해제 (상태 복구 보장)
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
```

### 로직 흐름

1. **중복 클릭 방지**: `_isProcessing` 플래그로 즉시 체크
2. **플래그 설정**: 비동기 작업 시작 전 즉시 `true`
3. **작업 실행**: `onPressed` 콜백 실행
4. **에러 처리**: catch 블록에서 자동 SnackBar 표시
5. **상태 복구**: finally 블록에서 항상 `_isProcessing = false`

## 기본 사용법

```dart
import 'package:bugcash/shared/widgets/debounce_button.dart';

DebounceButton(
  onPressed: () async {
    await someAsyncOperation();
  },
  child: Text('등록'),
)
```

## 매개변수

| 매개변수 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `onPressed` | `Future<void> Function()?` | ✅ | - | 비동기 작업 함수 |
| `child` | `Widget` | ✅ | - | 버튼 자식 위젯 |
| `loadingWidget` | `Widget?` | ❌ | `null` | 커스텀 로딩 위젯 |
| `loadingText` | `String?` | ❌ | `null` | 로딩 텍스트 |
| `style` | `ButtonStyle?` | ❌ | `null` | 버튼 스타일 |
| `showLoadingIndicator` | `bool` | ❌ | `true` | 로딩 인디케이터 표시 |
| `showErrorSnackBar` | `bool` | ❌ | `true` | 에러 SnackBar 표시 |
| `errorMessageBuilder` | `String Function(Object)?` | ❌ | `null` | 커스텀 에러 메시지 |

## 사용 예시

### 커스터마이징

```dart
DebounceButton(
  onPressed: _uploadApp,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  loadingText: '업로드 중...',
  errorMessageBuilder: (error) => '업로드 실패: ${error.toString()}',
  child: Text('등록'),
)
```

### 동적 로딩 텍스트

```dart
DebounceButton(
  onPressed: _uploadApp,
  loadingText: _uploadStatus.isNotEmpty ? _uploadStatus : '등록 중...',
  child: Text('등록'),
)
```

## 관련 파일

- **소스**: [lib/shared/widgets/debounce_button.dart](debounce_button.dart)
- **사용 예시**: [lib/features/provider_dashboard/presentation/pages/app_management_page.dart](../../features/provider_dashboard/presentation/pages/app_management_page.dart)
