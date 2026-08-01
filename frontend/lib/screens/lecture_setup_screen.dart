import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/lecture_provider.dart';
import 'lecture_screen.dart';

class LectureSetupScreen extends ConsumerStatefulWidget {
  const LectureSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LectureSetupScreen> createState() => _LectureSetupScreenState();
}

class _LectureSetupScreenState extends ConsumerState<LectureSetupScreen> {
  final _topicController = TextEditingController();

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _launchLecture(String topic) async {
    final student = ref.read(authProvider).student;
    if (student == null) return;

    final success = await ref.read(lectureProvider.notifier).startLecture(
      studentId: student.id,
      topic: topic,
      grade: student.grade,
    );

    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LectureScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lectureState = ref.watch(lectureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive AI Lectures', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cast_for_education_rounded, color: Colors.white, size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Solo On-Demand AI Lectures', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Slide-based narration, pause-and-ask doubts, and checkpoint quizzes.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Enter Lecture Topic (e.g. Photosynthesis, Newton\'s Laws)',
                  prefixIcon: Icon(Icons.menu_book_rounded, color: AppTheme.primaryViolet),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: lectureState.isLoading ? null : () => _launchLecture(_topicController.text.trim()),
                  child: lectureState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Generate & Start Interactive Lecture'),
                ),
              ),
              const SizedBox(height: 32),

              Text('Popular Recommended Topics', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),

              _buildTopicTile('Quadratic Equations & Formulas', 'Mathematics', Icons.functions),
              _buildTopicTile('Photosynthesis & Cellular Respiration', 'Biology', Icons.eco),
              _buildTopicTile('Newton\'s Laws of Motion', 'Physics', Icons.speed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicTile(String topic, String subject, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.accentCyan),
        title: Text(topic, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subject, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.play_arrow_rounded, color: AppTheme.primaryViolet),
        onTap: () => _launchLecture(topic),
      ),
    );
  }
}
