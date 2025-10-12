/// 지갑 관련 커스텀 Exception 클래스들
/// 프로덕션에서 사용자 친화적인 에러 메시지 제공
library wallet_exceptions;

/// 지갑을 찾을 수 없음
class WalletNotFoundException implements Exception {
  final String message;
  final String? userId;

  WalletNotFoundException({
    this.message = '지갑을 찾을 수 없습니다',
    this.userId,
  });

  @override
  String toString() => message;
}

/// 잔액 부족
class InsufficientBalanceException implements Exception {
  final String message;
  final int currentBalance;
  final int requiredAmount;

  InsufficientBalanceException({
    this.message = '잔액이 부족합니다',
    required this.currentBalance,
    required this.requiredAmount,
  });

  @override
  String toString() => '$message (현재: ${currentBalance}P, 필요: ${requiredAmount}P)';
}

/// 중복 결제
class DuplicatePaymentException implements Exception {
  final String message;
  final String? orderId;

  DuplicatePaymentException({
    this.message = '이미 처리된 결제입니다',
    this.orderId,
  });

  @override
  String toString() => orderId != null ? '$message (orderId: $orderId)' : message;
}

/// 거래 금액 유효하지 않음
class InvalidAmountException implements Exception {
  final String message;
  final int amount;
  final int? minAmount;
  final int? maxAmount;

  InvalidAmountException({
    this.message = '유효하지 않은 금액입니다',
    required this.amount,
    this.minAmount,
    this.maxAmount,
  });

  @override
  String toString() {
    if (minAmount != null && amount < minAmount!) {
      return '최소 $minAmount원 이상 충전해주세요';
    }
    if (maxAmount != null && amount > maxAmount!) {
      return '최대 $maxAmount원까지 충전 가능합니다';
    }
    return message;
  }
}

/// 거래 처리 실패
class TransactionFailedException implements Exception {
  final String message;
  final dynamic originalError;

  TransactionFailedException({
    this.message = '거래 처리 중 오류가 발생했습니다',
    this.originalError,
  });

  @override
  String toString() => message;
}
