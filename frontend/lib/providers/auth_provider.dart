import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_model.dart';
import '../services/local_auth_service.dart';
import '../services/api_service.dart';
import '../services/local_database_service.dart';

enum AuthStatus {
  uninitialized,
  unauthenticated,
  authenticated,
  ageGateBlocked, // grade < 7 pending parent link
  totpRecoveryMode,
}

class AuthState {
  final AuthStatus status;
  final StudentModel? student;
  final String? totpSecret;
  final String? totpQrUri;
  final String? errorMessage;
  final bool isLoading;

  AuthState({
    this.status = AuthStatus.uninitialized,
    this.student,
    this.totpSecret,
    this.totpQrUri,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    StudentModel? student,
    String? totpSecret,
    String? totpQrUri,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      student: student ?? this.student,
      totpSecret: totpSecret ?? this.totpSecret,
      totpQrUri: totpQrUri ?? this.totpQrUri,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LocalAuthService _localAuthService = LocalAuthService();
  final ApiService _apiService = ApiService();
  final LocalDatabaseService _dbService = LocalDatabaseService();

  AuthNotifier() : super(AuthState()) {
    checkInitialAuthStatus();
  }

  /// Initialize application state check
  Future<void> checkInitialAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final storedSession = await _localAuthService.getStoredStudentSession();

    if (storedSession != null) {
      final studentId = storedSession['id'];
      // Fetch cached student or mock active session
      final cachedProfile = await _dbService.getCachedStudentProfile(studentId);

      if (cachedProfile != null) {
        final student = StudentModel.fromJson(cachedProfile);
        if (!student.isActive && student.parentLinkRequired) {
          state = state.copyWith(
            status: AuthStatus.ageGateBlocked,
            student: student,
            isLoading: false,
          );
        } else {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            student: student,
            isLoading: false,
          );
        }
        return;
      }
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      isLoading: false,
    );
  }

  /// Register new student and apply Age-Gate logic
  Future<bool> registerStudent({
    required String name,
    required int grade,
    required String pin,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final res = await _apiService.registerStudent(name: name, grade: grade);

    if (!res['success']) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: res['message'],
      );
      return false;
    }

    final data = res['data'];
    final student = StudentModel.fromJson(data['student']);
    final totpSecret = data['totp_secret'];
    final totpQrUri = data['totp_qr_uri'];

    // Save local PIN in Keystore
    await _localAuthService.saveLocalPin(pin);
    await _localAuthService.saveStudentSession(
      studentId: student.id,
      name: student.name,
      grade: student.grade,
    );
    await _dbService.cacheStudentProfile(student.toJson());

    if (student.parentLinkRequired || !student.isActive) {
      state = state.copyWith(
        status: AuthStatus.ageGateBlocked,
        student: student,
        totpSecret: totpSecret,
        totpQrUri: totpQrUri,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        student: student,
        totpSecret: totpSecret,
        totpQrUri: totpQrUri,
        isLoading: false,
      );
    }
    return true;
  }

  /// Authenticate locally via PIN
  Future<bool> loginWithPin(String pin) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final isValidPin = await _localAuthService.verifyLocalPin(pin);

    if (!isValidPin) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid PIN. Please try again or use TOTP recovery.',
      );
      return false;
    }

    final storedSession = await _localAuthService.getStoredStudentSession();
    if (storedSession != null) {
      final studentId = storedSession['id'];
      final cached = await _dbService.getCachedStudentProfile(studentId);
      final student = cached != null
          ? StudentModel.fromJson(cached)
          : StudentModel(
              id: studentId,
              name: storedSession['name'],
              grade: storedSession['grade'],
              parentLinkRequired: storedSession['grade'] < 7,
              isActive: storedSession['grade'] >= 7,
            );

      state = state.copyWith(
        status: student.parentLinkRequired && !student.isActive
            ? AuthStatus.ageGateBlocked
            : AuthStatus.authenticated,
        student: student,
        isLoading: false,
      );
      return true;
    }

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      isLoading: false,
      errorMessage: 'No local account found. Please sign up.',
    );
    return false;
  }

  /// Authenticate locally via Hardware Biometrics
  Future<bool> loginWithBiometrics() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final authenticated = await _localAuthService.authenticateWithBiometrics();

    if (!authenticated) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Biometric authentication failed or cancelled.',
      );
      return false;
    }

    return await checkSessionAfterLocalAuth();
  }

  Future<bool> checkSessionAfterLocalAuth() async {
    final storedSession = await _localAuthService.getStoredStudentSession();
    if (storedSession != null) {
      final studentId = storedSession['id'];
      final cached = await _dbService.getCachedStudentProfile(studentId);
      final student = cached != null
          ? StudentModel.fromJson(cached)
          : StudentModel(
              id: studentId,
              name: storedSession['name'],
              grade: storedSession['grade'],
              parentLinkRequired: storedSession['grade'] < 7,
              isActive: storedSession['grade'] >= 7,
            );

      state = state.copyWith(
        status: student.parentLinkRequired && !student.isActive
            ? AuthStatus.ageGateBlocked
            : AuthStatus.authenticated,
        student: student,
        isLoading: false,
      );
      return true;
    }
    return false;
  }

  /// Verify TOTP code for PIN reset / Account recovery
  Future<bool> verifyTotpRecovery(String totpToken, String newPin) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final studentId = state.student?.id ?? await _localAuthService.getStoredStudentId();

    if (studentId == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No student account identified for recovery.',
      );
      return false;
    }

    final res = await _apiService.verifyTotp(studentId: studentId, totpToken: totpToken);

    if (res['success']) {
      await _localAuthService.saveLocalPin(newPin);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: res['message'] ?? 'Invalid 6-digit TOTP code.',
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _localAuthService.clearSession();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
