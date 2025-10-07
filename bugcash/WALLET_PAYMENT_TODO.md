# 💰 Wallet & Payment 모듈 완료 및 보류 현황

## ✅ 완료된 작업 (v2.51.0 ~ v2.53.0)

### v2.51.0: 지갑 모듈 기본 구조
- [x] `wallet_entity.dart` - 지갑 엔티티
- [x] `transaction_entity.dart` - 거래 내역 엔티티
- [x] `wallet_repository.dart` - 지갑 Repository 인터페이스
- [x] `wallet_service.dart` - 지갑 비즈니스 로직 (TODO 주석 포함)
- [x] `wallet_repository_impl.dart` - Firestore 연동 Repository 구현체
- [x] `wallet_provider.dart` - Riverpod Provider (Repository 패턴 적용)

### v2.52.0: 실시간 지갑 UI 위젯 및 대시보드 통합
- [x] `provider_wallet_card.dart` - 공급자 지갑 카드 위젯
- [x] `tester_wallet_card.dart` - 테스터 지갑 카드 위젯
- [x] `transaction_list_item.dart` - 거래 내역 리스트 아이템 위젯
- [x] Provider Dashboard 통합 (결제 탭)
- [x] Tester Dashboard 통합 (정산 탭)

### v2.53.0: 회원가입 시 지갑 자동 생성
- [x] `auth_service.dart` - createUserProfile() 수정
- [x] 신규 사용자 회원가입 시 wallets/{userId} 자동 생성

---

## ⏸️ 보류된 작업 (나중에 개발)

### 이유: Payment 모듈은 독립적으로 동작하며, 실제 결제가 필요한 시점에 추가 가능

### 1. Payment 모듈 (보류 - MVP 완료 후 개발)

#### A. Payment Entity
**파일**: `lib/features/payment/domain/entities/payment_entity.dart`

**TODO:**
```dart
enum PaymentStatus { pending, confirmed, failed, cancelled }
enum PaymentMethod { card, transfer, simplePay }

class PaymentEntity extends Equatable {
  final String id;
  final String userId;
  final String orderId;
  final int amount;
  final int points;
  final PaymentStatus status;
  final PaymentMethod method;
  final String? paymentKey; // 토스페이먼츠
  final String? receiptUrl;

  // TODO: toFirestore, fromFirestore, copyWith
}
```

#### B. Toss Payment Service
**파일**: `lib/features/payment/data/services/toss_payment_service.dart`

**TODO:**
```dart
import 'dart:js' as js;
import 'package:uuid/uuid.dart';

class TossPaymentService {
  final String _clientKey = const String.fromEnvironment('TOSS_CLIENT_KEY');

  // TODO: requestPayment() - 토스페이먼츠 결제 요청
  // TODO: confirmPayment() - Firebase Functions 통해 결제 승인
  // TODO: cancelPayment() - 결제 취소
}
```

#### C. Payment Page
**파일**: `lib/features/payment/presentation/pages/payment_page.dart`

**TODO:**
```dart
class PaymentPage extends StatelessWidget {
  final String userId;
  final int amount;

  // TODO: 충전 금액 선택 (10,000 / 30,000 / 50,000 / 100,000)
  // TODO: 결제 방법 선택 (카드/계좌이체/간편결제)
  // TODO: 결제하기 버튼
  // TODO: 이용약관 동의 체크박스
}
```

---

### 2. 거래 내역 페이지 (보류 - 선택사항)

**파일**: `lib/features/wallet/presentation/pages/transaction_history_page.dart`

**TODO:**
```dart
class TransactionHistoryPage extends ConsumerWidget {
  final String userId;

  // TODO: 거래 내역 리스트 (무한 스크롤)
  // TODO: 필터링 (타입별: 충전/사용/적립/출금)
  // TODO: 기간별 필터 (이번 달/지난 달/전체)
  // TODO: 검색 기능
  // TODO: 영수증/상세 보기
}
```

---

### 3. 출금 시스템 (보류 - 나중에)
**위치**: `tester_wallet_card.dart` 출금 다이얼로그 구현 필요

