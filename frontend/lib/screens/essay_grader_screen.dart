import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/productivity_provider.dart';

class EssayGraderScreen extends ConsumerStatefulWidget {
  const EssayGraderScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EssayGraderScreen> createState() => _EssayGraderScreenState();
}

class _EssayGraderScreenState extends ConsumerState<EssayGraderScreen> {
  final _subjectController = TextEditingController(text: 'English Literature');
  final _essayController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _essayController.dispose();
    super.dispose();
  }

  void _gradeEssay() async {
    final student = ref.read(authProvider).student;
    if (student == null) return;

    final essayText = _essayController.text.trim();
    if (essayText.isEmpty) return;

    await ref.read(productivityProvider.notifier).gradeEssay(
      studentId: student.id,
      subject: _subjectController.text.trim(),
      essayText: essayText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final prodState = ref.watch(productivityProvider);
    final result = prodState.essayGradeResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Essay & Assignment Grader', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  prefixIcon: Icon(Icons.subject, color: AppTheme.primaryViolet),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _essayController,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Paste Essay / Assignment Text',
                  hintText: 'Paste essay content for AI grading & inline feedback...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: prodState.isLoading ? null : _gradeEssay,
                  child: prodState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Grade Essay & Get Inline Suggestions'),
                ),
              ),
              const SizedBox(height: 24),

              // Feedback Presentation Section
              if (result != null) ...[
                Text('AI Evaluation & Feedback', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),

                // Overall Score Cards
                Row(
                  children: [
                    _buildScoreTile('Grammar', result['grammar_score'] ?? 8, AppTheme.primaryViolet),
                    const SizedBox(width: 10),
                    _buildScoreTile('Structure', result['structure_score'] ?? 7, AppTheme.accentCyan),
                    const SizedBox(width: 10),
                    _buildScoreTile('Clarity', result['clarity_score'] ?? 9, AppTheme.successGreen),
                  ],
                ),
                const SizedBox(height: 16),

                // Overall Summary Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Overall Summary', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentCyan)),
                      const SizedBox(height: 6),
                      Text(result['overall_feedback'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Inline Suggestion Categories
                ...((result['categories'] as List?) ?? []).map((cat) {
                  final title = cat['category'] ?? '';
                  final suggestions = (cat['suggestions'] as List?) ?? [];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        ...suggestions.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_right, color: AppTheme.accentCyan),
                              Expanded(child: Text(s, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreTile(String title, int score, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text('$score/10', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
