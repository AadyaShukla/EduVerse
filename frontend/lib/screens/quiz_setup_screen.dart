import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/screens/quiz_taking_screen.dart';

class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({super.key});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isMockExam = false;
  bool _isLoading = false;

  Future<void> _generateQuiz() async {
    if (_topicController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/quizzes/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': '00000000-0000-0000-0000-000000000000',
          'topic': _topicController.text,
          'notes_text': _notesController.text.isNotEmpty ? _notesController.text : null,
          'is_mock_exam': _isMockExam,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QuizTakingScreen(
                quizId: data['quiz_id'],
                topic: _topicController.text,
                questions: List<Map<String, dynamic>>.from(data['questions']),
                isMockExam: _isMockExam,
              ),
            ),
          );
        }
      } else {
        _showError('Failed to generate quiz: ${response.body}');
      }
    } catch (e) {
      _showError('Error connecting to server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _topicController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice & Assessment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(labelText: 'Topic (comma separate for Mock Exam)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Paste notes (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Mock Exam Mode (Timed)'),
                Switch(
                  value: _isMockExam,
                  onChanged: (val) => setState(() => _isMockExam = val),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateQuiz,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Generate Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