**TODO:**
- 최소 출금 금액 검증
- 은행 계좌 정보 입력/관리
- 출금 신청 처리
- 출금 상태 관리 (pending → completed)
- 출금 수수료 계산

---

### 4. Firebase Functions (보류 - 결제 연동 시)

**파일**: `functions/src/index.ts`

**TODO:**
```typescript
// TODO: confirmTossPayment() - 토스페이먼츠 결제 승인 검증
// TODO: deductPointsForApp() - 앱 등록 시 포인트 차감
// TODO: awardPointsToTester() - 미션 완료 시 포인트 적립
// TODO: processWithdrawal() - 출금 신청 처리
```

---

### 5. 환경설정 (보류 - 결제 연동 시)

#### A. pubspec.yaml
**TODO:**
```yaml
dependencies:
  # 토스페이먼츠
  js: ^0.7.1
  http: ^1.1.0
```

#### B. .env
**TODO:**
```env
# 토스페이먼츠 클라이언트 키 (테스트용)
TOSS_CLIENT_KEY=test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq
```

#### C. web/index.html
**TODO:**
```html
<head>
  <!-- 토스페이먼츠 SDK -->
  <script src="https://js.tosspayments.com/v1/payment-widget"></script>
</head>
```

---

## 🎯 현재 상태 요약

### ✅ 완료 (v2.51.0 ~ v2.53.0)
- 지갑 시스템 완전 구현 (Domain/Data/Presentation)
- 실시간 지갑 UI (ProviderWalletCard, TesterWalletCard)
- Dashboard 통합 완료
- 회원가입 시 지갑 자동 생성

### ⏸️ 보류 (MVP 완료 후 개발)
- Payment 모듈 (토스페이먼츠 연동)
- 출금 시스템
- 거래 내역 페이지 (선택사항)
- Firebase Functions

### 🚀 다음 개발 방향
지갑 시스템은 완성되었으므로, 다른 핵심 기능에 집중:
- 미션 시스템 고도화
- 정산 시스템 개선
- 관리자 기능 추가
- 기타 비즈니스 로직 개발

---

## 📌 참고사항

### Firestore 스키마
```
wallets/{userId}/
  - balance: int
  - totalCharged: int
  - totalSpent: int
  - totalEarned: int
  - totalWithdrawn: int
  - createdAt: Timestamp
  - updatedAt: Timestamp

transactions/{transactionId}/
  - userId: string
  - type: string (charge/spend/earn/withdraw)
  - amount: int
  - status: string (pending/completed/failed)
  - description: string
  - metadata: map
  - createdAt: Timestamp
  - completedAt: Timestamp?

payments/{paymentId}/  # 나중에 추가
  - userId: string
  - orderId: string
  - amount: int
  - points: int
  - status: string
  - paymentKey: string
  - createdAt: Timestamp
```

### 아키텍처 구조
```
lib/features/
├── wallet/                    # ✅ 완료
│   ├── domain/
│   │   ├── entities/         # ✅
│   │   ├── repositories/     # ✅
│   │   └── usecases/         # ✅
│   ├── data/
│   │   └── repositories/     # ✅
│   └── presentation/
│       ├── providers/        # ✅
│       ├── widgets/          # ⏳ TODO
│       └── pages/            # ⏳ TODO
│
├── payment/                   # ⏳ 나중에
│   └── (구조 동일)
```

---

## 📝 업데이트 이력
- **2025-01-26 (v2.51.0)**: 지갑 모듈 기본 구조 완성
- **2025-01-26 (v2.52.0)**: 실시간 지갑 UI 위젯 및 대시보드 통합 완료
- **2025-01-26 (v2.53.0)**: 회원가입 시 지갑 자동 생성 구현
- **2025-01-26**: Payment 모듈 보류 결정 (MVP 완료 후 개발)

**현재 상태**: 지갑 시스템 완료 ✅
**다음 작업**: 다른 핵심 기능 개발 (미션/정산/관리자)
