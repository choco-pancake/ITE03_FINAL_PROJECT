import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/activity_model.dart';
import '../../models/team_model.dart';
import '../../state/app_state.dart';
import '../../services/hybrid_matcher.dart';

class StudentTeamsScreen extends StatefulWidget {
  final AppState appState;

  const StudentTeamsScreen({super.key, required this.appState});

  @override
  State<StudentTeamsScreen> createState() => _StudentTeamsScreenState();
}

class _StudentTeamsScreenState extends State<StudentTeamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'All'; // 'All', 'Active', 'Completed'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.appState;
    final currentUser = app.currentUser;
    final allActivities = app.activities;

    // Filter activities by search and status
    final filteredActivities = allActivities.where((act) {
      if (_activeFilter == 'Active' && act.status == ActivityStatus.completed) {
        return false;
      }
      if (_activeFilter == 'Completed' && act.status != ActivityStatus.completed) {
        return false;
      }

      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchTitle = act.title.toLowerCase().contains(query);
        final matchClass = act.className.toLowerCase().contains(query);
        final matchSkills = act.requiredSkills.any((s) => s.toLowerCase().contains(query));
        if (!matchTitle && !matchClass && !matchSkills) return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Title, Subtitle & Refresh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Course Projects & Group Activities',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select an active project below to view requirements, manage your team, and find recommended teammates.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B), size: 24),
                tooltip: 'Refresh Activities',
                onPressed: () {
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Search & Segmented Filter Bar (Matching Photo)
          Row(
            children: [
              // Search Input
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search by project title or subject...',
                            hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Filter Segment Pills: [✓ All | Active | Completed]
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildFilterPill('All', label: 'All', showCheckWhenActive: true),
                    _buildFilterPill('Active', label: 'Active'),
                    _buildFilterPill('Completed', label: 'Completed'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 3. 2-Column Responsive Card Grid (Photo Match)
          LayoutBuilder(
            builder: (context, constraints) {
              final isTwoColumn = constraints.maxWidth >= 840;
              if (isTwoColumn) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 1
                    Expanded(
                      child: Column(
                        children: [
                          if (filteredActivities.isNotEmpty)
                            _buildProjectCard(filteredActivities[0], currentUser, app),
                          if (filteredActivities.length > 2)
                            _buildProjectCard(filteredActivities[2], currentUser, app),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Column 2
                    Expanded(
                      child: Column(
                        children: [
                          if (filteredActivities.length > 1)
                            _buildProjectCard(filteredActivities[1], currentUser, app),
                          if (filteredActivities.length > 3)
                            _buildProjectCard(filteredActivities[3], currentUser, app),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: filteredActivities
                      .map((act) => _buildProjectCard(act, currentUser, app))
                      .toList(),
                );
              }
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Filter Pill Widget
  Widget _buildFilterPill(String filterKey, {required String label, bool showCheckWhenActive = false}) {
    final bool isSelected = _activeFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDE9FE) : Colors.transparent, // Soft purple when selected
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (isSelected && showCheckWhenActive) ...[
              const Icon(Icons.check_rounded, size: 16, color: Color(0xFF6D28D9)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF6D28D9) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Project Activity Card (Matching Photo Specifications)
  Widget _buildProjectCard(ActivityModel activity, UserModel currentUser, AppState app) {
    // Check if current user is enrolled in a team for this activity
    final currentTeam = app.teams.where((t) => t.activityId == activity.id && t.members.any((m) => m.userId == currentUser.id)).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title & Method Badge (HYBRID, AUTO, MANUAL)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildMethodBadge(activity.groupingMethod),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Subject & Academic Block (e.g. Web Development - BSIT 2A)
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                activity.className,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3: Description Paragraph
          Text(
            activity.description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.45,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Row 4: Metadata Spec Pills (Capacity, Needed, Min hrs)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSpecPill(Icons.people_outline_rounded, 'Capacity: ${activity.groupCapacity} / team'),
              _buildSpecPill(Icons.grid_view_outlined, 'Needed: ${activity.neededGroups} groups'),
              _buildSpecPill(Icons.access_time_rounded, 'Min: ${activity.minCommonHours} hrs/wk'),
            ],
          ),
          const SizedBox(height: 14),

          // Row 5: Required Skills Chips (Blue rounded chips)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activity.requiredSkills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF), // Soft Blue
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D4ED8), // Royal Blue text
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Row 6: Card Footer / Status & Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Team Status Badge
              if (currentTeam != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7), // Light green
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Text(
                    'Your Team: ${currentTeam.name} (${currentTeam.members.length}/${currentTeam.capacity})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D), // Forest green
                    ),
                  ),
                )
              else if (activity.groupingMethod == GroupingMethod.auto)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Text(
                    'Auto-Matching Pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: const Text(
                    'Manual Forming Open',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),

              // Right: Action Button
              ElevatedButton(
                onPressed: () {
                  _showTeammatesDialog(context, activity, currentTeam, app);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A), // Dark Royal Navy/Blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_forward_rounded, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'View Teammates',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Grouping Method Badge (HYBRID, AUTO, MANUAL)
  Widget _buildMethodBadge(GroupingMethod method) {
    Color bg;
    Color textColor;
    String label;

    switch (method) {
      case GroupingMethod.hybrid:
        bg = const Color(0xFFEDE9FE); // Light lavender
        textColor = const Color(0xFF6D28D9); // Purple
        label = 'HYBRID';
        break;
      case GroupingMethod.auto:
        bg = const Color(0xFFFCE7F3); // Soft pink
        textColor = const Color(0xFF9D174D); // Magenta
        label = 'AUTO';
        break;
      case GroupingMethod.manual:
        bg = const Color(0xFFCCFBF1); // Light mint
        textColor = const Color(0xFF0F766E); // Teal
        label = 'MANUAL';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Metadata Pill (Capacity, Needed, Min hrs)
  Widget _buildSpecPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // Teammates & Hybrid Mode Computation Dialog
  void _showTeammatesDialog(
    BuildContext context,
    ActivityModel activity,
    TeamModel? team,
    AppState app,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _TeammatesModalDialog(
        activity: activity,
        initialTeam: team,
        appState: app,
      ),
    );
  }
}

class _TeammatesModalDialog extends StatefulWidget {
  final ActivityModel activity;
  final TeamModel? initialTeam;
  final AppState appState;

  const _TeammatesModalDialog({
    required this.activity,
    required this.initialTeam,
    required this.appState,
  });

  @override
  State<_TeammatesModalDialog> createState() => _TeammatesModalDialogState();
}

class _TeammatesModalDialogState extends State<_TeammatesModalDialog> {
  bool _fillIncompleteFirst = true;
  HybridResult? _hybridResult;
  bool _isComputing = false;

  @override
  Widget build(BuildContext context) {
    final team = widget.initialTeam;
    final activity = widget.activity;
    final app = widget.appState;

    // Unassigned students in this class
    final assignedIds = <String>{};
    for (var t in app.teams.where((t) => t.activityId == activity.id)) {
      for (var m in t.members) {
        assignedIds.add(m.userId);
      }
    }
    final targetClass = app.classes.firstWhere(
      (c) => c.id == activity.classId,
      orElse: () => app.classes.first,
    );
    final unassigned = app.students
        .where((s) => targetClass.enrolledStudentIds.contains(s.id) && !assignedIds.contains(s.id))
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 780,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team != null ? team.name : 'Team Roster & Hybrid Matching',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activity.title} • ${activity.className} • ${unassigned.length} Unassigned Students',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 28),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section A: Current Team Members Roster
                    if (team != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TEAM MEMBERS (${team.members.length} / ${team.capacity})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF64748B)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: team.overallCompatibility >= 75 ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'TeamScore: ${team.overallCompatibility.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: team.overallCompatibility >= 75 ? const Color(0xFF15803D) : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ...team.members.map((m) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF2563EB),
                                child: Text(
                                  m.name.isNotEmpty ? m.name[0] : 'S',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          m.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                        ),
                                        if (m.userId == team.leaderId) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                                            child: const Text('LEADER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${m.assignedRole} • ${m.weeklyCommonHours} hrs/wk free',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: m.isLocked ? const Color(0xFFF1F5F9) : const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  m.isLocked ? 'Student-Chosen' : 'Auto-Assigned',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: m.isLocked ? const Color(0xFF475569) : const Color(0xFF6D28D9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                    ],

                    // Section B: 7-Step Hybrid Algorithm Trigger & Results
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // Soft Blue container
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hybrid Mode Computation Engine',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A)),
                                    ),
                                    Text(
                                      'Executes 7-step optimization on unassigned students past deadline.',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Strategy Selector (Strategy A vs B)
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Strategy A: Fill Incomplete Teams First'),
                                  selected: _fillIncompleteFirst,
                                  selectedColor: const Color(0xFF2563EB),
                                  labelStyle: TextStyle(
                                    color: _fillIncompleteFirst ? Colors.white : const Color(0xFF1E293B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  onSelected: (val) => setState(() => _fillIncompleteFirst = true),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Strategy B: Form New Teams Only'),
                                  selected: !_fillIncompleteFirst,
                                  selectedColor: const Color(0xFF2563EB),
                                  labelStyle: TextStyle(
                                    color: !_fillIncompleteFirst ? Colors.white : const Color(0xFF1E293B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  onSelected: (val) => setState(() => _fillIncompleteFirst = false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Computation Trigger Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isComputing
                                  ? null
                                  : () {
                                      setState(() => _isComputing = true);
                                      Future.delayed(const Duration(milliseconds: 300), () {
                                        final res = app.runHybridModeComputation(
                                          activityId: activity.id,
                                          classId: activity.classId,
                                          fillIncompleteFirst: _fillIncompleteFirst,
                                        );
                                        setState(() {
                                          _hybridResult = res;
                                          _isComputing = false;
                                        });
                                      });
                                    },
                              icon: _isComputing
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.play_arrow_rounded, size: 18),
                              label: Text(
                                _isComputing ? 'Computing Optimal Placement...' : 'Run Hybrid Team Formation',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),

                          // Step-by-Step Execution Logs
                          if (_hybridResult != null) ...[
                            const SizedBox(height: 18),
                            const Text(
                              'COMPUTATION RESULTS & AUDIT LOG:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Class Balance Gap: ${_hybridResult!.balanceGap.toStringAsFixed(1)}% '
                                        '(${_hybridResult!.balanceGap <= 15 ? "High Balance" : "Moderate"})',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        'Swaps: ${_hybridResult!.swapsPerformed}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  ..._hybridResult!.stepLogs.map((log) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        log,
                                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF334155)),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
