import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_skill_request.dart';
import 'auth_service.dart';

class SkillApprovalService extends ChangeNotifier {
  static final SkillApprovalService _instance =
      SkillApprovalService._internal();
  factory SkillApprovalService() => _instance;

  SkillApprovalService._internal();

  final List<CustomSkillRequest> _requests = [];
  final Set<String> _approvedSkills = {};

  List<CustomSkillRequest> get requests => List.unmodifiable(_requests);

  Set<String> get approvedSkills => Set.unmodifiable(_approvedSkills);

  Future<Map<String, String>> _getHeaders() async {
    String? token = AuthService.authToken;
    if (token == null || token.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('gmm_active_token') ??
            prefs.getString('gmm_saved_token') ??
            prefs.getString('auth_token');
      } catch (_) {}
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> loadRequests() async {
    final headers = await _getHeaders();
    if (!headers.containsKey('Authorization')) return;
    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/custom-skill-requests'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Could not load custom skill requests.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _requests
      ..clear()
      ..addAll(
        (data['requests'] as List).map(
          (item) => CustomSkillRequest.fromJson(item as Map<String, dynamic>),
        ),
      );
    _approvedSkills
      ..clear()
      ..addAll(List<String>.from(data['approved_skills'] as List));
    notifyListeners();
  }

  List<CustomSkillRequest> getRequestsByStatus(SkillApprovalStatus? status) {
    if (status == null) return List.unmodifiable(_requests);
    return _requests.where((r) => r.status == status).toList();
  }

  Future<void> submitRequest({
    required String studentName,
    required String studentId,
    required String block,
    required String skillName,
    required String domain,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/custom-skill-requests'),
      headers: headers,
      body: jsonEncode({'skill_name': skillName, 'domain': domain}),
    );
    if (response.statusCode != 201) {
      throw Exception('Could not submit custom skill request.');
    }
    final newReq = CustomSkillRequest.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    _requests.insert(0, newReq);
    notifyListeners();
  }

  Future<void> updateStatus(
    String requestId,
    SkillApprovalStatus newStatus, {
    String? remarks,
  }) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('${AuthService.baseUrl}/custom-skill-requests/$requestId'),
        headers: headers,
        body: jsonEncode({'status': newStatus.name, 'remarks': remarks}),
      );
      if (response.statusCode != 200) {
        throw Exception('Could not update custom skill request.');
      }
      final req = CustomSkillRequest.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      _requests[index] = req;

      if (newStatus == SkillApprovalStatus.approved) {
        _approvedSkills.add(req.skillName);
      } else {
        _approvedSkills.remove(req.skillName);
      }
      notifyListeners();
    }
  }

  void deleteRequest(String requestId) {
    _requests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }

  void removeRequestsForStudent(String studentId) {
    _requests.removeWhere((request) => request.studentId == studentId);
    notifyListeners();
  }

  bool isSkillApproved(String skill) {
    return _approvedSkills.contains(skill);
  }
}
