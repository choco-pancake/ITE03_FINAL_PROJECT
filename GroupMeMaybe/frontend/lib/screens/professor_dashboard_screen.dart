import '../models/student_record.dart';
import '../services/student_record_service.dart';
import 'widgets/student_profile_dialog.dart';
import 'package:flutter/material.dart';

import 'widgets/portal_top_actions.dart';

import '../models/custom_skill_request.dart';
import '../models/grouping_activity.dart';
import '../models/profile.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/skill_approval_service.dart';
import 'professor_evaluation_screen.dart';
import 'professor_activities_screen.dart';
import 'professor_classes_screen.dart';
import 'widgets/bottom_right_notification.dart';
import '../models/academic_class.dart';
import 'widgets/professor_sidebar.dart';

// Helper model for student completion statuses
enum ProfileCompletionStatus { complete, incomplete, uninitialized }

class StudentRosterItem {
  final String id;
  final String name;
  final String studentId;
  final String block;
  final ProfileCompletionStatus status;
  final String? primaryRole;
  final String? skillLevel;
  final List<String> topSkills;
  final String email;

  StudentRosterItem({
    required this.id,
    required this.name,
    required this.studentId,
    required this.block,
    required this.status,
    this.primaryRole,
    this.skillLevel,
    this.topSkills = const [],
    required this.email,
  });
}

// Helper model for Team Overview
class TeamOverviewItem {
  final String id;
  final String name;
  final String course;
  final String activityName;
  final String status;
  final int maxMembers;
  final List<StudentRosterItem> members;
  final int? activityId;
  final String? proposalStatus;
  final Map<String, dynamic>? scarcityReport;
  final String? professorNotes;

  TeamOverviewItem({
    required this.id,
    required this.name,
    required this.course,
    required this.activityName,
    required this.status,
    required this.maxMembers,
    required this.members,
    this.activityId,
    this.proposalStatus,
    this.scarcityReport,
    this.professorNotes,
  });
}

// Helper model for Unassigned Student
class UnassignedStudent {
  final String id;
  final String name;
  final String studentId;
  final String block;
  final String preferredRole;
  final String skillLevel;
  final List<String> skills;
  final List<RecommendedGroupMatch> recommendedGroups;

  UnassignedStudent({
    required this.id,
    required this.name,
    required this.studentId,
    required this.block,
    required this.preferredRole,
    required this.skillLevel,
    required this.skills,
    required this.recommendedGroups,
  });
}

class RecommendedGroupMatch {
  final String teamId;
  final String teamName;
  final int matchPercentage;
  final String reason;

  RecommendedGroupMatch({
    required this.teamId,
    required this.teamName,
    required this.matchPercentage,
    required this.reason,
  });
}

class ProfessorDashboardScreen extends StatefulWidget {
  final bool scrollToSkills;
  final bool scrollToTeams;

  const ProfessorDashboardScreen({
    super.key,
    this.scrollToSkills = false,
    this.scrollToTeams = false,
  });

  @override
  State<ProfessorDashboardScreen> createState() =>
      _ProfessorDashboardScreenState();
}

class _ProfessorDashboardScreenState extends State<ProfessorDashboardScreen> {
  final SkillApprovalService _skillService = SkillApprovalService();
  final ProfileService _profileService = ProfileService();
  final ActivityService _activityService = ActivityService();
  final TextEditingController _studentSearchController =
      TextEditingController();
  final GlobalKey _skillsSectionKey = GlobalKey();
  final GlobalKey _teamsSectionKey = GlobalKey();

  // Completion filter: 'all', 'complete', 'incomplete', 'uninitialized'
  String _selectedCompletionFilter = 'all';

  // Skill approval filter: null for all, or SkillApprovalStatus
  SkillApprovalStatus? _selectedSkillStatusFilter;

  // Dynamic Students Roster
  List<StudentRosterItem> _allStudents = [];

  // Dynamic Teams
  List<TeamOverviewItem> _teams = [];

  // Dynamic Classes & Activities
  List<AcademicClass> _classes = [];
  List<GroupingActivity> _activities = [];

  // Unassigned Students past deadline
  List<UnassignedStudent> _unassignedStudents = [];

