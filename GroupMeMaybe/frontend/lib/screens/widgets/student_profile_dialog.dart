import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/profile.dart';
import '../../models/student_record.dart';
import '../professor_dashboard_screen.dart' show StudentRosterItem, ProfileCompletionStatus;

class StudentProfileDialog extends StatelessWidget {
  final String name;
  final String email;
  final String studentId;
  final String block;
  final String yearLevel;
  final String? preferredRole;
  final String? skillLevel;
  final List<String> skills;
  final List<String> interests;
  final String? meetingTime;
  final List<String> availableDays;
  final String? collaborationMode;
  final String? experience;
  final bool isProfileComplete;

  const StudentProfileDialog({
    super.key,
    required this.name,
    required this.email,
    required this.studentId,
    required this.block,
    required this.yearLevel,
    this.preferredRole,
    this.skillLevel,
    this.skills = const [],
    this.interests = const [],
    this.meetingTime,
    this.availableDays = const [],
    this.collaborationMode,
    this.experience,
    this.isProfileComplete = true,
  });

  factory StudentProfileDialog.fromProfile(Profile profile) {
    final details = profile.details;
    final sId = (details['student_id'] ?? '').toString().trim();
    final blk = (details['block'] ?? profile.availability).toString().trim();
    final yr = (details['year_level'] ?? '').toString().trim();
    final start = details['meeting_start']?.toString();
    final end = details['meeting_end']?.toString();
    final timeStr = (start != null && end != null && start.isNotEmpty && end.isNotEmpty)
        ? '$start - $end'
        : (profile.availability.contains('|') ? profile.availability.split('|').last.trim() : null);

    final daysList = (details['available_days'] as List?)
            ?.map((d) => d.toString())
            .toList() ??
        const <String>[];

    final hasRole = profile.preferredRole.isNotEmpty;
    final hasSkills = profile.skills.isNotEmpty;
    final isComplete = details['is_complete'] == true || (hasRole && hasSkills);

    final rating = profile.skills.length >= 4
        ? 'Advanced'
        : (profile.skills.length >= 2 ? 'Intermediate' : 'Beginner');

    return StudentProfileDialog(
      name: profile.name,
      email: profile.email,
      studentId: sId.isNotEmpty ? sId : 'ID Pending',
      block: blk.isNotEmpty ? blk : 'General',
      yearLevel: yr.isNotEmpty ? yr : '2nd Year',
      preferredRole: hasRole ? profile.preferredRole : 'Member',
      skillLevel: rating,
      skills: profile.skills,
      interests: profile.interests,
      meetingTime: timeStr,
      availableDays: daysList,
      collaborationMode: details['collaboration_mode']?.toString() ?? 'Hybrid',
      experience: details['experience']?.toString(),
      isProfileComplete: isComplete,
    );
  }

  factory StudentProfileDialog.fromStudentRecord(StudentRecord record, {Profile? profile}) {
    final sId = record.studentId.isNotEmpty ? record.studentId : 'ID Pending';
    final blk = record.block.isNotEmpty ? record.block : 'General';
    final yr = record.yearLevel.isNotEmpty ? record.yearLevel : '2nd Year';

    if (profile != null) {
      final fromP = StudentProfileDialog.fromProfile(profile);
      return StudentProfileDialog(
        name: record.name.isNotEmpty ? record.name : fromP.name,
        email: record.email.isNotEmpty ? record.email : fromP.email,
        studentId: sId != 'ID Pending' ? sId : fromP.studentId,
        block: blk != 'General' ? blk : fromP.block,
        yearLevel: yr != '2nd Year' ? yr : fromP.yearLevel,
        preferredRole: fromP.preferredRole,
        skillLevel: fromP.skillLevel,
        skills: fromP.skills,
        interests: fromP.interests,
        meetingTime: fromP.meetingTime,
        availableDays: fromP.availableDays,
        collaborationMode: fromP.collaborationMode,
        experience: fromP.experience,
        isProfileComplete: fromP.isProfileComplete,
      );
    }

    return StudentProfileDialog(
      name: record.name,
      email: record.email,
      studentId: sId,
      block: blk,
      yearLevel: yr,
      preferredRole: 'Developer',
      skillLevel: 'Intermediate',
      skills: const [],
      interests: const [],
      isProfileComplete: false,
    );
  }

