import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UsageTrackerService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _keyThreshold = 'eduverse_daily_usage_threshold_mins';

  Timer? _usageTimer;
  int _secondsUsedToday = 0;
  int _thresholdMinutes = 90; // Default 90 minutes
  bool _nudgeShownToday = false;

  int get secondsUsedToday => _secondsUsedToday;
  int get thresholdMinutes => _thresholdMinutes;

  /// Start on-device usage timer
  void startTracker(Function() onThresholdReached) async {
    final storedThreshold = await _storage.read(key: _keyThreshold);
    if (storedThreshold != null) {
      _thresholdMinutes = int.tryParse(storedThreshold) ?? 90;
    }

    _usageTimer?.cancel();
    _usageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsUsedToday++;

      final minutesUsed = _secondsUsedToday ~/ 60;
      if (minutesUsed >= _thresholdMinutes && !_nudgeShownToday) {
        _nudgeShownToday = true;
        onThresholdReached();
      }
    });
  }

  /// Stop tracker
  void stopTracker() {
    _usageTimer?.cancel();
  }

  /// Update anti-addiction daily threshold setting
  Future<void> updateThreshold(int minutes) async {
    _thresholdMinutes = minutes;
    await _storage.write(key: _keyThreshold, value: minutes.toString());
  }
}
