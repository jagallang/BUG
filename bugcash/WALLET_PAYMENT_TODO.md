# 💰 Wallet & Payment 모듈 TODO (v2.51.0)

## 📋 완료된 작업 (2025-01-26)

### ✅ Domain Layer
- [x] `wallet_entity.dart` - 지갑 엔티티
- [x] `transaction_entity.dart` - 거래 내역 엔티티
- [x] `wallet_repository.dart` - 지갑 Repository 인터페이스
- [x] `wallet_service.dart` - 지갑 비즈니스 로직

### ✅ Data Layer
- [x] `wallet_repository_impl.dart` - Firestore 연동 Repository 구현체

### ✅ Presentation Layer
- [x] `wallet_provider.dart` - Riverpod Provider (Repository 패턴 적용)

---

## 🚧 남은 작업 (우선순위 순)

### 1. Wallet UI 위젯 생성 (필수)

#### A. 공급자 지갑 카드
**파일**: `lib/features/wallet/presentation/widgets/provider_wallet_card.dart`

**TODO:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wallet_provider.dart';

class ProviderWalletCard extends ConsumerWidget {
  final String providerId;

  // TODO: 지갑 잔액 표시
  // TODO: 이번 달 충전 금액 표시
  // TODO: 이번 달 사용 금액 표시
  // TODO: 충전 버튼 (Payment 모듈로 라우팅)
  // TODO: 거래 내역 버튼
  // TODO: 로딩/에러 상태 처리
}
```

#### B. 테스터 지갑 카드
**파일**: `lib/features/wallet/presentation/widgets/tester_wallet_card.dart`

**TODO:**
```dart
class TesterWalletCard extends ConsumerWidget {
  final String testerId;

  // TODO: 지갑 잔액 표시
  // TODO: 이번 달 적립 금액 표시
  // TODO: 총 적립 금액 표시
  // TODO: 출금 버튼 (출금 다이얼로그)
  // TODO: 거래 내역 버튼
  // TODO: 로딩/에러 상태 처리
}
```

#### C. 거래 내역 리스트 아이템
**파일**: `lib/features/wallet/presentation/widgets/transaction_list_item.dart`

**TODO:**
```dart
class TransactionListItem extends StatelessWidget {
  final TransactionEntity transaction;

  // TODO: 거래 타입별 아이콘 (💳충전, 📤사용, 💰적립, 🏦출금)
  // TODO: 거래 금액 (+/-) 표시
  // TODO: 거래 설명
  // TODO: 거래 시간
  // TODO: 상태 (pending/completed/failed)
}
```

---

### 2. Dashboard 통합 (필수)

#### A. 공급자 대시보드
**파일**: `lib/features/provider_dashboard/presentation/pages/provider_dashboard_page.dart`

**TODO:**
```dart
// Line ~610: _buildPaymentTab() 수정

import '../../../wallet/presentation/widgets/provider_wallet_card.dart';

Widget _buildPaymentTab() {
  return SingleChildScrollView(
    child: Column(
      children: [
        // TODO: ProviderWalletCard 위젯 사용
        ProviderWalletCard(providerId: widget.providerId),

        // TODO: 충전 버튼 → Payment 페이지로 라우팅
        // TODO: 거래 내역 리스트 (TransactionListItem 사용)
      ],
    ),
  );
}
```

#### B. 테스터 대시보드
**파일**: `lib/features/tester_dashboard/presentation/pages/tester_dashboard_page.dart`

**TODO:**
```dart
import '../../../wallet/presentation/widgets/tester_wallet_card.dart';

// TODO: 상단 헤더 또는 별도 탭에 TesterWalletCard 추가
Widget _buildWalletSection() {
  return TesterWalletCard(testerId: widget.testerId);
}
```

---

### 3. 회원가입 시 지갑 자동 생성 (필수)

**파일**: `lib/core/services/auth_service.dart`

**TODO:**
```dart
// Line ~95: createUserProfile() 수정

static Future<void> createUserProfile(String userId, Map<String, dynamic> userData) async {
  // 기존 유저 프로필 생성
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .set({...userData});

  // TODO: 지갑 자동 생성 추가
  await FirebaseFirestore.instance
      .collection('wallets')
      .doc(userId)
      .set({
    'balance': 0,
    'totalCharged': 0,
    'totalSpent': 0,
    'totalEarned': 0,
    'totalWithdrawn': 0,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

---

### 4. Payment 모듈 생성 (나중에)

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

### 5. 거래 내역 페이지 (선택사항)

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

### 6. Firebase Functions (나중에 - 결제 연동 시)

**파일**: `functions/src/index.ts`

**TODO:**
```typescript
// TODO: confirmTossPayment() - 토스페이먼츠 결제 승인 검증
// TODO: deductPointsForApp() - 앱 등록 시 포인트 차감
// TODO: awardPointsToTester() - 미션 완료 시 포인트 적립
// TODO: processWithdrawal() - 출금 신청 처리
```

---

### 7. 환경설정 (나중에)

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

## 🎯 다음 단계 우선순위

1. **ProviderWalletCard, TesterWalletCard 위젯 생성** ← 가장 먼저
2. **Dashboard 통합** (provider_dashboard_page.dart, tester_dashboard_page.dart)
3. **Auth Service 수정** (회원가입 시 지갑 생성)
4. **테스트 & 샘플 데이터 추가**
5. **Payment 모듈 구현** (토스페이먼츠 연동)

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

**마지막 업데이트**: 2025-01-26
**다음 작업**: ProviderWalletCard, TesterWalletCard 위젯 생성