  factory StudentProfileDialog.fromRosterItem(StudentRosterItem item, {Profile? profile}) {
    if (profile != null) {
      return StudentProfileDialog.fromProfile(profile);
    }
    return StudentProfileDialog(
      name: item.name,
      email: item.email,
      studentId: item.studentId,
      block: item.block,
      yearLevel: '2nd Year',
      preferredRole: item.primaryRole ?? 'Developer',
      skillLevel: item.skillLevel ?? 'Intermediate',
      skills: item.topSkills,
      interests: const [],
      isProfileComplete: item.status == ProfileCompletionStatus.complete,
    );
  }

  factory StudentProfileDialog.fromMemberData(Map<String, dynamic> data, {Profile? profile}) {
    final email = data['email']?.toString() ?? '';
    final name = data['name']?.toString() ?? 'Student';
    final role = data['role']?.toString() ?? 'Member';

    if (profile != null) {
      return StudentProfileDialog.fromProfile(profile);
    }

    return StudentProfileDialog(
      name: name,
      email: email,
      studentId: data['student_id']?.toString() ?? 'ID Pending',
      block: data['block']?.toString() ?? 'General',
      yearLevel: data['year_level']?.toString() ?? '2nd Year',
      preferredRole: role,
      skillLevel: 'Intermediate',
      skills: (data['skills'] as List?)?.map((s) => s.toString()).toList() ?? const [],
      interests: const [],
      isProfileComplete: false,
    );
  }

  static void show(
    BuildContext context, {
    Profile? profile,
    StudentRecord? studentRecord,
    StudentRosterItem? rosterItem,
    Map<String, dynamic>? memberData,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        if (profile != null) {
          return StudentProfileDialog.fromProfile(profile);
        } else if (studentRecord != null) {
          return StudentProfileDialog.fromStudentRecord(studentRecord);
        } else if (rosterItem != null) {
          return StudentProfileDialog.fromRosterItem(rosterItem);
        } else if (memberData != null) {
          return StudentProfileDialog.fromMemberData(memberData);
        }
        return const StudentProfileDialog(
          name: 'Student',
          email: '',
          studentId: 'ID Pending',
          block: 'General',
          yearLevel: '2nd Year',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'S';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0x33FFFFFF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ID: $studentId',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0x33FFFFFF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$yearLevel • $block',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Body Details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email row with copy action
                    if (email.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: email));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Copied $email to clipboard'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.copy_outlined, size: 16, color: Color(0xFF2563EB)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Role & Skill Rating
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.badge_outlined,
                            label: 'Preferred Role',
                            value: preferredRole ?? 'Not specified',
                            valueColor: const Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.stars_outlined,
                            label: 'Skill Proficiency',
                            value: skillLevel ?? 'Intermediate',
                            valueColor: const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Technical Skills
                    const Text(
                      'Technical Skills & Competencies',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (skills.isEmpty)
                      const Text(
                        'No technical competencies listed yet.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: skills.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),

                    // Interests
                    if (interests.isNotEmpty) ...[
                      const Text(
                        'Professional Interests & Focus Areas',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: interests.map((item) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF5FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE9D5FF)),
                            ),
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7E22CE),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Schedule & Availability
                    const Text(
                      'Availability & Collaboration Style',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Preferred Meeting Time',
                            meetingTime ?? 'Not set',
                            Icons.schedule,
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            'Available Days',
                            availableDays.isNotEmpty ? availableDays.join(', ') : 'Not set',
                            Icons.calendar_today_outlined,
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            'Collaboration Mode',
                            collaborationMode ?? 'Hybrid',
                            Icons.laptop_chromebook,
                          ),
                        ],
                      ),
                    ),

                    // Experience
                    if (experience != null && experience!.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Experience & Background',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          experience!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            height: 1.4,
                          ),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: valueColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
