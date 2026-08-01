class AppConstants {
  static const String appName = 'EduVerse';
  static const String appTagline = 'Your AI-Powered Personal Learning Universe';
  
  // Backend API Base URL
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Android Emulator loopback
  static const String fallbackLocalUrl = 'http://localhost:8000/api/v1';

  // Secure Storage Keys
  static const String keyStudentId = 'eduverse_student_id';
  static const String keyStudentName = 'eduverse_student_name';
  static const String keyStudentGrade = 'eduverse_student_grade';
  static const String keyPinHash = 'eduverse_pin_hash';
  static const String keyBiometricEnabled = 'eduverse_biometric_enabled';

  // Age Gate threshold
  static const int ageGateMinIndependentGrade = 7;
}