  @override
  void initState() {
    super.initState();
    _skillService.addListener(_onSkillServiceUpdated);
    _skillService.loadRequests().catchError((Object _) {});
    _initData();
    if (widget.scrollToSkills) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_skillsSectionKey.currentContext != null) {
          Scrollable.ensureVisible(
            _skillsSectionKey.currentContext!,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      });
    }
    if (widget.scrollToTeams) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_teamsSectionKey.currentContext != null) {
          Scrollable.ensureVisible(
            _teamsSectionKey.currentContext!,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _skillService.removeListener(_onSkillServiceUpdated);
    _studentSearchController.dispose();
    super.dispose();
  }

  void _onSkillServiceUpdated() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmSkillDecision(
    CustomSkillRequest request,
    SkillApprovalStatus decision,
  ) async {
    final approving = decision == SkillApprovalStatus.approved;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: approving
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                approving ? Icons.verified : Icons.cancel_outlined,
                color: approving
                    ? const Color(0xFF1E40AF)
                    : const Color(0xFFDC2626),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              approving ? 'Approve Skill Request' : 'Decline Skill Request',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to ${approving ? "approve" : "decline"} this custom skill request?',
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Requested Skill: ',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      Text(
                        request.skillName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text(
                        'Student: ',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      Text(
                        '${request.studentName} (${request.block})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approving
                  ? const Color(0xFF1E40AF)
                  : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(approving ? 'Confirm Approve' : 'Confirm Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _skillService.updateStatus(
        request.id,
        decision,
        remarks: approving
            ? 'Verified syllabus alignment.'
            : 'Out of scope for current curriculum.',
      );
      if (mounted) {
        AppNotification.showMessage(
          context,
          approving ? 'Skill approved' : 'Skill request rejected',
          '"${request.skillName}" was ${approving ? 'approved' : 'rejected'}.',
        );
      }
    } catch (error) {
      if (mounted) {
        AppNotification.showError(
          context,
          error.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  void _initData() {
    _allStudents = [];
    _teams = [];
    _unassignedStudents = [];
    _loadDynamicData();
  }

  Future<void> _loadDynamicData() async {
    try {
      final profilesFuture = _profileService.getProfiles();
      final activitiesFuture = _activityService.getActivities();
      final classesFuture = _activityService.getClasses();
      final studentRecordsFuture = StudentRecordService().getStudents().catchError((_) => <StudentRecord>[]);
      final results = await Future.wait([
        profilesFuture,
        activitiesFuture,
        classesFuture,
        studentRecordsFuture,
      ]);

      final profiles = results[0] as List<Profile>;
      final activities = results[1] as List<GroupingActivity>;
      final classes = results[2] as List<AcademicClass>;
      final studentRecords = results[3] as List<StudentRecord>;

      if (!mounted) return;

      setState(() {
        _classes = classes;
        _activities = activities;

        // If the professor has not created any classes yet, no students or unassigned students should appear
        if (classes.isEmpty) {
          _allStudents = [];
          _teams = [];
          _unassignedStudents = [];
          return;
        }

        final classSections = classes
            .map((c) => c.section?.trim().toLowerCase())
            .where((s) => s != null && s.isNotEmpty)
            .toSet();

        // Filter profiles to those belonging to the instructor's created classes
        final classProfiles = profiles.where((p) {
          final block = (p.details['block'] ?? p.availability)
              .toString()
              .trim()
              .toLowerCase();
          if (classSections.contains(block)) {
            return true;
          }
          for (final sec in classSections) {
            if (sec != null && sec.isNotEmpty && block.contains(sec)) {
              return true;
            }
          }
          return false;
        }).toList();

        // Build students from enrolled records (or filtered profiles fallback)
        if (studentRecords.isNotEmpty) {
          _allStudents = studentRecords.map((r) {
            final p = profiles.where((prof) => prof.email.toLowerCase() == r.email.toLowerCase()).firstOrNull;
            final hasRole = p?.preferredRole.isNotEmpty == true;
            final hasSkills = p?.skills.isNotEmpty == true;
            final status = (hasRole && hasSkills)
                ? ProfileCompletionStatus.complete
                : ((hasRole || hasSkills)
                      ? ProfileCompletionStatus.incomplete
                      : ProfileCompletionStatus.uninitialized);

            return StudentRosterItem(
              id: 's-${r.id}',
              name: r.name,
              studentId: r.studentId,
              block: r.block,
              status: status,
              primaryRole: p?.preferredRole.isNotEmpty == true ? p!.preferredRole : null,
              skillLevel: (p?.skills.length ?? 0) >= 4
                  ? 'Advanced'
                  : ((p?.skills.length ?? 0) >= 2 ? 'Intermediate' : 'Beginner'),
              topSkills: p?.skills ?? [],
              email: r.email,
            );
          }).toList();
        } else {
        // Build students from filtered profiles
        _allStudents = classProfiles.map((p) {
          final hasRole = p.preferredRole.isNotEmpty;
          final hasSkills = p.skills.isNotEmpty;
          final status = (hasRole && hasSkills)
              ? ProfileCompletionStatus.complete
              : ((hasRole || hasSkills)
                    ? ProfileCompletionStatus.incomplete
                    : ProfileCompletionStatus.uninitialized);

          final details = p.details;
          final realStudentId = (details['student_id'] != null &&
                  details['student_id'].toString().trim().isNotEmpty)
              ? details['student_id'].toString().trim()
              : '2023-${(p.id ?? 1).toString().padLeft(4, '0')}';
          final realBlock = (details['block'] != null &&
                  details['block'].toString().trim().isNotEmpty)
              ? details['block'].toString().trim()
              : (p.availability.isNotEmpty ? p.availability : 'General');

          return StudentRosterItem(
            id: 's-${p.id ?? DateTime.now().millisecond}',
            name: p.name,
            studentId: realStudentId,
            block: realBlock,
            status: status,
            primaryRole: p.preferredRole.isNotEmpty ? p.preferredRole : null,
            skillLevel: p.skills.length >= 4
                ? 'Advanced'
                : (p.skills.length >= 2 ? 'Intermediate' : 'Beginner'),
            topSkills: p.skills,
            email: p.email,
          );
        }).toList();
        }

        // Build teams from activities
        _teams = [];
        for (final act in activities) {
          if (act.formedTeams != null && act.formedTeams!.isNotEmpty) {
            for (final tm in act.formedTeams!) {
              if (tm is Map) {
                final membersRaw = (tm['members'] as List?) ?? [];
                final teamMembers = membersRaw.map((m) {
                  final mName = (m is Map)
                      ? (m['name']?.toString() ?? 'Member')
                      : m.toString();
                  final existing = _allStudents
                      .cast<StudentRosterItem?>()
                      .firstWhere(
                        (s) =>
                            s != null &&
                            s.name.toLowerCase() == mName.toLowerCase(),
                        orElse: () => null,
                      );
                  return existing ??
                      StudentRosterItem(
                        id: 'tm-${mName.hashCode}',
                        name: mName,
                        studentId: '2023-0000',
                        block: 'General',
                        status: ProfileCompletionStatus.complete,
                        primaryRole: (m is Map)
                            ? m['role']?.toString()
                            : 'Member',
                        skillLevel: (m is Map)
                            ? m['level']?.toString()
                            : 'Intermediate',
                        topSkills: (m is Map)
                            ? ((m['skills'] as List?)
                                      ?.map((s) => s.toString())
                                      .toList() ??
                                  [])
                            : [],
                        email:
                            '${mName.toLowerCase().replaceAll(' ', '.')}@student.edu',
                      );
                }).toList();

                _teams.add(
                  TeamOverviewItem(
                    id: 'team-${tm['name'] ?? act.id}',
                    name: tm['name']?.toString() ?? 'Formed Team',
                    course: act.className,
                    activityName: act.title,
                    status: '${teamMembers.length}/${act.groupCapacity}',
                    maxMembers: act.groupCapacity,
                    members: teamMembers,
                  ),
                );
              }
            }
          }
        }

        // Compute unassigned students dynamically
        final assignedNames = _teams
            .expand((t) => t.members.map((m) => m.name.toLowerCase()))
            .toSet();
        _unassignedStudents = _allStudents
            .where((s) => !assignedNames.contains(s.name.toLowerCase()))
            .map(
              (s) => UnassignedStudent(
                id: s.id,
                name: s.name,
                studentId: s.studentId,
                block: s.block,
                preferredRole: s.primaryRole ?? 'Collaborator',
                skillLevel: s.skillLevel ?? 'Intermediate',
                skills: s.topSkills,
                recommendedGroups: _teams
                    .where((t) => t.members.length < t.maxMembers)
                    .take(2)
                    .map(
                      (t) => RecommendedGroupMatch(
                        teamId: t.id,
                        teamName: t.name,
                        matchPercentage: 88,
                        reason: 'Open slot available in ${t.name}',
                      ),
                    )
                    .toList(),
              ),
            )
            .toList();
      });
    } catch (_) {
      // Graceful fallback for offline mode
    }
  }

  // --- Assign Unassigned Student Action ---
  void _assignStudentToGroup(UnassignedStudent student, String teamId) {
    final teamIndex = _teams.indexWhere((t) => t.id == teamId);
    if (teamIndex == -1) return;

    final targetTeam = _teams[teamIndex];

    setState(() {
      // Add student to team
      final newMember = StudentRosterItem(
        id: student.id,
        name: student.name,
        studentId: student.studentId,
        block: student.block,
        status: ProfileCompletionStatus.complete,
        primaryRole: student.preferredRole,
        skillLevel: student.skillLevel,
        topSkills: student.skills,
        email: '${student.name.toLowerCase().replaceAll(' ', '.')}@student.edu',
      );

      final updatedMembers = List<StudentRosterItem>.from(targetTeam.members)
        ..add(newMember);

      _teams[teamIndex] = TeamOverviewItem(
        id: targetTeam.id,
        name: targetTeam.name,
        course: targetTeam.course,
        activityName: targetTeam.activityName,
        status: updatedMembers.length >= targetTeam.maxMembers
            ? 'Full (${targetTeam.maxMembers}/${targetTeam.maxMembers})'
            : 'Formed (${updatedMembers.length}/${targetTeam.maxMembers})',
        maxMembers: targetTeam.maxMembers,
        members: updatedMembers,
      );

      // Remove from unassigned
      _unassignedStudents.removeWhere((s) => s.id == student.id);
    });

    AppNotification.showSuccess(
      context,
      'Successfully assigned ${student.name} to ${targetTeam.name}!',
    );
  }

  void _showStudentProfileDialog(StudentRosterItem s) {
    StudentProfileDialog.show(context, rosterItem: s);
  }



  Widget _buildStatusBadge(ProfileCompletionStatus status) {
    switch (status) {
      case ProfileCompletionStatus.complete:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'COMPLETE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF047857),
            ),
          ),
        );
      case ProfileCompletionStatus.incomplete:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'INCOMPLETE (DRAFT)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD97706),
            ),
          ),
        );
      case ProfileCompletionStatus.uninitialized:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'UNINITIALIZED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final completeCount = _allStudents
        .where((s) => s.status == ProfileCompletionStatus.complete)
        .length;
    final incompleteCount = _allStudents
        .where((s) => s.status == ProfileCompletionStatus.incomplete)
        .length;
    final uninitCount = _allStudents
        .where((s) => s.status == ProfileCompletionStatus.uninitialized)
        .length;

    // Filtered students
    final filteredStudents = _allStudents.where((s) {
      if (_selectedCompletionFilter == 'complete' &&
          s.status != ProfileCompletionStatus.complete) {
        return false;
      }
      if (_selectedCompletionFilter == 'incomplete' &&
          s.status != ProfileCompletionStatus.incomplete) {
        return false;
      }
      if (_selectedCompletionFilter == 'uninitialized' &&
          s.status != ProfileCompletionStatus.uninitialized) {
        return false;
      }

      final query = _studentSearchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchesName = s.name.toLowerCase().contains(query);
        final matchesId = s.studentId.toLowerCase().contains(query);
        final matchesBlock = s.block.toLowerCase().contains(query);
        return matchesName || matchesId || matchesBlock;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Unified Professor Sidebar
          const ProfessorSidebar(
            currentDestination: ProfessorNavDestination.dashboard,
          ),

          // Main Dashboard Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Action Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [PortalTopActions()],
                      ),
                      const SizedBox(height: 12),

                      // Header Section
                      _buildWelcomeHeader(),
                      const SizedBox(height: 20),

                      // Profile Completion Status Cards
                      _buildCompletionStatusMetrics(
                        completeCount,
                        incompleteCount,
                        uninitCount,
                      ),
                      const SizedBox(height: 24),

                      // Manage Unassigned Students Past Deadline Section
                      if (_unassignedStudents.isNotEmpty) ...[
                        _buildManageUnassignedSection(),
                        const SizedBox(height: 28),
                      ],

                      // Teams, Squad Members & Profiles Section
                      KeyedSubtree(
                        key: _teamsSectionKey,
                        child: _buildTeamsRosterSection(),
                      ),
                      const SizedBox(height: 28),

                      // Student Profile Completion Roster Table
                      _buildStudentRosterSection(filteredStudents),
                      const SizedBox(height: 28),

                      // Custom Requested Skills Approval Queue
                      KeyedSubtree(
                        key: _skillsSectionKey,
                        child: _buildCustomSkillsApprovalSection(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Welcome Header Card
  Widget _buildWelcomeHeader() {
    final profName = (AuthService.currentUser?.name.isNotEmpty == true)
        ? AuthService.currentUser!.name
        : 'Prof. Aivhan';
    final profInitial = profName.isNotEmpty ? profName[0].toUpperCase() : 'P';
    final department =
        (AuthService.currentUser?.departmentOrSection?.isNotEmpty == true)
        ? AuthService.currentUser!.departmentOrSection!
        : 'College of Information and Computing Sciences';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          final avatarAndInfo = Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF1E40AF),
                child: Text(
                  profInitial,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Welcome, $profName!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Faculty Administrator',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$department • Academic Year 2026-2027',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final reviewButton = ElevatedButton.icon(
            key: const Key('review_evaluations_button'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfessorEvaluationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.rate_review_outlined, size: 16),
            label: const Text('Manage Student Records'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatarAndInfo,
                const SizedBox(height: 16),
                reviewButton,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: avatarAndInfo),
              const SizedBox(width: 16),
              reviewButton,
            ],
          );
        },
      ),
    );
  }

  // Student Profile Completion Status Metrics
  Widget _buildCompletionStatusMetrics(
    int complete,
    int incomplete,
    int uninit,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _buildMetricCard(
            title: 'Total Students',
            count: '${_allStudents.length}',
            subtitle: '$complete complete • $incomplete in progress',
            icon: Icons.people_alt_outlined,
            color: const Color(0xFF047857),
            bg: const Color(0xFFECFDF5),
          ),
          _buildMetricCard(
            title: 'Total Classes',
            count: '${_classes.length}',
            subtitle: 'Course sections & class codes',
            icon: Icons.school_outlined,
            color: const Color(0xFF1E40AF),
            bg: const Color(0xFFEFF6FF),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfessorClassesScreen(),
                ),
              );
            },
          ),
          _buildMetricCard(
            title: 'Active Projects & Teams',
            count: '${_activities.length} Projects',
            subtitle: '${_teams.length} teams formed',
            icon: Icons.groups_outlined,
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFFFBEB),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfessorActivitiesScreen(),
                ),
              );
            },
          ),
          _buildMetricCard(
            title: 'Student Records',
            count: 'Manage Records',
            subtitle: 'Edit students in your classes',
            icon: Icons.fact_check_outlined,
            color: const Color(0xFF7C3AED),
            bg: const Color(0xFFF3E8FF),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfessorEvaluationScreen(),
                ),
              );
            },
          ),
        ];

        if (constraints.maxWidth < 950) {
          return Column(
            children: cards
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: c,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: cards
              .map(
                (c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: c,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }
    return content;
  }

  // Manage Unassigned Students Past Deadline Section
  Widget _buildManageUnassignedSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.person_add_alt_1,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Manage Unassigned Students (Past Deadline)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_unassignedStudents.length} Action Needed',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Assign students who have not formed or joined a group past the deadline to recommended groups based on missing roles and skills balance.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Unassigned Students List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _unassignedStudents.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final student = _unassignedStudents[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF1E40AF),
                              child: Text(
                                student.name[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  '${student.studentId} • ${student.block} • ${student.preferredRole} (${student.skillLevel})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Quick dropdown to assign to ANY team
                        PopupMenuButton<String>(
                          onSelected: (teamId) =>
                              _assignStudentToGroup(student, teamId),
                          itemBuilder: (context) => _teams
                              .map(
                                (t) => PopupMenuItem(
                                  value: t.id,
                                  child: Text(
                                    'Assign to: ${t.name} (${t.status})',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Other Teams',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 16,
                                  color: Color(0xFF475569),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Top Recommended Groups:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Recommended groups cards
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: student.recommendedGroups.map((rec) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${rec.matchPercentage}% MATCH',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                rec.teamName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () =>
                                    _assignStudentToGroup(student, rec.teamId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E40AF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Assign to Group',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Teams Roster Section
  Widget _buildTeamsRosterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: const [
            Text(
              'Formed Teams & Squad Member Profiles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Click any student avatar to view full profile details and skill stack',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_teams.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 40,
                  color: Colors.blueGrey.shade300,
                ),
                const SizedBox(height: 10),
                const Text(
                  'No Teams Formed Yet',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Formed student squads and their skill levels will be listed here automatically as teams form in activities.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 900
                  ? 3
                  : (constraints.maxWidth >= 600 ? 2 : 1);
              final cardWidth =
                  (constraints.maxWidth - (crossAxisCount - 1) * 16) /
                      crossAxisCount;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _teams.map((team) {
                  return SizedBox(
                    width: cardWidth,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  team.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: team.members.length >= team.maxMembers
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  team.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: team.members.length >= team.maxMembers
                                        ? const Color(0xFF047857)
                                        : const Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            team.course,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            team.activityName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFFF1F5F9), height: 1),
                          const SizedBox(height: 8),

                          const Text(
                            'Team Members:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...team.members.map((m) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: InkWell(
                                onTap: () => _showStudentProfileDialog(m),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundColor: const Color(
                                          0xFF1E40AF,
                                        ),
                                        child: Text(
                                          m.name.isNotEmpty ? m.name[0] : 'S',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          m.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0F172A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        m.primaryRole ?? 'Member',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          // Scarcity Report Warning Banner
                          if (team.scarcityReport != null && team.scarcityReport!['is_scarce'] == true) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFD97706)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Missing: ${((team.scarcityReport!['scarce_skills'] as List?) ?? []).join(', ')}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Professor Notes display if exists
                          if (team.professorNotes != null && team.professorNotes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Notes: ${team.professorNotes}',
                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          // Proposal Evaluation Actions (Approve / Decline)
                          if (team.proposalStatus == 'Submitted for Evaluation' ||
                              team.proposalStatus == 'under_review' ||
                              team.proposalStatus == 'pending') ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _reviewTeamProposal(team, 'approved'),
                                    icon: const Icon(Icons.check, size: 14),
                                    label: const Text('Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _reviewTeamProposal(team, 'declined'),
                                    icon: const Icon(Icons.close, size: 14),
                                    label: const Text('Decline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFDC2626),
                                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      minimumSize: Size.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (team.proposalStatus == 'Approved') ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 12, color: Color(0xFF059669)),
                                  SizedBox(width: 4),
                                  Text('Approved by Professor', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                ],
                              ),
                            ),
                          ] else if (team.proposalStatus == 'Declined') ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.cancel, size: 12, color: Color(0xFFDC2626)),
                                      SizedBox(width: 4),
                                      Text('Declined', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _reviewTeamProposal(team, 'approved'),
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                                  child: const Text('Approve anyway', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  Future<void> _reviewTeamProposal(TeamOverviewItem team, String decision) async {
    if (team.activityId == null) return;

    if (decision == 'approved') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Approve Squad Proposal: ${team.name}?'),
          content: Text(
            'This will approve the squad for "${team.activityName}" and notify all team members.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve Squad'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;

      try {
        await _activityService.reviewTeamProposal(
          team.activityId!,
          teamName: team.name,
          decision: 'approved',
        );
        if (mounted) {
          AppNotification.showSuccess(context, 'Squad proposal for "${team.name}" approved!');
          _initData();
        }
      } catch (e) {
        if (mounted) AppNotification.showError(context, e.toString());
      }
    } else {
      final notesController = TextEditingController();
      final scarceSkills = (team.scarcityReport?['scarce_skills'] as List?)?.map((s) => s.toString()).toList() ?? [];

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Decline Squad Proposal: ${team.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (scarceSkills.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Identified Skill Scarcity:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF991B1B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                scarceSkills.join(', '),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                const Text(
                  'Professor Notes / Recommendations:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter notes explaining skill scarcity or changes required before resubmission...',
                    hintStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Decline & Send Notes'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;

      try {
        await _activityService.reviewTeamProposal(
          team.activityId!,
          teamName: team.name,
          decision: 'declined',
          notes: notesController.text.trim(),
        );
        if (mounted) {
          AppNotification.showSuccess(context, 'Squad proposal declined. Notes sent to students.');
          _initData();
        }
      } catch (e) {
        if (mounted) AppNotification.showError(context, e.toString());
      }
    }
  }

  // Student Profile Completion Roster Section
  Widget _buildStudentRosterSection(List<StudentRosterItem> students) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Text(
                'Student Profile Completion Statuses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),

              // Filter Tabs (All, Complete, Incomplete, Uninitialized)
              Wrap(
                spacing: 6,
                children: [
                  _buildCompletionFilterChip('All', 'all'),
                  _buildCompletionFilterChip('Complete', 'complete'),
                  _buildCompletionFilterChip('Incomplete', 'incomplete'),
                  _buildCompletionFilterChip('Uninitialized', 'uninitialized'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Field
          TextField(
            controller: _studentSearchController,
            decoration: InputDecoration(
              hintText:
                  'Search by student name, ID number, or section block...',
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: Color(0xFF64748B),
              ),
              suffixIcon: _studentSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () =>
                          setState(() => _studentSearchController.clear()),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.person_search_outlined,
                      size: 36,
                      color: Colors.blueGrey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _allStudents.isEmpty
                          ? 'No Students Registered Yet'
                          : 'No Students Matching Filter',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _allStudents.isEmpty
                          ? 'Student completion statuses and rosters will populate automatically as students register.'
                          : 'Try clearing your search query or selecting "All".',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            // Students Table
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: students.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
              itemBuilder: (context, index) {
                final s = students[index];
                return InkWell(
                  onTap: () => _showStudentProfileDialog(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF1E40AF),
                          child: Text(
                            s.name[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '${s.studentId} • ${s.block} • ${s.email}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(s.status),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCompletionFilterChip(String label, String value) {
    final isSelected = _selectedCompletionFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCompletionFilter = value),
      selectedColor: const Color(0xFF1E40AF),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF334155),
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
    );
  }

  // Custom Requested Skills Approval Queue Section
  Widget _buildCustomSkillsApprovalSection() {
    final requests = _skillService.getRequestsByStatus(
      _selectedSkillStatusFilter,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Custom Requested Skills Approval Queue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Review custom skills requested by students. Approved skills automatically become official and update student profiles.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),

              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Filter Tabs (All, Pending, Under Review, Approved, Rejected)
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildSkillStatusFilterChip('All', null),
                      _buildSkillStatusFilterChip(
                        'Pending',
                        SkillApprovalStatus.pending,
                      ),
                      _buildSkillStatusFilterChip(
                        'Approved',
                        SkillApprovalStatus.approved,
                      ),
                      _buildSkillStatusFilterChip(
                        'Rejected',
                        SkillApprovalStatus.rejected,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (requests.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              child: const Text(
                'No custom skill requests found in this category.',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
              itemBuilder: (context, index) {
                final req = requests[index];
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 650;
                    final skillInfo = Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.code,
                            size: 20,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    req.skillName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      req.domain,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Requested by ${req.studentName} (${req.studentId} • ${req.block})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              if (req.remarks != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Remarks: ${req.remarks}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );

                    final actions = Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildSkillStatusBadge(req.status),
                        if (req.status == SkillApprovalStatus.pending ||
                            req.status == SkillApprovalStatus.underReview) ...[
                          OutlinedButton(
                            onPressed: () => _confirmSkillDecision(
                              req,
                              SkillApprovalStatus.approved,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF16A34A),
                              side: const BorderSide(color: Color(0xFF86EFAC)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const Text(
                              'Approve',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => _confirmSkillDecision(
                              req,
                              SkillApprovalStatus.rejected,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFECACA)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const Text(
                              'Reject',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    );

                    if (isNarrow) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            skillInfo,
                            const SizedBox(height: 8),
                            actions,
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: skillInfo),
                          const SizedBox(width: 12),
                          actions,
                        ],
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSkillStatusFilterChip(
    String label,
    SkillApprovalStatus? status,
  ) {
    final isSelected = _selectedSkillStatusFilter == status;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedSkillStatusFilter = status),
      selectedColor: const Color(0xFF1E40AF),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF334155),
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
    );
  }

  Widget _buildSkillStatusBadge(SkillApprovalStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case SkillApprovalStatus.pending:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        break;
      case SkillApprovalStatus.underReview:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        break;
      case SkillApprovalStatus.approved:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF047857);
        break;
      case SkillApprovalStatus.rejected:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
