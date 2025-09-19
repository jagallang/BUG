import 'dart:io';
import '../services/gemini_service.dart';

void main() async {
  final geminiService = GeminiService();

  print('=== Gemini AI CLI ===');
  print('명령어:');
  print('  /quit - 종료');
  print('  /bug [설명] - 버그 분석');
  print('  /test [기능] - 테스트 케이스 생성');
  print('  /review [코드] - 코드 리뷰');
  print('---');

  while (true) {
    stdout.write('Gemini> ');
    final input = stdin.readLineSync();

    if (input == null || input.trim().isEmpty) continue;

    if (input == '/quit') {
      print('안녕히 가세요!');
      break;
    }

    try {
      String response;

      if (input.startsWith('/bug ')) {
        final bugDesc = input.substring(5);
        response = await geminiService.generateBugAnalysis(bugDesc);
      } else if (input.startsWith('/test ')) {
        final feature = input.substring(6);
        response = await geminiService.generateTestCase(feature);
      } else if (input.startsWith('/review ')) {
        final code = input.substring(8);
        response = await geminiService.generateCodeReview(code);
      } else {
        response = await geminiService.generateText(input);
      }

      print('\n$response\n');
      print('---');
    } catch (e) {
      print('Error: $e');
    }
  }
}