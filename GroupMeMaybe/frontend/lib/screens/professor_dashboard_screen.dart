import 'package:flutter/material.dart';

import '../models/custom_skill_request.dart';
import '../services/skill_approval_service.dart';
import 'widgets/professor_sidebar.dart';

// Helper model for student completion statuses
enum ProfileCompletionStatus {
  complete,
  incomplete,
  uninitialized,
}

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

  TeamOverviewItem({
    required this.id,
    required this.name,
    required this.course,
    required this.activityName,
    required this.status,
    required this.maxMembers,
    required this.members,
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
  const ProfessorDashboardScreen({super.key});

  @override
  State<ProfessorDashboardScreen> createState() => _ProfessorDashboardScreenState();
}

class _ProfessorDashboardScreenState extends State<ProfessorDashboardScreen> {
  final SkillApprovalService _skillService = SkillApprovalService();
  final TextEditingController _studentSearchController = TextEditingController();

  // Completion filter: 'all', 'complete', 'incomplete', 'uninitialized'
  String _selectedCompletionFilter = 'all';

  // Skill approval filter: null for all, or SkillApprovalStatus
  SkillApprovalStatus? _selectedSkillStatusFilter;

  // Mock Students Roster
  late List<StudentRosterItem> _allStudents;

  // Mock Teams
  late List<TeamOverviewItem> _teams;

  // Unassigned Students past deadline
  late List<UnassignedStudent> _unassignedStudents;

  @override
  void initState() {
    super.initState();
    _skillService.addListener(_onSkillServiceUpdated);
    _initData();
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

  void _initData() {
    _allStudents = [
      StudentRosterItem(
        id: 's-01',
        name: 'Carlos Mendoza',
        studentId: '2023-10492',
        block: 'BSIT-3A',
        status: ProfileCompletionStatus.complete,
        primaryRole: 'Frontend Developer',
        skillLevel: 'Advanced',
        topSkills: ['Flutter', 'React', 'TypeScript', 'Node.js'],
        email: 'carlos.mendoza@student.edu',
      ),
      StudentRosterItem(
        id: 's-02',
        name: 'Bianca Cruz',
        studentId: '2023-10114',
        block: 'BSIT-3A',
        status: ProfileCompletionStatus.complete,
        primaryRole: 'UI/UX Designer',
        skillLevel: 'Intermediate',
        topSkills: ['Figma', 'UI/UX Design', 'Canva', 'HTML/CSS'],
        email: 'bianca.cruz@student.edu',
      ),
      StudentRosterItem(
        id: 's-03',
        name: 'Dani Garcia',
        studentId: '2023-10229',
        block: 'BSIT-3B',
        status: ProfileCompletionStatus.complete,
        primaryRole: 'QA / Software Tester',
        skillLevel: 'Intermediate',
        topSkills: ['Software Testing', 'Postman', 'Python', 'Git'],
        email: 'dani.garcia@student.edu',
      ),
      StudentRosterItem(
        id: 's-04',
        name: 'Alex Santos',
        studentId: '2023-10555',
        block: 'BSIT-3A',
        status: ProfileCompletionStatus.complete,
        primaryRole: 'Backend Developer',
        skillLevel: 'Advanced',
        topSkills: ['Laravel', 'PostgreSQL', 'Docker', 'REST API'],
        email: 'alex.santos@student.edu',
      ),
      StudentRosterItem(
        id: 's-05',
        name: 'Marcus Vance',
        studentId: '2023-10671',
        block: 'BSIT-3A',
        status: ProfileCompletionStatus.incomplete,
        primaryRole: 'Mobile App Developer',
        skillLevel: 'Beginner',
        topSkills: ['Kotlin', 'Android Studio'],
        email: 'marcus.vance@student.edu',
      ),
      StudentRosterItem(
        id: 's-06',
        name: 'Leo Reyes',
        studentId: '2023-10782',
        block: 'BSIT-3B',
        status: ProfileCompletionStatus.incomplete,
        primaryRole: 'Database Administrator',
        skillLevel: 'Intermediate',
        topSkills: ['MySQL', 'Database Management'],
        email: 'leo.reyes@student.edu',
      ),
      StudentRosterItem(
        id: 's-07',
        name: 'Ryan Tan',
        studentId: '2023-10901',
        block: 'BSIT-3A',
        status: ProfileCompletionStatus.uninitialized,
        email: 'ryan.tan@student.edu',
      ),
      StudentRosterItem(
        id: 's-08',
        name: 'Chloe Diaz',
        studentId: '2023-10992',
        block: 'BSIT-3B',
        status: ProfileCompletionStatus.uninitialized,
        email: 'chloe.diaz@student.edu',
      ),
    ];

    _teams = [
      TeamOverviewItem(
        id: 'team-alpha',
        name: 'Alpha Squad',
        course: 'ITE 03 - Object Oriented Programming',
        activityName: 'Final Capstone Project',
        status: 'Needs 1 Member (3/4)',
        maxMembers: 4,
        members: [
          _allStudents[0], // Carlos
          _allStudents[1], // Bianca
          _allStudents[2], // Dani
        ],
      ),
      TeamOverviewItem(
        id: 'team-devninjas',
        name: 'DevNinjas',
        course: 'ITE 03 - Object Oriented Programming',
        activityName: 'Final Capstone Project',
        status: 'Needs Backend (2/4)',
        maxMembers: 4,
        members: [
          _allStudents[3], // Alex
          _allStudents[4], // Marcus
        ],
      ),
      TeamOverviewItem(
        id: 'team-bytecraft',
        name: 'ByteCraft',
        course: 'IT 211 - Data Structures & Algorithms',
        activityName: 'Midterm Algorithm Lab',
        status: 'Full (4/4)',
        maxMembers: 4,
        members: [
          _allStudents[0],
          _allStudents[1],
          _allStudents[2],
          _allStudents[3],
        ],
      ),
    ];

    _unassignedStudents = [
      UnassignedStudent(
        id: 'unassign-01',
        name: 'Leo Reyes',
        studentId: '2023-10782',
        block: 'BSIT-3B',
        preferredRole: 'Database Administrator',
        skillLevel: 'Intermediate',
        skills: ['MySQL', 'PostgreSQL', 'Database Management'],
        recommendedGroups: [
          RecommendedGroupMatch(
            teamId: 'team-alpha',
            teamName: 'Alpha Squad',
            matchPercentage: 96,
            reason: 'Alpha Squad specifically lacks a dedicated Database Administrator role.',
          ),
          RecommendedGroupMatch(
            teamId: 'team-devninjas',
            teamName: 'DevNinjas',
            matchPercentage: 84,
            reason: 'DevNinjas requires persistence layer support.',
          ),
        ],
      ),
      UnassignedStudent(
        id: 'unassign-02',
        name: 'Ryan Tan',
        studentId: '2023-10901',
        block: 'BSIT-3A',
        preferredRole: 'Backend Developer',
        skillLevel: 'Beginner',
        skills: ['Node.js', 'Express.js', 'Git'],
        recommendedGroups: [
          RecommendedGroupMatch(
            teamId: 'team-devninjas',
            teamName: 'DevNinjas',
            matchPercentage: 91,
            reason: 'DevNinjas has open backend slot and complementary mentorship from Alex Santos.',
          ),
        ],
      ),
    ];
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

      final updatedMembers = List<StudentRosterItem>.from(targetTeam.members)..add(newMember);

      _teams[teamIndex] = TeamOverviewItem(
        id: targetTeam.id,
        name: targetTeam.name,
        course: targetTeam.course,
        activityName: targetTeam.activityName,
        status: updatedMembers.length >= targetTeam.maxMembers ? 'Full (${targetTeam.maxMembers}/${targetTeam.maxMembers})' : 'Formed (${updatedMembers.length}/${targetTeam.maxMembers})',
        maxMembers: targetTeam.maxMembers,
        members: updatedMembers,
      );

      // Remove from unassigned
      _unassignedStudents.removeWhere((s) => s.id == student.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully assigned ${student.name} to ${targetTeam.name}!'),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showStudentProfileDialog(StudentRosterItem s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF1E40AF),
              child: Text(s.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${s.studentId} • ${s.block}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileRow('Profile Status', _buildStatusBadge(s.status)),
              const Divider(height: 18),
              _buildProfileRow('Primary Role', Text(s.primaryRole ?? 'Not specified', style: const TextStyle(fontWeight: FontWeight.bold))),
              const Divider(height: 18),
              _buildProfileRow('Proficiency Rating', Text(s.skillLevel ?? 'Unrated', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF7E22CE)))),
              const Divider(height: 18),
              _buildProfileRow('Institutional Email', Text(s.email, style: const TextStyle(fontSize: 13, color: Color(0xFF2563EB)))),
              const SizedBox(height: 12),
              const Text('Skills & Technologies:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: s.topSkills.isEmpty
                    ? [const Text('No skills provided yet.', style: TextStyle(fontSize: 12, color: Colors.grey))]
                    : s.topSkills.map((sk) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                          child: Text(sk, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                        );
                      }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E40AF), foregroundColor: Colors.white),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, Widget value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        value,
      ],
    );
  }

  Widget _buildStatusBadge(ProfileCompletionStatus status) {
    switch (status) {
      case ProfileCompletionStatus.complete:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
          child: const Text('COMPLETE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
        );
      case ProfileCompletionStatus.incomplete:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(6)),
          child: const Text('INCOMPLETE (DRAFT)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
        );
      case ProfileCompletionStatus.uninitialized:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
          child: const Text('UNINITIALIZED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final completeCount = _allStudents.where((s) => s.status == ProfileCompletionStatus.complete).length;
    final incompleteCount = _allStudents.where((s) => s.status == ProfileCompletionStatus.incomplete).length;
    final uninitCount = _allStudents.where((s) => s.status == ProfileCompletionStatus.uninitialized).length;

    // Filtered students
    final filteredStudents = _allStudents.where((s) {
      if (_selectedCompletionFilter == 'complete' && s.status != ProfileCompletionStatus.complete) return false;
      if (_selectedCompletionFilter == 'incomplete' && s.status != ProfileCompletionStatus.incomplete) return false;
      if (_selectedCompletionFilter == 'uninitialized' && s.status != ProfileCompletionStatus.uninitialized) return false;

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
          const ProfessorSidebar(currentDestination: ProfessorNavDestination.dashboard),

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
                      // Header Section
                      _buildWelcomeHeader(),
                      const SizedBox(height: 20),

                      // Urgent Unassigned Past-Deadline Alert Banner
                      if (_unassignedStudents.isNotEmpty) ...[
                        _buildUnassignedDeadlineBanner(),
                        const SizedBox(height: 24),
                      ],

                      // Profile Completion Status Cards
                      _buildCompletionStatusMetrics(completeCount, incompleteCount, uninitCount),
                      const SizedBox(height: 24),

                      // Manage Unassigned Students Past Deadline Section
                      if (_unassignedStudents.isNotEmpty) ...[
                        _buildManageUnassignedSection(),
                        const SizedBox(height: 28),
                      ],

                      // Teams, Squad Members & Profiles Section
                      _buildTeamsRosterSection(),
                      const SizedBox(height: 28),

                      // Student Profile Completion Roster Table
                      _buildStudentRosterSection(filteredStudents),
                      const SizedBox(height: 28),

                      // Custom Requested Skills Approval Queue
                      _buildCustomSkillsApprovalSection(),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          final avatarAndInfo = Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFF1E40AF),
                child: Text('A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
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
                        const Text(
                          'Welcome, Prof. Aivhan!',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                          child: const Text('Faculty Administrator', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'College of Information and Computing Sciences • Academic Year 2026-2027',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatarAndInfo,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: avatarAndInfo),
            ],
          );
        },
      ),
    );
  }

  // 24-Hour Past Deadline Alert Banner
  Widget _buildUnassignedDeadlineBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_unassignedStudents.length} Students Unassigned Past Group Formation Deadline',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'The capstone grouping cutoff has passed. As professor, you can review system-recommended groups below and assign these students to ensure balanced team sizes and skill distribution.',
                  style: TextStyle(fontSize: 13, color: Color(0xFFB45309), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Student Profile Completion Status Metrics
  Widget _buildCompletionStatusMetrics(int complete, int incomplete, int uninit) {
    final total = complete + incomplete + uninit;
    final completePct = total > 0 ? (complete / total * 100).toInt() : 0;
    final incompletePct = total > 0 ? (incomplete / total * 100).toInt() : 0;
    final uninitPct = total > 0 ? (uninit / total * 100).toInt() : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _buildMetricCard(
            title: 'Complete Profiles',
            count: '$complete ($completePct%)',
            subtitle: 'Ready & active in matching algorithms',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF047857),
            bg: const Color(0xFFECFDF5),
          ),
          _buildMetricCard(
            title: 'Incomplete Profiles',
            count: '$incomplete ($incompletePct%)',
            subtitle: 'Draft saved or missing priority roles',
            icon: Icons.edit_note,
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFFFBEB),
          ),
          _buildMetricCard(
            title: 'Uninitialized',
            count: '$uninit ($uninitPct%)',
            subtitle: 'Has not yet opened profile setup',
            icon: Icons.person_off_outlined,
            color: const Color(0xFF64748B),
            bg: const Color(0xFFF1F5F9),
          ),
        ];

        if (constraints.maxWidth < 800) {
          return Column(
            children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
          );
        }

        return Row(
          children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
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
  }) {
    return Container(
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
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Manage Unassigned Students Past Deadline Section
  Widget _buildManageUnassignedSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
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
                  Icon(Icons.person_add_alt_1, color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Manage Unassigned Students (Past Deadline)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  '${_unassignedStudents.length} Action Needed',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
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
                              child: Text(student.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                Text('${student.studentId} • ${student.block} • ${student.preferredRole} (${student.skillLevel})',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ),
                          ],
                        ),
                        // Quick dropdown to assign to ANY team
                        PopupMenuButton<String>(
                          onSelected: (teamId) => _assignStudentToGroup(student, teamId),
                          itemBuilder: (context) => _teams
                              .map(
                                (t) => PopupMenuItem(
                                  value: t.id,
                                  child: Text('Assign to: ${t.name} (${t.status})', style: const TextStyle(fontSize: 13)),
                                ),
                              )
                              .toList(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('Other Teams', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF475569)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Top Recommended Groups:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    const SizedBox(height: 6),

                    // Recommended groups cards
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: student.recommendedGroups.map((rec) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                                child: Text('${rec.matchPercentage}% MATCH', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                              ),
                              const SizedBox(width: 8),
                              Text(rec.teamName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () => _assignStudentToGroup(student, rec.teamId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E40AF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Assign to Group', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            Text(
              'Click any student avatar to view full profile details and skill stack',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 600 ? 2 : 1);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 250,
              ),
              itemCount: _teams.length,
              itemBuilder: (context, index) {
                final team = _teams[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              team.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: team.members.length >= team.maxMembers ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              team.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: team.members.length >= team.maxMembers ? const Color(0xFF047857) : const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(team.course, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(team.activityName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      const SizedBox(height: 8),

                      const Text('Team Members:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: team.members.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, mi) {
                            final m = team.members[mi];
                            return InkWell(
                              onTap: () => _showStudentProfileDialog(m),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: const Color(0xFF1E40AF),
                                      child: Text(m.name[0], style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(m.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                                    ),
                                    Text(m.primaryRole ?? 'Member', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
              hintText: 'Search by student name, ID number, or section block...',
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
              suffixIcon: _studentSearchController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setState(() => _studentSearchController.clear()))
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Students Table
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: students.length,
            separatorBuilder: (_, _) => const Divider(color: Color(0xFFF1F5F9), height: 1),
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
                        child: Text(s.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Text('${s.studentId} • ${s.block} • ${s.email}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(s.status),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
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
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCompletionFilter = value),
      selectedColor: const Color(0xFF1E40AF),
      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155)),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
    );
  }

  // Custom Requested Skills Approval Queue Section
  Widget _buildCustomSkillsApprovalSection() {
    final requests = _skillService.getRequestsByStatus(_selectedSkillStatusFilter);

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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Review custom skills requested by students. Approved skills automatically become official and update student profiles.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),

              // Filter Tabs (All, Pending, Under Review, Approved, Rejected)
              Wrap(
                spacing: 6,
                children: [
                  _buildSkillStatusFilterChip('All', null),
                  _buildSkillStatusFilterChip('Pending', SkillApprovalStatus.pending),
                  _buildSkillStatusFilterChip('Under Review', SkillApprovalStatus.underReview),
                  _buildSkillStatusFilterChip('Approved', SkillApprovalStatus.approved),
                  _buildSkillStatusFilterChip('Rejected', SkillApprovalStatus.rejected),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (requests.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              child: const Text('No custom skill requests found in this category.', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const Divider(color: Color(0xFFF1F5F9), height: 1),
              itemBuilder: (context, index) {
                final req = requests[index];
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 650;
                    final skillInfo = Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.code, size: 20, color: Color(0xFF1E40AF)),
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
                                  Text(req.skillName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                    child: Text(req.domain, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('Requested by ${req.studentName} (${req.studentId} • ${req.block})', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              if (req.remarks != null) ...[
                                const SizedBox(height: 2),
                                Text('Remarks: ${req.remarks}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF475569))),
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
                        if (req.status == SkillApprovalStatus.pending || req.status == SkillApprovalStatus.underReview) ...[
                          OutlinedButton(
                            onPressed: () {
                              _skillService.updateStatus(req.id, SkillApprovalStatus.approved, remarks: 'Verified syllabus alignment.');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Approved "${req.skillName}". Added to official skill catalog!'),
                                  backgroundColor: const Color(0xFF16A34A),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF16A34A),
                              side: const BorderSide(color: Color(0xFF86EFAC)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          if (req.status != SkillApprovalStatus.underReview)
                            OutlinedButton(
                              onPressed: () {
                                _skillService.updateStatus(req.id, SkillApprovalStatus.underReview, remarks: 'Reviewing domain applicability.');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Review', style: TextStyle(fontSize: 11)),
                            ),
                          OutlinedButton(
                            onPressed: () {
                              _skillService.updateStatus(req.id, SkillApprovalStatus.rejected, remarks: 'Out of scope for current curriculum.');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFFECACA)),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Reject', style: TextStyle(fontSize: 11)),
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

  Widget _buildSkillStatusFilterChip(String label, SkillApprovalStatus? status) {
    final isSelected = _selectedSkillStatusFilter == status;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedSkillStatusFilter = status),
      selectedColor: const Color(0xFF1E40AF),
      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155)),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
