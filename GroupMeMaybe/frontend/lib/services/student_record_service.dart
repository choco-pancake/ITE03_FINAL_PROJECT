import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/student_record.dart';
import 'auth_service.dart';

class StudentRecordService {
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (AuthService.authToken != null)
      'Authorization': 'Bearer ${AuthService.authToken}',
  };

  Future<List<StudentRecord>> getStudents() async {
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/professor/students'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception(_message(response, 'Could not load students.'));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['students'] as List<dynamic>)
        .map((item) => StudentRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateStudent(int studentId, Map<String, String> values) async {
    final response = await http.patch(
      Uri.parse('${AuthService.baseUrl}/professor/students/$studentId/record'),
      headers: _headers,
      body: jsonEncode(values),
    );
    if (response.statusCode != 200) {
      throw Exception(_message(response, 'Could not update student record.'));
    }
  }

  String _message(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['message'] ?? fallback).toString();
    } catch (_) {
      return fallback;
    }
  }
}
