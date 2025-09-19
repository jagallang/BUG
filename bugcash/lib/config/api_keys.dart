class ApiKeys {
  // Gemini API Key
  // Get your API key from: https://aistudio.google.com/app/apikey
  // 보안을 위해 환경변수에서 읽어오거나 외부 설정 파일을 사용하세요
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'your_gemini_api_key_here',
  );

  // 개발용 키 설정 방법:
  // flutter run --dart-define=GEMINI_API_KEY=your_actual_key_here
  // 또는 IDE에서 Additional run args에 --dart-define=GEMINI_API_KEY=your_key 추가

  // WARNING: Never commit real API keys to version control!
  // Use environment variables or secure storage in production
}