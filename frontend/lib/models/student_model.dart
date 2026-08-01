class StudentModel {
  final String id;
  final String name;
  final int grade;
  final bool parentLinkRequired;
  final String? parentId;
  final bool isActive;
  final String? createdAt;

  StudentModel({
    required this.id,
    required this.name,
    required this.grade,
    required this.parentLinkRequired,
    this.parentId,
    required this.isActive,
    this.createdAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      grade: json['grade'] ?? 1,
      parentLinkRequired: json['parent_link_required'] ?? false,
      parentId: json['parent_id'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'parent_link_required': parentLinkRequired,
      'parent_id': parentId,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}
