class LectureSessionModel {
  final String id;
  final String studentId;
  final String topic;
  final int currentSegment;
  final String? pausedAt;
  final bool completed;
  final String createdAt;

  LectureSessionModel({
    required this.id,
    required this.studentId,
    required this.topic,
    required this.currentSegment,
    this.pausedAt,
    required this.completed,
    required this.createdAt,
  });

  factory LectureSessionModel.fromJson(Map<String, dynamic> json) {
    return LectureSessionModel(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      topic: json['topic'] ?? '',
      currentSegment: json['current_segment'] ?? 0,
      pausedAt: json['paused_at'],
      completed: json['completed'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'topic': topic,
      'current_segment': currentSegment,
      'paused_at': pausedAt,
      'completed': completed,
      'created_at': createdAt,
    };
  }
}
