abstract class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  
  const AppError({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });
  
  @override
  String toString() {
    return 'AppError(message: $message, code: $code)';
  }
}

class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

class FirebaseError extends AppError {
  const FirebaseError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

class ValidationError extends AppError {
  const ValidationError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

class UnknownError extends AppError {
  const UnknownError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}