import 'package:flutter/material.dart';

import 'widgets/portal_top_actions.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/academic_class.dart';
import '../models/grouping_activity.dart';
import '../models/profile.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/notification_service.dart';
import 'student_classes_screen.dart';
import 'student_groups_screen.dart';
import 'student_settings_screen.dart';
import 'widgets/student_sidebar.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final _activityService = ActivityService();

  List<GroupingActivity> _activities = [];
  List<AcademicClass> _classes = [];
  bool _isLoading = true;
  bool _showGroupActivityAlerts = true;

  // Student info state
  String get _studentName => (AuthService.currentUser?.name.isNotEmpty == true)
      ? AuthService.currentUser!.name
      : 'Student User';
  String get _studentBlock =>
      (AuthService.currentUser?.departmentOrSection?.isNotEmpty == true)
      ? AuthService.currentUser!.departmentOrSection!
      : 'BSIT 2A';
  String _primaryRole = 'Frontend Developer';
  String _skillLevel = 'Intermediate';

  GroupingActivity? get _urgentImpendingActivity {
    if (!_showGroupActivityAlerts) return null;
    if (_activities.isEmpty) return null;
    final studentName = _studentName.toLowerCase();

    for (final act in _activities) {
      bool inTeam = false;
      if (act.formedTeams != null) {
        for (final team in act.formedTeams!) {
          if (team is Map) {
            final members = (team['members'] as List?) ?? [];
            for (final m in members) {
              final mName = (m is Map)
                  ? (m['name']?.toString() ?? '')
                  : m.toString();
              if (mName.toLowerCase() == studentName) {
                inTeam = true;
                break;
              }
            }
          }
          if (inTeam) break;
        }
      }

      if (!inTeam) {
        final diff = act.groupingDeadline.difference(DateTime.now());
        if (diff.isNegative || diff.inHours <= 24) {
          return act;
        }
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadAlertPreference();
  }

  Future<void> _loadAlertPreference() async {
    try {
      final values = await NotificationService().getPreferences();
      if (mounted) {
        setState(
          () => _showGroupActivityAlerts = values['group_activity'] ?? true,
        );
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final user = AuthService.currentUser;
      final key =
          'gmm_notifications_${user?.id ?? user?.email ?? 'guest'}_group';
      if (mounted) {
        setState(() => _showGroupActivityAlerts = prefs.getBool(key) ?? true);
      }
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final activitiesFuture = _activityService.getActivities();
      final classesFuture = _activityService.getClasses();
      final profilesFuture = ProfileService().getProfiles();

      final results = await Future.wait([
        activitiesFuture,
        classesFuture,
        profilesFuture,
      ]);
      if (mounted) {
        final profiles = results[2] as List<Profile>;
        final currentEmail = AuthService.currentUser?.email ?? '';
        final myProfile = profiles.cast<Profile?>().firstWhere(
          (p) =>
              p != null && p.email.toLowerCase() == currentEmail.toLowerCase(),
          orElse: () => null,
        );

        setState(() {
          _activities = results[0] as List<GroupingActivity>;
          _classes = results[1] as List<AcademicClass>;
          if (myProfile != null) {
            if (myProfile.preferredRole.isNotEmpty) {
              _primaryRole = myProfile.preferredRole;
            }
            if (myProfile.skills.isNotEmpty) {
              _skillLevel = myProfile.skills.length >= 4
                  ? 'Advanced'
                  : (myProfile.skills.length >= 2
                        ? 'Intermediate'
                        : 'Beginner');
            }
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSwitchGroupDialog(GroupingActivity activity) {
    final reasonController = TextEditingController();
    String targetTeam = 'Team Beta';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.swap_horiz, color: Color(0xFF1E40AF)),
            SizedBox(width: 8),
            Text(
              'Request Group Switch',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Text(
                'Note: Because profiles and teams are locked once confirmed, your switch request will be routed to your Project Manager and Professor for approval.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1E40AF),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Activity',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            Text(
              activity.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Requested Target Team',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: targetTeam,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: ['Team Beta', 'Team Gamma', 'Team Delta']
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) targetTeam = val;
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'Reason for Transfer Request',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Schedule misalignment, complementary skill request...',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Switch request for "$targetTeam" submitted to Project Manager and Professor.',
                  ),
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Send Switch Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Unified Sidebar
          const StudentSidebar(
            currentDestination: StudentNavDestination.dashboard,
          ),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 28,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Actions Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: const [PortalTopActions()],
                              ),
                              const SizedBox(height: 12),

                              // Top Greeting Banner
                              _buildWelcomeHeader(),
                              const SizedBox(height: 20),

                              // 24-Hour Urgent Grouping Reminder Alert Banner (Eventful only)
                              if (_urgentImpendingActivity != null) ...[
                                _buildDeadlineAlertBanner(
                                  _urgentImpendingActivity!,
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Metrics Row
                              _buildMetricsRow(),
                              const SizedBox(height: 28),

                              // Main Columns: My Teams & Active Projects (Left) vs Classes & Recommendations (Right)
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth >= 780;
                                  return isWide
                                      ? Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child:
                                                  _buildActiveProjectsSection(),
                                            ),
                                            const SizedBox(width: 24),
                                            Expanded(
                                              flex: 2,
                                              child:
                                                  _buildEnrolledClassesSummary(),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            _buildActiveProjectsSection(),
                                            const SizedBox(height: 24),
                                            _buildEnrolledClassesSummary(),
                                          ],
                                        );
                                },
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Welcome Header with Student Status & Level
  Widget _buildWelcomeHeader() {
    final firstName = _studentName.trim().split(RegExp(r'\s+')).first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;
          final avatarAndInfo = Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF1E40AF),
                child: Text(
                  _studentName.isNotEmpty ? _studentName[0] : 'S',
                  style: const TextStyle(
                    fontSize: 20,
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
                          'Welcome back, $firstName!',
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
                          child: Text(
                            _studentBlock,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          '$_primaryRole • ',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$_skillLevel Level',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7E22CE),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final editButton = OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentSettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.tune, size: 16),
            label: const Text('Edit Profile & Skills'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E40AF),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatarAndInfo,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: editButton),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: avatarAndInfo),
              const SizedBox(width: 16),
              editButton,
            ],
          );
        },
      ),
    );
  }

  // 24-Hour Urgent Grouping Deadline Alert Banner (strictly eventful)
  Widget _buildDeadlineAlertBanner(GroupingActivity activity) {
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
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notification_important,
              color: Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Urgent: Group Formation Deadline Approaching (< 24 Hours Left)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The grouping deadline for "${activity.title}" is approaching. If you are not in a confirmed team by the deadline, your professor will automatically assign you to a group.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB45309),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentGroupsScreen()),
              );
            },
            child: const Text(
              'Find Group Now',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Metric Statistics Row
  Widget _buildMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _buildStatCard(
            title: 'Enrolled Classes',
            value: _classes.length.toString(),
            icon: Icons.school,
            color: const Color(0xFF1E40AF),
            bg: const Color(0xFFEFF6FF),
          ),
          _buildStatCard(
            title: 'Active Activities',
            value: _activities.length.toString(),
            icon: Icons.dashboard_customize_outlined,
            color: const Color(0xFF059669),
            bg: const Color(0xFFECFDF5),
          ),
          _buildStatCard(
            title: 'Formed Teams',
            value: '1 Confirmed',
            icon: Icons.groups_outlined,
            color: const Color(0xFF7E22CE),
            bg: const Color(0xFFF3E8FF),
          ),
          _buildStatCard(
            title: 'Next Cutoff',
            value: 'Tomorrow',
            icon: Icons.timer_outlined,
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFFFBEB),
          ),
        ];

        if (constraints.maxWidth < 750) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: cards,
          );
        }

        return Row(
          children: cards
              .map(
                (c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Active Projects List with Team Cards and Switch Option
  Widget _buildActiveProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            const Text(
              'My Projects & Assigned Teams',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentGroupsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Open Groups Workspace'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E40AF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_activities.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No active activities right now.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          for (final activity in _activities) ...[
            _buildActivityProjectCard(activity),
            const SizedBox(height: 14),
          ],
      ],
    );
  }

  Widget _buildActivityProjectCard(GroupingActivity activity) {
    final isTeamFormed =
        activity.status.toLowerCase().contains('lock') ||
        activity.status.toLowerCase().contains('open');

    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  activity.className,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isTeamFormed
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isTeamFormed ? 'TEAM FORMED' : 'GROUPING IN PROGRESS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isTeamFormed
                        ? const Color(0xFF047857)
                        : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            activity.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            activity.description ?? 'Project activity specifications, guidelines, and team requirements.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Teammates Preview Row
          const Text(
            'Formed Team Roster (Alpha Squad):',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTeammateAvatar(
                'Carlos Mendoza (You)',
                'Frontend Developer',
                'C',
                const Color(0xFF1E40AF),
              ),
              _buildTeammateAvatar(
                'Bianca Cruz',
                'UI/UX Designer',
                'B',
                const Color(0xFF047857),
              ),
              _buildTeammateAvatar(
                'Dani Garcia',
                'QA & Docs',
                'D',
                const Color(0xFF7E22CE),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 12),

          // Action Buttons: Request Switch & Open Workspace
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showSwitchGroupDialog(activity),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text(
                  'Request Switch',
                  style: TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StudentGroupsScreen(initialActivityId: activity.id),
                    ),
                  );
                },
                icon: const Icon(Icons.hub_outlined, size: 16),
                label: const Text(
                  'Enter Team Workspace',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeammateAvatar(
    String name,
    String role,
    String initial,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                role,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Right Column: Quick Enrolled Classes Summary
  Widget _buildEnrolledClassesSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            const Text(
              'Enrolled Courses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentClassesScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        for (final c in _classes.take(3)) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        c.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
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
                        c.classCode,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Section: ${c.section ?? "N/A"} • ${c.studentCount} Students',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      size: 14,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${c.activitiesCount} Grouping Activities',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Enroll Class Code Shortcut Card
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentClassesScreen()),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: const [
                Icon(Icons.add_circle_outline, color: Color(0xFF1E40AF)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Got a class code from your professor? Enroll here',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Color(0xFF1E40AF)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
