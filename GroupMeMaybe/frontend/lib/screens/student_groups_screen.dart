import 'package:flutter/material.dart';

import 'student_classes_screen.dart';
import 'widgets/bottom_right_notification.dart';
import 'widgets/portal_top_actions.dart';
import 'widgets/student_sidebar.dart';
import '../models/academic_class.dart';
import '../models/grouping_activity.dart';
import '../models/profile.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class CompatibilityResult {
  final double complementarySkills; // max 35
  final double sharedInterests; // max 20
  final double preferredRoles; // max 20
  final double availabilityOverlap; // max 15
  final double projectPreference; // max 10
  final double totalScore; // sum of above
  final String compatibilityTier; // "Highly compatible", "Good compatibility", "Moderate compatibility"
  final Color color;

  CompatibilityResult({
    required this.complementarySkills,
    required this.sharedInterests,
    required this.preferredRoles,
    required this.availabilityOverlap,
    required this.projectPreference,
    required this.totalScore,
    required this.compatibilityTier,
    required this.color,
  });
}

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

/// Simplified Student Groups Workspace implementing Workflow Steps 6, 7 & 8:
/// - Step 6: Compatibility Matching
/// - Step 7: Automated Team Formation
/// - Step 8: Student Review and Modification (Accept Group / Request Change)
class StudentGroupsScreen extends StatefulWidget {
  final int? initialActivityId;
  final int? initialClassId;
  final String? initialClassName;

  const StudentGroupsScreen({
    super.key,
    this.initialActivityId,
    this.initialClassId,
    this.initialClassName,
  });

  @override
  State<StudentGroupsScreen> createState() => _StudentGroupsScreenState();
}

