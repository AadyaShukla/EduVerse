import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class SpeechTTSService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isSpeechInitialized = false;

  Future<bool> initSpeech() async {
    if (!_isSpeechInitialized) {
      _isSpeechInitialized = await _speech.initialize(
        onError: (val) {},
        onStatus: (val) {},
      );
    }
    return _isSpeechInitialized;
  }

  /// Listen to voice input for STT
  Future<void> startListening(Function(String) onResult) async {
    final available = await initSpeech();
    if (available) {
      _speech.listen(
        onResult: (val) {
          if (val.recognizedWords.isNotEmpty) {
            onResult(val.recognizedWords);
          }
        },
      );
    } else {
      onResult("What is Newton's Second Law of Motion?");
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Read text aloud using native TTS
  Future<void> speakText(String text, {String language = 'en-US'}) async {
    await _tts.setLanguage(language);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}
