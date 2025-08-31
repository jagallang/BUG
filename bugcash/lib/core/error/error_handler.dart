import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';
import 'app_error.dart';

class ErrorHandler {
  static AppError handleError(dynamic error, [StackTrace? stackTrace]) {
    AppLogger.error('Handling error', 'ErrorHandler', error, stackTrace);
    
    if (error is AppError) {
      return error;
    }
    
    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthError(error, stackTrace);
    }
    
    if (error is FirebaseException) {
      return _handleFirebaseError(error, stackTrace);
    }
    
    if (error is FormatException) {
      return ValidationError(
        message: '잘못된 데이터 형식입니다',
        code: 'format_error',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    
    return UnknownError(
      message: error?.toString() ?? '알 수 없는 오류가 발생했습니다',
      code: 'unknown_error',
      originalError: error,
      stackTrace: stackTrace,
    );
  }
  
  static FirebaseError _handleFirebaseAuthError(
    FirebaseAuthException error, 
    StackTrace? stackTrace,
  ) {
    String message;
    switch (error.code) {
      case 'user-not-found':
        message = '사용자를 찾을 수 없습니다';
        break;
      case 'wrong-password':
        message = '비밀번호가 올바르지 않습니다';
        break;
      case 'email-already-in-use':
        message = '이미 사용 중인 이메일입니다';
        break;
      case 'weak-password':
        message = '비밀번호가 너무 약합니다';
        break;
      case 'invalid-email':
        message = '올바르지 않은 이메일 형식입니다';
        break;
      case 'operation-not-allowed':
        message = '허용되지 않은 작업입니다';
        break;
      case 'too-many-requests':
        message = '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요';
        break;
      default:
        message = error.message ?? '인증 오류가 발생했습니다';
    }
    
    return FirebaseError(
      message: message,
      code: error.code,
      originalError: error,
      stackTrace: stackTrace,
    );
  }
  
  static FirebaseError _handleFirebaseError(
    FirebaseException error, 
    StackTrace? stackTrace,
  ) {
    String message;
    switch (error.code) {
      case 'permission-denied':
        message = '접근 권한이 없습니다';
        break;
      case 'not-found':
        message = '요청한 데이터를 찾을 수 없습니다';
        break;
      case 'already-exists':
        message = '이미 존재하는 데이터입니다';
        break;
      case 'resource-exhausted':
        message = '할당량을 초과했습니다';
        break;
      case 'failed-precondition':
        message = '작업을 수행할 수 없는 상태입니다';
        break;
      case 'aborted':
        message = '작업이 중단되었습니다';
        break;
      case 'out-of-range':
        message = '유효하지 않은 범위입니다';
        break;
      case 'unimplemented':
        message = '구현되지 않은 기능입니다';
        break;
      case 'internal':
        message = '내부 서버 오류가 발생했습니다';
        break;
      case 'unavailable':
        message = '서비스를 사용할 수 없습니다';
        break;
      case 'data-loss':
        message = '데이터 손실이 발생했습니다';
        break;
      case 'unauthenticated':
        message = '인증이 필요합니다';
        break;
      default:
        message = error.message ?? 'Firebase 오류가 발생했습니다';
    }
    
    return FirebaseError(
      message: message,
      code: error.code,
      originalError: error,
      stackTrace: stackTrace,
    );
  }
  
  static String getUserFriendlyMessage(AppError error) {
    // 사용자에게 표시할 친화적인 메시지 반환
    switch (error.runtimeType) {
      case NetworkError:
        return '인터넷 연결을 확인해주세요';
      case FirebaseError:
        return error.message;
      case ValidationError:
        return error.message;
      default:
        return '오류가 발생했습니다. 잠시 후 다시 시도해주세요';
    }
  }
}