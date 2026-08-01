import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wellbeing_provider.dart';

class StudyReceiptScreen extends ConsumerStatefulWidget {
  const StudyReceiptScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudyReceiptScreen> createState() => _StudyReceiptScreenState();
}

class _StudyReceiptScreenState extends ConsumerState<StudyReceiptScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final student = ref.read(authProvider).student;
      if (student != null) {
        ref.read(wellbeingProvider.notifier).loadStudyReceipt(student.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wellbeingState = ref.watch(wellbeingProvider);
    final receipt = wellbeingState.studyReceipt;

    final mins = receipt?['total_study_minutes'] ?? 45;
    final doubts = receipt?['doubts_solved_count'] ?? 3;
    final quizzes = receipt?['quizzes_completed_count'] ?? 2;
    final topics = (receipt?['mastered_topics'] as List?) ?? ['Quadratic Formulas', 'Newton\'s Laws'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Study Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Styled Study Receipt Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.accentCyan.withOpacity(0.4), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentCyan.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: AppTheme.accentCyan, size: 48),
                    const SizedBox(height: 12),
                    const Text('EDUVERSE STUDY RECEIPT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    const Text('Daily Learning Summary Log', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const Divider(height: 32, color: Colors.white24),

                    _buildReceiptRow('Total Focus Minutes', '$mins Mins'),
                    _buildReceiptRow('AI Doubts Solved', '$doubts Solved'),
                    _buildReceiptRow('Quizzes Completed', '$quizzes Completed'),

                    const Divider(height: 32, color: Colors.white24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Mastered Core Concepts:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    ...topics.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.stars, color: AppTheme.successGreen, size: 18),
                          const SizedBox(width: 8),
                          Text(t.toString(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    )).toList(),

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('GREAT PROGRESS TODAY! 🎉', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