class _StudentGroupsScreenState extends State<StudentGroupsScreen>
    with SingleTickerProviderStateMixin {
  final _activityService = ActivityService();
  final _profileService = ProfileService();

  late TabController _tabController;
  List<GroupingActivity> _activities = [];
  List<Profile> _allProfiles = [];
  List<AcademicClass> _enrolledClasses = [];
  GroupingActivity? _selectedActivity;

  bool _isLoading = true;
  String? _errorMessage;

  // Local state for user review status: 'suggested', 'accepted', 'under_review'
  String _groupReviewStatus = 'suggested';
  bool _isActionInProgress = false;
  bool _showingDetails = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialActivityId != null ||
        widget.initialClassId != null ||
        widget.initialClassName != null) {
      _showingDetails = true;
    }
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final activitiesFuture = _activityService.getActivities();
      final profilesFuture = _profileService.getProfiles();
      final classesFuture = _activityService.getClasses();

      final results = await Future.wait([activitiesFuture, profilesFuture, classesFuture]);
      final rawList = results[0] as List<GroupingActivity>;
      final profiles = results[1] as List<Profile>;
      final classes = results[2] as List<AcademicClass>;

      if (mounted) {
        setState(() {
          _enrolledClasses = classes;
          _allProfiles = profiles;

          // Only keep activities for classes the student is enrolled in
          final enrolledClassIds = classes.map((c) => c.id).whereType<int>().toSet();
          final list = rawList
              .where((a) => a.academicClassId != null && enrolledClassIds.contains(a.academicClassId))
              .toList();
          _activities = list;

          // Select matching activity
          if (widget.initialActivityId != null) {
            _selectedActivity = list.firstWhere(
              (a) => a.id == widget.initialActivityId,
              orElse: () => list.isNotEmpty ? list.first : null as dynamic,
            );
          } else if (widget.initialClassId != null || widget.initialClassName != null) {
            final matching = list.where((a) {
              if (widget.initialClassId != null && a.academicClassId == widget.initialClassId) {
                return true;
              }
              if (widget.initialClassName != null) {
                final cName = widget.initialClassName!.toLowerCase();
                final aClass = a.className.toLowerCase();
                return aClass.contains(cName.split(' - ').first.trim());
              }
              return false;
            }).toList();

            _selectedActivity = matching.isNotEmpty ? matching.first : (list.isNotEmpty ? list.first : null);
          } else if (list.isNotEmpty) {
            _selectedActivity = list.first;
          } else {
            _selectedActivity = null;
          }

          // Detect group status from activity teams
          if (_selectedActivity != null) {
            final team = _getStudentTeam(_selectedActivity!);
            if (team != null) {
              _groupReviewStatus = team['status']?.toString() ?? 'suggested';
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

  Map<String, dynamic>? _getStudentTeam(GroupingActivity activity) {
    final currentUser = AuthService.currentUser;
    final currentEmail = currentUser?.email.toLowerCase() ?? '';
    final currentName = currentUser?.name.toLowerCase() ?? '';

    final teams = activity.formedTeams;
    if (teams != null && teams.isNotEmpty) {
      for (final t in teams) {
        final teamMap = Map<String, dynamic>.from(t as Map);
        final members = (teamMap['members'] as List?) ?? [];
        for (final m in members) {
          final memberMap = Map<String, dynamic>.from(m as Map);
          final email = memberMap['email']?.toString().toLowerCase() ?? '';
          final name = memberMap['name']?.toString().toLowerCase() ?? '';
          final isCurrentUser = (currentEmail.isNotEmpty && email == currentEmail) ||
              (currentName.isNotEmpty && name.contains(currentName));
          if (isCurrentUser) {
            return teamMap;
          }
        }
      }
    }

    return null;
  }

  Future<void> _acceptGroup() async {
    if (_selectedActivity?.id == null) return;
    setState(() => _isActionInProgress = true);

    try {
      await _activityService.acceptGroup(
        _selectedActivity!.id!,
        email: AuthService.currentUser?.email,
      );
      if (mounted) {
        setState(() {
          _groupReviewStatus = 'accepted';
          _isActionInProgress = false;
        });
        AppNotification.showSuccess(
          context,
          'Group assignment officially accepted! Final assignments will be published soon.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _groupReviewStatus = 'accepted';
          _isActionInProgress = false;
        });
        AppNotification.showSuccess(
          context,
          'Group assignment accepted!',
        );
      }
    }
  }

  Future<void> _handleRespondJoin(
    int activityId,
    String teamName,
    String studentEmail,
    String studentName,
    String action,
  ) async {
    setState(() => _isActionInProgress = true);
    try {
      final res = await _activityService.respondJoinRequest(
        activityId,
        teamName: teamName,
        studentEmail: studentEmail,
        action: action,
      );
      await _loadData();
      if (mounted) {
        setState(() => _isActionInProgress = false);
        if (action == 'accept') {
          AppNotification.showSuccess(
            context,
            res['message']?.toString() ?? 'Accepted $studentName into $teamName!',
          );
        } else {
          AppNotification.showInfo(
            context,
            res['message']?.toString() ?? 'Declined join request from $studentName.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionInProgress = false);
        AppNotification.showError(
          context,
          'Action Failed',
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _handleRespondAllJoin(
    int activityId,
    String teamName,
    String action,
  ) async {
    setState(() => _isActionInProgress = true);
    try {
      final res = await _activityService.respondAllJoinRequests(
        activityId,
        teamName: teamName,
        action: action,
      );
      await _loadData();
      if (mounted) {
        setState(() => _isActionInProgress = false);
        if (action == 'accept_all') {
          AppNotification.showSuccess(
            context,
            res['message']?.toString() ?? 'Accepted all pending requests for $teamName!',
          );
        } else {
          AppNotification.showInfo(
            context,
            res['message']?.toString() ?? 'Declined all pending requests for $teamName.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionInProgress = false);
        AppNotification.showError(
          context,
          'Action Failed',
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  int calculateBalanceScore(GroupingActivity activity, Map<String, dynamic>? team) {
    if (team == null) return 0;
    if (team['balance_score'] != null && team['balance_score'] is num && (team['balance_score'] as num) > 0) {
      return (team['balance_score'] as num).toInt();
    }
    final members = ((team['members'] as List?) ?? [])
        .map((m) => Map<String, dynamic>.from(m as Map))
        .where((m) => m['status'] != 'pending' && m['is_pending'] != true)
        .toList();

    if (members.isEmpty) return 0;

    // 1. Capacity score (20%)
    final targetSize = activity.groupCapacity > 0 ? activity.groupCapacity : 4;
    final capacityRatio = (members.length / targetSize).clamp(0.0, 1.0);
    final capacityScore = capacityRatio * 20.0;

    // 2. Skill coverage score (60%)
    final reqSkills = activity.requiredSkills.map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty).toSet();
    double skillScore = 0.0;
    if (reqSkills.isEmpty) {
      skillScore = 60.0;
    } else {
      final coveredSkills = <String>{};
      for (final m in members) {
        final mSkills = (m['skills'] as List?)?.map((s) => s.toString().trim().toLowerCase()) ?? [];
        for (final s in mSkills) {
          if (reqSkills.contains(s)) {
            coveredSkills.add(s);
          }
        }
      }
      skillScore = (coveredSkills.length / reqSkills.length).clamp(0.0, 1.0) * 60.0;
    }

    // 3. Role diversity score (20%)
    final roles = members.map((m) => (m['role'] ?? 'Member').toString().trim().toLowerCase()).toSet();
    final roleScore = (roles.length / 3.0).clamp(0.0, 1.0) * 20.0;

    final total = (capacityScore + skillScore + roleScore).round();
    return total.clamp(15, 100);
  }

  void _showSubmitEvaluationDialog(GroupingActivity activity, Map<String, dynamic> team) {
    final teamName = team['name']?.toString() ?? 'Your Team';
    final members = ((team['members'] as List?) ?? [])
        .map((m) => Map<String, dynamic>.from(m as Map))
        .where((m) => m['status'] != 'pending' && m['is_pending'] != true)
        .toList();

    final reqSkills = activity.requiredSkills.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final coveredSkills = <String>{};
    final scarceSkills = <String>[];

    final allMemberSkills = <String>{};
    for (final m in members) {
      final sList = (m['skills'] as List?)?.map((s) => s.toString().trim().toLowerCase()) ?? [];
      allMemberSkills.addAll(sList);
    }

    for (final req in reqSkills) {
      if (allMemberSkills.contains(req.toLowerCase())) {
        coveredSkills.add(req);
      } else {
        scarceSkills.add(req);
      }
    }

    final balanceScore = calculateBalanceScore(activity, team);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.rate_review_outlined, color: Color(0xFF1E40AF)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Submit Group for Evaluation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit "$teamName" to your professor for project evaluation. The system automatically inspects your roster for skill coverage and scarce requirements.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Group Balance Score', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(
                            '$balanceScore%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: balanceScore >= 70 ? const Color(0xFF059669) : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Active Members', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(
                            '${members.length} / ${activity.groupCapacity}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Required Skill Analysis',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                if (reqSkills.isEmpty)
                  const Text('No specific skills mandated by the instructor for this project.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
                else ...[
                  if (coveredSkills.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Color(0xFF059669)),
                        const SizedBox(width: 6),
                        Text('Covered Skills (${coveredSkills.length}):', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: coveredSkills.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 11, color: Color(0xFF065F46), fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (scarceSkills.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                        const SizedBox(width: 6),
                        Text('Scarce / Missing Skills (${scarceSkills.length}):', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: scarceSkills.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B), fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Text(
                        'Note: Submitting with scarce skills will alert your professor. They can help balance your squad or suggest complementary candidates.',
                        style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, size: 16, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Great job! Your squad covers 100% of required project skills.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF065F46), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Submit to Professor', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isActionInProgress = true);
              try {
                final res = await _activityService.submitGroupEvaluation(
                  activity.id!,
                  teamName: teamName,
                );
                await _loadData();
                if (mounted) {
                  setState(() => _isActionInProgress = false);
                  final msg = res['message']?.toString() ?? 'Group submitted for professor evaluation!';
                  AppNotification.showSuccess(context, msg);
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isActionInProgress = false);
                  AppNotification.showError(
                    context,
                    'Submission Failed',
                    e.toString().replaceAll('Exception: ', ''),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showRequestChangeDialog() {
    final reasonController = TextEditingController();
    String selectedReason = 'Schedule conflict';
    String? selectedSwapPeer;

    final peers = _allProfiles
        .where((p) => p.email.toLowerCase() != (AuthService.currentUser?.email.toLowerCase() ?? ''))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.swap_horiz, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Request Group Change', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Workflow Step 8: Modification Request',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Submit your request to the professor for review and evaluation.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),

              const Text('Reason for Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: [
                  'Schedule conflict',
                  'Request to swap with peer',
                  'Complementary skill preference',
                  'Request reconsideration',
                ]
                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedReason = val);
                },
              ),
              const SizedBox(height: 12),

              if (selectedReason.contains('swap')) ...[
                const Text('Preferred Swap Partner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'Select classmate to swap with',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: peers
                      .map((p) => DropdownMenuItem(value: p.name, child: Text('${p.name} (${p.preferredRole})', style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) => setModalState(() => selectedSwapPeer = val),
                ),
                const SizedBox(height: 12),
              ],

              const Text('Additional Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Brief explanation for instructor evaluation...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() {
                  _groupReviewStatus = 'under_review';
                });

                if (_selectedActivity?.id != null) {
                  try {
                    await _activityService.requestChange(
                      _selectedActivity!.id!,
                      reason: selectedReason,
                      preferredSwap: selectedSwapPeer,
                      studentName: AuthService.currentUser?.name,
                      studentEmail: AuthService.currentUser?.email,
                    );
                  } catch (_) {}
                }

                if (mounted) {
                  AppNotification.showInfo(
                    context,
                    'Modification request submitted! Your group status is now Under Review by the professor.',
                  );
                }
              },
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog({GroupingActivity? preselectedActivity}) {
    if (_activities.isEmpty) {
      AppNotification.showWarning(context, 'No available subjects or activities to create a group for.');
      return;
    }
    final nameController = TextEditingController();
    GroupingActivity selectedActivity = preselectedActivity ?? _selectedActivity ?? _activities.first;
    String selectedRole = 'Project leader / team leader';
    final availableRoles = [
      'Project leader / team leader',
      'Frontend developer',
      'Backend developer',
      'Full-stack developer',
      'Mobile app developer',
      'UI / UX designer',
      'Database administrator',
      'System analyst',
      'QA / software tester',
      'Technical writer / documentation specialist',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.group_add, color: Color(0xFF1E40AF)),
              SizedBox(width: 10),
              Text('Create Your Own Group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Form a new team for your subject project. You will automatically become the group leader.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Subject / Activity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<GroupingActivity>(
                        isExpanded: true,
                        value: selectedActivity,
                        items: _activities.map((a) => DropdownMenuItem(
                          value: a,
                          child: Text('${a.className} - ${a.title}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedActivity = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Group / Team Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Binary Beasts, Code Wizards',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Your Role in this Group', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedRole,
                        items: availableRoles.map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r, style: const TextStyle(fontSize: 13)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedRole = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final teamName = nameController.text.trim();
                if (teamName.isEmpty) {
                  AppNotification.showWarning(context, 'Please enter a group name.');
                  return;
                }
                final leaderRole = selectedRole.toLowerCase().contains('leader')
                    ? selectedRole
                    : '$selectedRole (Leader)';
                Navigator.pop(ctx);
                setState(() => _isActionInProgress = true);

                try {
                  final user = AuthService.currentUser;
                  await _activityService.createTeam(
                    selectedActivity.id!,
                    teamName,
                    role: leaderRole,
                    leaderName: user?.name ?? 'Student Leader',
                    leaderEmail: user?.email ?? 'student@university.edu',
                  );
                  await _loadData();
                  if (mounted) {
                    setState(() {
                      _isActionInProgress = false;
                      _selectedActivity = _activities.firstWhere((a) => a.id == selectedActivity.id, orElse: () => selectedActivity);
                      _showingDetails = true;
                    });
                    AppNotification.showSuccess(
                      context,
                      'Group "$teamName" created successfully!',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isActionInProgress = false);
                    AppNotification.showError(
                      context,
                      'Creation Error',
                      e.toString().replaceAll('Exception: ', ''),
                    );
                  }
                }
              },
              child: const Text('Create Team'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _getUserMembership(Map<String, dynamic> team) {
    final user = AuthService.currentUser;
    final currentEmail = user?.email.toLowerCase() ?? '';
    final currentName = user?.name.toLowerCase() ?? '';
    final members = (team['members'] as List?) ?? [];
    for (final m in members) {
      final map = Map<String, dynamic>.from(m as Map);
      final email = map['email']?.toString().toLowerCase() ?? '';
      final name = map['name']?.toString().toLowerCase() ?? '';
      if ((currentEmail.isNotEmpty && email == currentEmail) ||
          (currentName.isNotEmpty && name.contains(currentName))) {
        return map;
      }
    }
    return null;
  }

  bool _isUserOfficialMember(Map<String, dynamic> team) {
    final m = _getUserMembership(team);
    if (m == null) return false;
    final status = m['status']?.toString().toLowerCase() ?? '';
    final isPending = m['is_pending'] == true || status == 'pending';
    return !isPending;
  }

  bool _isUserPendingMember(Map<String, dynamic> team) {
    final m = _getUserMembership(team);
    if (m == null) return false;
    final status = m['status']?.toString().toLowerCase() ?? '';
    return m['is_pending'] == true || status == 'pending';
  }

  void _showJoinTeamDialog(GroupingActivity activity, String teamName) {
    final user = AuthService.currentUser;
    final availableRoles = [
      'Developer',
      'Frontend developer',
      'Backend developer',
      'Full-stack developer',
      'Mobile app developer',
      'UI / UX designer',
      'Database administrator',
      'System analyst',
      'QA / software tester',
      'Technical writer / documentation specialist',
    ];
    String selectedRole = availableRoles.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.group_add, color: Color(0xFF1E40AF)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Join $teamName',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to join $teamName for "${activity.title}"?',
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your Role in Team',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: availableRoles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selectedRole = val);
                  }
                },
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isActionInProgress = true);
                try {
                  await _activityService.joinTeam(
                    activity.id!,
                    teamName: teamName,
                    studentName: user?.name ?? 'Student Member',
                    studentEmail: user?.email ?? 'student@university.edu',
                    role: selectedRole,
                  );
                  await _loadData();
                  if (mounted) {
                    setState(() {
                      _isActionInProgress = false;
                      _selectedActivity = _activities.firstWhere(
                        (a) => a.id == activity.id,
                        orElse: () => activity,
                      );
                      _showingDetails = true;
                    });
                    AppNotification.showSuccess(
                      context,
                      'Join request submitted to $teamName! Awaiting approval from the team leader.',
                    );
                    _tabController.animateTo(0);
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isActionInProgress = false);
                    AppNotification.showError(
                      context,
                      'Failed to join team',
                      e.toString().replaceAll('Exception: ', ''),
                    );
                  }
                }
              },
              child: const Text('Confirm & Join'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsAndGroupsCardsView() {
    final totalProjects = _activities.length;
    final openProjects = _activities.where((a) => a.status.toLowerCase() != 'completed').length;
    final studentMadeProjects = _activities.where((a) => a.groupingMethod == 'student_formed').length;
    final autoFormedProjects = _activities.where((a) => a.groupingMethod != 'student_formed').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Projects',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Browse your class projects, manage your squad, or create and join a team.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showCreateGroupDialog(),
                icon: const Icon(Icons.group_add, size: 16),
                label: const Text('Create Team'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Summary Metric Cards (Matching Professor Project View)
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Projects',
                  value: '$totalProjects',
                  subtitle: 'Enrolled in classes',
                  icon: Icons.assignment_outlined,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Open / In-Progress',
                  value: '$openProjects',
                  subtitle: 'Team formation active',
                  icon: Icons.pending_actions_outlined,
                  color: const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Auto-Formed',
                  value: '$autoFormedProjects',
                  subtitle: 'Skill-balanced system',
                  icon: Icons.auto_awesome_outlined,
                  color: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Student-Made',
                  value: '$studentMadeProjects',
                  subtitle: 'Self-selected squads',
                  icon: Icons.groups_outlined,
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_enrolledClasses.isEmpty)
            Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_outlined, size: 40, color: Color(0xFF1E40AF)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Not Enrolled in Any Classes Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Groups and projects are only visible once you enroll in your classes. Join a class using your instructor\'s class code to view active projects and join or create squads.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StudentClassesScreen()),
                      ).then((_) => _loadData());
                    },
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: const Text('Go to Classes & Enroll', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            )
          else if (_activities.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Icon(Icons.assignment_outlined, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 12),
                  Text('No class projects found.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  SizedBox(height: 4),
                  Text('Your professors have not published any grouping projects for your enrolled classes yet.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 600 ? 2 : 1);
                final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _activities.map((activity) {
                    final studentTeam = _getStudentTeam(activity);
                    final hasTeam = studentTeam != null;
                    final isPendingInTeam = hasTeam && _isUserPendingMember(studentTeam);
                    final teamName = studentTeam?['name']?.toString() ?? 'Unassigned';
                    final teamStatus = studentTeam?['status']?.toString() ?? 'Pending Group Formation';
                    final members = (studentTeam?['members'] as List?) ?? [];
                    final balanceScore = calculateBalanceScore(activity, studentTeam);

                    return SizedBox(
                      width: cardWidth,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isPendingInTeam
                                ? const Color(0xFFFDE68A)
                                : (hasTeam ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
                          ),
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
                            // Subject Code & Grouping Method Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    activity.className,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: activity.groupingMethod == 'student_formed'
                                        ? const Color(0xFFF3E8FF)
                                        : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    activity.groupingMethod == 'student_formed' ? 'Student-Made' : 'Auto-Formed',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: activity.groupingMethod == 'student_formed'
                                          ? const Color(0xFF7E22CE)
                                          : const Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    activity.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2563EB),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPendingInTeam
                                        ? const Color(0xFFFFFBEB)
                                        : (hasTeam ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB)),
                                    borderRadius: BorderRadius.circular(4),
                                    border: isPendingInTeam
                                        ? Border.all(color: const Color(0xFFFDE68A))
                                        : null,
                                  ),
                                  child: Text(
                                    isPendingInTeam ? 'Request Pending ⏳' : (hasTeam ? teamStatus : 'No Team Yet'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isPendingInTeam
                                          ? const Color(0xFFD97706)
                                          : (hasTeam ? const Color(0xFF059669) : const Color(0xFFD97706)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (activity.description != null && activity.description!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                activity.description!,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Divider(color: Color(0xFFF1F5F9), height: 1),
                            const SizedBox(height: 10),

                            // Group Details Info
                            if (hasTeam) ...[
                              Row(
                                children: [
                                  const Icon(Icons.groups, size: 16, color: Color(0xFF1E40AF)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      teamName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Balance: $balanceScore%',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF047857),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Members Avatars
                              Row(
                                children: [
                                  ...members.take(4).map((m) {
                                    final mName = (m['name'] ?? 'M').toString();
                                    return Container(
                                      margin: const EdgeInsets.only(right: 4),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: const Color(0xFF1E40AF),
                                        child: Text(
                                          mName.isNotEmpty ? mName[0].toUpperCase() : 'M',
                                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    );
                                  }),
                                  if (members.length > 4)
                                    Text('+${members.length - 4}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  const Spacer(),
                                  Text(
                                    '${members.length} member${members.length == 1 ? '' : 's'}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Row(
                                children: const [
                                  Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Awaiting team assignment or creation',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 14),
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedActivity = activity;
                                        _showingDetails = true;
                                        final team = _getStudentTeam(activity);
                                        if (team != null) {
                                          _groupReviewStatus = team['status']?.toString() ?? 'suggested';
                                        }
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF1E40AF),
                                      side: const BorderSide(color: Color(0xFF93C5FD)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('View Project & Teams →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Create Team for this Project',
                                  icon: const Icon(Icons.group_add_outlined, size: 18, color: Color(0xFF1E40AF)),
                                  onPressed: () => _showCreateGroupDialog(preselectedActivity: activity),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
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
          const StudentSidebar(currentDestination: StudentNavDestination.groups),
          Expanded(
            child: Column(
              children: [
                _buildHeaderBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Error loading groups: $_errorMessage'),
                                  const SizedBox(height: 10),
                                  ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                                ],
                              ),
                            )
                          : (!_showingDetails || _selectedActivity == null)
                              ? _buildSubjectsAndGroupsCardsView()
                              : TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildYourSuggestedGroupTab(),
                                    _buildAllGeneratedGroupsTab(),
                                  ],
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar() {
    final activity = _selectedActivity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_showingDetails) ...[
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showingDetails = false),
                  icon: const Icon(Icons.arrow_back, size: 14),
                  label: const Text('← All Projects', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  _showingDetails && activity != null
                      ? '${activity.className} • ${activity.title}'
                      : 'Projects',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              if (!_showingDetails) ...[
                FilledButton.icon(
                  onPressed: () => _showCreateGroupDialog(),
                  icon: const Icon(Icons.group_add, size: 14),
                  label: const Text('Create Team', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (_showingDetails && _activities.length > 1) ...[
                const SizedBox(width: 8),
                DropdownButton<GroupingActivity>(
                  value: _selectedActivity,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                  items: _activities
                      .map((a) => DropdownMenuItem(value: a, child: Text(a.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))))
                      .toList(),
                  onChanged: (a) {
                    if (a != null) {
                      setState(() {
                        _selectedActivity = a;
                        final team = _getStudentTeam(a);
                        if (team != null) {
                          _groupReviewStatus = team['status']?.toString() ?? 'suggested';
                        }
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
              const PortalTopActions(),
            ],
          ),
          if (_showingDetails) ...[
            const SizedBox(height: 10),

            // 2 Tabs for Project Squads & Overview
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF059669),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF059669),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.stars, size: 18), text: 'Your Team'),
                Tab(icon: Icon(Icons.groups, size: 18), text: 'All Teams & Squads'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// ───────────────────────── TAB 1: STEP 8 ─────────────────────────
  /// "Student Review and Modification"
  Widget _buildYourSuggestedGroupTab() {
    final activity = _selectedActivity!;
    final team = _getStudentTeam(activity);
    final members = (team?['members'] as List?) ?? [];
    final balanceScore = calculateBalanceScore(activity, team);
    final teamName = team?['name']?.toString() ?? 'Group';

    if (team == null || members.isEmpty) {
      final isStudentMade = activity.groupingMethod == 'student_formed';
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner explaining grouping method
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF1E40AF), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isStudentMade
                              ? 'This project uses Student-Made groupings. Students form squads and join open slots up to ${activity.groupCapacity} members.'
                              : 'This project uses Auto-Formed groupings. You can browse open squads, or create a squad directly.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Friendly Empty State Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.groups_outlined,
                          size: 48,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Team Assigned Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isStudentMade
                            ? 'You are not yet a member of any squad for "${activity.title}".\nCreate a new team as a leader or browse open squads in the All Teams tab to join.'
                            : 'You are currently unassigned in "${activity.title}".\nCreate a new team now or browse open squads with available slots to join.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _showCreateGroupDialog(preselectedActivity: activity),
                            icon: const Icon(Icons.group_add, size: 16),
                            label: const Text('Create Team'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1E40AF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _tabController.animateTo(1),
                            icon: const Icon(Icons.search, size: 16),
                            label: const Text('Browse & Join Team'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E40AF),
                              side: const BorderSide(color: Color(0xFF93C5FD)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isAccepted = _groupReviewStatus == 'accepted';
    final isUnderReview = _groupReviewStatus == 'under_review';

    final currentUser = AuthService.currentUser;
    final currentEmail = currentUser?.email.toLowerCase() ?? '';
    final currentName = currentUser?.name.toLowerCase() ?? '';
    final leaderEmail = team['leader_email']?.toString().toLowerCase() ?? '';

    Map<String, dynamic>? currentMemberMap;
    for (final m in members) {
      final map = Map<String, dynamic>.from(m as Map);
      final email = map['email']?.toString().toLowerCase() ?? '';
      final name = map['name']?.toString().toLowerCase() ?? '';
      if ((currentEmail.isNotEmpty && email == currentEmail) ||
          (currentName.isNotEmpty && name.contains(currentName))) {
        currentMemberMap = map;
        break;
      }
    }

    final isCurrentUserPending = currentMemberMap != null &&
        (currentMemberMap['status'] == 'pending' || currentMemberMap['is_pending'] == true);

    bool isCurrentUserLeader = false;
    if (currentEmail.isNotEmpty && leaderEmail.isNotEmpty && leaderEmail == currentEmail) {
      isCurrentUserLeader = true;
    }
    if (currentMemberMap != null) {
      final isLeader = currentMemberMap['is_leader'] == true ||
          (currentMemberMap['role']?.toString().toLowerCase().contains('leader') ?? false);
      if (isLeader) isCurrentUserLeader = true;
    }

    final pendingRequests = members
        .map((m) => Map<String, dynamic>.from(m as Map))
        .where((m) => m['status'] == 'pending' || m['is_pending'] == true)
        .toList();

    final officialMembers = members
        .map((m) => Map<String, dynamic>.from(m as Map))
        .where((m) => m['status'] != 'pending' && m['is_pending'] != true)
        .toList();

    final totalOfficial = officialMembers.length;
    final acceptedOfficial = officialMembers.where((m) => m['status'] == 'accepted').length;

    // Display roster: official members first; if current user is pending, also append their pending entry
    final displayRoster = <Map<String, dynamic>>[...officialMembers];
    if (isCurrentUserPending) {
      displayRoster.add(currentMemberMap);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending Approval Banner for Applicant
              if (isCurrentUserPending) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD97706),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Join Request Pending Leader Approval ⏳',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'You requested to join $teamName as ${currentMemberMap['role'] ?? 'Member'}. You will officially join once the squad leader accepts your request.',
                              style: const TextStyle(fontSize: 13, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Pending Join Requests Box (Visible to Squad Leader)
              if (isCurrentUserLeader && pendingRequests.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person_add, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pending Join Requests (${pendingRequests.length})',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Students who requested to join your squad. Accept or decline their requests.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                                ),
                              ],
                            ),
                          ),
                          if (pendingRequests.isNotEmpty) ...[
                            ElevatedButton.icon(
                              onPressed: _isActionInProgress
                                  ? null
                                  : () => _handleRespondAllJoin(activity.id!, teamName, 'accept_all'),
                              icon: const Icon(Icons.done_all, size: 14),
                              label: const Text('Accept All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton.icon(
                              onPressed: _isActionInProgress
                                  ? null
                                  : () => _handleRespondAllJoin(activity.id!, teamName, 'decline_all'),
                              icon: const Icon(Icons.close, size: 14),
                              label: const Text('Decline All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFFCA5A5)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pendingRequests.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final req = pendingRequests[idx];
                          final reqName = req['name']?.toString() ?? 'Student';
                          final reqEmail = req['email']?.toString() ?? '';
                          final reqRole = req['role']?.toString() ?? 'Developer';
                          final reqAvatar = req['avatar']?.toString() ?? (reqName.isNotEmpty ? reqName.substring(0, 1).toUpperCase() : 'S');

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFFDC2626),
                                  child: Text(
                                    reqAvatar,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reqName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Role: $reqRole • $reqEmail',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: _isActionInProgress
                                      ? null
                                      : () => _handleRespondJoin(activity.id!, teamName, reqEmail, reqName, 'accept'),
                                  icon: const Icon(Icons.check, size: 14),
                                  label: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _isActionInProgress
                                      ? null
                                      : () => _handleRespondJoin(activity.id!, teamName, reqEmail, reqName, 'decline'),
                                  icon: const Icon(Icons.close, size: 14),
                                  label: const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFDC2626),
                                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],

              // Step 8 Info Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFF1E40AF), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Step 8: Review your suggested group balanced by skills and availability. Accept your group or request a modification from your professor.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Step 10 Celebration Banner (when activity is completed or student accepted)
              if (activity.status.toLowerCase() == 'completed' || isAccepted) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF059669),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Grouping Successfully Finalized! 🎉',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${activity.className} - ${activity.title} • Official group assignments published',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Your Suggested Group Card (matching Step 8 in infographic)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: Group Name, Balance Score, Status Pill
                    Row(
                      children: [
                        Text(
                          teamName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 12),

                        // Balance score pill (green)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            '$balanceScore% balance score',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                          ),
                        ),
                        const Spacer(),

                        // Status pill
                        if (isCurrentUserPending)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.hourglass_top, size: 12, color: Color(0xFFD97706)),
                                SizedBox(width: 4),
                                Text(
                                  'Request Pending Approval',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAccepted
                                  ? const Color(0xFFECFDF5)
                                  : (isUnderReview ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAccepted
                                    ? const Color(0xFFA7F3D0)
                                    : (isUnderReview ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A)),
                              ),
                            ),
                            child: Text(
                              isAccepted
                                  ? 'Your Acceptance Recorded ✓'
                                  : (isUnderReview
                                      ? 'Change Under Review'
                                      : 'Review in Progress ($acceptedOfficial/$totalOfficial Confirmed)'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAccepted
                                    ? const Color(0xFF059669)
                                    : (isUnderReview ? const Color(0xFF2563EB) : const Color(0xFFD97706)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isCurrentUserPending
                          ? 'Your request to join this squad has been submitted. Waiting for team leader approval before you become an official member.'
                          : (isCurrentUserLeader
                              ? 'You are the leader of this squad. Manage incoming join requests and lead your team for "${activity.title}".'
                              : (isAccepted
                                  ? 'You have accepted this group! Waiting for all teammates to confirm or for the professor to officially finalize groupings.'
                                  : 'Review your suggested group. Each teammate confirms their assignment individually before the group is officially locked.')),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Team Roster list
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayRoster.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final m = displayRoster[index];
                        final rawName = m['name']?.toString() ?? 'Student';
                        final cleanName = rawName.replaceAll(RegExp(r'\s*\(You\)', caseSensitive: false), '').trim();
                        final memberEmail = m['email']?.toString().toLowerCase() ?? '';
                        final rawRole = m['role']?.toString() ?? 'Developer';
                        final isMemberLeader = m['is_leader'] == true ||
                            (leaderEmail.isNotEmpty && memberEmail == leaderEmail);
                        final role = (isMemberLeader && !rawRole.toLowerCase().contains('leader'))
                            ? '$rawRole (Leader)'
                            : rawRole;
                        final avatar = m['avatar']?.toString() ?? (cleanName.isNotEmpty ? cleanName.substring(0, 1).toUpperCase() : 'S');
                        final isPending = m['status'] == 'pending' || m['is_pending'] == true;

                        final isProfessor = currentUser?.role.toLowerCase() == 'professor';
                        final isSelf = !isProfessor && (
                          (currentEmail.isNotEmpty && memberEmail == currentEmail) ||
                          (currentName.isNotEmpty && cleanName.toLowerCase() == currentName)
                        );

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isPending
                                ? const Color(0xFFFFFBEB)
                                : (isSelf ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isPending
                                  ? const Color(0xFFFDE68A)
                                  : (isSelf ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isPending
                                    ? const Color(0xFFD97706)
                                    : (isSelf ? const Color(0xFF1E40AF) : const Color(0xFF059669)),
                                child: Text(
                                  avatar,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                                          cleanName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelf ? FontWeight.bold : FontWeight.w600,
                                            color: isPending
                                                ? const Color(0xFF92400E)
                                                : (isSelf ? const Color(0xFF1E40AF) : const Color(0xFF0F172A)),
                                          ),
                                        ),
                                        if (isSelf) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isPending ? 'You (Pending)' : 'You',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isPending ? const Color(0xFFB45309) : const Color(0xFF1E40AF),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(role, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  role,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Teammate's Individual Review Status Pill
                              if (isPending)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.hourglass_top, size: 11, color: Color(0xFFD97706)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Pending Approval',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (isMemberLeader)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shield, size: 11, color: Color(0xFF1E40AF)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Team Leader',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E40AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Builder(
                                  builder: (_) {
                                    final mStatus = m['status']?.toString() ?? 'suggested';
                                    final confirmed = mStatus == 'accepted' || (isSelf && isAccepted);
                                    final underReview = mStatus == 'under_review';

                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: confirmed
                                            ? const Color(0xFFECFDF5)
                                            : (underReview ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB)),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: confirmed
                                              ? const Color(0xFFA7F3D0)
                                              : (underReview ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A)),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            confirmed
                                                ? Icons.check
                                                : (underReview ? Icons.sync : Icons.schedule),
                                            size: 11,
                                            color: confirmed
                                                ? const Color(0xFF059669)
                                                : (underReview ? const Color(0xFF2563EB) : const Color(0xFFD97706)),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            confirmed
                                                ? 'Accepted'
                                                : (underReview ? 'Under Review' : 'Reviewing'),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: confirmed
                                                  ? const Color(0xFF059669)
                                                  : (underReview ? const Color(0xFF2563EB) : const Color(0xFFD97706)),
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
                      },
                    ),

                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    // Actions Row (Request change, Leader badge, Pending indicator, or Accept group)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showRequestChangeDialog,
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          label: const Text('Request Change', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        if (isCurrentUserLeader) ...[
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF93C5FD)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield, size: 16, color: Color(0xFF1E40AF)),
                                SizedBox(width: 6),
                                Text(
                                  'Team Leader',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (team['status'] == 'Submitted for Evaluation')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 16, color: Color(0xFF059669)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Submitted for Evaluation ✓',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF065F46),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _isActionInProgress ? null : () => _showSubmitEvaluationDialog(activity, team),
                              icon: const Icon(Icons.rate_review_outlined, size: 16),
                              label: const Text('Submit Group for Evaluation', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E40AF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                        ] else if (team['status'] == 'Submitted for Evaluation') ...[
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 16, color: Color(0xFF059669)),
                                SizedBox(width: 6),
                                Text(
                                  'Submitted for Evaluation ✓',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (isCurrentUserPending) ...[
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFD97706)),
                                SizedBox(width: 6),
                                Text(
                                  'Awaiting Leader Approval',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 14),
                          ElevatedButton.icon(
                            onPressed: (isAccepted || _isActionInProgress) ? null : _acceptGroup,
                            icon: isAccepted
                                ? const Icon(Icons.check_circle, size: 18)
                                : const Icon(Icons.thumb_up_alt_outlined, size: 18),
                            label: Text(
                              isAccepted ? 'Group Accepted' : 'Accept Group',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ───────────────────────── TAB 2: ALL TEAMS & SQUADS ─────────────────────────
  Widget _buildAllGeneratedGroupsTab() {
    final activity = _selectedActivity!;
    final teams = activity.formedTeams ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 7 Info Banner & Actions
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE9D5FF)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF7E22CE), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              activity.groupingMethod == 'student_formed'
                                  ? 'Student-Made Teams: Browse existing squads below. You can join any squad with open slots or create a new team.'
                                  : 'Auto-Formed Teams: System-balanced team compositions. You can join open squads or create a team.',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B21A8), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _showCreateGroupDialog(preselectedActivity: activity),
                    icon: const Icon(Icons.group_add, size: 14),
                    label: const Text('Create Team', style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (teams.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.group_off_outlined, size: 40, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 10),
                        const Text('No teams have been created or formed yet for this project.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _showCreateGroupDialog(preselectedActivity: activity),
                          icon: const Icon(Icons.group_add, size: 14),
                          label: const Text('Create the First Team'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E40AF),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final t = Map<String, dynamic>.from(teams[index] as Map);
                    final name = t['name']?.toString() ?? 'Group ${index + 1}';
                    final score = calculateBalanceScore(activity, t);
                    final members = (t['members'] as List?) ?? [];
                    final officialMembers = members.where((m) => m is Map && m['status'] != 'pending' && m['is_pending'] != true).toList();
                    final pendingMembers = members.where((m) => m is Map && (m['status'] == 'pending' || m['is_pending'] == true)).toList();
                    final capacity = activity.groupCapacity;
                    final isOfficialUser = _isUserOfficialMember(t);
                    final isPendingUser = _isUserPendingMember(t);
                    final hasOpenSlots = members.length < capacity;

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOfficialUser
                              ? const Color(0xFF93C5FD)
                              : (isPendingUser ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
                          width: (isOfficialUser || isPendingUser) ? 1.8 : 1.0,
                        ),
                        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('$score%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Expanded(
                            child: members.isEmpty
                                ? const Center(
                                    child: Text('No members in this team yet', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                  )
                                : ListView.separated(
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: members.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                                    itemBuilder: (context, mIdx) {
                                      final m = Map<String, dynamic>.from(members[mIdx] as Map);
                                      final mName = m['name']?.toString() ?? 'Student';
                                      final mRole = m['role']?.toString() ?? 'Developer';
                                      final isMemberLeader = m['is_leader'] == true ||
                                          (t['leader_email'] != null && t['leader_email'].toString().toLowerCase() == (m['email']?.toString().toLowerCase() ?? ''));
                                      final displayRole = (isMemberLeader && !mRole.toLowerCase().contains('leader'))
                                          ? '$mRole (Leader)'
                                          : mRole;
                                      final isPending = m['status'] == 'pending' || m['is_pending'] == true;
                                      final avatar = m['avatar']?.toString() ?? (mName.isNotEmpty ? mName.substring(0, 1).toUpperCase() : 'S');

                                      return Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: isPending ? const Color(0xFFD97706) : const Color(0xFF1E40AF),
                                            child: Text(avatar, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    mName,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: isPending ? const Color(0xFF92400E) : const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ),
                                                if (isPending) ...[
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEF3C7),
                                                      borderRadius: BorderRadius.circular(3),
                                                    ),
                                                    child: const Text('Pending', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Text(displayRole, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${officialMembers.length}/$capacity Members${pendingMembers.isNotEmpty ? ' (${pendingMembers.length} req)' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: officialMembers.length >= capacity ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                ),
                              ),
                              if (isOfficialUser)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: const Text(
                                    '✓ Your Team',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                  ),
                                )
                              else if (isPendingUser)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.hourglass_top, size: 11, color: Color(0xFFD97706)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Request Pending',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                      ),
                                    ],
                                  ),
                                )
                              else if (hasOpenSlots)
                                FilledButton.icon(
                                  onPressed: () => _showJoinTeamDialog(activity, name),
                                  icon: const Icon(Icons.person_add_alt_1, size: 12),
                                  label: const Text('Join Team', style: TextStyle(fontSize: 11)),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E40AF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Team Full',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
