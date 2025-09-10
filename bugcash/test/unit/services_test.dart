import 'package:flutter_test/flutter_test.dart';
import 'package:bugcash_web_demo/core/utils/logger.dart';

void main() {
  group('Logger Tests', () {
    test('Logger info method works correctly', () {
      // 로거가 정상적으로 작동하는지 테스트
      expect(() => AppLogger.info('Test message', 'TestClass'), returnsNormally);
    });

    test('Logger error method works correctly', () {
      // 에러 로깅이 정상적으로 작동하는지 테스트
      final testError = Exception('Test error');
      expect(() => AppLogger.error('Test error message', 'TestClass', testError), returnsNormally);
    });

    test('Logger warning method works correctly', () {
      // 경고 로깅이 정상적으로 작동하는지 테스트
      expect(() => AppLogger.warning('Test warning', 'TestClass'), returnsNormally);
    });

    test('Logger debug method works correctly', () {
      // 디버그 로깅이 정상적으로 작동하는지 테스트
      expect(() => AppLogger.debug('Test debug message', 'TestClass'), returnsNormally);
    });
  });
}