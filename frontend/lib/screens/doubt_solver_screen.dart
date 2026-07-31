import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class DoubtSolverScreen extends StatefulWidget {
  const DoubtSolverScreen({super.key});

  @override
  State<DoubtSolverScreen> createState() => _DoubtSolverScreenState();
}

class _DoubtSolverScreenState extends State<DoubtSolverScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  final LanguageIdentifier _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool _isLoading = false;
  String _detectedLanguage = 'en'; // default
  bool _explainInEnglish = false;
  List<String> _explanationSteps = [];

  @override
  void dispose() {
    _questionController.dispose();
    _textRecognizer.close();
    _languageIdentifier.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() => _isLoading = true);
      final InputImage inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      setState(() {
        _questionController.text = recognizedText.text;
        _isLoading = false;
      });
      _detectLanguage(recognizedText.text);
    }
  }

  Future<void> _detectLanguage(String text) async {
    if (text.isEmpty) return;
    try {
      final String languageCode = await _languageIdentifier.identifyLanguage(text);
      if (languageCode != 'und') {
        setState(() {
          _detectedLanguage = languageCode;
        });
      }
    } catch (e) {
      // Ignored
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      await Permission.microphone.request();
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _questionController.text = val.recognizedWords;
            _detectLanguage(val.recognizedWords);
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _submitDoubt() async {
    if (_questionController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _explanationSteps = [];
    });

    final String targetLang = _explainInEnglish ? 'en' : _detectedLanguage;

    try {
      // In production, point to real backend URL
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/doubt-solver/'), // Android emulator localhost
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': '00000000-0000-0000-0000-000000000000', // Mock UUID for now
          'question': _questionController.text,
          'language': targetLang,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _explanationSteps = List<String>.from(data['steps']);
        });
      } else {
        _showError('Failed to get explanation.');
      }
    } catch (e) {
      _showError('Error connecting to server.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _readAloud() async {
    final textToRead = _explanationSteps.join('. ');
    if (textToRead.isNotEmpty) {
      final String lang = _explainInEnglish ? 'en' : _detectedLanguage;
      await _flutterTts.setLanguage(lang);
      await _flutterTts.speak(textToRead);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doubt Solver')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () => _pickImage(ImageSource.camera),
                  tooltip: 'Take Photo',
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  tooltip: 'Upload Image',
                ),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : null),
                  onPressed: _listen,
                  tooltip: 'Voice Input',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Your Question (Edit if needed)',
              ),
              onChanged: _detectLanguage,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Explain in English'),
                Switch(
                  value: _explainInEnglish,
                  onChanged: (val) => setState(() => _explainInEnglish = val),
                ),
                Expanded(child: Text('Detected: $_detectedLanguage', textAlign: TextAlign.right)),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitDoubt,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Solve Doubt'),
            ),
            const SizedBox(height: 24),
            if (_explanationSteps.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Explanation:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: _readAloud,
                    tooltip: 'Read Aloud',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._explanationSteps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('• $step', style: const TextStyle(fontSize: 16)),
              )),
            ]
          ],
        ),
      ),
    );
  }
}
