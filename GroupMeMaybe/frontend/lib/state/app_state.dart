// Updated AppState with required stubs and proper syntax
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/class_model.dart';
import '../models/activity_model.dart';
import '../models/team_model.dart';
import '../models/request_model.dart';
import '../models/notification_model.dart';
import '../data/constants.dart';
import '../data/seed_data.dart';
import '../services/hybrid_matcher.dart';

class AppState extends ChangeNotifier {
  // Current session user (null initially, requiring login/signup)
  UserModel? _currentUser;
  bool get isAuthenticated => _currentUser != null;
  UserModel get currentUser => _currentUser ?? SeedData.alexStudentUser;
  bool get isProfessor => _currentUser?.role == UserRole.professor;
  bool get isStudent => _currentUser?.role == UserRole.student;

  // Repositories
  List<UserModel> _students = [];
  List<ClassModel> _classes = [];
  List<ActivityModel> _activities = [];
  List<TeamModel> _teams = [];
  List<ModificationRequestModel> _requests = [];
  List<CustomSkillRequestModel> _customSkills = [];
  List<NotificationItem> _notifications = [];
  List<String> _officialSkills = [];

  // Adjustable Compatibility Weights
  double skillsWeight = 0.40;
  double interestWeight = 0.30;
  double availabilityWeight = 0.30;

  // Selected contexts
  String? selectedClassId;
  String? selectedActivityId;

  AppState() {
    _initData();
  }

  void _initData() {
    _currentUser = null;
    _students = List.from(SeedData.initialStudents);
    _classes = List.from(SeedData.initialClasses);
    _activities = List.from(SeedData.initialActivities);
    _teams = List.from(SeedData.initialTeams);
    _requests = List.from(SeedData.initialRequests);
    _customSkills = List.from(SeedData.initialCustomSkills);
    _notifications = List.from(SeedData.initialNotifications);
    _officialSkills = List.from(AppConstants.defaultTechnicalSkills);
    if (_classes.isNotEmpty) selectedClassId = _classes.first.id;
    if (_activities.isNotEmpty) selectedActivityId = _activities.first.id;
  }

  // Getters (unmodifiable)
  List<UserModel> get students => List.unmodifiable(_students);
  List<ClassModel> get classes => List.unmodifiable(_classes);
  List<ActivityModel> get activities => List.unmodifiable(_activities);
  List<TeamModel> get teams => List.unmodifiable(_teams);
  List<ModificationRequestModel> get requests => List.unmodifiable(_requests);
  List<CustomSkillRequestModel> get customSkills =>
      List.unmodifiable(_customSkills);
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  List<String> get officialSkills => List.unmodifiable(_officialSkills);

  // Notifications filtered for current user
  List<NotificationItem> get userNotifications => _notifications.where((n) {
    if (n.recipientId == 'all') return true;
    if (isProfessor && n.recipientId == 'prof-1') return true;
    return n.recipientId == currentUser.id;
  }).toList();

  int get unreadNotificationsCount =>
      userNotifications.where((n) => !n.isRead).length;

  void markAllNotificationsRead() {
    for (var n in _notifications) {
      if (n.recipientId == 'all' ||
          n.recipientId == currentUser.id ||
          (isProfessor && n.recipientId == 'prof-1')) {
        n.isRead = true;
      }
    }
    notifyListeners();
  }

  // Authentication helpers
  void setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void loginAsProfessor() {
    _currentUser = SeedData.professorUser;
    notifyListeners();
  }

  void loginAsStudent([String? studentId]) {
    if (studentId != null && studentId.isNotEmpty) {
      _currentUser = _students.firstWhere(
        (s) => s.id == studentId,
        orElse: () => SeedData.alexStudentUser,
      );
    } else {
      _currentUser = _students.firstWhere(
        (s) => s.id == SeedData.alexStudentUser.id,
        orElse: () => SeedData.alexStudentUser,
      );
    }
    notifyListeners();
  }

  // Profile Management
  void updateStudentProfile(UserModel updatedUser, {bool asDraft = false}) {
    updatedUser.isDraft = asDraft;
    updatedUser.recalculateProficiency();
    updatedUser.recalculateProfileStatus();
    final index = _students.indexWhere((s) => s.id == updatedUser.id);
    if (index != -1) {
      _students[index] = updatedUser;
    } else {
      _students.add(updatedUser);
    }
    if (_currentUser?.id == updatedUser.id) {
      _currentUser = updatedUser;
    }
    _notifications.insert(
      0,
      NotificationItem(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        title: asDraft
            ? 'Profile Saved as Draft'
            : 'Profile Updated Successfully',
        message: asDraft
            ? 'Your profile details were saved as a draft. Finalize to participate in team grouping.'
            : 'Your profile has been rated: ${updatedUser.proficiencyRating.name.toUpperCase()} level. You are now active in team matching.',
        timestamp: DateTime.now(),
        recipientId: updatedUser.id,
        type: NotificationType.general,
      ),
    );
    notifyListeners();
  }

