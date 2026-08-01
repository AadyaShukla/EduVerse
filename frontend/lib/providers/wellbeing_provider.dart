import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/local_notification_service.dart';
import '../services/usage_tracker_service.dart';

class WellbeingState {
  final int focusMinutes;
  final int breakMinutes;
  final int timerSecondsRemaining;
  final bool isTimerRunning;
  final bool isFocusModeActive;
  final String currentMode; // 'focus' or 'break'

  // Gamification
  final int xp;
  final int currentStreak;
  final int longestStreak;
  final List<dynamic> badges;

  // Anti-Addiction Nudge
  final bool showAntiAddictionNudge;

  // Study Receipt
  final Map<String, dynamic>? studyReceipt;

  WellbeingState({
    this.focusMinutes = 25,
    this.breakMinutes = 5,
    this.timerSecondsRemaining = 1500,
    this.isTimerRunning = false,
    this.isFocusModeActive = false,
    this.currentMode = 'focus',
    this.xp = 150,
    this.currentStreak = 3,
    this.longestStreak = 7,
    this.badges = const [],
    this.showAntiAddictionNudge = false,
    this.studyReceipt,
  });

  WellbeingState copyWith({
    int? focusMinutes,
    int? breakMinutes,
    int? timerSecondsRemaining,
    bool? isTimerRunning,
    bool? isFocusModeActive,
    String? currentMode,
    int? xp,
    int? currentStreak,
    int? longestStreak,
    List<dynamic>? badges,
    bool? showAntiAddictionNudge,
    Map<String, dynamic>? studyReceipt,
  }) {
    return WellbeingState(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      timerSecondsRemaining: timerSecondsRemaining ?? this.timerSecondsRemaining,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      isFocusModeActive: isFocusModeActive ?? this.isFocusModeActive,
      currentMode: currentMode ?? this.currentMode,
      xp: xp ?? this.xp,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      badges: badges ?? this.badges,
      showAntiAddictionNudge: showAntiAddictionNudge ?? this.showAntiAddictionNudge,
      studyReceipt: studyReceipt ?? this.studyReceipt,
    );
  }
}

class WellbeingNotifier extends StateNotifier<WellbeingState> {
  final ApiService _apiService = ApiService();
  final LocalNotificationService _notificationService = LocalNotificationService();
  final UsageTrackerService _usageTracker = UsageTrackerService();
  Timer? _pomodoroTimer;

  WellbeingNotifier() : super(WellbeingState()) {
    _usageTracker.startTracker(() {
      state = state.copyWith(showAntiAddictionNudge: true);
    });
  }

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    _usageTracker.stopTracker();
    super.dispose();
  }

  void dismissAntiAddictionNudge() {
    state = state.copyWith(showAntiAddictionNudge: false);
  }

  /// Update timer parameters
  void setTimerDurations(int focusMins, int breakMins) {
    state = state.copyWith(
      focusMinutes: focusMins,
      breakMinutes: breakMins,
      timerSecondsRemaining: focusMins * 60,
    );
  }

  /// Start or Pause Pomodoro Timer
  void togglePomodoro(String studentId) {
    if (state.isTimerRunning) {
      _pomodoroTimer?.cancel();
      state = state.copyWith(isTimerRunning: false);
    } else {
      state = state.copyWith(isTimerRunning: true, isFocusModeActive: true);
      _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (state.timerSecondsRemaining <= 1) {
          timer.cancel();
          await _handleSessionComplete(studentId);
        } else {
          state = state.copyWith(timerSecondsRemaining: state.timerSecondsRemaining - 1);
        }
      });
    }
  }

  /// Reset Timer
  void resetTimer() {
    _pomodoroTimer?.cancel();
    state = state.copyWith(
      isTimerRunning: false,
      isFocusModeActive: false,
      timerSecondsRemaining: state.focusMinutes * 60,
      currentMode: 'focus',
    );
  }

  Future<void> _handleSessionComplete(String studentId) async {
    final completedType = state.currentMode;
    final durationMins = completedType == 'focus' ? state.focusMinutes : state.breakMinutes;

    // Log to backend & local notification
    await _apiService.logFocusSession(
      studentId: studentId,
      durationMinutes: durationMins,
      type: completedType,
    );

    await _notificationService.showNotification(
      id: 999,
      title: completedType == 'focus' ? 'Focus Session Completed! 🌟' : 'Break Time Over! 🔔',
      body: completedType == 'focus'
          ? 'Great work! Take a short ${state.breakMinutes}-minute break now.'
          : 'Ready to focus again? Start your next study sprint!',
    );

    // Switch mode
    final nextMode = completedType == 'focus' ? 'break' : 'focus';
    final nextSeconds = (nextMode == 'focus' ? state.focusMinutes : state.breakMinutes) * 60;

    state = state.copyWith(
      isTimerRunning: false,
      isFocusModeActive: false, // Auto-disables DND Focus mode when session ends
      currentMode: nextMode,
      timerSecondsRemaining: nextSeconds,
    );

    // Refresh XP & progress
    await loadStudentProgress(studentId);
  }

  /// Load Gamification Progress
  Future<void> loadStudentProgress(String studentId) async {
    final res = await _apiService.fetchProgress(studentId);
    if (res['success']) {
      final data = res['data'];
      state = state.copyWith(
        xp: data['xp'] ?? 150,
        currentStreak: data['current_streak'] ?? 3,
        longestStreak: data['longest_streak'] ?? 7,
        badges: (data['badges'] as List?) ?? [],
      );
    }
  }

  /// Load Study Receipt
  Future<void> loadStudyReceipt(String studentId) async {
    final res = await _apiService.fetchStudyReceipt(studentId);
    if (res['success']) {
      state = state.copyWith(studyReceipt: res['data']);
    }
  }
}

final wellbeingProvider = StateNotifierProvider<WellbeingNotifier, WellbeingState>((ref) {
  return WellbeingNotifier();
});
