import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import 'widgets/portal_top_actions.dart';

import 'widgets/professor_sidebar.dart';

class ProfessorSettingsScreen extends StatefulWidget {
  const ProfessorSettingsScreen({super.key});

  @override
  State<ProfessorSettingsScreen> createState() =>
      _ProfessorSettingsScreenState();
}

class _ProfessorSettingsScreenState extends State<ProfessorSettingsScreen> {
  final _nameController = TextEditingController(text: 'Prof. Aivhan');
  final _emailController = TextEditingController(
    text: 'prof.aivhan@university.edu',
  );
  final _deptController = TextEditingController(
    text: 'College of Information and Computing Sciences',
  );
  final _officeController = TextEditingController(text: 'Tech Building 402');

  bool _notifyDeadline = true;
  bool _notifySwapRequests = true;
  bool _notifyCustomSkills = true;
  bool _autoLockOnDeadline = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final values = await NotificationService().getPreferences();
      if (mounted) {
        setState(() => _notifyCustomSkills = values['custom_skills'] ?? true);
      }
    } catch (_) {}
  }

  Future<void> _setCustomSkillNotifications(bool value) async {
    setState(() => _notifyCustomSkills = value);
    try {
      await NotificationService().updatePreferences(customSkills: value);
    } catch (_) {
      if (mounted) {
        setState(() => _notifyCustomSkills = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save notification preference.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _deptController.dispose();
    _officeController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Faculty settings updated successfully!'),
        backgroundColor: Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Unified Professor Sidebar
          const ProfessorSidebar(
            currentDestination: ProfessorNavDestination.settings,
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Faculty Settings',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          PortalTopActions(onProfile: () {}),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage your academic profile, notification preferences, and team formation defaults.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Profile Info Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF1E40AF),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Instructor Profile Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Display Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'University Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            TextField(
                              controller: _deptController,
                              decoration: InputDecoration(
                                labelText: 'Department / College',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            TextField(
                              controller: _officeController,
                              decoration: InputDecoration(
                                labelText: 'Faculty Office / Consultation Room',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Notification Preferences
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.notifications_outlined,
                                    color: Color(0xFF1E40AF),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Notifications & Automated Grouping Alerts',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              SwitchListTile(
                                title: const Text(
                                  'Deadline Reminders',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Notify when group formation cutoff is 24 hours away and unassigned students remain.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                value: _notifyDeadline,
                                activeThumbColor: const Color(0xFF1E40AF),
                                onChanged: (val) =>
                                    setState(() => _notifyDeadline = val),
                              ),
                              const Divider(height: 1),

                              SwitchListTile(
                                title: const Text(
                                  'Student Group Swap Requests',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Receive notifications when a student requests to switch squads.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                value: _notifySwapRequests,
                                activeThumbColor: const Color(0xFF1E40AF),
                                onChanged: (val) =>
                                    setState(() => _notifySwapRequests = val),
                              ),
                              const Divider(height: 1),

                              SwitchListTile(
                                title: const Text(
                                  'Custom Skill Requests',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Notify when students submit custom skills for syllabus approval in Step 2.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                value: _notifyCustomSkills,
                                activeThumbColor: const Color(0xFF1E40AF),
                                onChanged: _setCustomSkillNotifications,
                              ),
                              const Divider(height: 1),

                              SwitchListTile(
                                title: const Text(
                                  'Auto-lock Teams on Cutoff',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Automatically finalize groups when creation deadline passes.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                value: _autoLockOnDeadline,
                                activeThumbColor: const Color(0xFF1E40AF),
                                onChanged: (val) =>
                                    setState(() => _autoLockOnDeadline = val),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E40AF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Save Settings',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