  // Custom Skill Requests
  void submitCustomSkillRequest({
    required String skillName,
    required String category,
    required String justification,
  }) {
    final req = CustomSkillRequestModel(
      id: 'skill-req-${DateTime.now().millisecondsSinceEpoch}',
      studentId: currentUser.id,
      studentName: currentUser.fullName.isNotEmpty
          ? currentUser.fullName
          : currentUser.displayName,
      skillName: skillName,
      category: category,
      justification: justification,
      dateRequested: DateTime.now(),
      status: RequestStatus.pending,
    );
    _customSkills.insert(0, req);
    _notifications.insert(
      0,
      NotificationItem(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Skill Approval Request',
        message:
            '${currentUser.fullName.isNotEmpty ? currentUser.fullName : currentUser.displayName} requested addition of "$skillName" to official curriculum skills.',
        timestamp: DateTime.now(),
        recipientId: 'prof-1',
        type: NotificationType.customSkill,
      ),
    );
    notifyListeners();
  }

  void approveCustomSkill(String requestId, {String? remarks}) {
    final index = _customSkills.indexWhere((r) => r.id == requestId);
    if (index == -1) return;
    final req = _customSkills[index];
    req.status = RequestStatus.approved;
    req.reviewerRemarks = remarks ?? 'Approved for official course grouping.';
    if (!_officialSkills.contains(req.skillName)) {
      _officialSkills.add(req.skillName);
    }
    final student = _students.firstWhere(
      (s) => s.id == req.studentId,
      orElse: () => currentUser,
    );
    student.technicalSkills ??= [];
    student.technicalSkills!.add(req.skillName);
    notifyListeners();
  }

  void rejectCustomSkill(String requestId, {String? remarks}) {
    final index = _customSkills.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _customSkills[index].status = RequestStatus.rejected;
      _customSkills[index].reviewerRemarks = remarks ?? 'Rejected';
    }
    notifyListeners();
  }

  // Stub for class creation – required parameters matching UI calls
  void createClass({
    required String code,
    required String name,
    required String section,
    String? professorId,
    String? professorName,
  }) {
    final newClass = ClassModel(
      id: code,
      code: code,
      name: name,
      section: section,
      enrollmentCode: '',
      professorId: professorId ?? '',
      professorName: professorName ?? '',
    );
    _classes.add(newClass);
    notifyListeners();
  }

  // Enroll in class – optional activityId param for UI compatibility
  bool enrollInClass(String classCode, {String? activityId}) {
    // Placeholder logic – always succeed
    return true;
  }

  HybridResult runHybridModeComputation({
    required String activityId,
    required String classId,
    required bool fillIncompleteFirst,
  }) {
    // Placeholder hybrid matcher result – in a real app this would invoke HybridMatcher.execute.
    return HybridResult(
      allTeams: [],
      modifiedTeams: [],
      newTeams: [],
      remainingStudents: [],
      stepLogs: ['Hybrid computation placeholder executed.'],
      balanceGap: 0.0,
      highestScore: 0.0,
      lowestScore: 0.0,
      openSlots: 0,
      unassignedCount: 0,
      studentsFilled: 0,
      newTeamsCount: 0,
      swapsPerformed: 0,
    );
  }

  // Accept any first argument for metrics calculation to match UI calls
  Map<String, dynamic> calculateTeamMetrics(dynamic team, dynamic extra) {
    return {};
  }

  void assignUnassignedStudentToTeam(String studentId, String teamId) {
    final idx = _students.indexWhere((s) => s.id == studentId);
    if (idx != -1) {
      _students[idx].assignedTeamId = teamId;
    }
    notifyListeners();
  }

  // Load initial data from Blade‑injected JSON (used on web start)
  void loadInitialData(String json) {
    try {
      final Map<String, dynamic> data = jsonDecode(json);
      final String? userId = data['userId'] as String?;
      final String? role = data['role'] as String?;
      if (userId != null && role != null) {
        final UserModel? user = _students.firstWhere(
          (s) => s.id == userId,
          orElse: () => SeedData.alexStudentUser,
        );
        if (user != null) {
          _currentUser = user;
        }
      }
    } catch (_) {}
    notifyListeners();
  }
}
