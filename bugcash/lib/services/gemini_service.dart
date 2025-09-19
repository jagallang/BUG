import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_keys.dart';

class GeminiService {
  static const String _apiKey = ApiKeys.geminiApiKey;
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<String> generateText(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'No response generated';
    } catch (e) {
      throw Exception('Error generating text: $e');
    }
  }

  Future<String> generateBugAnalysis(String bugDescription) async {
    final prompt = '''
    다음 버그 설명을 분석하고 다음 정보를 제공해주세요:
    1. 가능한 원인들
    2. 재현 단계
    3. 해결 방안 제안
    4. 우선순위 (높음/중간/낮음)

    버그 설명: $bugDescription
    ''';

    return await generateText(prompt);
  }

  Future<String> generateTestCase(String featureDescription) async {
    final prompt = '''
    다음 기능에 대한 테스트 케이스를 생성해주세요:
    1. 정상 동작 테스트 케이스
    2. 예외 상황 테스트 케이스
    3. 경계값 테스트 케이스

    기능 설명: $featureDescription
    ''';

    return await generateText(prompt);
  }

  Future<String> generateCodeReview(String codeSnippet) async {
    final prompt = '''
    다음 코드를 리뷰하고 개선사항을 제안해주세요:
    1. 코드 품질 평가
    2. 잠재적 버그 지적
    3. 성능 개선 제안
    4. 가독성 개선 제안

    코드:
    $codeSnippet
    ''';

    return await generateText(prompt);
  }
}