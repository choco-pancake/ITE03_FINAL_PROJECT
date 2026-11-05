class AcademicClass {
  final int id;
  final String name;
  final String? section;
  final String classCode;
  final String? description;
  final int studentCount;

  AcademicClass({
    required this.id,
    required this.name,
    this.section,
    required this.classCode,
    this.description,
    this.studentCount = 30,
  });

  String get displayName =>
      (section != null && section!.isNotEmpty) ? '$name - $section' : name;

  factory AcademicClass.fromJson(Map<String, dynamic> json) {
    return AcademicClass(
      id: json['id'] as int,
      name: json['name'] as String,
      section: json['section'] as String?,
      classCode: json['class_code'] as String? ?? '',
      description: json['description'] as String?,
      studentCount: json['student_count'] is int
          ? json['student_count'] as int
          : int.tryParse(json['student_count']?.toString() ?? '30') ?? 30,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'section': section,
        'class_code': classCode,
        'description': description,
        'student_count': studentCount,
      };
}
