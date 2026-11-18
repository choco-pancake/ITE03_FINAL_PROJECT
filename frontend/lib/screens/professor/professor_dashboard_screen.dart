import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/team_model.dart';
import '../../models/request_model.dart';
import '../../state/app_state.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/compatibility_ring.dart';
import '../../widgets/unassigned_students_sheet.dart';
import '../../widgets/simple_activity_card.dart';

class ProfessorDashboardScreen extends StatefulWidget {
  final AppState appState;
  final Function(int) onNavigate;

  const ProfessorDashboardScreen({super.key, required this.appState, required this.onNavigate});

  @override
  State<ProfessorDashboardScreen> createState() => _ProfessorDashboardScreenState();
}

class _ProfessorDashboardScreenState extends State<ProfessorDashboardScreen> {
  // Added import for ActivityCard widget

  // Theme Color (Vibrant Royal Blue)
  static const Color activeBlue = Color(0xFF2563EB);
  static const Color lightBlueBg = Color(0xFFEFF6FF);

  // Profile Filter & Search
  ProfileCompletionStatus? _profileStatusFilter;
  final _studentSearchController = TextEditingController();

  // Custom Skill Filter
  RequestStatus? _skillFilter;
  final _skillSearchController = TextEditingController();

  // Team Filter
  String _teamFilter = 'all'; // 'all', 'open', 'confirmed'

  @override
  void dispose() {
    _studentSearchController.dispose();
    _skillSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.appState;
    final students = app.students;
    final teams = app.teams;
    final customSkills = app.customSkills;

    // Profile Completion Status metrics
    final completeCount = students.where((s) => s.profileStatus == ProfileCompletionStatus.complete).length;
    final incompleteCount = students.where((s) => s.profileStatus == ProfileCompletionStatus.incomplete).length;
    final uninitializedCount = students.where((s) => s.profileStatus == ProfileCompletionStatus.uninitialized).length;

    // Unassigned students past deadline
    final assignedUserIds = <String>{};
    for (var t in teams) {
      for (var m in t.members) {
        assignedUserIds.add(m.userId);
      }
    }
    final unassignedStudents = students.where((s) => !assignedUserIds.contains(s.id)).toList();

    // Filtered Student List
    final filteredStudents = students.where((s) {
      if (_profileStatusFilter != null && s.profileStatus != _profileStatusFilter) {
        return false;
      }
      final q = _studentSearchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final matchName = s.fullName.toLowerCase().contains(q) || s.displayName.toLowerCase().contains(q);
        final matchId = s.studentId.toLowerCase().contains(q);
        final matchBlock = s.block.toLowerCase().contains(q);
        final matchSkills = s.technicalSkills.any((skill) => skill.toLowerCase().contains(q));
        if (!matchName && !matchId && !matchBlock && !matchSkills) return false;
      }
      return true;
    }).toList();

    // Filtered Teams List
    final filteredTeams = teams.where((t) {
      if (_teamFilter == 'open') return !t.isFull;
      if (_teamFilter == 'confirmed') return t.isConfirmed;
      return true;
    }).toList();

