import 'package:flutter/material.dart';

import 'widgets/portal_top_actions.dart';

import '../models/activity_summary.dart';
import '../models/grouping_activity.dart';
import '../services/activity_service.dart';
import 'widgets/activity_card.dart';
import 'widgets/activity_details_dialog.dart';
import 'widgets/activity_form_dialog.dart';
import 'widgets/professor_sidebar.dart';
import 'widgets/scarcity_report_dialog.dart';
import 'widgets/summary_cards_row.dart';

class ProfessorActivitiesScreen extends StatefulWidget {
  const ProfessorActivitiesScreen({super.key});

  @override
  State<ProfessorActivitiesScreen> createState() =>
      _ProfessorActivitiesScreenState();
}

class _ProfessorActivitiesScreenState extends State<ProfessorActivitiesScreen> {
  final _activityService = ActivityService();
  final _searchController = TextEditingController();
  final _groupSearchController = TextEditingController();

  List<GroupingActivity> _activities = [];
  ActivitySummary _summary = const ActivitySummary();

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all';
  int _activeProjectTab =
      0; // 0 = Activities & Milestones, 1 = Formed Teams & Groups

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summaryFuture = _activityService.getActivitySummary();
      final activitiesFuture = _activityService.getActivities(
        status: _selectedStatus,
        search: _searchController.text.trim(),
      );

      final results = await Future.wait([summaryFuture, activitiesFuture]);

