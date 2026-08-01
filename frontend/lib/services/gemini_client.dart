import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiClient {
  GenerativeModel? _model;

  void init(String apiKey) {
    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
    }
  }

  bool get isReady => _model != null;

  Future<String> askTutorStub(String prompt, int grade) async {
    if (_model != null) {
      try {
        final content = [Content.text("Grade $grade student asks: $prompt")];
        final response = await _model!.generateContent(content);
        return response.text ?? "No response received from Gemini.";
      } catch (e) {
        return "Gemini API error: $e";
      }
    }
    return "[Phase 0 Gemini Scaffold]: Gemini API client ready. Add API Key to unleash AI tutor capabilities!";
  }
}
