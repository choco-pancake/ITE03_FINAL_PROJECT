import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/activity_model.dart';
import '../../state/app_state.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/compatibility_ring.dart';

class StudentDashboardScreen extends StatelessWidget {
  final AppState appState;
  final Function(int) onNavigate;

  const StudentDashboardScreen({super.key, required this.appState, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final student = appState.currentUser;
    final myTeam = appState.teams.where((t) => t.members.any((m) => m.userId == student.id)).firstOrNull;
    final openActivities = appState.activities.where((a) => a.status == ActivityStatus.open || a.status == ActivityStatus.groupingInProgress).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Completeness Notice Banner
          if (student.profileStatus != ProfileCompletionStatus.complete)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 32, color: Color(0xFFD97706)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile Incomplete: Action Required',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF92400E)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'You must complete and save your verified skills and availability to appear in teammate recommendations and join or form teams.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF78350F)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => onNavigate(3), // Navigate to Profile Setup
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Complete Profile Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Welcome Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${student.displayName}!',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${student.studentId} • ${student.block} • Profile Status: ${student.profileStatus.name.toUpperCase()}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Row(
                children: [
                  ProfileStatusBadge(status: student.profileStatus),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      'Proficiency: ${student.proficiencyRating.name.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Team Status Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: myTeam != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(myTeam.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                  Text(
                                    '${myTeam.members.length}/${myTeam.capacity} Members • Status: ${myTeam.isConfirmed ? "Confirmed by Instructor" : "Pending Confirmation"}',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          CompatibilityRing(
                            score: myTeam.overallCompatibility,
                            size: 60,
                            strokeWidth: 6,
                            skillCoverage: myTeam.skillCoverage,
                            interestMatch: myTeam.interestMatch,
                            availabilityOverlap: myTeam.availabilityOverlap,
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      const Text('YOUR TEAMMATES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 14,
                        runSpacing: 10,
                        children: myTeam.members.map((m) {
                          final bool isSelf = m.userId == student.id;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelf ? const Color(0xFFEEF2FF) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelf ? const Color(0xFFC7D2FE) : Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isSelf ? const Color(0xFF4F46E5) : Colors.grey.shade400,
                                  child: Text(m.name.isNotEmpty ? m.name[0] : 'T', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${m.name}${isSelf ? " (You)" : ""}',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelf ? const Color(0xFF3730A3) : const Color(0xFF1E293B)),
                                    ),
                                    Text(m.assignedRole, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You are currently not in a group',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Explore open activities and teammate recommendations to form or join a team.',
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => onNavigate(2), // Navigate to Groups / Teammates
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.group_add_rounded, size: 18),
                            label: const Text('Find Teammates', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 28),

          // Active Grouping Activities
          const Text('Active Grouping Activities for Your Classes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 14),

          openActivities.isEmpty
              ? const Text('No active activities.')
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: openActivities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final act = openActivities[idx];
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.assignment_outlined, color: Color(0xFF4F46E5), size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(act.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                      child: Text(act.className, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Method: ${act.groupingMethodLabel} • Capacity: ${act.groupCapacity} • Deadline: ${act.groupingDeadline.month}/${act.groupingDeadline.day}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => onNavigate(2),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('View Matcher'),
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
}
