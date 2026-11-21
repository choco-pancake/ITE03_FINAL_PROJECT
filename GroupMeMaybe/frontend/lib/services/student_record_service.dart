import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/student_record.dart';
import 'auth_service.dart';

class StudentRecordService {
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (AuthService.authToken != null && AuthService.authToken!.isNotEmpty)
      'Authorization': 'Bearer ${AuthService.authToken}',
  };

  Future<List<StudentRecord>> getStudents() async {
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/professor/students'),
      headers: _headers,
    );
    if (response.statusCode == 401) {
      AuthService.authToken = null;
      throw Exception('Session expired or unauthenticated. Please log in again.');
    }
    if (response.statusCode != 200) {
      throw Exception(_message(response, 'Could not load students.'));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['students'] as List<dynamic>)
        .map((item) => StudentRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> unenrollStudent(int classId, int studentId) async {
    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/classes/$classId/students/$studentId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception(_message(response, 'Could not unenroll student.'));
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
