import 'package:flutter/material.dart';

import '../models/grouping_activity.dart';
import '../services/activity_service.dart';
import 'landing_screen.dart';
import 'student_classes_screen.dart';
import 'student_dashboard_screen.dart';
import 'student_settings_screen.dart';

class StudentCandidate {
  final int id;
  final String name;
  final String block;
  final String avatarUrl;
  final List<String> skills;
  final List<String> interests;
  final String availability;
  final int commonHours;
  final double compatibilityScore;
  final String preferredRole;
  bool isInvited;

  StudentCandidate({
    required this.id,
    required this.name,
    required this.block,
    required this.avatarUrl,
    required this.skills,
    required this.interests,
    required this.availability,
    required this.commonHours,
    required this.compatibilityScore,
    required this.preferredRole,
    this.isInvited = false,
  });
}

class StudentGroupsScreen extends StatefulWidget {
  final int? initialActivityId;

  const StudentGroupsScreen({
    super.key,
    this.initialActivityId,
  });

  @override
  State<StudentGroupsScreen> createState() => _StudentGroupsScreenState();
}

class _StudentGroupsScreenState extends State<StudentGroupsScreen> {
  final _activityService = ActivityService();

  List<GroupingActivity> _activities = [];
  GroupingActivity? _selectedActivity;
  bool _isLoading = true;
  String? _errorMessage;

  String _filterMode = 'skills'; // 'skills', 'availability', 'all'
  bool _isSidebarCollapsed = false;

  // Student's current team mockup
  String _teamName = 'Team Alpha Core';
  bool _isLeader = true;
  final List<Map<String, String>> _myTeamMembers = [
    {
      'name': 'Alex Santos (You)',
      'role': 'Frontend Developer & Leader',
      'block': 'BSIT 2A',
      'avatar': 'A'
    },
    {
      'name': 'Carl Reyes',
      'role': 'UI/UX Designer',
      'block': 'BSIT 2A',
      'avatar': 'C'
    },
    {
      'name': 'Dani Garcia',
      'role': 'Technical Writer / QA',
      'block': 'BSIT 2A',
      'avatar': 'D'
    },
  ];

  // Candidates list matching spec
  late List<StudentCandidate> _candidates;

  @override
  void initState() {
    super.initState();
    _initCandidates();
    _loadActivities();
  }

