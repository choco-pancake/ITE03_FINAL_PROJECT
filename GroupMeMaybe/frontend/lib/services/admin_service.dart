import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AdminOverview {
  final int totalFaculty;
  final int totalStudents;
  final int totalClasses;
  final int totalActivities;
  final String activeFacultyCode;
  final String semester;
  final String academicYear;
  final String semesterMode;
  final String manualSemester;
  final String manualAcademicYear;

  AdminOverview({
    required this.totalFaculty,
    required this.totalStudents,
    required this.totalClasses,
    required this.totalActivities,
    required this.activeFacultyCode,
    required this.semester,
    required this.academicYear,
    required this.semesterMode,
    required this.manualSemester,
    required this.manualAcademicYear,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> json) => AdminOverview(
        totalFaculty: json['total_faculty'] as int? ?? 0,
        totalStudents: json['total_students'] as int? ?? 0,
        totalClasses: json['total_classes'] as int? ?? 0,
        totalActivities: json['total_activities'] as int? ?? 0,
        activeFacultyCode:
            json['active_faculty_code'] as String? ?? 'BSIT-FACULTY-2026',
        semester: json['semester'] as String? ?? '1st Semester',
        academicYear: json['academic_year'] as String? ?? '2026-2027',
        semesterMode: json['semester_mode'] as String? ?? 'auto',
        manualSemester: json['manual_semester'] as String? ?? '1st Semester',
        manualAcademicYear:
            json['manual_academic_year'] as String? ?? '2026-2027',
      );
}

class AdminFacultyMember {
  final int id;
  final String name;
  final String email;
  final String department;
  final String? createdAt;

  AdminFacultyMember({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    this.createdAt,
  });

  factory AdminFacultyMember.fromJson(Map<String, dynamic> json) =>
      AdminFacultyMember(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? 'Faculty Member',
        email: json['email'] as String? ?? '',
        department:
            json['department_or_section'] as String? ?? 'College of Computer Studies',
        createdAt: json['created_at'] as String?,
      );
}

class AdminStudent {
  final int id;
  final String name;
  final String email;
  final String section;
  final String status;
  final String? preferredRole;
  final List<String> skills;

  AdminStudent({
    required this.id,
    required this.name,
    required this.email,
    required this.section,
    required this.status,
    this.preferredRole,
    this.skills = const [],
  });

  factory AdminStudent.fromJson(Map<String, dynamic> json) {
    final rawSkills = json['skills'];
    final skillsList = <String>[];
    if (rawSkills is List) {
      for (final s in rawSkills) {
        if (s != null) skillsList.add(s.toString());
      }
    }
    return AdminStudent(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Student',
      email: json['email'] as String? ?? '',
      section: json['section'] as String? ?? 'General',
      status: json['status'] as String? ?? 'uninitialized',
      preferredRole: json['preferred_role'] as String?,
      skills: skillsList,
    );
  }
}

class AdminService {
  final String baseUrl = AuthService.baseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AuthService.authToken != null)
          'Authorization': 'Bearer ${AuthService.authToken}',
      };

  Future<AdminOverview> getOverview() async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/overview'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return AdminOverview.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to load admin overview: ${res.body}');
  }

  Future<List<AdminFacultyMember>> getFaculty() async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/faculty'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((item) => AdminFacultyMember.fromJson(item)).toList();
    }
    throw Exception('Failed to load faculty list: ${res.body}');
  }

  Future<List<AdminStudent>> getStudents() async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/students'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((item) => AdminStudent.fromJson(item)).toList();
    }
    throw Exception('Failed to load student list: ${res.body}');
  }

  Future<void> updateFacultyCode(String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/faculty-code'),
      headers: _headers,
      body: jsonEncode({'faculty_code': code}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update faculty code: ${res.body}');
    }
  }

  Future<void> updateSemester({
    required String mode,
    String? semester,
    String? academicYear,
  }) async {
    final payload = <String, dynamic>{'mode': mode};
    if (semester != null) payload['semester'] = semester;
    if (academicYear != null) payload['academic_year'] = academicYear;

    final res = await http.post(
      Uri.parse('$baseUrl/admin/semester'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update semester configuration: ${res.body}');
    }
  }

  Future<Map<String, String>> getCurrentSemester() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/settings/semester'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return {
          'semester': data['semester']?.toString() ?? '1st Semester',
          'academic_year': data['academic_year']?.toString() ?? '2026-2027',
          'mode': data['mode']?.toString() ?? 'auto',
        };
      }
    } catch (_) {}
    return {
      'semester': '1st Semester',
      'academic_year': '2026-2027',
      'mode': 'auto',
    };
  }
}
