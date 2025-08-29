import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static const String _appName = 'BugCash';
  
  static void debug(String message, [String? tag]) {
    _log(LogLevel.debug, message, tag);
  }
  
  static void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }
  
  static void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }
  
  static void error(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, tag, error: error, stackTrace: stackTrace);
  }
  
  static void _log(
    LogLevel level, 
    String message, 
    String? tag, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // 프로덕션에서는 에러 레벨만 로깅
    if (kReleaseMode && level != LogLevel.error) {
      return;
    }
    
    // 디버그 모드에서만 전체 로깅
    if (kDebugMode) {
      final logTag = tag != null ? '$_appName:$tag' : _appName;
      final logMessage = '${level.name.toUpperCase()}: $message';
      
      developer.log(
        logMessage,
        name: logTag,
        level: _getLevelValue(level),
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
  
  static int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
  
  // 민감한 데이터 마스킹
  static String maskSensitiveData(String data) {
    if (!kDebugMode) {
      return '***MASKED***';
    }
    
    // 이메일 마스킹
    if (data.contains('@')) {
      final parts = data.split('@');
      if (parts.length == 2) {
        final username = parts[0];
        final domain = parts[1];
        final maskedUsername = username.length > 2 
            ? '${username.substring(0, 2)}***' 
            : '***';
        return '$maskedUsername@$domain';
      }
    }
    
    // 긴 문자열 마스킹
    if (data.length > 10) {
      return '${data.substring(0, 4)}***${data.substring(data.length - 4)}';
    }
    
    return '***';
  }
}