import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/ocr_service.dart';
import '../services/speech_tts_service.dart';

class DoubtState {
  final String questionText;
  final String targetLanguage;
  final bool isLoading;
  final bool isListening;
  final Map<String, dynamic>? explanationData;
  final String? errorMessage;

  DoubtState({
    this.questionText = '',
    this.targetLanguage = 'English',
    this.isLoading = false,
    this.isListening = false,
    this.explanationData,
    this.errorMessage,
  });

  DoubtState copyWith({
    String? questionText,
    String? targetLanguage,
    bool? isLoading,
    bool? isListening,
    Map<String, dynamic>? explanationData,
    String? errorMessage,
  }) {
    return DoubtState(
      questionText: questionText ?? this.questionText,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      isLoading: isLoading ?? this.isLoading,
      isListening: isListening ?? this.isListening,
      explanationData: explanationData ?? this.explanationData,
      errorMessage: errorMessage,
    );
  }
}

class DoubtNotifier extends StateNotifier<DoubtState> {
  final ApiService _apiService = ApiService();
  final OCRService _ocrService = OCRService();
  final SpeechTTSService _speechService = SpeechTTSService();

  DoubtNotifier() : super(DoubtState());

  void setQuestionText(String text) {
    state = state.copyWith(questionText: text);
  }

  void setTargetLanguage(String lang) {
    state = state.copyWith(targetLanguage: lang);
  }

  /// Process image via OCR (camera or gallery)
  Future<void> captureImageOCR(ImageSource source) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final text = await _ocrService.processImageFromSource(source);

    if (text != null && text.isNotEmpty) {
      state = state.copyWith(
        questionText: text,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not extract text from selected image.',
      );
    }
  }

  /// Voice input listening via native STT
  Future<void> toggleVoiceInput() async {
    if (state.isListening) {
      await _speechService.stopListening();
      state = state.copyWith(isListening: false);
    } else {
      state = state.copyWith(isListening: true);
      await _speechService.startListening((recognizedText) {
        state = state.copyWith(
          questionText: recognizedText,
          isListening: false,
        );
      });
    }
  }

  /// Submit doubt to backend Gemini agent
  Future<bool> solveDoubt(String studentId) async {
    if (state.questionText.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter or capture a question first.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final res = await _apiService.solveDoubt(
      studentId: studentId,
      questionText: state.questionText,
      targetLanguage: state.targetLanguage,
    );

    if (res['success']) {
      state = state.copyWith(
        isLoading: false,
        explanationData: res['data'],
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: res['message'],
      );
      return false;
    }
  }

  /// Speak text aloud via TTS
  Future<void> speakExplanation(String text) async {
    await _speechService.speakText(text);
  }

  Future<void> stopSpeaking() async {
    await _speechService.stopSpeaking();
  }
}

final doubtProvider = StateNotifierProvider<DoubtNotifier, DoubtState>((ref) {
  return DoubtNotifier();
});
