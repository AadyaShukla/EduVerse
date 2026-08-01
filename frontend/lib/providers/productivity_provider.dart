import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/ocr_service.dart';
import '../services/local_notification_service.dart';

class ProductivityState {
  final bool isLoading;
  final List<dynamic> notes;
  final List<dynamic> scheduleItems;
  final Map<String, dynamic>? parsedHomework;
  final Map<String, dynamic>? essayGradeResult;
  final String? errorMessage;

  ProductivityState({
    this.isLoading = false,
    this.notes = const [],
    this.scheduleItems = const [],
    this.parsedHomework,
    this.essayGradeResult,
    this.errorMessage,
  });

  ProductivityState copyWith({
    bool? isLoading,
    List<dynamic>? notes,
    List<dynamic>? scheduleItems,
    Map<String, dynamic>? parsedHomework,
    Map<String, dynamic>? essayGradeResult,
    String? errorMessage,
  }) {
    return ProductivityState(
      isLoading: isLoading ?? this.isLoading,
      notes: notes ?? this.notes,
      scheduleItems: scheduleItems ?? this.scheduleItems,
      parsedHomework: parsedHomework,
      essayGradeResult: essayGradeResult ?? this.essayGradeResult,
      errorMessage: errorMessage,
    );
  }
}

class ProductivityNotifier extends StateNotifier<ProductivityState> {
  final ApiService _apiService = ApiService();
  final OCRService _ocrService = OCRService();
  final LocalNotificationService _notificationService = LocalNotificationService();

  ProductivityNotifier() : super(ProductivityState()) {
    _notificationService.initNotifications();
  }

  /// AI Auto-Tagging for student notes
  Future<Map<String, dynamic>> autoTagNote(String content) async {
    final res = await _apiService.tagNoteContent(content);
    return res['data'] ?? {'suggested_subject': 'General', 'suggested_tags': ['study']};
  }

  /// Scan handwriting via OCR & import to note editor
  Future<String?> scanHandwritingOCR(ImageSource source) async {
    state = state.copyWith(isLoading: true);
    final text = await _ocrService.processImageFromSource(source);
    state = state.copyWith(isLoading: false);
    return text;
  }

  /// Parse Homework Diary via OCR
  Future<void> scanAndParseHomework(String studentId, ImageSource source) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final ocrText = await _ocrService.processImageFromSource(source);

    if (ocrText == null || ocrText.isEmpty) {
      state = state.copyWith(isLoading: false, errorMessage: 'No text recognized from homework photo.');
      return;
    }

    final res = await _apiService.parseHomeworkOcr(studentId, ocrText);
    if (res['success']) {
      state = state.copyWith(isLoading: false, parsedHomework: res['data']);
    } else {
      state = state.copyWith(isLoading: false, errorMessage: res['message']);
    }
  }

  /// Schedule Class / Assignment Deadline with local device notification
  Future<void> addScheduleItem({
    required String studentId,
    required String type,
    required String title,
    required String subject,
    required DateTime itemDateTime,
    bool reminderSet = true,
  }) async {
    if (reminderSet) {
      await _notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'EduVerse Reminder: $title',
        body: '$subject $type scheduled for ${itemDateTime.hour}:${itemDateTime.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  /// Grade Essay / Assignment via Gemini backend agent
  Future<bool> gradeEssay({
    required String studentId,
    required String subject,
    required String essayText,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final res = await _apiService.gradeEssay(
      studentId: studentId,
      subject: subject,
      essayText: essayText,
    );

    if (res['success']) {
      state = state.copyWith(
        isLoading: false,
        essayGradeResult: res['data'],
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
}

final productivityProvider = StateNotifierProvider<ProductivityNotifier, ProductivityState>((ref) {
  return ProductivityNotifier();
});
