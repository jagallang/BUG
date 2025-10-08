/// 에러를 사용자 친화적인 메시지로 변환하는 헬퍼 클래스
import '../exceptions/wallet_exceptions.dart';

class ErrorMessageHelper {
  /// 에러 객체를 사용자가 이해할 수 있는 한글 메시지로 변환
  static String getErrorMessage(dynamic error) {
    if (error is WalletNotFoundException) {
      return '지갑을 찾을 수 없습니다.\n고객센터에 문의해주세요.';
    } else if (error is InsufficientBalanceException) {
      return '잔액이 부족합니다.\n현재 잔액: ${error.currentBalance}P\n필요 금액: ${error.requiredAmount}P';
    } else if (error is DuplicatePaymentException) {
      return '이미 처리된 결제입니다.\n중복 결제는 불가능합니다.';
    } else if (error is InvalidAmountException) {
      return error.toString();
    } else if (error is TransactionFailedException) {
      return '거래 처리 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
    }

    // 기타 에러
    final errorString = error.toString();

    // Firebase 에러 처리
    if (errorString.contains('network-request-failed')) {
      return '인터넷 연결을 확인해주세요.';
    } else if (errorString.contains('permission-denied')) {
      return '접근 권한이 없습니다.';
    } else if (errorString.contains('timeout')) {
      return '요청 시간이 초과되었습니다.\n잠시 후 다시 시도해주세요.';
    }

    // 기본 에러 메시지
    return '오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
  }

  /// 짧은 에러 메시지 (SnackBar용)
  static String getShortErrorMessage(dynamic error) {
    if (error is WalletNotFoundException) {
      return '지갑을 찾을 수 없습니다';
    } else if (error is InsufficientBalanceException) {
      return '잔액이 부족합니다 (${error.currentBalance}P)';
    } else if (error is DuplicatePaymentException) {
      return '이미 처리된 결제입니다';
    } else if (error is InvalidAmountException) {
      return error.message;
    } else if (error is TransactionFailedException) {
      return '거래 처리 실패';
    }

    final errorString = error.toString();
    if (errorString.contains('network-request-failed')) {
      return '인터넷 연결 확인';
    } else if (errorString.contains('permission-denied')) {
      return '접근 권한 없음';
    } else if (errorString.contains('timeout')) {
      return '요청 시간 초과';
    }

    return '오류 발생';
  }
}
