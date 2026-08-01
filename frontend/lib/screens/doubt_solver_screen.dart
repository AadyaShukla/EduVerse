import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/doubt_provider.dart';
import 'doubt_explanation_screen.dart';

class DoubtSolverScreen extends ConsumerStatefulWidget {
  const DoubtSolverScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DoubtSolverScreen> createState() => _DoubtSolverScreenState();
}

class _DoubtSolverScreenState extends ConsumerState<DoubtSolverScreen> {
  final _textController = TextEditingController();

  final List<String> _languages = ['English', 'Hindi', 'Spanish', 'French', 'German', 'Marathi', 'Tamil', 'Telugu'];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitDoubt() async {
    final student = ref.read(authProvider).student;
    if (student == null) return;

    ref.read(doubtProvider.notifier).setQuestionText(_textController.text.trim());

    final success = await ref.read(doubtProvider.notifier).solveDoubt(student.id);
    if (success) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DoubtExplanationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doubtState = ref.watch(doubtProvider);
    final doubtNotifier = ref.read(doubtProvider.notifier);

    if (_textController.text != doubtState.questionText && !doubtState.isListening) {
      _textController.text = doubtState.questionText;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Doubt Solver', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.help_center_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Ask Any Study Doubt',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Use OCR Photo, Voice STT, or type below for step-by-step AI explanations.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Input Methods Toolbar (Camera OCR, Gallery OCR, Voice STT)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: doubtState.isLoading
                          ? null
                          : () => doubtNotifier.captureImageOCR(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Camera OCR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cardSurface,
                        foregroundColor: AppTheme.accentCyan,
                        padding: const EdgeInsets.vertical(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: doubtState.isLoading
                          ? null
                          : () => doubtNotifier.captureImageOCR(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Gallery OCR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cardSurface,
                        foregroundColor: AppTheme.primaryViolet,
                        padding: const EdgeInsets.vertical(14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Voice Input Microphone Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: doubtState.isLoading ? null : doubtNotifier.toggleVoiceInput,
                  icon: Icon(
                    doubtState.isListening ? Icons.mic : Icons.mic_none,
                    color: doubtState.isListening ? AppTheme.warningOrange : AppTheme.accentCyan,
                  ),
                  label: Text(
                    doubtState.isListening ? 'Listening... Speak your doubt' : 'Voice Input (Native Android STT)',
                    style: TextStyle(
                      color: doubtState.isListening ? AppTheme.warningOrange : AppTheme.accentCyan,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: doubtState.isListening ? AppTheme.warningOrange : AppTheme.accentCyan,
                    ),
                    padding: const EdgeInsets.vertical(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Multilingual Language Preference Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Explanation Language:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: doubtState.targetLanguage,
                    dropdownColor: AppTheme.cardSurface,
                    items: _languages
                        .map((lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang, style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) doubtNotifier.setTargetLanguage(val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Text Confirmation Editor
              TextField(
                controller: _textController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Confirm / Edit Question Text',
                  hintText: 'Type or edit question here...',
                  alignLabelWithHint: true,
                ),
                onChanged: (val) => doubtNotifier.setQuestionText(val),
              ),
              const SizedBox(height: 20),

              // Error Message Banner
              if (doubtState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    doubtState.errorMessage!,
                    style: const TextStyle(color: AppTheme.warningOrange, fontSize: 13),
                  ),
                ),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: doubtState.isLoading ? null : _submitDoubt,
                  child: doubtState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Get Step-by-Step AI Explanation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