  void _initCandidates() {
    _candidates = [
      StudentCandidate(
        id: 101,
        name: 'Bea Cruz',
        block: 'BSIT 2A',
        avatarUrl: 'B',
        skills: ['Backend Development', 'Database Management', 'Laravel', 'PHP'],
        interests: ['Web Development', 'Data Analysis', 'Cloud Computing'],
        availability: 'Mon, Tue, Thu afternoons (1-5 PM)',
        commonHours: 5,
        compatibilityScore: 92.5,
        preferredRole: 'Backend Developer',
      ),
      StudentCandidate(
        id: 102,
        name: 'Ethan Lim',
        block: 'BSIT 2A',
        avatarUrl: 'E',
        skills: ['Database Management', 'MySQL', 'PostgreSQL', 'API Development'],
        interests: ['Database Systems', 'Networking', 'Cybersecurity'],
        availability: 'Tue, Wed, Fri (2-6 PM)',
        commonHours: 4,
        compatibilityScore: 88.0,
        preferredRole: 'Database Administrator',
      ),
      StudentCandidate(
        id: 103,
        name: 'Gabe Tan',
        block: 'BSIT 2A',
        avatarUrl: 'G',
        skills: ['Backend Development', 'Node.js', 'Express.js', 'Docker'],
        interests: ['API Integrations', 'Game Development'],
        availability: 'Mon, Wed, Fri mornings (9-12 AM)',
        commonHours: 3,
        compatibilityScore: 81.0,
        preferredRole: 'Backend Developer',
      ),
      StudentCandidate(
        id: 104,
        name: 'Hana Cruz',
        block: 'BSIT 2A',
        avatarUrl: 'H',
        skills: ['UI/UX Design', 'Figma', 'Adobe XD', 'Frontend Development'],
        interests: ['Creative Design', 'Mobile UI'],
        availability: 'Weekdays after 3 PM',
        commonHours: 5,
        compatibilityScore: 85.5,
        preferredRole: 'UI/UX Designer',
      ),
      StudentCandidate(
        id: 105,
        name: 'Ivan Santos',
        block: 'BSIT 2A',
        avatarUrl: 'I',
        skills: ['Software Testing and Quality Assurance', 'Postman', 'Git'],
        interests: ['Quality Engineering', 'Technical Documentation'],
        availability: 'Thu, Fri, Sat (10 AM - 4 PM)',
        commonHours: 2,
        compatibilityScore: 74.0,
        preferredRole: 'QA / Software Tester',
      ),
    ];
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _activityService.getActivities();
      if (mounted) {
        setState(() {
          _activities = list;
          if (list.isNotEmpty) {
            if (widget.initialActivityId != null) {
              _selectedActivity = list.firstWhere(
                (a) => a.id == widget.initialActivityId,
                orElse: () => list.first,
              );
            } else {
              _selectedActivity = list.first;
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  List<StudentCandidate> get _sortedCandidates {
    final list = List<StudentCandidate>.from(_candidates);
    if (_filterMode == 'skills') {
      list.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
    } else if (_filterMode == 'availability') {
      list.sort((a, b) => b.commonHours.compareTo(a.commonHours));
    }
    return list;
  }

  void _inviteTeammate(StudentCandidate candidate) {
    final slotsOpen =
        (_selectedActivity?.groupCapacity ?? 5) - _myTeamMembers.length;

    if (slotsOpen <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your team has already reached maximum capacity!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      candidate.isInvited = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invitation sent to ${candidate.name} ($slotsOpen slots remaining)!'),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final titleController = TextEditingController(text: 'Team NextGen');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'As the group creator, you will be assigned as the Team Leader.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isLeader = true;
                _teamName = titleController.text.trim();
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Created team "$_teamName" as Team Leader!'),
                  backgroundColor: const Color(0xFF059669),
                ),
              );
            },
            child: const Text('Create Group'),
          ),
        ],
      ),
    );
  }