      setState(() {
        _summary = results[0] as ActivitySummary;
        _activities = results[1] as List<GroupingActivity>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _openCreateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ActivityFormDialog(
        onSaved: () {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _openEditDialog(GroupingActivity activity) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ActivityFormDialog(
        activity: activity,
        onSaved: () {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _openDetailsDialog(GroupingActivity activity) {
    showDialog(
      context: context,
      builder: (ctx) => ActivityDetailsDialog(
        activity: activity,
        onEdit: () => _openEditDialog(activity),
      ),
    );
  }

  void _openScarcityDialog(GroupingActivity activity) {
    showDialog(
      context: context,
      builder: (ctx) => ScarcityReportDialog(
        activity: activity,
        onUpdated: () => _loadData(),
      ),
    );
  }

  Future<void> _finalizeActivity(GroupingActivity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalize Grouping (Step 10)?'),
        content: Text(
          'Are you ready to officially finalize and publish groups for "${activity.title}"? Students will receive their official assignments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Finalize & Publish'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _activityService.updateActivity(
          activity.id!,
          activity.copyWith(status: 'completed'),
        );
        _loadData();
        if (mounted) {
          _showFinalizedCelebrationDialog(activity);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to finalize activity: $e')),
          );
        }
      }
    }
  }

  void _showFinalizedCelebrationDialog(GroupingActivity activity) {
    final totalStudents = activity.studentsCount > 0 ? activity.studentsCount : 30;
    final totalGroups = activity.numberOfGroups > 0
        ? activity.numberOfGroups
        : (totalStudents / (activity.groupCapacity > 0 ? activity.groupCapacity : 5)).ceil();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Celebration Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Grouping Successfully Finalized! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${activity.className} - ${activity.title}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                // Stats badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people, size: 18, color: Color(0xFF1E293B)),
                          const SizedBox(width: 6),
                          Text(
                            '$totalStudents Students',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.groups, size: 18, color: Color(0xFF1E293B)),
                          const SizedBox(width: 6),
                          Text(
                            '$totalGroups Groups',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, size: 16, color: Color(0xFF059669)),
                      SizedBox(width: 8),
                      Text(
                        'Official group assignments published',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(GroupingActivity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Activity?'),
        content: Text(
          'Are you sure you want to delete "${activity.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _activityService.deleteActivity(activity.id!);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Activity deleted.')));
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting activity: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          const ProfessorSidebar(
            currentDestination: ProfessorNavDestination.projects,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header: Grouping Activities + Create Project button
                  _buildPageHeader(),
                  const SizedBox(height: 16),

                  // Top View Switcher (Activities vs Formed Groups)
                  _buildViewSwitcher(),
                  const SizedBox(height: 20),

                  if (_activeProjectTab == 0) ...[
                    // Summary Cards
                    SummaryCardsRow(
                      summary: _summary,
                      selectedFilter: _selectedStatus,
                      onSelectFilter: (filterKey) {
                        setState(() => _selectedStatus = filterKey);
                        _loadData();
                      },
                    ),
                    const SizedBox(height: 20),

                    // Search & Filter Toolbar
                    _buildToolbar(),
                    const SizedBox(height: 18),

                    // Main Content Area
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_errorMessage != null)
                      _buildErrorState()
                    else if (_activities.isEmpty)
                      _buildEmptyState()
                    else
                      _buildActivityGrid(),
                  ] else ...[
                    // Formed Teams & Groups View
                    _buildGroupsContent(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabPill(
            index: 0,
            icon: Icons.assignment_outlined,
            label: 'Activities & Milestones',
          ),
          const SizedBox(width: 4),
          _buildTabPill(
            index: 1,
            icon: Icons.groups_outlined,
            label: 'Formed Teams & Groups',
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _activeProjectTab == index;
    return InkWell(
      onTap: () => setState(() => _activeProjectTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF1E40AF)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsContent() {
    final query = _groupSearchController.text.trim().toLowerCase();
    final List<Map<String, dynamic>> groups = [];

    for (final act in _activities) {
      if (act.formedTeams != null && act.formedTeams!.isNotEmpty) {
        for (final tm in act.formedTeams!) {
          if (tm is Map) {
            final membersRaw = (tm['members'] as List?) ?? [];
            final membersList = membersRaw.map((m) {
              if (m is Map) {
                return {
                  'name': m['name']?.toString() ?? 'Member',
                  'role': m['role']?.toString() ?? 'Collaborator',
                  'level': m['level']?.toString() ?? 'Intermediate',
                  'skills':
                      (m['skills'] as List?)
                          ?.map((s) => s.toString())
                          .toList() ??
                      <String>[],
                };
              }
              return {
                'name': m.toString(),
                'role': 'Member',
                'level': 'Intermediate',
                'skills': <String>[],
              };
            }).toList();

            final capacity = act.groupCapacity;
            final count = membersList.length;
            final isFull = count >= capacity;

            groups.add({
              'name': tm['name']?.toString() ?? 'Team',
              'activity': act.title,
              'course': act.className,
              'status': isFull
                  ? 'Full ($count/$capacity)'
                  : 'Formed ($count/$capacity)',
              'isFull': isFull,
              'members': membersList,
            });
          }
        }
      }
    }

    final filtered = groups.where((g) {
      if (query.isEmpty) return true;
      final gName = (g['name'] as String).toLowerCase();
      final aName = (g['activity'] as String).toLowerCase();
      final cName = (g['course'] as String).toLowerCase();
      final mNames = (g['members'] as List)
          .map((m) => ((m as Map)['name'] as String).toLowerCase())
          .join(' ');
      return gName.contains(query) ||
          aName.contains(query) ||
          cName.contains(query) ||
          mNames.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Toolbar for Groups
        TextField(
          controller: _groupSearchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText:
                'Search groups by team name, activity, or student member...',
            prefixIcon: const Icon(
              Icons.search,
              size: 18,
              color: Color(0xFF64748B),
            ),
            suffixIcon: _groupSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () =>
                        setState(() => _groupSearchController.clear()),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        const SizedBox(height: 18),

        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 48,
                  color: Colors.blueGrey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  groups.isEmpty
                      ? 'No Teams Formed Yet'
                      : 'No Matching Groups Found',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  groups.isEmpty
                      ? 'Teams will appear here once formed or assigned in your grouping activities.'
                      : 'Try clearing your search query.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          // Groups Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 900 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 260,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final group = filtered[index];
                  final members =
                      group['members'] as List<Map<String, dynamic>>;
                  final isFull = group['isFull'] as bool;

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                group['name'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isFull
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                group['status'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isFull
                                      ? const Color(0xFF047857)
                                      : const Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group['course'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          group['activity'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFF1F5F9), height: 1),
                        const SizedBox(height: 8),

                        const Text(
                          'Team Roster (click to view profile):',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: members.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, mi) {
                              final m = members[mi];
                              final name = m['name'] as String;
                              final role = m['role'] as String;
                              final level = m['level'] as String;
                              final skills = (m['skills'] as List)
                                  .cast<String>();

                              return InkWell(
                                onTap: () => _showMemberDialog(
                                  name,
                                  role,
                                  level,
                                  skills,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
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
                                          name[0],
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
                                          name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0F172A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        role,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
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
              );
            },
          ),
      ],
    );
  }

  void _showMemberDialog(
    String name,
    String role,
    String level,
    List<String> skills,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF1E40AF),
              child: Text(
                name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    role,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Proficiency Level:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      level,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7E22CE),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Skills & Stack:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills.map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grouping Activities',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create and manage group activities for your classes',
              style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade600),
            ),
          ],
        );

        final createButton = ElevatedButton.icon(
          onPressed: _openCreateDialog,
          icon: const Icon(Icons.add, size: 20),
          label: const Text(
            'Create New Project',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E40AF), // Deep royal blue
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleBlock),
                  const PortalTopActions(),
                ],
              ),
              const SizedBox(height: 12),
              createButton,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            createButton,
            const SizedBox(width: 16),
            const PortalTopActions(),
          ],
        );
      },
    );
  }

  Widget _buildToolbar() {
    final statusPills = [
      {'key': 'all', 'label': 'All'},
      {'key': 'active', 'label': 'Active'},
      {'key': 'grouping in progress', 'label': 'In Progress'},
      {'key': 'upcoming', 'label': 'Upcoming'},
      {'key': 'completed', 'label': 'Completed'},
      {'key': 'draft', 'label': 'Draft'},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search input
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by activity title or class name...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _loadData();
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _loadData(),
                ),
              ),
              const SizedBox(width: 10),
              // Search button
              OutlinedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.filter_list, size: 18),
                label: const Text('Search'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Refresh button
              IconButton(
                onPressed: _loadData,
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statusPills.map((pill) {
                final isSelected = _selectedStatus == pill['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(pill['label']!),
                    selected: isSelected,
                    selectedColor: const Color(0xFFDBEAFE),
                    checkmarkColor: const Color(0xFF1E40AF),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF1E40AF)
                          : const Color(0xFF475569),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      setState(() => _selectedStatus = pill['key']!);
                      _loadData();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 950;

        if (isWide) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 310,
            ),
            itemCount: _activities.length,
            itemBuilder: (context, index) {
              final activity = _activities[index];
              return ActivityCard(
                activity: activity,
                onViewDetails: () => _openDetailsDialog(activity),
                onScarcityReport: () => _openScarcityDialog(activity),
                onFinalize: () => _finalizeActivity(activity),
                onEdit: () => _openEditDialog(activity),
                onDelete: () => _confirmDelete(activity),
              );
            },
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _activities.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final activity = _activities[index];
            return ActivityCard(
              activity: activity,
              onViewDetails: () => _openDetailsDialog(activity),
              onScarcityReport: () => _openScarcityDialog(activity),
              onFinalize: () => _finalizeActivity(activity),
              onEdit: () => _openEditDialog(activity),
              onDelete: () => _confirmDelete(activity),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 56,
              color: Colors.blueGrey.shade300,
            ),
            const SizedBox(height: 14),
            const Text(
              'No Activities Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'There are no grouping activities matching your criteria.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create New Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 30),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
            const SizedBox(height: 10),
            const Text(
              'Unable to load activities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF991B1B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.red.shade800),
            ),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
