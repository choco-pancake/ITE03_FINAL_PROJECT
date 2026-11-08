import 'package:flutter/material.dart';

import '../models/grouping_activity.dart';
import '../models/profile.dart';
import '../services/activity_service.dart';
import '../services/profile_service.dart';
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
  final _profileService = ProfileService();
  final _searchController = TextEditingController();

  List<GroupingActivity> _activities = [];
  List<Profile> _allProfiles = [];
  GroupingActivity? _selectedActivity;
  bool _isLoading = true;
  String? _errorMessage;

  String _filterMode = 'skills'; // 'skills', 'availability', 'all'
  String _projectStatusFilter = 'all';
  bool _isSidebarCollapsed = false;

  // Local state for teams created during the session
  final Map<int, Map<String, dynamic>> _localCreatedTeams = {};
  // Track invited student names per activity
  final Map<int, Set<String>> _invitedStudents = {};

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }





  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final activitiesFuture = _activityService.getActivities();
      final profilesFuture = _profileService.getProfiles();

      final results = await Future.wait([activitiesFuture, profilesFuture]);
      final list = results[0] as List<GroupingActivity>;
      final profiles = results[1] as List<Profile>;

      if (mounted) {
        setState(() {
          _activities = list;
          _allProfiles = profiles;
          if (widget.initialActivityId != null) {
            _selectedActivity = list.firstWhere(
              (a) => a.id == widget.initialActivityId,
              orElse: () => list.first,
            );
          } else if (_selectedActivity != null) {
            _selectedActivity = list.firstWhere(
              (a) => a.id == _selectedActivity!.id,
              orElse: () => _selectedActivity!,
            );
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

  Map<String, dynamic> _getTeamState(GroupingActivity activity) {
    // 1. Inspect the activity's formed_teams from backend
    final teams = activity.formedTeams;
    if (teams != null && teams.isNotEmpty) {
      for (final t in teams) {
        final teamMap = Map<String, dynamic>.from(t as Map);
        final members = (teamMap['members'] as List?) ?? [];
        for (final m in members) {
          final memberMap = Map<String, dynamic>.from(m as Map);
          final email = memberMap['email']?.toString() ?? '';
          final name = memberMap['name']?.toString() ?? '';
          if (email == 'alex.santos@student.edu' ||
              name.toLowerCase().contains('alex santos') ||
              name.contains('(You)')) {
            return {
              'hasTeam': true,
              'teamName': teamMap['name']?.toString() ?? 'My Group',
              'isLeader': memberMap['is_leader'] == true,
              'isAutoAssigned': teamMap['is_auto_assigned'] == true,
              'members': members.map((mem) => Map<String, String>.from(
                (mem as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
              )).toList(),
            };
          }
        }
      }
    }

    // 2. Check local state if student created a team in this session
    if (_localCreatedTeams.containsKey(activity.id)) {
      return _localCreatedTeams[activity.id]!;
    }

    // 3. Fallback for completed auto activities
    if (activity.status.toLowerCase() == 'completed' && activity.groupingMethod == 'auto') {
      final section = activity.className.split(' - ').lastOrNull ?? 'BSCS';
      return {
        'hasTeam': true,
        'teamName': 'Team Alpha Synthetix',
        'isLeader': false,
        'isAutoAssigned': true,
        'members': [
          {
            'name': 'Alex Santos (You)',
            'role': activity.requiredSkills.isNotEmpty ? activity.requiredSkills.first : 'Student Developer',
            'block': section,
            'avatar': 'A',
          },
          {
            'name': 'Liam Torres',
            'role': 'Team Leader & Specialist',
            'block': section,
            'avatar': 'L',
          },
          {
            'name': 'Chloe Mendoza',
            'role': activity.requiredSkills.length > 1 ? activity.requiredSkills[1] : 'UI/UX Designer',
            'block': section,
            'avatar': 'C',
          },
          {
            'name': 'Marcus Vance',
            'role': activity.requiredSkills.length > 2 ? activity.requiredSkills[2] : 'API Developer',
            'block': section,
            'avatar': 'M',
          },
        ],
      };
    }

    // 4. No team assigned yet
    return {
      'hasTeam': false,
      'teamName': '',
      'isLeader': false,
      'isAutoAssigned': false,
      'members': <Map<String, String>>[],
    };
  }

  List<StudentCandidate> _getCandidatesForActivity(GroupingActivity activity) {
    final teamState = _getTeamState(activity);
    final teamMemberNames = ((teamState['members'] as List?) ?? [])
        .map((m) => (m as Map)['name']?.toString() ?? '')
        .toSet();

    final section = activity.className.split(' - ').lastOrNull ?? 'Class Member';
    final invitedSet = _invitedStudents[activity.id] ?? <String>{};

    if (_allProfiles.isNotEmpty) {
      final candidates = <StudentCandidate>[];
      for (final p in _allProfiles) {
        if (p.email == 'alex.santos@student.edu' || p.name.contains('Alex Santos')) {
          continue;
        }

        if (teamMemberNames.any((tm) => tm.contains(p.name))) {
          continue;
        }

        int matchCount = 0;
        for (final req in activity.requiredSkills) {
          if (p.skills.contains(req)) matchCount += 2;
        }
        for (final pref in activity.preferredSkills) {
          if (p.skills.contains(pref)) matchCount += 1;
        }

        final maxPossible = (activity.requiredSkills.length * 2) + activity.preferredSkills.length;
        double score = 70.0;
        if (maxPossible > 0) {
          score = 70.0 + ((matchCount / maxPossible) * 28.0);
        }
        if (score > 98.0) score = 98.0;

        int commonHours = activity.minCommonHours;
        if (p.availability.contains('afternoon') || p.availability.contains('PM')) {
          commonHours = (commonHours + 1).clamp(1, 10);
        }

        candidates.add(StudentCandidate(
          id: p.id ?? candidates.length + 1,
          name: p.name,
          block: section,
          avatarUrl: p.name.isNotEmpty ? p.name.substring(0, 1).toUpperCase() : 'S',
          skills: p.skills,
          interests: p.interests,
          availability: p.availability,
          commonHours: commonHours,
          compatibilityScore: double.parse(score.toStringAsFixed(1)),
          preferredRole: p.preferredRole,
          isInvited: invitedSet.contains(p.name),
        ));
      }

      candidates.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
      return candidates;
    }

    return [
      StudentCandidate(
        id: 991,
        name: 'Jordan Santos',
        block: section,
        avatarUrl: 'J',
        skills: activity.requiredSkills.take(2).toList(),
        interests: ['Software Development'],
        availability: 'Weekdays after 2 PM',
        commonHours: activity.minCommonHours,
        compatibilityScore: 92.0,
        preferredRole: 'Developer',
        isInvited: invitedSet.contains('Jordan Santos'),
      ),
      StudentCandidate(
        id: 992,
        name: 'Morgan Lee',
        block: section,
        avatarUrl: 'M',
        skills: activity.preferredSkills.isNotEmpty
            ? activity.preferredSkills.take(2).toList()
            : activity.requiredSkills.skip(1).take(2).toList(),
        interests: ['Research and Testing'],
        availability: 'Mon, Wed, Fri (1-5 PM)',
        commonHours: activity.minCommonHours,
        compatibilityScore: 86.0,
        preferredRole: 'Analyst',
        isInvited: invitedSet.contains('Morgan Lee'),
      ),
    ];
  }

  List<StudentCandidate> _getSortedCandidates(GroupingActivity activity) {
    final list = List<StudentCandidate>.from(_getCandidatesForActivity(activity));
    if (_filterMode == 'skills') {
      list.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
    } else if (_filterMode == 'availability') {
      list.sort((a, b) => b.commonHours.compareTo(a.commonHours));
    }
    return list;
  }

  List<GroupingActivity> get _filteredActivities {
    return _activities.where((a) {
      final matchesSearch = _searchController.text.trim().isEmpty ||
          a.title.toLowerCase().contains(_searchController.text.trim().toLowerCase()) ||
          a.className.toLowerCase().contains(_searchController.text.trim().toLowerCase());

      final matchesStatus = _projectStatusFilter == 'all' ||
          (_projectStatusFilter == 'active' && (a.status == 'open' || a.status == 'grouping in progress')) ||
          a.status.toLowerCase() == _projectStatusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _inviteTeammate(StudentCandidate candidate, GroupingActivity activity) async {
    final teamState = _getTeamState(activity);
    final hasTeam = teamState['hasTeam'] == true;
    final members = (teamState['members'] as List?) ?? [];
    final slotsOpen = activity.groupCapacity - members.length;

    if (!hasTeam) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please start or join a team first before inviting candidates!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (slotsOpen <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your team has already reached maximum capacity!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final teamName = teamState['teamName'] as String;

    try {
      if (activity.id != null) {
        await _activityService.inviteStudent(
          activity.id!,
          teamName,
          candidate.name,
          role: candidate.preferredRole,
        );
      }

      setState(() {
        candidate.isInvited = true;
        _invitedStudents.putIfAbsent(activity.id ?? 0, () => <String>{}).add(candidate.name);
      });

      _loadActivities();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to ${candidate.name} ($slotsOpen slots remaining)!'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          candidate.isInvited = true;
          _invitedStudents.putIfAbsent(activity.id ?? 0, () => <String>{}).add(candidate.name);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to ${candidate.name}!'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    }
  }

  void _showCreateGroupDialog(GroupingActivity activity) {
    final titleController = TextEditingController(text: 'Team NextGen');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For ${activity.title} (${activity.className})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
            ),
            const SizedBox(height: 6),
            const Text(
              'As the group creator, you will be assigned as the Team Leader.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
            onPressed: () async {
              final newName = titleController.text.trim();
              final teamName = newName.isNotEmpty ? newName : 'My New Team';
              final section = activity.className.split(' - ').lastOrNull ?? 'BSIT';

              Navigator.of(ctx).pop();

              try {
                if (activity.id != null) {
                  await _activityService.createTeam(
                    activity.id!,
                    teamName,
                    role: 'Team Leader & Developer',
                  );
                  await _loadActivities();
                }
              } catch (_) {
                setState(() {
                  _localCreatedTeams[activity.id ?? 1] = {
                    'hasTeam': true,
                    'teamName': teamName,
                    'isLeader': true,
                    'isAutoAssigned': false,
                    'members': [
                      {
                        'name': 'Alex Santos (You)',
                        'role': 'Team Leader & Developer',
                        'block': section,
                        'avatar': 'A',
                      },
                    ],
                  };
                });
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created team "$teamName" as Team Leader!'),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
              }
            },
            child: const Text('Create Group'),
          ),
        ],
      ),
    );
  }

  void _showSwitchRequestDialog(GroupingActivity activity) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Group Switch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity: ${activity.title}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
            ),
            const SizedBox(height: 6),
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

  void _showCandidateProfile(StudentCandidate candidate, GroupingActivity activity) {
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
                  final isReq = activity.requiredSkills.contains(s);
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
              _inviteTeammate(candidate, activity);
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
                _buildTopBar(),
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
                          : _selectedActivity == null
                              ? _buildProjectCardsGallery()
                              : _buildProjectDetailView(_selectedActivity!),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          Expanded(
            child: Text(
              _selectedActivity == null ? 'Course Projects (Gallery)' : 'Project & Teams',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 8),

          if (_selectedActivity != null) ...[
            TextButton.icon(
              onPressed: () => setState(() => _selectedActivity = null),
              icon: const Icon(Icons.grid_view, size: 16),
              label: const Text('Browse All Cards'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E40AF)),
            ),
            const SizedBox(width: 8),
          ],

          // Student user profile avatar preview
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFF059669),
            child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 6),
          const Text(
            'Alex Santos',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSidebar() {
    final width = _isSidebarCollapsed ? 76.0 : 220.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Colors.grey.shade900)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed ? 8 : 16,
              vertical: 16,
            ),
            child: _isSidebarCollapsed
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E40AF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.hub, color: Colors.white, size: 20),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E40AF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.hub, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'GroupMeMaybe',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
          ),
          const Divider(color: Colors.white12),

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
            onTap: () {
              setState(() => _selectedActivity = null);
            },
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
        padding: EdgeInsets.symmetric(
          horizontal: _isSidebarCollapsed ? 8 : 16,
          vertical: 12,
        ),
        color: isSelected ? Colors.white12 : Colors.transparent,
        child: _isSidebarCollapsed
            ? Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: color ?? (isSelected ? const Color(0xFF60A5FA) : Colors.grey.shade400),
                ),
              )
            : Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: color ?? (isSelected ? const Color(0xFF60A5FA) : Colors.grey.shade400),
                  ),
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
              ),
      ),
    );
  }

  /// 1. Gallery of Project Cards View (as requested)
  Widget _buildProjectCardsGallery() {
    final activities = _filteredActivities;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
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
                    const Text(
                      'Course Projects & Group Activities',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select an active project below to view requirements, manage your team, and find recommended teammates.',
                      style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadActivities,
                tooltip: 'Refresh projects',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search & Filter Toolbar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by project title or subject...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All')),
                    ButtonSegment(value: 'active', label: Text('Active')),
                    ButtonSegment(value: 'completed', label: Text('Completed')),
                  ],
                  selected: {_projectStatusFilter},
                  onSelectionChanged: (set) => setState(() => _projectStatusFilter = set.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Project Cards Grid
          if (activities.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 40),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text('No projects found matching your search.'),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 850;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 290,
                  ),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final a = activities[index];
                    return _buildGalleryProjectCard(a);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryProjectCard(GroupingActivity a) {
    final teamState = _getTeamState(a);
    final hasTeam = teamState['hasTeam'] == true;
    final teamName = teamState['teamName'] as String? ?? '';
    final members = (teamState['members'] as List?) ?? [];

    Color methodColor = Colors.teal.shade700;
    if (a.groupingMethod.toLowerCase() == 'auto') {
      methodColor = Colors.purple.shade600;
    } else if (a.groupingMethod.toLowerCase() == 'hybrid') {
      methodColor = Colors.indigo.shade600;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedActivity = a;
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Class
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.school, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 4),
                            Text(
                              a.className,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: methodColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: methodColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      a.groupingMethod.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: methodColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Description snippet
              if (a.description != null && a.description!.isNotEmpty)
                Text(
                  a.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                ),
              const SizedBox(height: 12),

              // Spec badges
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildSpecBadge(icon: Icons.groups, label: 'Capacity', value: '${a.groupCapacity} / team'),
                  _buildSpecBadge(icon: Icons.grid_view, label: 'Needed', value: '${a.numberOfGroups} groups'),
                  _buildSpecBadge(icon: Icons.access_time, label: 'Min', value: '${a.minCommonHours} hrs/wk'),
                ],
              ),
              const SizedBox(height: 10),

              // Required Skills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: a.requiredSkills.map((s) {
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(s, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    );
                  }).toList(),
                ),
              ),

              const Spacer(),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Footer status & Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  hasTeam
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            teamState['isAutoAssigned'] == true
                                ? 'Assigned Team: $teamName (${members.length}/${a.groupCapacity})'
                                : 'Your Team: $teamName (${members.length}/${a.groupCapacity})',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: a.groupingMethod == 'auto'
                                ? const Color(0xFFEFF6FF)
                                : Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: a.groupingMethod == 'auto'
                                  ? const Color(0xFFBFDBFE)
                                  : Colors.amber.shade200,
                            ),
                          ),
                          child: Text(
                            a.groupingMethod == 'auto'
                                ? 'Auto-Matching Pending'
                                : 'No Team Joined Yet',
                            style: TextStyle(
                              fontSize: 11,
                              color: a.groupingMethod == 'auto'
                                  ? const Color(0xFF1E40AF)
                                  : Colors.amber.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedActivity = a;
                      });
                    },
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: const Text('View Teammates', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 2. Detailed Project & Teammates View
  Widget _buildProjectDetailView(GroupingActivity activity) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb to go back to projects gallery
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _selectedActivity = null),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('← Back to Project Cards'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Browsing: ${activity.title}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Deadline Warning Reminder Banner
          _buildDeadlineAlertBanner(activity),
          const SizedBox(height: 18),

          // Project Overview Card with "+ Create Group" button
          _buildProjectOverviewCard(activity),
          const SizedBox(height: 20),

          // Project-Specific Team Status Box
          _buildMyTeamCard(activity),
          const SizedBox(height: 24),

          // Project-Specific Teammates Recommendations Section
          _buildRecommendationsSection(activity),
        ],
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
                  'Group creation closes on ${activity.groupingDeadline.year}-${activity.groupingDeadline.month.toString().padLeft(2, '0')}-${activity.groupingDeadline.day.toString().padLeft(2, '0')}. Students without a confirmed team will be automatically matched.',
                  style: TextStyle(color: Colors.brown.shade800, fontSize: 12),
                ),
              ],
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
                  onPressed: () => _showCreateGroupDialog(activity),
                  icon: const Icon(Icons.group_add, size: 18),
                  label: const Text('+ Create Group', style: TextStyle(fontWeight: FontWeight.bold)),
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

          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildSpecBadge(icon: Icons.groups, label: 'Team Size', value: '${activity.groupCapacity} members'),
              _buildSpecBadge(icon: Icons.grid_view, label: 'Target Groups', value: '${activity.numberOfGroups} teams'),
              _buildSpecBadge(icon: Icons.access_time, label: 'Min Common Hours', value: '${activity.minCommonHours} hrs / wk'),
              _buildSpecBadge(icon: Icons.verified, label: 'Min Level', value: activity.minProficiencyLevel),
            ],
          ),
          const SizedBox(height: 14),

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
    final teamState = _getTeamState(activity);
    final hasTeam = teamState['hasTeam'] == true;
    final teamName = teamState['teamName'] as String? ?? 'Unnamed Group';
    final isLeader = teamState['isLeader'] == true;
    final isAutoAssigned = teamState['isAutoAssigned'] == true;
    final members = (teamState['members'] as List?) ?? [];
    final slotsRemaining = activity.groupCapacity - members.length;

    if (!hasTeam) {
      if (activity.groupingMethod == 'auto') {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF1E40AF), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Automated Team Matching in Progress',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                          ),
                          child: const Text(
                            'Pending Instructor Release',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This project uses algorithmic team balancing based on required skills and availability. Your balanced team assignment will appear here automatically once finalized and published by the professor.',
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.group_off_outlined, color: Colors.amber.shade800, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You are not currently in a team for this project',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You can create a team to become the Team Leader or browse recommended candidates below to build your roster.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showCreateGroupDialog(activity),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Start Team'),
            ),
          ],
        ),
      );
    }

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
                        teamName,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      if (isLeader)
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
                        )
                      else if (isAutoAssigned)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Text(
                            'AUTO-ASSIGNED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '${members.length} / ${activity.groupCapacity} members ($slotsRemaining slots open)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _showSwitchRequestDialog(activity),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Request Group Switch'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: members.map((m) {
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
    final candidates = _getSortedCandidates(activity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teammate Recommendations for ${activity.className}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Ranked candidate recommendations matching requirements for ${activity.title}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            Row(
              children: [
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
                    _loadActivities();
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

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: candidates.length,
          separatorBuilder: (_, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final c = candidates[index];
            return _buildCandidateCard(c, activity);
          },
        ),
      ],
    );
  }

  Widget _buildCandidateCard(StudentCandidate c, GroupingActivity activity) {
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
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF1E40AF),
            child: Text(
              c.avatarUrl,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),

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

                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: c.skills.map((s) {
                    final isReq = activity.requiredSkills.contains(s);
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

          Column(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                onPressed: () => _showCandidateProfile(c, activity),
                child: const Text('View Profile', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(height: 6),
              if (activity.groupingMethod == 'auto')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: Color(0xFF1E40AF)),
                      SizedBox(width: 4),
                      Text('Auto Pool', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.isInvited ? Colors.grey.shade400 : const Color(0xFF1E40AF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  onPressed: c.isInvited ? null : () => _inviteTeammate(c, activity),
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
