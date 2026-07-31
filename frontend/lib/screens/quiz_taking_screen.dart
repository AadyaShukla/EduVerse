import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuizTakingScreen extends StatefulWidget {
  final String quizId;
  final String topic;
  final List<Map<String, dynamic>> questions;
  final bool isMockExam;

  const QuizTakingScreen({
    super.key,
    required this.quizId,
    required this.topic,
    required this.questions,
    this.isMockExam = false,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int _currentIndex = 0;
  int _score = 0;
  final Map<String, String> _userAnswers = {};
  final List<String> _weakTopicsFound = [];
  bool _showExplanation = false;
  String? _selectedOption;

  Timer? _timer;
  int _timeLeft = 300; // 5 mins for mock exam

  @override
  void initState() {
    super.initState();
    if (widget.isMockExam) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        _submitQuiz();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkAnswer() {
    if (_selectedOption == null) return;

    final currentQ = widget.questions[_currentIndex];
    final isCorrect = _selectedOption == currentQ['correct_answer'];

    _userAnswers[currentQ['question']] = _selectedOption!;

    setState(() {
      _showExplanation = true;
      if (isCorrect) {
        _score++;
      } else {
        if (!_weakTopicsFound.contains(widget.topic)) {
          _weakTopicsFound.add(widget.topic);
        }
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _showExplanation = false;
        _selectedOption = null;
      });
    } else {
      _submitQuiz();
    }
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();

    final finalScore = (_score / widget.questions.length * 100).round();

    try {
      await http.post(
        Uri.parse('http://10.0.2.2:8000/api/tracker/attempt'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': '00000000-0000-0000-0000-000000000000',
          'quiz_id': widget.quizId,
          'score': finalScore,
          'answers': _userAnswers,
          'weak_topics': _weakTopicsFound,
        }),
      );
    } catch (e) {
      // Just showing error locally
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Quiz Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your score: $finalScore%'),
              if (widget.isMockExam)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Topic Breakdown: ${widget.topic} - Score: $finalScore%'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) return const Scaffold(body: Center(child: Text('No questions')));

    final currentQ = widget.questions[_currentIndex];
    final options = List<String>.from(currentQ['options'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} / ${widget.questions.length}'),
        actions: [
          if (widget.isMockExam)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: Text('${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}')),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(currentQ['question'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (options.isNotEmpty)
              ...options.map((opt) => InkWell(
                onTap: _showExplanation ? null : () => setState(() => _selectedOption = opt),
                child: Row(
                  children: [
                    // Workaround for deprecated groupValue by wrapping in ignore

                    Radio<String>(
                      value: opt,

                      groupValue: _selectedOption,

                      onChanged: _showExplanation ? null : (val) => setState(() => _selectedOption = val),
                    ),
                    Expanded(child: Text(opt)),
                  ],
                ),
              )),
            if (options.isEmpty)
              TextField(
                enabled: !_showExplanation,
                decoration: const InputDecoration(labelText: 'Type answer'),
                onChanged: (val) => setState(() => _selectedOption = val),
              ),
            const Spacer(),
            if (_showExplanation)
              Container(
                padding: const EdgeInsets.all(12),
                color: _selectedOption == currentQ['correct_answer'] ? Colors.green.shade100 : Colors.red.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedOption == currentQ['correct_answer'] ? 'Correct!' : 'Incorrect. Correct: ${currentQ['correct_answer']}'),
                    const SizedBox(height: 8),
                    Text(currentQ['explanation']),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectedOption == null ? null : (_showExplanation ? _nextQuestion : _checkAnswer),
              child: Text(_showExplanation ? (_currentIndex < widget.questions.length - 1 ? 'Next' : 'Finish') : 'Check'),
            ),
          ],
        ),
      ),
    );
  }
}
