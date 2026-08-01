import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class QuizState {
  final bool isLoading;
  final Map<String, dynamic>? activeQuiz;
  final int currentQuestionIndex;
  final Map<String, String> userAnswers;
  final Map<String, dynamic>? attemptResult;
  final List<dynamic> weakTopics;
  final List<dynamic> revisionSchedule;
  final String? errorMessage;

  // Mock Exam Timer
  final int timerSecondsRemaining;
  final bool isTimerActive;

  QuizState({
    this.isLoading = false,
    this.activeQuiz,
    this.currentQuestionIndex = 0,
    this.userAnswers = const {},
    this.attemptResult,
    this.weakTopics = const [],
    this.revisionSchedule = const [],
    this.errorMessage,
    this.timerSecondsRemaining = 0,
    this.isTimerActive = false,
  });

  QuizState copyWith({
    bool? isLoading,
    Map<String, dynamic>? activeQuiz,
    int? currentQuestionIndex,
    Map<String, String>? userAnswers,
    Map<String, dynamic>? attemptResult,
    List<dynamic>? weakTopics,
    List<dynamic>? revisionSchedule,
    String? errorMessage,
    int? timerSecondsRemaining,
    bool? isTimerActive,
  }) {
    return QuizState(
      isLoading: isLoading ?? this.isLoading,
      activeQuiz: activeQuiz ?? this.activeQuiz,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      attemptResult: attemptResult,
      weakTopics: weakTopics ?? this.weakTopics,
      revisionSchedule: revisionSchedule ?? this.revisionSchedule,
      errorMessage: errorMessage,
      timerSecondsRemaining: timerSecondsRemaining ?? this.timerSecondsRemaining,
      isTimerActive: isTimerActive ?? this.isTimerActive,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  final ApiService _apiService = ApiService();
  Timer? _timer;

  QuizNotifier() : super(QuizState());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Generate Quiz on topic
  Future<bool> generateQuiz({
    required String studentId,
    required String topic,
    String? notesText,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, attemptResult: null);

    final res = await _apiService.generateQuiz(
      studentId: studentId,
      topic: topic,
      notesText: notesText,
    );

    if (res['success']) {
      state = state.copyWith(
        isLoading: false,
        activeQuiz: res['data'],
        currentQuestionIndex: 0,
        userAnswers: {},
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: res['message'],
      );
      return false;
    }
  }

  /// Start Mock Exam with countdown timer
  void startMockExamTimer(int durationMinutes, Function onTimeUp) {
    _timer?.cancel();
    final totalSeconds = durationMinutes * 60;
    state = state.copyWith(
      timerSecondsRemaining: totalSeconds,
      isTimerActive: true,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timerSecondsRemaining <= 1) {
        timer.cancel();
        state = state.copyWith(isTimerActive: false, timerSecondsRemaining: 0);
        onTimeUp();
      } else {
        state = state.copyWith(timerSecondsRemaining: state.timerSecondsRemaining - 1);
      }
    });
  }

  void recordAnswer(String questionId, String answer) {
    final newAnswers = Map<String, String>.from(state.userAnswers);
    newAnswers[questionId] = answer;
    state = state.copyWith(userAnswers: newAnswers);
  }

  void nextQuestion() {
    final questions = state.activeQuiz?['questions'] as List?;
    if (questions != null && state.currentQuestionIndex < questions.length - 1) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1);
    }
  }

  /// Submit Quiz Attempt to backend
  Future<bool> submitQuizAttempt(String studentId) async {
    _timer?.cancel();
    state = state.copyWith(isLoading: true, isTimerActive: false);

    final quizId = state.activeQuiz?['id'];
    if (quizId == null) return false;

    final res = await _apiService.submitQuizAttempt(
      quizId: quizId,
      studentId: studentId,
      userAnswers: state.userAnswers,
    );

    if (res['success']) {
      state = state.copyWith(
        isLoading: false,
        attemptResult: res['data'],
      );
      // Refresh weak topics & revision schedule
      loadWeakTopicsAndSchedule(studentId);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: res['message'],
      );
      return false;
    }
  }

  /// Fetch Weak Topics & Spaced Repetition Schedule
  Future<void> loadWeakTopicsAndSchedule(String studentId) async {
    final weak = await _apiService.fetchWeakTopics(studentId);
    final schedule = await _apiService.fetchRevisionSchedule(studentId);

    state = state.copyWith(
      weakTopics: weak,
      revisionSchedule: schedule,
    );
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier();
});
