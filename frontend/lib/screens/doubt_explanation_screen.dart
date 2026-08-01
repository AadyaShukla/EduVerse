import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/doubt_provider.dart';

class DoubtExplanationScreen extends ConsumerStatefulWidget {
  const DoubtExplanationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DoubtExplanationScreen> createState() => _DoubtExplanationScreenState();
}

class _DoubtExplanationScreenState extends ConsumerState<DoubtExplanationScreen> {
  bool _isSpeaking = false;

  void _toggleReadAloud(String fullText) async {
    final doubtNotifier = ref.read(doubtProvider.notifier);
    if (_isSpeaking) {
      await doubtNotifier.stopSpeaking();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await doubtNotifier.speakExplanation(fullText);
      setState(() => _isSpeaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doubtState = ref.watch(doubtProvider);
    final data = doubtState.explanationData;

    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Explanation')),
        body: const Center(child: Text('No explanation data available.')),
      );
    }

    final question = data['question_text'] ?? '';
    final summary = data['summary'] ?? '';
    final topic = data['topic'] ?? 'Study Topic';
    final language = data['explanation_language'] ?? 'English';
    final steps = (data['steps'] as List?) ?? [];

    final fullSpeechText = "$summary. " + steps.map((s) => "Step ${s['step_number']}: ${s['title']}. ${s['explanation']}").join(" ");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Step-by-Step Explanation', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _toggleReadAloud(fullSpeechText),
        backgroundColor: _isSpeaking ? AppTheme.warningOrange : AppTheme.accentCyan,
        icon: Icon(_isSpeaking ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.black),
        label: Text(
          _isSpeaking ? 'Stop Reading' : 'Read Aloud (TTS)',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question & Language Tag Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(topic, style: const TextStyle(color: AppTheme.primaryViolet, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(language, style: const TextStyle(color: AppTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Q: $question', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Summary Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentCyan.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, color: AppTheme.accentCyan, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(summary, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Explanation Steps', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),

            // Steps Accordion Cards
            ...steps.map((step) {
              final stepNum = step['step_number'] ?? 1;
              final title = step['title'] ?? 'Step $stepNum';
              final explanation = step['explanation'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.primaryViolet,
                          child: Text('$stepNum', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(explanation, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4)),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