    // Filtered Custom Skills
    final filteredSkills = customSkills.where((s) {
      if (_skillFilter != null && s.status != _skillFilter) return false;
      final q = _skillSearchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final matchSkill = s.skillName.toLowerCase().contains(q);
        final matchStudent = s.studentName.toLowerCase().contains(q);
        final matchCat = s.category.toLowerCase().contains(q);
        if (!matchSkill && !matchStudent && !matchCat) return false;
      }
      return true;
    }).toList();

    final pendingSkillsCount = customSkills.where((s) => s.status == RequestStatus.pending || s.status == RequestStatus.underReview).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Banner & Quick Actions
          _buildDashboardHeader(context, app, unassignedStudents.length, pendingSkillsCount),
          const SizedBox(height: 24),

          // 2. High-Level KPI Summary Metrics Bar
          _buildKpiMetricsBar(
            totalStudents: students.length,
            completeCount: completeCount,
            totalTeams: teams.length,
            unassignedCount: unassignedStudents.length,
            pendingSkills: pendingSkillsCount,
          ),
          const SizedBox(height: 28),

          // 3. Urgent Action Box: Unassigned Students Past Deadline (Page 1)
          if (unassignedStudents.isNotEmpty) ...[
            _buildUnassignedAlertCard(context, app, unassignedStudents),
            const SizedBox(height: 28),
          ],

          // 4. Section 1: Student Profile Completion Statuses (Page 1)
          _buildProfileStatusesSection(context, app, completeCount, incompleteCount, uninitializedCount, filteredStudents),
          const SizedBox(height: 32),

          // 5. Section 2: Active Teams, Members & Detailed Profiles (Page 1)
          _buildTeamsRosterSection(context, app, filteredTeams),
          const SizedBox(height: 32),

          // 6. Section 3: Custom Requested Skills Approval & Official Curriculum Sync (Page 1)
          _buildCustomSkillsApprovalSection(context, app, filteredSkills, customSkills),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Header Banner
  Widget _buildDashboardHeader(BuildContext context, AppState app, int unassignedCount, int pendingSkills) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: lightBlueBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: activeBlue.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.dashboard_rounded, color: activeBlue, size: 30),
              ),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Professor Dashboard',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('GHIAN MODULE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor student profile completion statuses, review active team rosters, assign unassigned students, and approve custom skills.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ManageUnassignedStudentsDialog(appState: app),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: unassignedCount > 0 ? const Color(0xFFD97706) : activeBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                ),
                icon: Badge(
                  isLabelVisible: unassignedCount > 0,
                  label: Text('$unassignedCount'),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.person_search_rounded, size: 18),
                ),
                label: const Text('Manage Unassigned Students', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // High-Level KPI Summary Metrics Bar
  Widget _buildKpiMetricsBar({
    required int totalStudents,
    required int completeCount,
    required int totalTeams,
    required int unassignedCount,
    required int pendingSkills,
  }) {
    final double completionRate = totalStudents == 0 ? 0 : (completeCount / totalStudents);

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Enrolled Students',
            value: '$totalStudents',
            subtitle: '${(completionRate * 100).toInt()}% completed profiles',
            icon: Icons.people_outline_rounded,
            color: activeBlue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricTile(
            title: 'Active Teams',
            value: '$totalTeams',
            subtitle: 'Balanced across skills',
            icon: Icons.groups_rounded,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricTile(
            title: 'Unassigned Past Deadline',
            value: '$unassignedCount',
            subtitle: unassignedCount > 0 ? 'Requires group assignment' : 'All students grouped',
            icon: Icons.person_off_outlined,
            color: unassignedCount > 0 ? const Color(0xFFD97706) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricTile(
            title: 'Pending Skill Requests',
            value: '$pendingSkills',
            subtitle: pendingSkills > 0 ? 'Awaiting official review' : 'All skills evaluated',
            icon: Icons.stars_rounded,
            color: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Urgent Alert Card: Unassigned Students Past Deadline (Page 1)
  Widget _buildUnassignedAlertCard(BuildContext context, AppState app, List<UserModel> unassigned) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alarm_on_rounded, color: Color(0xFFD97706), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Action Required: ${unassigned.length} Unassigned Student${unassigned.length == 1 ? "" : "s"} Past Grouping Deadline',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF92400E)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => ManageUnassignedStudentsDialog(appState: app),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                      label: const Text('Review Recommended Groups', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Per the GroupMeMaybe algorithm, students who remain unassigned once the deadline elapses are shown with their recommended groups ranked by compatibility score (40% skills, 30% interests, 30% availability). You can assign them directly with one click.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF78350F), height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: unassigned.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: const Color(0xFFD97706),
                            child: Text(s.fullName.isNotEmpty ? s.fullName[0] : 'S', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text(s.fullName.isNotEmpty ? s.fullName : s.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF78350F))),
                          const SizedBox(width: 6),
                          Text('(${s.block})', style: const TextStyle(fontSize: 11, color: Color(0xFF92400E))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section 1: Student Profile Completion Statuses (Page 1)
  Widget _buildProfileStatusesSection(
    BuildContext context,
    AppState app,
    int completeCount,
    int incompleteCount,
    int uninitializedCount,
    List<UserModel> filteredStudents,
  ) {
    final int total = app.students.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, color: activeBlue),
                  SizedBox(width: 10),
                  Text(
                    'Student Profile Completion Statuses',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Text(
                'Total Enrolled: $total Students',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Displays complete, incomplete, and uninitialized student profiles. Click any category card to filter the directory.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),

          // 3 Interactive Filter Cards (Complete, Incomplete, Uninitialized)
          Row(
            children: [
              Expanded(
                child: _buildInteractiveStatusCard(
                  title: 'Complete',
                  count: completeCount,
                  total: total,
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle_rounded,
                  description: 'Verified skills & availability ready for grouping',
                  status: ProfileCompletionStatus.complete,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildInteractiveStatusCard(
                  title: 'Incomplete',
                  count: incompleteCount,
                  total: total,
                  color: const Color(0xFFF59E0B),
                  icon: Icons.warning_amber_rounded,
                  description: 'Saved as draft or missing required skills/hours',
                  status: ProfileCompletionStatus.incomplete,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildInteractiveStatusCard(
                  title: 'Uninitialized',
                  count: uninitializedCount,
                  total: total,
                  color: const Color(0xFFEF4444),
                  icon: Icons.hourglass_empty_rounded,
                  description: 'Has not yet started initial profile configuration',
                  status: ProfileCompletionStatus.uninitialized,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Student Directory Header & Search Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _studentSearchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by student name, ID, block, or skill...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: activeBlue),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_profileStatusFilter != null || _studentSearchController.text.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _profileStatusFilter = null;
                      _studentSearchController.clear();
                    });
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Reset Filter'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Filtered Student List Cards
          filteredStudents.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  child: const Center(child: Text('No students match the selected completion status or search query.')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredStudents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final student = filteredStudents[idx];
                    final assignedTeam = app.teams.where((t) => t.members.any((m) => m.userId == student.id)).firstOrNull;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: activeBlue.withValues(alpha: 0.1),
                            child: Text(
                              student.fullName.isNotEmpty ? student.fullName[0] : 'S',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: activeBlue, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      student.fullName.isNotEmpty ? student.fullName : student.displayName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                                      child: Text(student.studentId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                                      child: Text(student.block, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  student.technicalSkills.isEmpty
                                      ? 'No technical skills provided'
                                      : 'Skills: ${student.technicalSkills.take(4).join(", ")}${student.technicalSkills.length > 4 ? " +${student.technicalSkills.length - 4} more" : ""}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Rating Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              student.proficiencyRating.name.toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: activeBlue),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Team status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: assignedTeam != null ? Colors.green.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              assignedTeam != null ? assignedTeam.name : 'Unassigned',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: assignedTeam != null ? Colors.green.shade800 : Colors.amber.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Status Badge
                          ProfileStatusBadge(status: student.profileStatus),
                          const SizedBox(width: 10),
                          // View Profile Action
                          IconButton(
                            icon: const Icon(Icons.info_outline_rounded, size: 20, color: activeBlue),
                            tooltip: 'View Student Profile Details',
                            onPressed: () => _showStudentDetailModal(context, student),
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

  Widget _buildInteractiveStatusCard({
    required String title,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
    required String description,
    required ProfileCompletionStatus status,
  }) {
    final bool isSelected = _profileStatusFilter == status;
    final double pct = total == 0 ? 0 : (count / total);

    return InkWell(
      onTap: () {
        setState(() {
          if (_profileStatusFilter == status) {
            _profileStatusFilter = null; // Toggle off
          } else {
            _profileStatusFilter = status;
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 8),
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                  ],
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                    child: const Text('FILTERED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
                const SizedBox(width: 6),
                Text('/ $total (${(pct * 100).toInt()}%)', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  // Section 2: Active Teams, Members & Detailed Profiles (Page 1)
  Widget _buildTeamsRosterSection(BuildContext context, AppState app, List<TeamModel> teams) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.groups_rounded, color: activeBlue),
                  const SizedBox(width: 10),
                  const Text('Active Teams, Members & Member Profiles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: lightBlueBg, borderRadius: BorderRadius.circular(10)),
                    child: Text('${teams.length} Teams', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: activeBlue)),
                  ),
                ],
              ),
              // Filter Choice Chips: All, Has Open Slots, Confirmed
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Teams'),
                    selected: _teamFilter == 'all',
                    selectedColor: activeBlue,
                    labelStyle: TextStyle(color: _teamFilter == 'all' ? Colors.white : Colors.black87, fontSize: 12),
                    onSelected: (val) {
                      if (val) setState(() => _teamFilter = 'all');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Open Slots Available'),
                    selected: _teamFilter == 'open',
                    selectedColor: activeBlue,
                    labelStyle: TextStyle(color: _teamFilter == 'open' ? Colors.white : Colors.black87, fontSize: 12),
                    onSelected: (val) {
                      if (val) setState(() => _teamFilter = 'open');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Confirmed'),
                    selected: _teamFilter == 'confirmed',
                    selectedColor: activeBlue,
                    labelStyle: TextStyle(color: _teamFilter == 'confirmed' ? Colors.white : Colors.black87, fontSize: 12),
                    onSelected: (val) {
                      if (val) setState(() => _teamFilter = 'confirmed');
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Live view of formed teams, assigned roles, compatibility percentage rings, and individual member profile details.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          teams.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(40),
                  child: const Center(child: Text('No teams match this filter.')),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 600,
                    mainAxisExtent: 280,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                  ),
                  itemCount: teams.length,
                  itemBuilder: (ctx, idx) {
                    final team = teams[idx];
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: team.isConfirmed ? Colors.green.shade50 : Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          team.isConfirmed ? 'Confirmed' : 'Draft Proposal',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: team.isConfirmed ? Colors.green.shade800 : Colors.amber.shade900),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${team.members.length}/${team.capacity} Members • ${team.openSlots > 0 ? "${team.openSlots} open slot(s)" : "Capacity full"}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              CompatibilityRing(
                                score: team.overallCompatibility,
                                size: 54,
                                strokeWidth: 5,
                                skillCoverage: team.skillCoverage,
                                interestMatch: team.interestMatch,
                                availabilityOverlap: team.availabilityOverlap,
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          const Text('TEAM MEMBERS & ASSIGNED ROLES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.separated(
                              itemCount: team.members.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 6),
                              itemBuilder: (c, mIdx) {
                                final member = team.members[mIdx];
                                final bool isLeader = member.userId == team.leaderId;
                                return InkWell(
                                  onTap: () {
                                    final found = app.students.where((s) => s.id == member.userId).firstOrNull;
                                    if (found != null) {
                                      _showStudentDetailModal(context, found);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: isLeader ? activeBlue : Colors.grey.shade300,
                                          child: Text(
                                            member.name.isNotEmpty ? member.name[0] : 'M',
                                            style: TextStyle(fontSize: 10, color: isLeader ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            member.name,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isLeader ? lightBlueBg : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isLeader ? 'Leader • ${member.assignedRole}' : member.assignedRole,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isLeader ? FontWeight.bold : FontWeight.w500,
                                              color: isLeader ? activeBlue : const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
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
                ),
        ],
      ),
    );
  }

  // Section 3: Custom Requested Skills Approval (Page 1)
  Widget _buildCustomSkillsApprovalSection(
    BuildContext context,
    AppState app,
    List<CustomSkillRequestModel> filteredSkills,
    List<CustomSkillRequestModel> allSkills,
  ) {
    final pendingCount = allSkills.where((s) => s.status == RequestStatus.pending).length;
    final reviewCount = allSkills.where((s) => s.status == RequestStatus.underReview).length;
    final approvedCount = allSkills.where((s) => s.status == RequestStatus.approved).length;
    final rejectedCount = allSkills.where((s) => s.status == RequestStatus.rejected).length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.stars_rounded, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 10),
                  Text(
                    'Custom Requested Skills for Approval',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              // Filters: pending, under review, approved or rejected (Page 1)
              Wrap(
                spacing: 8,
                children: [
                  _buildSkillFilterChip('All', null, allSkills.length),
                  _buildSkillFilterChip('Pending', RequestStatus.pending, pendingCount),
                  _buildSkillFilterChip('Under Review', RequestStatus.underReview, reviewCount),
                  _buildSkillFilterChip('Approved', RequestStatus.approved, approvedCount),
                  _buildSkillFilterChip('Rejected', RequestStatus.rejected, rejectedCount),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Students can request custom skills for their profile. When approved by the professor, the skill is automatically added to the official skill list and the student\'s verified profile is automatically updated.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 18),

          filteredSkills.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  child: const Center(child: Text('No custom skill requests found in this category.')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredSkills.length,
                  separatorBuilder: (_, __) => const Divider(height: 20),
                  itemBuilder: (ctx, idx) {
                    final skillReq = filteredSkills[idx];
                    final bool isPending = skillReq.status == RequestStatus.pending || skillReq.status == RequestStatus.underReview;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.code_rounded, color: Color(0xFF7C3AED), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(skillReq.skillName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                    child: Text(skillReq.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Requested: ${skillReq.dateRequested.month}/${skillReq.dateRequested.day}/${skillReq.dateRequested.year}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Requested by: ${skillReq.studentName} • "${skillReq.justification}"',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                              if (skillReq.reviewerRemarks != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Remarks: ${skillReq.reviewerRemarks}',
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        RequestStatusBadge(status: skillReq.status),
                        const SizedBox(width: 12),
                        if (isPending) ...[
                          ElevatedButton.icon(
                            onPressed: () {
                              app.approveCustomSkill(skillReq.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Approved "${skillReq.skillName}". Added to official skill list & synced to ${skillReq.studentName}\'s profile!'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('Approve & Sync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              app.rejectCustomSkill(skillReq.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Declined "${skillReq.skillName}".'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Decline', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ],
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildSkillFilterChip(String label, RequestStatus? status, int count) {
    final bool isSelected = _skillFilter == status;
    return ChoiceChip(
      label: Text('$label ($count)', style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: activeBlue,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      onSelected: (val) {
        setState(() => _skillFilter = status);
      },
    );
  }

  // Comprehensive Student Profile Modal Viewer
  void _showStudentDetailModal(BuildContext context, UserModel student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: activeBlue.withValues(alpha: 0.1),
              child: Text(student.fullName.isNotEmpty ? student.fullName[0] : 'S', style: const TextStyle(fontWeight: FontWeight.bold, color: activeBlue)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName.isNotEmpty ? student.fullName : student.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                Text('${student.studentId} • ${student.block} • ${student.email}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProfileStatusBadge(status: student.profileStatus),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: lightBlueBg, borderRadius: BorderRadius.circular(10)),
                      child: Text('Proficiency: ${student.proficiencyRating.name.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: activeBlue)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text('Preferred Project Roles (Prioritized):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(student.preferredRoles.isEmpty ? 'None specified' : student.preferredRoles.asMap().entries.map((e) => '#${e.key + 1} ${e.value}').join('  •  ')),
                const SizedBox(height: 14),
                const Text('Technical Skills:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: student.technicalSkills.map((s) => Chip(label: Text(s, style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact)).toList(),
                ),
                const SizedBox(height: 14),
                const Text('Tools & Technologies:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: student.toolsAndTechnologies.map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact)).toList(),
                ),
                const SizedBox(height: 14),
                const Text('Availability & Collaboration:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Days: ${student.availableDays.join(", ")} (${student.weeklyCommonHours} hrs/wk) • ${student.preferredMeetingTime} • ${student.collaborationMode}'),
                const SizedBox(height: 14),
                const Text('Previous Experience:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(student.previousExperience.isNotEmpty ? student.previousExperience : 'No written background recorded.', style: TextStyle(color: Colors.grey.shade800)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
