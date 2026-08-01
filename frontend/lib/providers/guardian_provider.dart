import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class GuardianState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? guardianId;
  final String? guardianName;
  final String? guardianEmail;
  final Map<String, dynamic>? dashboardData;
  final Map<String, dynamic>? aiInsights;
  final String? errorMessage;

  GuardianState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.guardianId,
    this.guardianName,
    this.guardianEmail,
    this.dashboardData,
    this.aiInsights,
    this.errorMessage,
  });

  GuardianState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? guardianId,
    String? guardianName,
    String? guardianEmail,
    Map<String, dynamic>? dashboardData,
    Map<String, dynamic>? aiInsights,
    String? errorMessage,
  }) {
    return GuardianState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      guardianId: guardianId ?? this.guardianId,
      guardianName: guardianName ?? this.guardianName,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      dashboardData: dashboardData ?? this.dashboardData,
      aiInsights: aiInsights ?? this.aiInsights,
      errorMessage: errorMessage,
    );
  }
}

class GuardianNotifier extends StateNotifier<GuardianState> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  GuardianNotifier() : super(GuardianState()) {
    checkInitialGuardianAuth();
  }

  Future<void> checkInitialGuardianAuth() async {
    final storedId = await _storage.read(key: 'eduverse_guardian_id');
    final storedName = await _storage.read(key: 'eduverse_guardian_name');
    final storedEmail = await _storage.read(key: 'eduverse_guardian_email');

    if (storedId != null && storedName != null) {
      state = state.copyWith(
        isAuthenticated: true,
        guardianId: storedId,
        guardianName: storedName,
        guardianEmail: storedEmail,
      );
      loadDashboardAndInsights(storedId);
    }
  }

  /// Link Guardian via Invite Code
  Future<bool> linkWithInviteCode({
    required String inviteCode,
    required String guardianName,
    required String guardianEmail,
    required String pin,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final res = await _apiService.linkGuardian(
      inviteCode: inviteCode,
      guardianName: guardianName,
      guardianEmail: guardianEmail,
    );

    if (res['success']) {
      final data = res['data'];
      final guardianId = data['guardian_id'] ?? 'g_${DateTime.now().millisecondsSinceEpoch}';

      await _storage.write(key: 'eduverse_guardian_id', value: guardianId);
      await _storage.write(key: 'eduverse_guardian_name', value: guardianName);
      await _storage.write(key: 'eduverse_guardian_email', value: guardianEmail);
      await _storage.write(key: 'eduverse_guardian_pin', value: pin);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        guardianId: guardianId,
        guardianName: guardianName,
        guardianEmail: guardianEmail,
      );

      await loadDashboardAndInsights(guardianId);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: res['message'],
      );
      return false;
    }
  }

  /// Load Dashboard & AI Weekly Insights
  Future<void> loadDashboardAndInsights(String guardianId) async {
    state = state.copyWith(isLoading: true);
    final dashRes = await _apiService.fetchGuardianDashboard(guardianId);
    final insightsRes = await _apiService.fetchGuardianAIInsights(guardianId);

    state = state.copyWith(
      isLoading: false,
      dashboardData: dashRes['data'],
      aiInsights: insightsRes['data'],
    );
  }

  /// Revoke Link (Grade >= 7 student side)
  Future<bool> revokeGuardianLink(String studentId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final res = await _apiService.revokeGuardianLink(studentId);

    if (res['success']) {
      state = state.copyWith(
        isLoading: false,
        dashboardData: null,
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

  Future<void> logout() async {
    await _storage.delete(key: 'eduverse_guardian_id');
    await _storage.delete(key: 'eduverse_guardian_name');
    await _storage.delete(key: 'eduverse_guardian_email');
    await _storage.delete(key: 'eduverse_guardian_pin');
    state = GuardianState();
  }
}

final guardianProvider = StateNotifierProvider<GuardianNotifier, GuardianState>((ref) {
  return GuardianNotifier();
});