  void _showSwitchRequestDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Group Switch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Switch requests are submitted to the Project Manager and Professor for approval. Teams are locked once approved.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for group switch / Target team or member',
                hintText: 'e.g. Schedule conflict, complementary skill swap with Bea Cruz...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Switch request sent to Professor & Team Manager!'),
                  backgroundColor: Color(0xFF1E40AF),
                ),
              );
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  void _showCandidateProfile(StudentCandidate candidate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF1E40AF),
              child: Text(
                candidate.avatarUrl,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(candidate.name, style: const TextStyle(fontSize: 18)),
                Text(
                  '${candidate.block} • ${candidate.preferredRole}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compatibility banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            value: candidate.compatibilityScore / 100,
                            strokeWidth: 4,
                            backgroundColor: Colors.teal.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade700),
                          ),
                        ),
                        Text(
                          '${candidate.compatibilityScore.toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'High Compatibility Match',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '40% Skills • 30% Interests • 30% Availability',
                            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              const Text('Skills:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: candidate.skills.map((s) {
                  final isReq = _selectedActivity?.requiredSkills.contains(s) ?? false;
                  return Chip(
                    label: Text(s, style: TextStyle(fontSize: 11, color: isReq ? Colors.blue.shade900 : Colors.grey.shade800)),
                    backgroundColor: isReq ? Colors.blue.shade50 : Colors.grey.shade100,
                    side: BorderSide(color: isReq ? Colors.blue.shade300 : Colors.grey.shade300),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              const Text('Interests:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: candidate.interests.map((i) {
                  return Chip(
                    label: Text(i, style: const TextStyle(fontSize: 11)),
                    backgroundColor: Colors.teal.shade50,
                    side: BorderSide(color: Colors.teal.shade200),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text(
                    'Availability: ${candidate.availability}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _inviteTeammate(candidate);
            },
            icon: const Icon(Icons.person_add, size: 16),
            label: Text(candidate.isInvited ? 'Invited' : 'Invite to Team'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = _selectedActivity;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Collapsible Student Sidebar
          _buildCollapsibleSidebar(),

          // Main POV Content Area
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                _buildTopBar(),

                // Scrollable Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Error: $_errorMessage'),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: _loadActivities,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : activity == null
                              ? const Center(child: Text('No active projects available.'))
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Deadline Warning Reminder Banner
                                      _buildDeadlineAlertBanner(activity),
                                      const SizedBox(height: 18),

                                      // Project Overview Card with "+ Create Group" button
                                      _buildProjectOverviewCard(activity),
                                      const SizedBox(height: 20),

                                      // My Current Team Status Box
                                      _buildMyTeamCard(activity),
                                      const SizedBox(height: 24),

                                      // Teammates Recommendations Section
                                      _buildRecommendationsSection(activity),
                                    ],
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isSidebarCollapsed ? Icons.menu_open : Icons.menu),
            onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            tooltip: 'Toggle Sidebar',
          ),
          const SizedBox(width: 8),
          const Text(
            'Teams & Projects',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),

          // Activity Switcher dropdown
          if (_activities.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedActivity?.id,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1E40AF)),
                  items: _activities.map((a) {
                    return DropdownMenuItem<int>(
                      value: a.id,
                      child: Text(
                        '${a.title} (${a.className})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    setState(() {
                      _selectedActivity = _activities.firstWhere((a) => a.id == id);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],

          // Student user profile avatar preview
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF059669),
            child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          const Text(
            'Alex Santos',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSidebar() {
    final width = _isSidebarCollapsed ? 70.0 : 220.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark slate
        border: Border(right: BorderSide(color: Colors.grey.shade900)),
      ),
      child: Column(
        children: [
          // Logo & Brand
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hub, color: Colors.white, size: 20),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'GroupMeMaybe',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Colors.white12),

          // Student Navigation Items: dashboard, classes, groups, settings
          _buildSidebarItem(
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            isSelected: false,
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentDashboardScreen())),
          ),
          _buildSidebarItem(
            icon: Icons.school_outlined,
            title: 'Classes',
            isSelected: false,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentClassesScreen())),
          ),
          _buildSidebarItem(
            icon: Icons.groups_outlined,
            title: 'Groups (Teams)',
            isSelected: true,
            onTap: () {},
          ),
          _buildSidebarItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            isSelected: false,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentSettingsScreen())),
          ),

          const Spacer(),
          const Divider(color: Colors.white12),
          _buildSidebarItem(
            icon: Icons.logout,
            title: 'Log Out',
            isSelected: false,
            color: Colors.redAccent,
            onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LandingScreen()), (r) => false),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? Colors.white12 : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? (isSelected ? const Color(0xFF60A5FA) : Colors.grey.shade400)),
            if (!_isSidebarCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: color ?? (isSelected ? Colors.white : Colors.grey.shade300),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineAlertBanner(GroupingActivity activity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_filled, color: Colors.amber.shade900, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grouping Deadline Approaching (${activity.groupingMethod.toUpperCase()} Mode)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Group creation deadline closes soon. Students without a confirmed group by deadline will be automatically distributed by the professor.',
                  style: TextStyle(color: Colors.brown.shade800, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Deadline: ${activity.groupingDeadline.year}-${activity.groupingDeadline.month.toString().padLeft(2, '0')}-${activity.groupingDeadline.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.brown.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectOverviewCard(GroupingActivity activity) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.school, size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 6),
                        Text(
                          activity.className,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Create Group button for manual/hybrid modes
              if (activity.groupingMethod != 'auto')
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: _showCreateGroupDialog,
                  icon: const Icon(Icons.group_add, size: 18),
                  label: const Text('Create Group', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (activity.description != null && activity.description!.isNotEmpty) ...[
            Text(
              activity.description!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
            ),
            const SizedBox(height: 14),
          ],

          // Constraints Row
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildSpecBadge(
                icon: Icons.groups,
                label: 'Team Size',
                value: '${activity.groupCapacity} members',
              ),
              _buildSpecBadge(
                icon: Icons.grid_view,
                label: 'Target Groups',
                value: '${activity.numberOfGroups} teams',
              ),
              _buildSpecBadge(
                icon: Icons.access_time,
                label: 'Min Common Hours',
                value: '${activity.minCommonHours} hrs / wk',
              ),
              _buildSpecBadge(
                icon: Icons.verified,
                label: 'Min Level',
                value: activity.minProficiencyLevel,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Required Skills chips
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  'Required Skills: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: activity.requiredSkills.map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyTeamCard(GroupingActivity activity) {
    final slotsRemaining = activity.groupCapacity - _myTeamMembers.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people, color: Color(0xFF059669), size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _teamName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      if (_isLeader)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Text(
                            'LEADER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '${_myTeamMembers.length} / ${activity.groupCapacity} members ($slotsRemaining slots open)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const Spacer(),
              // Request swap button
              OutlinedButton.icon(
                onPressed: _showSwitchRequestDialog,
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Request Group Switch'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Team members list
          Row(
            children: _myTeamMembers.map((m) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF1E40AF),
                        child: Text(
                          m['avatar']!,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['name']!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              m['role']!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(GroupingActivity activity) {
    final candidates = _sortedCandidates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with refresh & filter tabs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teammate Recommendations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Ranked candidate recommendations matching your project requirements',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            Row(
              children: [
                // Filter Tabs
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'skills',
                      label: Text('Skills Match'),
                      icon: Icon(Icons.star, size: 14),
                    ),
                    ButtonSegment(
                      value: 'availability',
                      label: Text('Availability'),
                      icon: Icon(Icons.access_time, size: 14),
                    ),
                    ButtonSegment(
                      value: 'all',
                      label: Text('All'),
                    ),
                  ],
                  selected: {_filterMode},
                  onSelectionChanged: (set) => setState(() => _filterMode = set.first),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () {
                    _initCandidates();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Refreshed teammate recommendations.')),
                    );
                  },
                  tooltip: 'Refresh Recommendations',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Gallery of recommended teammate cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: candidates.length,
          separatorBuilder: (_, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final c = candidates[index];
            return _buildCandidateCard(c);
          },
        ),
      ],
    );
  }

  Widget _buildCandidateCard(StudentCandidate c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Student Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF1E40AF),
            child: Text(
              c.avatarUrl,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        c.block,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c.preferredRole,
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Skills chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: c.skills.map((s) {
                    final isReq = _selectedActivity?.requiredSkills.contains(s) ?? false;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isReq ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: isReq ? const Color(0xFFBFDBFE) : Colors.transparent),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isReq ? FontWeight.bold : FontWeight.normal,
                          color: isReq ? const Color(0xFF1E40AF) : Colors.grey.shade800,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),

                // Common Availability
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      '${c.commonHours} common free hours • ${c.availability}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Compatibility Ring
          Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: CircularProgressIndicator(
                      value: c.compatibilityScore / 100,
                      strokeWidth: 4,
                      backgroundColor: Colors.teal.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade700),
                    ),
                  ),
                  Text(
                    '${c.compatibilityScore.toInt()}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Match', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),

          const SizedBox(width: 16),

          // Buttons: View Profile & Invite
          Column(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                onPressed: () => _showCandidateProfile(c),
                child: const Text('View Profile', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.isInvited ? Colors.grey.shade400 : const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                onPressed: c.isInvited ? null : () => _inviteTeammate(c),
                icon: Icon(c.isInvited ? Icons.check : Icons.add, size: 14),
                label: Text(c.isInvited ? 'Invited' : 'Invite to Team', style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecBadge({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
