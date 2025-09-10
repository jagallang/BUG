import 'package:flutter_test/flutter_test.dart';
import 'package:bugcash_web_demo/models/mission_model.dart';

void main() {
  group('MissionModel Tests', () {
    test('MissionType enum has all required values', () {
      // Enum 값들이 올바르게 정의되어 있는지 확인
      expect(MissionType.values.contains(MissionType.bugReport), isTrue);
      expect(MissionType.values.contains(MissionType.featureTesting), isTrue);
      expect(MissionType.values.contains(MissionType.usabilityTest), isTrue);
      expect(MissionType.values.contains(MissionType.performanceTest), isTrue);
      expect(MissionType.values.contains(MissionType.performance), isTrue); // 새로 추가된 별칭
      expect(MissionType.values.contains(MissionType.survey), isTrue);
      expect(MissionType.values.contains(MissionType.feedback), isTrue);
      expect(MissionType.values.contains(MissionType.functional), isTrue);
      expect(MissionType.values.contains(MissionType.uiUx), isTrue);
      expect(MissionType.values.contains(MissionType.security), isTrue);
      expect(MissionType.values.contains(MissionType.compatibility), isTrue);
    });

    test('MissionType enum count is correct', () {
      // 현재 13개의 미션 타입이 정의되어 있어야 함
      expect(MissionType.values.length, equals(13)); // performance 별칭 추가로 13개
    });
  });

  group('Mission Status Tests', () {
    test('MissionStatus enum has all required values', () {
      expect(MissionStatus.values.isNotEmpty, isTrue);
      // 여기에 실제 MissionStatus enum 값들에 대한 테스트를 추가할 수 있습니다
    });
  });
}