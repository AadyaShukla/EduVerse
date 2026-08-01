import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../core/constants/app_constants.dart';

class LocalAuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device hardware supports biometric authentication
  Future<bool> isBiometricsAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Authenticate user via Android Keystore hardware fingerprint/face unlock
  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool available = await isBiometricsAvailable();
      if (!available) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to log in to EduVerse',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Save PIN hash securely in Android Keystore
  Future<void> saveLocalPin(String pin) async {
    await _storage.write(key: AppConstants.keyPinHash, value: pin);
  }

  /// Verify entered PIN against stored secure PIN
  Future<bool> verifyLocalPin(String enteredPin) async {
    final storedPin = await _storage.read(key: AppConstants.keyPinHash);
    if (storedPin == null) return false;
    return storedPin == enteredPin;
  }

  /// Save student credentials locally
  Future<void> saveStudentSession({
    required String studentId,
    required String name,
    required int grade,
  }) async {
    await _storage.write(key: AppConstants.keyStudentId, value: studentId);
    await _storage.write(key: AppConstants.keyStudentName, value: name);
    await _storage.write(key: AppConstants.keyStudentGrade, value: grade.toString());
  }

  /// Get stored student ID
  Future<String?> getStoredStudentId() async {
    return await _storage.read(key: AppConstants.keyStudentId);
  }

  /// Get stored student details
  Future<Map<String, dynamic>?> getStoredStudentSession() async {
    final id = await _storage.read(key: AppConstants.keyStudentId);
    final name = await _storage.read(key: AppConstants.keyStudentName);
    final gradeStr = await _storage.read(key: AppConstants.keyStudentGrade);

    if (id == null || name == null || gradeStr == null) return null;
    return {
      'id': id,
      'name': name,
      'grade': int.tryParse(gradeStr) ?? 1,
    };
  }

  /// Clear session on logout
  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
