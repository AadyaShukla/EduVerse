import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart';

class QuizTakingScreen extends ConsumerStatefulWidget {
  final bool isMockExam;
  const QuizTakingScreen({Key? key, this.isMockExam = false}) : super(key: key);

  @override
  ConsumerState<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends ConsumerState<QuizTakingScreen> {
  final Map<String, bool> _showExplanation = {};

  void _submitQuiz() async {
    final student = ref.read(authProvider).student;
    if (student == null) return;

    await ref.read(quizProvider.notifier).submitQuizAttempt(student.id);
  }

  String _formatTimer(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final quizNotifier = ref.read(quizProvider.notifier);

    final quiz = quizState.activeQuiz;
    final attemptResult = quizState.attemptResult;

    if (quiz == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Session')),
        body: const Center(child: Text('No active quiz found.')),
      );
    }

    // Score Summary View
    if (attemptResult != null) {
      final score = attemptResult['score'] ?? 0.0;
      final correctCount = attemptResult['correct_count'] ?? 0;
      final total = attemptResult['total_questions'] ?? 0;
      final details = (attemptResult['answers_detail'] as List?) ?? [];

      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz Result Summary', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.cardSurface,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: score >= 80.0
                      ? AppTheme.accentGradient
                      : (score >= 50.0 ? AppTheme.primaryGradient : const LinearGradient(colors: [Color(0xFFd63031), Color(0xFFFF7675)])),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      'Score: ${score.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$correctCount of $total questions answered correctly',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerLeft,
                child: Text('Detailed Breakdown', style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 12),

              ...details.map((item) {
                final isCorrect = item['is_correct'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isCorrect ? AppTheme.successGreen : AppTheme.warningOrange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? AppTheme.successGreen : AppTheme.warningOrange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Your Answer: ${item['user_answer']}', style: TextStyle(color: isCorrect ? AppTheme.successGreen : AppTheme.warningOrange, fontSize: 13)),
                      Text('Correct Answer: ${item['correct_answer']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('Explanation: ${item['explanation']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Dashboard'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final questions = (quiz['questions'] as List?) ?? [];
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Session')),
        body: const Center(child: Text('No questions generated.')),
      );
    }

    final currentIndex = quizState.currentQuestionIndex;
    final currentQ = questions[currentIndex];
    final qId = currentQ['id'] ?? 'q_$currentIndex';
    final selectedAnswer = quizState.userAnswers[qId];
    final options = (currentQ['options'] as List?) ?? [];
    final isMcq = currentQ['type'] == 'mcq';

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${currentIndex + 1} of ${questions.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
        actions: [
          if (widget.isMockExam && quizState.isTimerActive)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.warningOrange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: AppTheme.warningOrange, size: 18),
                    const SizedBox(width: 6),
                    Text(_formatTimer(quizState.timerSecondsRemaining), style: const TextStyle(color: AppTheme.warningOrange, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (currentIndex + 1) / questions.length,
                backgroundColor: Colors.white10,
                color: AppTheme.primaryViolet,
              ),
              const SizedBox(height: 20),

              // Question Text Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  currentQ['question'] ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              // Answer Options or Text Entry
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (isMcq)
                        ...options.map((opt) {
                          final isSelected = selectedAnswer == opt;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => quizNotifier.recordAnswer(qId, opt),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryViolet.withOpacity(0.25) : AppTheme.cardSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryViolet : Colors.white10,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                      color: isSelected ? AppTheme.primaryViolet : AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(opt, style: const TextStyle(fontSize: 15)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList()
                      else
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Enter Short Answer',
                            hintText: 'Type your answer here...',
                          ),
                          onChanged: (val) => quizNotifier.recordAnswer(qId, val),
                        ),

                      const SizedBox(height: 16),

                      // Immediate Feedback Check Toggle
                      if (selectedAnswer != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showExplanation[qId] = !(_showExplanation[qId] ?? false);
                              });
                            },
                            icon: const Icon(Icons.info_outline, color: AppTheme.accentCyan),
                            label: const Text('Show Immediate Feedback & Explanation', style: TextStyle(color: AppTheme.accentCyan)),
                          ),
                        ),

                      if (_showExplanation[qId] == true)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.accentCyan),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Correct Answer: ${currentQ['correct_answer']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                              const SizedBox(height: 6),
                              Text('Explanation: ${currentQ['explanation']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentIndex > 0)
                    OutlinedButton(
                      onPressed: quizNotifier.previousQuestion,
                      child: const Text('Previous'),
                    )
                  else
                    const SizedBox.shrink(),

                  if (currentIndex < questions.length - 1)
                    ElevatedButton(
                      onPressed: quizNotifier.nextQuestion,
                      child: const Text('Next Question'),
                    )
                  else
                    ElevatedButton(
                      onPressed: quizState.isLoading ? null : _submitQuiz,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                      child: quizState.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Quiz', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
