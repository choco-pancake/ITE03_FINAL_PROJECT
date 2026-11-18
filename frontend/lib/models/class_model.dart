class ClassModel {
  final String id;
  final String code; // e.g. CS401
  final String name; // e.g. Software Engineering & Capstone Project
  final String section; // e.g. BSCS 4-A
  final String enrollmentCode; // e.g. GMM-8419
  final String professorId;
  final String professorName;
  final List<String> enrolledStudentIds;

  ClassModel({
    required this.id,
    required this.code,
    required this.name,
    required this.section,
    required this.enrollmentCode,
    required this.professorId,
    required this.professorName,
    List<String>? enrolledStudentIds,
  }) : enrolledStudentIds = enrolledStudentIds ?? [];

  ClassModel copyWith({
    String? code,
    String? name,
    String? section,
    String? enrollmentCode,
    List<String>? enrolledStudentIds,
  }) {
    return ClassModel(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      section: section ?? this.section,
      enrollmentCode: enrollmentCode ?? this.enrollmentCode,
      professorId: professorId,
      professorName: professorName,
      enrolledStudentIds: enrolledStudentIds ?? List.from(this.enrolledStudentIds),
    );
  }
}
