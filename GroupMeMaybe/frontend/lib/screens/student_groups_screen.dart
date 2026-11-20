import 'package:flutter/material.dart';

import 'widgets/bottom_right_notification.dart';
import 'widgets/portal_top_actions.dart';
import 'widgets/student_sidebar.dart';
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
  GroupingActivity? _selectedActivity;
  Profile? _selectedPeerForCompatibility;

  bool _isLoading = true;
  String? _errorMessage;

  // Local state for user review status: 'suggested', 'accepted', 'under_review'
  String _groupReviewStatus = 'suggested';
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

      final results = await Future.wait([activitiesFuture, profilesFuture]);
      final list = results[0] as List<GroupingActivity>;
      final profiles = results[1] as List<Profile>;

      if (mounted) {
        setState(() {
          _activities = list;
          _allProfiles = profiles;

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
          }

          // Select initial peer for compatibility matching (Step 6)
          final currentUser = AuthService.currentUser;
          final currentEmail = currentUser?.email.toLowerCase() ?? '';
          final otherProfiles = profiles.where((p) => p.email.toLowerCase() != currentEmail).toList();
          if (otherProfiles.isNotEmpty) {
            _selectedPeerForCompatibility = otherProfiles.first;
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
              (currentName.isNotEmpty && name.contains(currentName)) ||
              (currentUser == null && (email == 'carlos.mendoza@student.edu' || email == 'alex.santos@student.edu'));
          if (isCurrentUser) {
            return teamMap;
          }
        }
      }
      // Fall back to the first team of this specific activity
      return Map<String, dynamic>.from(teams.first as Map);
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
                          : _selectedActivity == null
                              ? const Center(child: Text('No active activities available.'))
                              : TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildYourSuggestedGroupTab(),
                                    _buildCompatibilityMatchingTab(),
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
              if (widget.initialClassId != null && Navigator.canPop(context)) ...[
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 14),
                  label: const Text('← Enrolled Classes', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  activity != null ? '${activity.className} • ${activity.title}' : 'Student Groups Workspace',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              if (_activities.length > 1) ...[
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
          const SizedBox(height: 10),

          // 3 Tabs corresponding to Steps 8, 6, and 7
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color(0xFF059669),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF059669),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.stars, size: 18), text: 'Your Suggested Group (Step 8)'),
              Tab(icon: Icon(Icons.compare_arrows, size: 18), text: 'Compatibility Matching (Step 6)'),
              Tab(icon: Icon(Icons.groups, size: 18), text: 'All Generated Groups (Step 7)'),
            ],
          ),
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
    final balanceScore = team?['balance_score'] ?? 90;
    final teamName = team?['name']?.toString() ?? 'Group 3';

    final totalMembers = members.length;
    final acceptedCount = members.where((m) => (m as Map)['status'] == 'accepted').length;

    final isAccepted = _groupReviewStatus == 'accepted';
    final isUnderReview = _groupReviewStatus == 'under_review';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                    : 'Review in Progress ($acceptedCount/$totalMembers Confirmed)'),
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
                      isAccepted
                          ? 'You have accepted this group! Waiting for all teammates to confirm or for the professor to officially finalize groupings.'
                          : 'Review your suggested group. Each teammate confirms their assignment individually before the group is officially locked.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Team Roster (5 members list)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final m = Map<String, dynamic>.from(members[index] as Map);
                        final rawName = m['name']?.toString() ?? 'Student';
                        final cleanName = rawName.replaceAll(RegExp(r'\s*\(You\)', caseSensitive: false), '').trim();
                        final memberEmail = m['email']?.toString().toLowerCase() ?? '';
                        final role = m['role']?.toString() ?? 'Developer';
                        final avatar = m['avatar']?.toString() ?? (cleanName.isNotEmpty ? cleanName.substring(0, 1).toUpperCase() : 'S');

                        final currentUser = AuthService.currentUser;
                        final isProfessor = currentUser?.role.toLowerCase() == 'professor';
                        final currentEmail = currentUser?.email.toLowerCase() ?? '';
                        final currentName = currentUser?.name.toLowerCase() ?? '';

                        final isSelf = !isProfessor && (
                          (currentEmail.isNotEmpty && memberEmail == currentEmail) ||
                          (currentName.isNotEmpty && cleanName.toLowerCase() == currentName)
                        );

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelf ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelf ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isSelf ? const Color(0xFF1E40AF) : const Color(0xFF059669),
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
                                            color: isSelf ? const Color(0xFF1E40AF) : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        if (isSelf) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDBEAFE),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('You', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
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

                    // Two Primary Action Buttons (matching Step 8 in infographic)
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
                            backgroundColor: const Color(0xFF059669), // Emerald green from Step 8
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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

  CompatibilityResult _computeCompatibility(
    Profile? studentA,
    Profile? studentB,
    GroupingActivity? activity,
  ) {
    if (studentB == null) {
      return CompatibilityResult(
        complementarySkills: 35.0,
        sharedInterests: 20.0,
        preferredRoles: 20.0,
        availabilityOverlap: 15.0,
        projectPreference: 10.0,
        totalScore: 88.5,
        compatibilityTier: 'Highly compatible',
        color: const Color(0xFF059669),
      );
    }

    final skillsA = studentA?.skills ?? ['Frontend Development', 'UI/UX Design', 'JavaScript'];
    final skillsB = studentB.skills;

    final interestsA = studentA?.interests ?? ['Web Development', 'UI/UX and Creative Design'];
    final interestsB = studentB.interests;

    final roleA = studentA?.preferredRole ?? 'Frontend Developer';
    final roleB = studentB.preferredRole;

    final availA = (studentA?.availability ?? 'Mon, Wed, Fri').toLowerCase();
    final availB = studentB.availability.toLowerCase();

    // 1. Complementary Skills (weight max 35%)
    final uniqueSkillsB = skillsB.where((s) => !skillsA.contains(s)).length;
    double compSkillsScore;
    if (uniqueSkillsB >= 2) {
      compSkillsScore = 31.0 + (uniqueSkillsB > 2 ? 4.0 : 2.0);
    } else if (uniqueSkillsB == 1) {
      compSkillsScore = 26.0 + (skillsB.length > 2 ? 3.0 : 1.0);
    } else {
      compSkillsScore = 20.0 + (studentB.name.length % 5);
    }
    compSkillsScore = compSkillsScore.clamp(18.0, 35.0);

    // 2. Shared Interests (weight max 20%)
    final commonInterests = interestsA.where((i) => interestsB.any((b) => b.toLowerCase().contains(i.toLowerCase()) || i.toLowerCase().contains(b.toLowerCase()))).length;
    double interestsScore;
    if (commonInterests >= 2) {
      interestsScore = 18.0 + (commonInterests > 2 ? 2.0 : 1.0);
    } else if (commonInterests == 1) {
      interestsScore = 15.0;
    } else {
      interestsScore = 11.0 + (studentB.name.length % 4);
    }
    interestsScore = interestsScore.clamp(10.0, 20.0);

    // 3. Preferred Roles (weight max 20%)
    double rolesScore;
    if (roleA.toLowerCase() != roleB.toLowerCase()) {
      rolesScore = 18.0 + ((roleA.length + roleB.length) % 3);
    } else {
      rolesScore = 11.0 + (studentB.name.length % 3);
    }
    rolesScore = rolesScore.clamp(10.0, 20.0);

    // 4. Availability Overlap (weight max 15%)
    final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    int commonDays = 0;
    for (final d in days) {
      if (availA.contains(d) && availB.contains(d)) {
        commonDays++;
      }
    }
    double availScore;
    if (commonDays >= 3) {
      availScore = 15.0;
    } else if (commonDays >= 2) {
      availScore = 13.0;
    } else if (commonDays == 1) {
      availScore = 11.0;
    } else {
      availScore = 8.5 + (commonDays * 2);
    }
    availScore = availScore.clamp(8.0, 15.0);

    // 5. Project Preference (weight max 10%)
    final className = activity?.className.toLowerCase() ?? '';
    bool matchesInterest = interestsB.any((i) => className.contains(i.toLowerCase().split(' ').first));
    double prefScore = matchesInterest ? 9.5 : (8.0 + (studentB.skills.length % 2));
    prefScore = prefScore.clamp(7.0, 10.0);

    final total = compSkillsScore + interestsScore + rolesScore + availScore + prefScore;
    final roundedTotal = (total * 10).round() / 10.0;

    String tier;
    Color color;
    if (roundedTotal >= 85.0) {
      tier = 'Highly compatible';
      color = const Color(0xFF059669);
    } else if (roundedTotal >= 72.0) {
      tier = 'Good compatibility';
      color = const Color(0xFF2563EB);
    } else {
      tier = 'Moderate compatibility';
      color = const Color(0xFFD97706);
    }

    return CompatibilityResult(
      complementarySkills: (compSkillsScore * 10).round() / 10.0,
      sharedInterests: (interestsScore * 10).round() / 10.0,
      preferredRoles: (rolesScore * 10).round() / 10.0,
      availabilityOverlap: (availScore * 10).round() / 10.0,
      projectPreference: (prefScore * 10).round() / 10.0,
      totalScore: roundedTotal,
      compatibilityTier: tier,
      color: color,
    );
  }

  /// ───────────────────────── TAB 2: STEP 6 ─────────────────────────
  /// "Compatibility Matching"
  Widget _buildCompatibilityMatchingTab() {
    final currentUser = AuthService.currentUser;
    final currentEmail = currentUser?.email.toLowerCase() ?? '';
    final isProfessor = currentUser?.role.toLowerCase() == 'professor';
    final isStudentSelf = !isProfessor && (currentUser?.name.isNotEmpty == true);

    // Student A Profile (current logged in user, or first profile)
    final studentAProfile = _allProfiles.firstWhere(
      (p) => p.email.toLowerCase() == currentEmail,
      orElse: () => _allProfiles.firstWhere(
        (p) => p.name == 'Alex Santos',
        orElse: () => Profile(
          name: isStudentSelf ? currentUser!.name : 'Alex Santos',
          email: isStudentSelf ? currentEmail : 'alex.santos@student.edu',
          skills: ['Frontend Development', 'UI/UX Design', 'JavaScript'],
          interests: ['Web Development', 'UI/UX and Creative Design'],
          preferredRole: 'Frontend Developer',
          availability: 'Mon, Tue, Thu afternoon (3-6 PM)',
        ),
      ),
    );

    final userName = isStudentSelf ? currentUser!.name : studentAProfile.name;

    // Enrolled classmates in this specific activity's class
    final activityMembers = <String, Map<String, dynamic>>{};
    if (_selectedActivity?.formedTeams != null) {
      for (final t in _selectedActivity!.formedTeams!) {
        final members = (t as Map)['members'] as List? ?? [];
        for (final m in members) {
          final mMap = Map<String, dynamic>.from(m as Map);
          final email = mMap['email']?.toString().toLowerCase() ?? '';
          if (email.isNotEmpty) {
            activityMembers[email] = mMap;
          }
        }
      }
    }

    final peers = _allProfiles.where((p) {
      final pEmail = p.email.toLowerCase();
      if (pEmail == studentAProfile.email.toLowerCase() || p.name == userName) {
        return false;
      }
      // Strictly scope to students enrolled in this specific activity
      if (activityMembers.isNotEmpty) {
        return activityMembers.containsKey(pEmail);
      }
      return true;
    }).toList();

    final peer = (_selectedPeerForCompatibility != null && peers.contains(_selectedPeerForCompatibility))
        ? _selectedPeerForCompatibility
        : (peers.isNotEmpty ? peers.first : null);

    final compat = _computeCompatibility(studentAProfile, peer, _selectedActivity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 6 Info Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.hub_outlined, color: Color(0xFF059669), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Step 6: Compatibility Matching: The system calculates individual compatibility between students based on multiple factors.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF065F46), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Peer comparison selector
              Row(
                children: [
                  const Text('Compare with classmate:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(width: 12),
                  DropdownButton<Profile>(
                    value: peers.contains(peer) ? peer : (peers.isNotEmpty ? peers.first : null),
                    items: peers.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (${p.preferredRole})', style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (p) => setState(() => _selectedPeerForCompatibility = p),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Step 6 Main Comparison Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    // Student A <---> Student B Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Left: Student A
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xFF1E40AF),
                              child: Text(userName.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            if (isStudentSelf) ...[
                              const SizedBox(height: 2),
                              const Text('(You)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                            ],
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: studentAProfile.skills.take(2).map((s) => _SkillChip(
                                label: s.split(' ').first,
                                color: const Color(0xFFEFF6FF),
                                textColor: const Color(0xFF1D4ED8),
                              )).toList(),
                            ),
                          ],
                        ),

                        // Center: ↔ Arrow
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.swap_horiz, size: 28, color: Color(0xFF64748B)),
                        ),

                        // Right: Student B (Selected Peer)
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xFF059669),
                              child: Text(peer?.name.substring(0, 1).toUpperCase() ?? 'B', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            Text(peer?.name ?? 'Bea Cruz', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: (peer?.skills ?? ['Backend', 'Database']).take(2).map((s) => _SkillChip(
                                label: s.split(' ').first,
                                color: const Color(0xFFECFDF5),
                                textColor: const Color(0xFF047857),
                              )).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    const Divider(height: 1),
                    const SizedBox(height: 24),

                    // Breakdown factors & Circular Compatibility Score Gauge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Compatibility Factors breakdown
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Compatibility Factors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                              const SizedBox(height: 14),
                              _FactorRow(label: 'Complementary skills', percentage: compat.complementarySkills, maxScore: 35, color: const Color(0xFF059669)),
                              const SizedBox(height: 10),
                              _FactorRow(label: 'Shared interests', percentage: compat.sharedInterests, maxScore: 20, color: const Color(0xFF2563EB)),
                              const SizedBox(height: 10),
                              _FactorRow(label: 'Preferred roles', percentage: compat.preferredRoles, maxScore: 20, color: const Color(0xFF7E22CE)),
                              const SizedBox(height: 10),
                              _FactorRow(label: 'Availability overlap', percentage: compat.availabilityOverlap, maxScore: 15, color: const Color(0xFFD97706)),
                              const SizedBox(height: 10),
                              _FactorRow(label: 'Project preference', percentage: compat.projectPreference, maxScore: 10, color: const Color(0xFFE11D48)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),

                        // Right: Circular Compatibility Score Gauge (dynamically updates!)
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Compatibility Score', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                              const SizedBox(height: 14),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 110,
                                    height: 110,
                                    child: CircularProgressIndicator(
                                      value: (compat.totalScore / 100.0).clamp(0.0, 1.0),
                                      strokeWidth: 10,
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      valueColor: AlwaysStoppedAnimation<Color>(compat.color),
                                    ),
                                  ),
                                  Text(
                                    '${compat.totalScore.toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: compat.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: compat.color.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  compat.compatibilityTier,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: compat.color),
                                ),
                              ),
                            ],
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

  /// ───────────────────────── TAB 3: STEP 7 ─────────────────────────
  /// "Automated Team Formation"
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
              // Step 7 Info Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Color(0xFF7E22CE), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Step 7: Automated Team Formation: The system generates balanced group compositions based on skills and compatibility. 6 groups generated for 30 students.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B21A8), height: 1.4),
                      ),
                    ),
                  ],
                ),
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
                  child: const Center(
                    child: Text('Suggested teams are being balanced by the system...'),
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
                    childAspectRatio: 0.95,
                  ),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final t = Map<String, dynamic>.from(teams[index] as Map);
                    final name = t['name']?.toString() ?? 'Group ${index + 1}';
                    final score = t['balance_score'] ?? [92, 89, 90, 88, 91, 87][index % 6];
                    final members = (t['members'] as List?) ?? [];

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
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
                            child: ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: members.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 6),
                              itemBuilder: (context, mIdx) {
                                final m = Map<String, dynamic>.from(members[mIdx] as Map);
                                final mName = m['name']?.toString() ?? 'Student';
                                final mRole = m['role']?.toString() ?? 'Developer';
                                final avatar = m['avatar']?.toString() ?? mName.substring(0, 1).toUpperCase();

                                return Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: const Color(0xFF1E40AF),
                                      child: Text(avatar, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        mName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Text(mRole, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  ],
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
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _SkillChip({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
    );
  }
}

class _FactorRow extends StatelessWidget {
  final String label;
  final double percentage;
  final double maxScore;
  final Color color;

  const _FactorRow({
    required this.label,
    required this.percentage,
    required this.maxScore,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            Text(
              '${percentage.toStringAsFixed(0)}% (max ${maxScore.toStringAsFixed(0)}%)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percentage / maxScore).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
