import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/speech_tts_service.dart';

class LectureState {
  final bool isLoading;
  final String? lectureId;
  final String? topic;
  final List<dynamic> segments;
  final int currentSegmentIndex;
  final bool isNarrating;
  final bool isPausedForDoubt;
  final bool showCheckpointQuestion;
  final bool isCheckpointIncorrect;
  final bool isLectureCompleted;
  final String? recapSummary;
  final String? errorMessage;

  LectureState({
    this.isLoading = false,
    this.lectureId,
    this.topic,
    this.segments = const [],
    this.currentSegmentIndex = 0,
    this.isNarrating = false,
    this.isPausedForDoubt = false,
    this.showCheckpointQuestion = false,
    this.isCheckpointIncorrect = false,
    this.isLectureCompleted = false,
    this.recapSummary,
    this.errorMessage,
  });

  LectureState copyWith({
    bool? isLoading,
    String? lectureId,
    String? topic,
    List<dynamic>? segments,
    int? currentSegmentIndex,
    bool? isNarrating,
    bool? isPausedForDoubt,
    bool? showCheckpointQuestion,
    bool? isCheckpointIncorrect,
    bool? isLectureCompleted,
    String? recapSummary,
    String? errorMessage,
  }) {
    return LectureState(
      isLoading: isLoading ?? this.isLoading,
      lectureId: lectureId ?? this.lectureId,
      topic: topic ?? this.topic,
      segments: segments ?? this.segments,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
      isNarrating: isNarrating ?? this.isNarrating,
      isPausedForDoubt: isPausedForDoubt ?? this.isPausedForDoubt,
      showCheckpointQuestion: showCheckpointQuestion ?? this.showCheckpointQuestion,
      isCheckpointIncorrect: isCheckpointIncorrect ?? this.isCheckpointIncorrect,
      isLectureCompleted: isLectureCompleted ?? this.isLectureCompleted,
      recapSummary: recapSummary ?? this.recapSummary,
      errorMessage: errorMessage,
    );
  }
}

class LectureNotifier extends StateNotifier<LectureState> {
  final ApiService _apiService = ApiService();
  final SpeechTTSService _ttsService = SpeechTTSService();

  LectureNotifier() : super(LectureState());

  @override
  void dispose() {
    _ttsService.stopSpeaking();
    super.dispose();
  }

  /// Initialize or fetch lecture
  Future<bool> startLecture({
    required String studentId,
    required String topic,
    required int grade,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final res = await _apiService.generateLecture(
      studentId: studentId,
      topic: topic,
      grade: grade,
    );

    if (res['success']) {
      final data = res['data'];
      final segments = (data['segments'] as List?) ?? [];

      state = state.copyWith(
        isLoading: false,
        lectureId: data['lecture_id'],
        topic: data['topic'],
        segments: segments,
        currentSegmentIndex: 0,
        isLectureCompleted: false,
      );

      _narrateCurrentSegment(studentId);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: res['message'],
      );
      return false;
    }
  }

  /// Narrate current segment text
  void _narrateCurrentSegment(String studentId) async {
    if (state.currentSegmentIndex >= state.segments.length) {
      await _completeLecture(studentId);
      return;
    }

    final seg = state.segments[state.currentSegmentIndex];
    final text = seg['narration_text'] ?? '';

    state = state.copyWith(
      isNarrating: true,
      isPausedForDoubt: false,
      showCheckpointQuestion: false,
    );

    await _ttsService.speakText(text);

    // Narration finished -> Show Checkpoint Question
    if (!state.isPausedForDoubt && mounted) {
      state = state.copyWith(
        isNarrating: false,
        showCheckpointQuestion: true,
      );
    }
  }

  /// Pause Narration for Doubt Overlay
  void pauseForDoubt() {
    _ttsService.stopSpeaking();
    state = state.copyWith(
      isNarrating: false,
      isPausedForDoubt: true,
    );
  }

  /// Resume Narration from exact segment position
  void resumeLecture(String studentId) {
    _narrateCurrentSegment(studentId);
  }

  /// Answer Checkpoint Question
  Future<void> answerCheckpoint({
    required String studentId,
    required String selectedOption,
  }) async {
    final seg = state.segments[state.currentSegmentIndex];
    final checkpoint = seg['checkpoint'];
    final correctAnswer = checkpoint['correct_answer'];

    if (selectedOption == correctAnswer) {
      state = state.copyWith(
        showCheckpointQuestion: false,
        isCheckpointIncorrect: false,
      );
      _advanceToNextSegment(studentId);
    } else {
      // Incorrect -> Narrate short recap text before advancing
      state = state.copyWith(
        showCheckpointQuestion: false,
        isCheckpointIncorrect: true,
      );
      final recapText = checkpoint['recap_text'] ?? "Let's review the main key points before moving on.";
      await _ttsService.speakText(recapText);

      state = state.copyWith(isCheckpointIncorrect: false);
      _advanceToNextSegment(studentId);
    }
  }

  void _advanceToNextSegment(String studentId) {
    final nextIndex = state.currentSegmentIndex + 1;
    if (nextIndex < state.segments.length) {
      state = state.copyWith(currentSegmentIndex: nextIndex);
      _apiService.updateLectureSession(
        studentId: studentId,
        lectureId: state.lectureId ?? '',
        currentSegment: nextIndex,
      );
      _narrateCurrentSegment(studentId);
    } else {
      _completeLecture(studentId);
    }
  }

  Future<void> _completeLecture(String studentId) async {
    _ttsService.stopSpeaking();
    final res = await _apiService.fetchLectureRecap(state.lectureId ?? '', state.topic ?? '');

    state = state.copyWith(
      isNarrating: false,
      isLectureCompleted: true,
      recapSummary: res['data']?['recap_summary'],
    );

    await _apiService.updateLectureSession(
      studentId: studentId,
      lectureId: state.lectureId ?? '',
      currentSegment: state.segments.length,
      completed: true,
    );
  }
}

final lectureProvider = StateNotifierProvider<LectureNotifier, LectureState>((ref) {
  return LectureNotifier();
});
