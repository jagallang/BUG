import 'dart:io';
import '../services/gemini_service.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('사용법: dart run lib/scripts/gemini_cli.dart "질문내용"');
    return;
  }

  final geminiService = GeminiService();
  final prompt = arguments.join(' ');

  print('Gemini에게 질문중: $prompt');
  print('---');

  try {
    final response = await geminiService.generateText(prompt);
    print(response);
  } catch (e) {
    print('Error: $e');
  }
}