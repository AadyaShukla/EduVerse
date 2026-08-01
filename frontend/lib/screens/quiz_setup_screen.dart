import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';
import 'quiz_taking_screen.dart';

class QuizSetupScreen extends ConsumerStatefulWidget {
  const QuizSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends ConsumerState<QuizSetupScreen> {
  final _topicController = TextEditingController(text: 'Algebra & Equations');
  final _notesController = TextEditingController();
  bool _isMockExamMode = false;
  int _examDurationMinutes = 15;

  @override
  void dispose() {
    _topicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startQuiz() async {
    final student = ref.read(authProvider).student;
    if (student == null) return;

    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;

    final success = await ref.read(quizProvider.notifier).generateQuiz(
      studentId: student.id,
      topic: topic,
      notesText: _notesController.text.trim(),
    );

    if (success) {
      if (_isMockExamMode) {
        ref.read(quizProvider.notifier).startMockExamTimer(_examDurationMinutes, () {
          // Auto submit on time up
          ref.read(quizProvider.notifier).submitQuizAttempt(student.id);
        });
      }

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuizTakingScreen(isMockExam: _isMockExamMode)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Practice & Quizzes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Adaptive Engine Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology_rounded, color: Colors.black, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'AI Adaptive Difficulty',
                            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Questions auto-adjust to your past score history (>80% -> Harder, <50% -> Foundational).',
                            style: TextStyle(color: Colors.black87, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Mode Selector (Standard Practice vs Timed Mock Exam)
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Standard Quiz')),
                      selected: !_isMockExamMode,
                      selectedColor: AppTheme.primaryViolet,
                      onSelected: (val) => setState(() => _isMockExamMode = !_isMockExamMode),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Timed Mock Exam')),
                      selected: _isMockExamMode,
                      selectedColor: AppTheme.warningOrange,
                      onSelected: (val) => setState(() => _isMockExamMode = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Topic Input
              TextField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Study Topic or Chapter Name',
                  prefixIcon: Icon(Icons.topic_rounded, color: AppTheme.primaryViolet),
                ),
              ),
              const SizedBox(height: 16),

              // Notes Input Context
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Upload / Paste Study Notes (Optional)',
                  hintText: 'Paste summary notes for AI quiz generation...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Mock Exam Duration Slider
              if (_isMockExamMode) ...[
                Text('Exam Countdown Duration: $_examDurationMinutes Minutes', style: const TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: _examDurationMinutes.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  activeColor: AppTheme.warningOrange,
                  label: '$_examDurationMinutes mins',
                  onChanged: (val) => setState(() => _examDurationMinutes = val.toInt()),
                ),
                const SizedBox(height: 16),
              ],

              // Error Message
              if (quizState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    quizState.errorMessage!,
                    style: const TextStyle(color: AppTheme.warningOrange, fontSize: 13),
                  ),
                ),

              // Start Quiz Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: quizState.isLoading ? null : _startQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMockExamMode ? AppTheme.warningOrange : AppTheme.primaryViolet,
                  ),
                  child: quizState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isMockExamMode ? 'Start Timed Mock Exam' : 'Generate Adaptive Quiz'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
