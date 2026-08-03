import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/lecture_provider.dart';
import '../providers/doubt_provider.dart';
import 'quiz_setup_screen.dart';

class LectureScreen extends ConsumerStatefulWidget {
  const LectureScreen({super.key});

  @override

  ConsumerState<LectureScreen> createState() => _LectureScreenState();
}

class _LectureScreenState extends ConsumerState<LectureScreen> {
  final _doubtController = TextEditingController();

  @override
  void dispose() {
    _doubtController.dispose();
    super.dispose();
  }

  void _showDoubtOverlay() {
    ref.read(lectureProvider.notifier).pauseForDoubt();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.pause_circle_filled_rounded, color: AppTheme.warningOrange, size: 28),
                SizedBox(width: 10),
                Text('Lecture Paused: Ask a Doubt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _doubtController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Type your doubt here... (e.g. Can you explain step 2 again?)',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final student = ref.read(authProvider).student;
                      final topic = ref.read(lectureProvider).topic ?? 'Lecture';
                      if (student != null && _doubtController.text.trim().isNotEmpty) {
                        await ref.read(doubtProvider.notifier).submitDoubt(
                          studentId: student.id,
                          questionText: _doubtController.text.trim(),
                          language: 'English',
                        );
                        _doubtController.clear();
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Doubt sent to AI Doubt Solver!')),
                        );
                      }
                    },
                    child: const Text('Submit Doubt'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    final student = ref.read(authProvider).student;
                    if (student != null) {
                      ref.read(lectureProvider.notifier).resumeLecture(student.id);
                    }
                  },
                  child: const Text('Resume Lecture', style: TextStyle(color: AppTheme.accentCyan)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckpointModal(Map<String, dynamic> checkpoint) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.quiz_rounded, color: AppTheme.accentCyan, size: 28),
                SizedBox(width: 10),
                Text('Checkpoint Question', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            Text(checkpoint['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...((checkpoint['options'] as List?) ?? []).map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    final student = ref.read(authProvider).student;
                    if (student != null) {
                      ref.read(lectureProvider.notifier).answerCheckpoint(
                        studentId: student.id,
                        selectedOption: opt.toString(),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(opt.toString(), style: const TextStyle(color: Colors.white)),
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lectureState = ref.watch(lectureProvider);
    final student = ref.watch(authProvider).student;

    if (lectureState.showCheckpointQuestion && lectureState.segments.isNotEmpty) {
      final currentSeg = lectureState.segments[lectureState.currentSegmentIndex];
      final checkpoint = currentSeg['checkpoint'];
      Future.microtask(() {
        _showCheckpointModal(checkpoint);
      });
    }

    if (lectureState.isLectureCompleted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lecture Completed! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.cardSurface,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded, color: AppTheme.successGreen, size: 64),
                const SizedBox(height: 16),
                Text(lectureState.topic ?? 'Lecture', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.successGreen.withOpacity(0.4)),
                  ),
                  child: Text(
                    lectureState.recapSummary ?? 'Great job completing all lecture segments!',
                    style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const QuizSetupScreen()),
                      );
                    },
                    icon: const Icon(Icons.quiz_rounded),
                    label: const Text('Take Full Topic Quiz Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (lectureState.segments.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentSeg = lectureState.segments[lectureState.currentSegmentIndex];
    final bullets = (currentSeg['slide_bullets'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(lectureState.topic ?? 'Interactive Lecture', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segment Progress Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Segment ${lectureState.currentSegmentIndex + 1} of ${lectureState.segments.length}',
                    style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Icon(
                        lectureState.isNarrating ? Icons.volume_up_rounded : Icons.pause_rounded,
                        color: lectureState.isNarrating ? AppTheme.successGreen : AppTheme.warningOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        lectureState.isNarrating ? 'Narrating Slide' : 'Paused',
                        style: TextStyle(
                          color: lectureState.isNarrating ? AppTheme.successGreen : AppTheme.warningOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Slide Canvas Card (Slide Content)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryViolet.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentSeg['segment_title'] ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Divider(height: 24, color: Colors.white10),

                    ...bullets.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppTheme.accentCyan, fontSize: 18, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(b.toString(), style: const TextStyle(fontSize: 15, height: 1.3, color: Colors.white70)),
                          ),
                        ],
                      ),
                    )).toList(),

                    if (currentSeg['diagram_description'] != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.schema_rounded, color: AppTheme.accentCyan, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Diagram Concept: ${currentSeg['diagram_description']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pause-and-Ask Doubt Action Row
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showDoubtOverlay,
                  icon: const Icon(Icons.help_center_rounded),
                  label: const Text('Pause & Ask a Doubt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
