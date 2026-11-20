class StudentRecord {
  const StudentRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.studentId,
    required this.yearLevel,
    required this.block,
    required this.classes,
  });

  final int id;
  final String name;
  final String email;
  final String firstName;
  final String middleName;
  final String lastName;
  final String studentId;
  final String yearLevel;
  final String block;
  final List<String> classes;

  factory StudentRecord.fromJson(Map<String, dynamic> json) => StudentRecord(
    id: json['id'] as int,
    name: (json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    firstName: (json['first_name'] ?? '').toString(),
    middleName: (json['middle_name'] ?? '').toString(),
    lastName: (json['last_name'] ?? '').toString(),
    studentId: (json['student_id'] ?? '').toString(),
    yearLevel: (json['year_level'] ?? '').toString(),
    block: (json['block'] ?? '').toString(),
    classes: (json['classes'] as List<dynamic>? ?? [])
        .map((entry) => (entry as Map<String, dynamic>)['name'].toString())
        .toList(),
  );
}
