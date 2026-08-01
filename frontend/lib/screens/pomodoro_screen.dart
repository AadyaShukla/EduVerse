import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/wellbeing_provider.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  String _formatSeconds(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final wellbeingState = ref.watch(wellbeingProvider);
    final wellbeingNotifier = ref.read(wellbeingProvider.notifier);
    final student = ref.watch(authProvider).student;

    final isFocus = wellbeingState.currentMode == 'focus';
    final progressVal = isFocus
        ? 1.0 - (wellbeingState.timerSecondsRemaining / (wellbeingState.focusMinutes * 60))
        : 1.0 - (wellbeingState.timerSecondsRemaining / (wellbeingState.breakMinutes * 60));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro & Focus Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.cardSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Focus Mode Notification DND Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: wellbeingState.isFocusModeActive
                      ? AppTheme.accentCyan.withOpacity(0.15)
                      : AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: wellbeingState.isFocusModeActive ? AppTheme.accentCyan : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      wellbeingState.isFocusModeActive ? Icons.do_not_disturb_on : Icons.notifications_active_outlined,
                      color: wellbeingState.isFocusModeActive ? AppTheme.accentCyan : AppTheme.textSecondary,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wellbeingState.isFocusModeActive
                                ? 'Focus Mode Active (Do Not Disturb)'
                                : 'Focus Mode Off',
                            style: TextStyle(
                              color: wellbeingState.isFocusModeActive ? AppTheme.accentCyan : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Silences non-EduVerse notifications while focus session is running.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Circular Pomodoro Progress Dial
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: progressVal.clamp(0.0, 1.0),
                      strokeWidth: 14,
                      backgroundColor: Colors.white10,
                      color: isFocus ? AppTheme.primaryViolet : AppTheme.successGreen,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatSeconds(wellbeingState.timerSecondsRemaining),
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFocus ? AppTheme.primaryViolet.withOpacity(0.2) : AppTheme.successGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isFocus ? 'Focus Sprint' : 'Short Break',
                          style: TextStyle(
                            color: isFocus ? AppTheme.primaryViolet : AppTheme.successGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Timer Controls (Start/Pause & Reset)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: student == null ? null : () => wellbeingNotifier.togglePomodoro(student.id),
                    icon: Icon(wellbeingState.isTimerRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(wellbeingState.isTimerRunning ? 'Pause Sprint' : 'Start Focus Sprint'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFocus ? AppTheme.primaryViolet : AppTheme.successGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
                    onPressed: wellbeingNotifier.resetTimer,
                    tooltip: 'Reset Timer',
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Adjust Duration Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDurationChip('25m Focus / 5m Break', 25, 5, wellbeingState, wellbeingNotifier),
                  _buildDurationChip('45m Focus / 10m Break', 45, 10, wellbeingState, wellbeingNotifier),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationChip(
    String label,
    int focusMins,
    int breakMins,
    WellbeingState state,
    WellbeingNotifier notifier,
  ) {
    final isSelected = state.focusMinutes == focusMins;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.accentCyan.withOpacity(0.3),
      onSelected: (val) {
        if (val) notifier.setTimerDurations(focusMins, breakMins);
      },
    );
  }
}
