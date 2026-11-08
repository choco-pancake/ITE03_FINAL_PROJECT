import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/academic_class.dart';
import '../models/activity_summary.dart';
import '../models/grouping_activity.dart';
import '../models/scarcity_report.dart';
import 'api_service.dart';

class ActivityService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Get list of grouping activities with optional filters
  Future<List<GroupingActivity>> getActivities({
    String? status,
    String? search,
    int? classId,
  }) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (classId != null) {
      queryParams['class_id'] = classId.toString();
    }

    final uri = Uri.parse('${ApiService.baseUrl}/activities')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => GroupingActivity.fromJson(json)).toList();
    }

    throw Exception('Failed to load activities (${response.statusCode}): ${response.body}');
  }

  /// Get dashboard activity summary counts
  Future<ActivitySummary> getActivitySummary() async {
    final uri = Uri.parse('${ApiService.baseUrl}/activities/summary');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return ActivitySummary.fromJson(data);
    }

    throw Exception('Failed to load activity summary (${response.statusCode})');
  }

  /// Get single activity details
  Future<GroupingActivity> getActivity(int id) async {
    final uri = Uri.parse('${ApiService.baseUrl}/activities/$id');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return GroupingActivity.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to load activity #$id (${response.statusCode})');
  }

  /// Create a new grouping activity
  Future<GroupingActivity> createActivity(GroupingActivity activity) async {
    final uri = Uri.parse('${ApiService.baseUrl}/activities');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(activity.toJson()),
    );

    if (response.statusCode == 201) {
      return GroupingActivity.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to create activity (${response.statusCode}): ${response.body}');
  }

  /// Update an existing activity
  Future<GroupingActivity> updateActivity(int id, GroupingActivity activity) async {
    final uri = Uri.parse('${ApiService.baseUrl}/activities/$id');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(activity.toJson()),
    );

    if (response.statusCode == 200) {
      return GroupingActivity.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to update activity (${response.statusCode}): ${response.body}');
  }

  /// Delete an activity
  Future<void> deleteActivity(int id) async {
    final uri = Uri.parse('${ApiService.baseUrl}/activities/$id');
    final response = await http.delete(uri, headers: _headers);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete activity (${response.statusCode})');
    }
  }

  /// Get list of classes for dropdown
  Future<List<AcademicClass>> getClasses() async {
    final uri = Uri.parse('${ApiService.baseUrl}/classes');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AcademicClass.fromJson(json)).toList();
    }

    throw Exception('Failed to load classes (${response.statusCode})');
  }

  /// Get skill distribution and scarcity analysis for an activity
  Future<ScarcityReport> getScarcityReport(int activityId) async {
    final uri = Uri.parse('${ApiService.baseUrl}/activities/$activityId/scarcity');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return ScarcityReport.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to load scarcity report (${response.statusCode})');
  }

  /// Auto-form teams for unassigned students
  Future<Map<String, dynamic>> autoFormUnassigned(
    int activityId, {
    String strategy = 'fill_incomplete',
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/activities/$activityId/auto-form');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'strategy': strategy}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to auto-form unassigned students (${response.statusCode})');
  }

  /// Add skill directly to activity
  Future<GroupingActivity> addSkillToActivity(
    int activityId,
    String skill,
    String type,
  ) async {
    final uri = Uri.parse('${ApiService.baseUrl}/activities/$activityId/add-skill');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'skill': skill, 'type': type}),
    );

    if (response.statusCode == 200) {
      return GroupingActivity.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to add skill to activity (${response.statusCode})');
  }
}
