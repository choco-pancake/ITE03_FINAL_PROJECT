import 'package:flutter/material.dart';
import '../models/team_model.dart';
import '../state/app_state.dart';
import 'compatibility_ring.dart';

class ManageUnassignedStudentsDialog extends StatelessWidget {
  final AppState appState;

  const ManageUnassignedStudentsDialog({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    // Find unassigned students in active classes
    final assignedUserIds = <String>{};
    for (var t in appState.teams) {
      for (var m in t.members) {
        assignedUserIds.add(m.userId);
      }
    }

    final unassignedStudents = appState.students.where((s) {
      return !assignedUserIds.contains(s.id);
    }).toList();

    final availableTeams = appState.teams.where((t) => !t.isFull).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.person_search, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manage Unassigned Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    '${unassignedStudents.length} student(s) past deadline awaiting group assignment',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ],
      ),
      content: SizedBox(
        width: 750,
        height: 520,
        child: unassignedStudents.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 54, color: Color(0xFF10B981)),
                    SizedBox(height: 12),
                    Text('All students are successfully grouped!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('There are no unassigned students past the deadline.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: unassignedStudents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, idx) {
                  final student = unassignedStudents[idx];

                  // Calculate recommended teams for this student
                  final recommendations = availableTeams.map((team) {
                    final candidateMember = TeamMember(
                      userId: student.id,
                      name: student.fullName.isNotEmpty ? student.fullName : student.displayName,
                      block: student.block,
                      assignedRole: student.preferredRoles.isNotEmpty ? student.preferredRoles.first : 'Developer',
                      skills: student.technicalSkills,
                      interests: student.interests,
                      availableDays: student.availableDays,
                      weeklyCommonHours: student.weeklyCommonHours,
                    );
                    final hypothetical = List<TeamMember>.from(team.members)..add(candidateMember);
                    final metrics = appState.calculateTeamMetrics(hypothetical, null);
                    return {
                      'team': team,
                      'score': metrics['overall']!,
                      'skillCoverage': metrics['skillCoverage']!,
                      'interestMatch': metrics['interestMatch']!,
                      'availabilityOverlap': metrics['availabilityOverlap']!,
                    };
                  }).toList()
                    ..sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                child: Text(
                                  student.fullName.isNotEmpty ? student.fullName[0] : 'S',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
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
                                          student.fullName.isNotEmpty ? student.fullName : student.displayName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                          child: Text(student.block, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                                          child: Text(
                                            'Level: ${student.proficiencyRating.name.toUpperCase()}',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Skills: ${student.technicalSkills.isEmpty ? "No skills entered" : student.technicalSkills.join(", ")}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          const Text(
                            'Recommended Groups (Ranked by Compatibility):',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 10),
                          if (recommendations.isEmpty)
                            const Text('No teams with open slots. Consider generating new teams or increasing capacity.',
                                style: TextStyle(fontSize: 12, color: Colors.grey))
                          else
                            Column(
                              children: recommendations.take(2).map((rec) {
                                final team = rec['team'] as TeamModel;
                                final score = rec['score'] as double;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      CompatibilityRing(
                                        score: score,
                                        size: 42,
                                        strokeWidth: 4,
                                        skillCoverage: rec['skillCoverage'] as double,
                                        interestMatch: rec['interestMatch'] as double,
                                        availabilityOverlap: rec['availabilityOverlap'] as double,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            Text(
                                              '${team.members.length}/${team.capacity} members • Needs: ${team.openSlots} more',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          appState.assignUnassignedStudentToTeam(student.id, team.id);
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Assigned ${student.fullName} to ${team.name}!'),
                                              backgroundColor: const Color(0xFF10B981),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4F46E5),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        icon: const Icon(Icons.add, size: 14),
                                        label: const Text('Assign to Team'),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
