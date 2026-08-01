import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/local_database_service.dart';

class AccessibilityState {
  final bool isOffline;
  final bool isLowDataMode;
  final bool isDyslexicFont;
  final bool isHighContrast;

  AccessibilityState({
    this.isOffline = false,
    this.isLowDataMode = false,
    this.isDyslexicFont = false,
    this.isHighContrast = false,
  });

  AccessibilityState copyWith({
    bool? isOffline,
    bool? isLowDataMode,
    bool? isDyslexicFont,
    bool? isHighContrast,
  }) {
    return AccessibilityState(
      isOffline: isOffline ?? this.isOffline,
      isLowDataMode: isLowDataMode ?? this.isLowDataMode,
      isDyslexicFont: isDyslexicFont ?? this.isDyslexicFont,
      isHighContrast: isHighContrast ?? this.isHighContrast,
    );
  }
}

class AccessibilityNotifier extends StateNotifier<AccessibilityState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalDatabaseService _dbService = LocalDatabaseService();

  AccessibilityNotifier() : super(AccessibilityState()) {
    _loadAccessibilityPreferences();
  }

  Future<void> _loadAccessibilityPreferences() async {
    final lowData = await _storage.read(key: 'eduverse_low_data_mode');
    final dyslexic = await _storage.read(key: 'eduverse_dyslexic_font');
    final highContrast = await _storage.read(key: 'eduverse_high_contrast');

    state = state.copyWith(
      isLowDataMode: lowData == 'true',
      isDyslexicFont: dyslexic == 'true',
      isHighContrast: highContrast == 'true',
    );
  }

  void toggleOfflineMode(bool offline) {
    state = state.copyWith(isOffline: offline);
    if (!offline) {
      // Connection restored -> Flush offline sync queue to backend
      _dbService.getSyncQueueItems().then((items) {
        if (items.isNotEmpty) {
          _dbService.clearSyncQueue();
        }
      });
    }
  }

  void toggleLowDataMode(bool value) async {
    state = state.copyWith(isLowDataMode: value);
    await _storage.write(key: 'eduverse_low_data_mode', value: value.toString());
  }

  void toggleDyslexicFont(bool value) async {
    state = state.copyWith(isDyslexicFont: value);
    await _storage.write(key: 'eduverse_dyslexic_font', value: value.toString());
  }

  void toggleHighContrast(bool value) async {
    state = state.copyWith(isHighContrast: value);
    await _storage.write(key: 'eduverse_high_contrast', value: value.toString());
  }
}

final accessibilityProvider = StateNotifierProvider<AccessibilityNotifier, AccessibilityState>((ref) {
  return AccessibilityNotifier();
});
