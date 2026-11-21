import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/academic_class.dart';
import '../models/activity_summary.dart';
import '../models/grouping_activity.dart';
import '../models/instruction_file.dart';
import '../models/project_submission.dart';
import '../models/profile.dart';
import '../models/scarcity_report.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'instruction_file_download.dart';

class ActivityService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> get _classHeaders => {
    ..._headers,
    if (AuthService.authToken != null && AuthService.authToken!.isNotEmpty)
      'Authorization': 'Bearer ${AuthService.authToken}',
  };

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getValidToken();
    return {
      ..._headers,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

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

    throw Exception(
      'Failed to load activities (${response.statusCode}): ${response.body}',
    );
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
  Future<GroupingActivity> createActivity(
    GroupingActivity activity, {
    InstructionFile? instructionFile,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/activities');
    final headers = await _authHeaders();
    final response = instructionFile == null
        ? await http.post(uri, headers: headers, body: jsonEncode(activity.toJson()))
        : await _sendActivityMultipart(uri, activity, instructionFile);

    if (response.statusCode == 201) {
      return GroupingActivity.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      'Failed to create activity (${response.statusCode}): ${response.body}',
    );
  }

  /// Update an existing activity
  Future<GroupingActivity> updateActivity(
    int id,
    GroupingActivity activity, {
    InstructionFile? instructionFile,
    bool removeInstructionFile = false,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/activities/$id');
    final headers = await _authHeaders();
    final response = instructionFile == null
        ? await http.put(
            uri,
            headers: headers,
            body: jsonEncode({
              ...activity.toJson(),
              if (removeInstructionFile) 'remove_instruction_file': true,
            }),
          )
        : await _sendActivityMultipart(uri, activity, instructionFile, method: 'POST');

    if (response.statusCode == 200) {
      return GroupingActivity.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      'Failed to update activity (${response.statusCode}): ${response.body}',
    );
  }

  Future<http.Response> _sendActivityMultipart(
    Uri uri,
    GroupingActivity activity,
    InstructionFile instructionFile, {
    String method = 'POST',
  }) async {
    final token = await AuthService.getValidToken();
    final request = http.MultipartRequest(method, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      })
      ..fields['payload'] = jsonEncode(activity.toJson())
      ..files.add(http.MultipartFile.fromBytes(
        'instruction_file',
        instructionFile.bytes,
        filename: instructionFile.name,
      ));
    if (uri.path.endsWith('/${activity.id}')) {
      request.fields['_method'] = 'PUT';
    }
    return http.Response.fromStream(await request.send());
  }

  Future<void> downloadInstructions(GroupingActivity activity) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/activities/${activity.id}/instructions'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Could not download project instructions (${response.statusCode}).');
    }
    saveInstructionFile(
      activity.instructionFileName ?? 'project-instructions',
      response.bodyBytes,
    );
  }

  Future<void> unenrollStudent(int classId, int studentId) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/classes/$classId/students/$studentId'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Could not unenroll student (${response.statusCode}): ${response.body}');
    }
  }

  Future<Map<int, Map<String, dynamic>>> getProjectStatuses(int classId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/classes/$classId/project-statuses'),
      headers: _classHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('Could not load project statuses (${response.statusCode}).');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data.map((key, value) => MapEntry(
      int.parse(key), Map<String, dynamic>.from(value as Map),
    ));
  }

  Future<List<ProjectSubmission>> getProjectSubmissions(int activityId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/activities/$activityId/project-submissions'),
      headers: _classHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('Could not load project submissions (${response.statusCode}).');
    }
    return (jsonDecode(response.body) as List)
        .map((item) => ProjectSubmission.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<ProjectSubmission> submitProject(
    int activityId,
    String teamName,
    InstructionFile file,
  ) async {
    final request = http.MultipartRequest(
      'POST', Uri.parse('${ApiService.baseUrl}/activities/$activityId/project-submissions'),
    )
      ..headers.addAll({
        'Accept': 'application/json',
        if (AuthService.authToken != null && AuthService.authToken!.isNotEmpty)
          'Authorization': 'Bearer ${AuthService.authToken}',
      })
      ..fields['team_name'] = teamName
      ..files.add(http.MultipartFile.fromBytes('file', file.bytes, filename: file.name));
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Could not submit project: ${response.body}');
    }
    return ProjectSubmission.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<ProjectSubmission> gradeProject(
    int submissionId, double grade, String feedback,
  ) async {
    final response = await http.patch(
      Uri.parse('${ApiService.baseUrl}/project-submissions/$submissionId/grade'),
      headers: _classHeaders,
      body: jsonEncode({'grade': grade, 'feedback': feedback}),
    );
    if (response.statusCode != 200) {
      throw Exception('Could not save grade: ${response.body}');
    }
    return ProjectSubmission.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> downloadProjectSubmission(ProjectSubmission submission) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/project-submissions/${submission.id}/file'),
      headers: _classHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('Could not download project file (${response.statusCode}).');
    }
    saveInstructionFile(submission.fileName, response.bodyBytes);
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
    final response = await http.get(uri, headers: _classHeaders);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AcademicClass.fromJson(json)).toList();
    }

    if (response.statusCode == 401) {
      AuthService.authToken = null;
      throw Exception('Session expired or unauthenticated. Please log in again.');
    }

    throw Exception('Failed to load classes (${response.statusCode})');
  }

  /// Get students enrolled in a specific class
  Future<List<Map<String, dynamic>>> getClassStudents(int classId) async {
    final uri = Uri.parse('${ApiService.baseUrl}/classes/$classId/students');
    final response = await http.get(uri, headers: _classHeaders);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }

    if (response.statusCode == 401) {
      AuthService.authToken = null;
      throw Exception('Session expired or unauthenticated. Please log in again.');
    }

    throw Exception('Failed to load class students (${response.statusCode})');
  }

  /// Create a new academic class in backend
  Future<AcademicClass> createClass(AcademicClass academicClass) async {
    final uri = Uri.parse('${ApiService.baseUrl}/classes');
    final response = await http.post(
      uri,
      headers: _classHeaders,
      body: jsonEncode({
        'name': academicClass.name,
        'class_code': academicClass.classCode,
        'section': academicClass.section,
        'description': academicClass.description,
      }),
    );

    if (response.statusCode == 201) {
      return AcademicClass.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 401) {
      AuthService.authToken = null;
      throw Exception('Session expired or unauthenticated. Please log in again.');
    }

    throw Exception(
      'Failed to create class (${response.statusCode}): ${response.body}',
    );
  }

  /// Update an academic class in backend
  Future<AcademicClass> updateClass(
    int id,
    AcademicClass academicClass,
  ) async {
    final uri = Uri.parse('${ApiService.baseUrl}/classes/$id');
    final response = await http.put(
      uri,
      headers: _classHeaders,
      body: jsonEncode({
        'name': academicClass.name,
        'class_code': academicClass.classCode,
        'section': academicClass.section,
        'description': academicClass.description,
      }),
    );

    if (response.statusCode == 200) {
      return AcademicClass.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 401) {
      AuthService.authToken = null;
      throw Exception('Session expired or unauthenticated. Please log in again.');
    }

    throw Exception(
      'Failed to update class (${response.statusCode}): ${response.body}',
    );
  }

  /// Delete an academic class from backend
  Future<void> deleteClass(int id) async {
    final uri = Uri.parse('${ApiService.baseUrl}/classes/$id');
    final response = await http.delete(uri, headers: _classHeaders);

    if (response.statusCode == 401) {
      AuthService.authToken = null;
      throw Exception('Session expired or unauthenticated. Please log in again.');
    }

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete class (${response.statusCode})');
    }
  }

  Future<AcademicClass> enrollInClass(String classCode) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/classes/enroll'),
      headers: _classHeaders,
      body: jsonEncode({'class_code': classCode.trim()}),
    );
    if (response.statusCode == 200) {
      return AcademicClass.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 401) {
      AuthService.authToken = null;
      throw Exception('Session expired or unauthenticated. Please log in again.');
    }
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] != null) {
        throw Exception(body['message']);
      }
    } catch (e) {
      if (e is! FormatException) rethrow;
    }
    throw Exception('Class code "$classCode" not found. Please verify with your instructor.');
  }

  /// Get skill distribution and scarcity analysis for an activity
  Future<ScarcityReport> getScarcityReport(int activityId) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/activities/$activityId/scarcity',
    );
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
    final uri = Uri.parse(
      '${ApiService.baseUrl}/activities/$activityId/auto-form',
    );
    final response = await http.post(
      uri,
      headers: _classHeaders,
      body: jsonEncode({'strategy': strategy}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to auto-form unassigned students (${response.statusCode})',
    );
  }

  /// Add skill directly to activity
  Future<GroupingActivity> addSkillToActivity(
    int activityId,
    String skill,
    String type,
  ) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/activities/$activityId/add-skill',
    );
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

  /// Get formed teams for an activity
  Future<List<dynamic>> getTeams(int activityId) async {
    final uri = Uri.parse('${ApiService.baseUrl}/activities/$activityId/teams');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }

    throw Exception('Failed to load teams (${response.statusCode})');
  }

  /// Create a new team for an activity
  Future<Map<String, dynamic>> createTeam(
    int activityId,
    String name, {
    String? role,
    String? leaderName,
    String? leaderEmail,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/activities/$activityId/teams');
    final response = await http.post(
      uri,
      headers: _classHeaders,
      body: jsonEncode({
        'name': name,
        'role': role,
        if (leaderName != null) ...{'leader_name': leaderName},
        if (leaderEmail != null) ...{'leader_email': leaderEmail},
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to create team (${response.statusCode}): ${response.body}',
    );
  }

  Future<List<Profile>> getInviteCandidates(int activityId, String teamName) async {
    final uri = Uri.parse('${ApiService.baseUrl}/activities/$activityId/teams/invite-candidates')
        .replace(queryParameters: {'team_name': teamName});
    final response = await http.get(uri, headers: _classHeaders);
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((item) => Profile.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load invite candidates (${response.statusCode}): ${response.body}');
  }

  /// Invite a student to join a team
  Future<void> inviteStudent(
    int activityId,
    String teamName,
    String studentName, {
    String? studentEmail,
    String? role,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/activities/$activityId/teams/invite',
    );
    final response = await http.post(
      uri,
      headers: _classHeaders,
      body: jsonEncode({
        'team_name': teamName,
        'student_name': studentName,
        'student_email': studentEmail,
        'role': role,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to invite student (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Respond to a team invitation.
  Future<Map<String, dynamic>> respondInvitation(
    int activityId, {
    required String teamName,
    required String action,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/activities/$activityId/teams/respond-invite'),
      headers: _classHeaders,
      body: jsonEncode({'team_name': teamName, 'action': action}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to respond to invitation (${response.statusCode}): ${response.body}');
  }

  /// Join an existing team in an activity
  Future<Map<String, dynamic>> joinTeam(
    int activityId, {
    required String teamName,
    required String studentName,
    required String studentEmail,
    String? role,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/activities/$activityId/teams/join',
    );
    final response = await http.post(
      uri,
      headers: _classHeaders,
      body: jsonEncode({
        'team_name': teamName,
        'student_name': studentName,
        'student_email': studentEmail,
        'role': ?role,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to join team (${response.statusCode}): ${response.body}',
    );
  }

  /// Respond to a join request (Leader accepts or declines)
  Future<Map<String, dynamic>> respondJoinRequest(
    int activityId, {
    required String teamName,
    required String studentEmail,
    required String action, // 'accept' or 'decline'
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/activities/$activityId/teams/respond-join',
    );
    final response = await http.post(
      uri,
      headers: _classHeaders,
      body: jsonEncode({
        'team_name': teamName,
        'student_email': studentEmail,
        'action': action,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to respond to join request (${response.statusCode}): ${response.body}',
    );
  }

  /// Respond to all join requests for a team (Leader accepts or declines all)
  Future<Map<String, dynamic>> respondAllJoinRequests(
    int activityId, {
    required String teamName,
    required String action, // 'accept_all' or 'decline_all'
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/activities/$activityId/teams/respond-join',
    );
    final response = await http.post(
      uri,
      headers: _classHeaders,
      body: jsonEncode({
        'team_name': teamName,
        'student_email': 'all',
        'action': action,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to respond to all join requests (${response.statusCode}): ${response.body}',
    );
  }

  /// Submit group for professor evaluation (checks scarce skills)
  Future<Map<String, dynamic>> submitGroupEvaluation(
    int activityId, {
    required String teamName,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/activities/$activityId/teams/submit-evaluation',
    );
    final response = await http.post(
      uri,
      headers: _classHeaders,
      body: jsonEncode({
        'team_name': teamName,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to submit group for evaluation (${response.statusCode}): ${response.body}',
    );
  }

  /// Professor reviews group proposal (approve or decline with scarcity notes)
  Future<Map<String, dynamic>> reviewTeamProposal(
    int activityId, {
    required String teamName,
    required String decision,
    String? notes,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/activities/$activityId/teams/review',
    );
    final response = await http.post(
      uri,
      headers: _classHeaders,
      body: jsonEncode({
        'team_name': teamName,
        'decision': decision,
        'professor_notes': ?notes,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to review group proposal (${response.statusCode}): ${response.body}',
    );
  }

  /// Accept suggested group (Step 8)
  Future<void> acceptGroup(int activityId, {String? email}) async {
    final uri = Uri.parse('${ApiService.baseUrl}/activities/$activityId/accept-group');
    final payload = <String, dynamic>{};
    if (email != null) payload['email'] = email;
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to accept group (${response.statusCode})');
    }
  }

  /// Request group change (Step 8 -> Step 9)
  Future<void> requestChange(
    int activityId, {
    required String reason,
    String? preferredSwap,
    String? studentName,
    String? studentEmail,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/activities/$activityId/request-change');
    final payload = <String, dynamic>{'reason': reason};
    if (preferredSwap != null) payload['preferred_swap'] = preferredSwap;
    if (studentName != null) payload['student_name'] = studentName;
    if (studentEmail != null) payload['student_email'] = studentEmail;
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to request change (${response.statusCode})');
    }
  }

  /// Request member replacement for a team (Step 8 -> Step 9, Leader picks outgoing and replacement)
  Future<List<Map<String, dynamic>>> getPreSubmissionSwaps() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/pre-submission-swaps'),
      headers: _classHeaders,
    );
    if (response.statusCode != 200) {
      throw Exception('Could not load replacement proposals (${response.statusCode}): ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['swaps'] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> proposePreSubmissionSwap(
    int activityId, {
    required String teamName,
    required String outgoingEmail,
    required String incomingEmail,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/activities/$activityId/teams/pre-submission-swaps'),
      headers: _classHeaders,
      body: jsonEncode({
        'team_name': teamName,
        'outgoing_email': outgoingEmail,
        'incoming_email': incomingEmail,
        'reason': reason,
      }),
    );
    if (response.statusCode != 201) throw Exception('Could not propose replacement: ${response.body}');
  }

  Future<void> decidePreSubmissionSwap(int id, String decision) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/pre-submission-swaps/$id/decision'),
      headers: _classHeaders,
      body: jsonEncode({'decision': decision}),
    );
    if (response.statusCode != 200) throw Exception('Could not update replacement: ${response.body}');
  }

  Future<Map<String, dynamic>> requestMemberChange(
    int activityId, {
    required String teamName,
    required String outgoingEmail,
    required String outgoingName,
    required String incomingEmail,
    required String incomingName,
    required String reason,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/activities/$activityId/teams/request-member-change',
    );
    final response = await http.post(
      uri,
      headers: _classHeaders,
      body: jsonEncode({
        'team_name': teamName,
        'outgoing_student_email': outgoingEmail,
        'outgoing_student_name': outgoingName,
        'incoming_student_email': incomingEmail,
        'incoming_student_name': incomingName,
        'reason': reason,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to submit member change request (${response.statusCode}): ${response.body}',
    );
  }

  /// Get modification requests (Step 9 for professor)
  Future<List<Map<String, dynamic>>> getModificationRequests() async {
    final uri = Uri.parse('${ApiService.baseUrl}/modification-requests');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List list = decoded is List
          ? decoded
          : ((decoded as Map<String, dynamic>)['requests'] as List? ?? []);
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }

    throw Exception(
      'Failed to load modification requests (${response.statusCode})',
    );
  }

  /// Professor decides a modification request (approve or decline)
  Future<Map<String, dynamic>> decideModificationRequest(
    int requestId, {
    required String decision,
    String? notes,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/modification-requests/$requestId/decision',
    );
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'decision': decision,
        'notes': ?notes,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to decide modification request (${response.statusCode}): ${response.body}',
    );
  }
}
