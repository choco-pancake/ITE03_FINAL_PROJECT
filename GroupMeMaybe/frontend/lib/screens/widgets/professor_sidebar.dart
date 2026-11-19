import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../landing_screen.dart';
import '../professor_activities_screen.dart';
import '../professor_classes_screen.dart';
import '../professor_dashboard_screen.dart';
import '../professor_evaluation_screen.dart';
import '../professor_settings_screen.dart';

enum ProfessorNavDestination {
  dashboard,
  classes,
  projects,
  evaluation,
  settings,
}

class ProfessorSidebar extends StatelessWidget {
  final ProfessorNavDestination currentDestination;

  const ProfessorSidebar({super.key, required this.currentDestination});

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.logout, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 10),
            Text(
              'Confirm Sign Out',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of GroupMeMaybe?',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await AuthService().logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Column(
        children: [
          // Logo & Brand Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hub, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GroupMeMaybe',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FACULTY PORTAL',
                          style: TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),

          // Navigation Items: Dashboard, Classes, Groups, Activities, Settings
          _buildItem(
            context: context,
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            isSelected: currentDestination == ProfessorNavDestination.dashboard,
            onTap: () {
              if (currentDestination != ProfessorNavDestination.dashboard) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfessorDashboardScreen(),
                  ),
                );
              }
            },
          ),
          _buildItem(
            context: context,
            icon: Icons.school_outlined,
            title: 'Classes',
            isSelected: currentDestination == ProfessorNavDestination.classes,
            onTap: () {
              if (currentDestination != ProfessorNavDestination.classes) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfessorClassesScreen(),
                  ),
                );
              }
            },
          ),
          _buildItem(
            context: context,
            icon: Icons.assignment_outlined,
            title: 'Projects',
            isSelected: currentDestination == ProfessorNavDestination.projects,
            onTap: () {
              if (currentDestination != ProfessorNavDestination.projects) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfessorActivitiesScreen(),
                  ),
                );
              }
            },
          ),
          _buildItem(
            context: context,
            icon: Icons.fact_check_outlined,
            title: 'Evaluation',
            isSelected:
                currentDestination == ProfessorNavDestination.evaluation,
            onTap: () {
              if (currentDestination != ProfessorNavDestination.evaluation) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfessorEvaluationScreen(),
                  ),
                );
              }
            },
          ),
          _buildItem(
            context: context,
            icon: Icons.tune_outlined,
            title: 'Settings',
            isSelected: currentDestination == ProfessorNavDestination.settings,
            onTap: () {
              if (currentDestination != ProfessorNavDestination.settings) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfessorSettingsScreen(),
                  ),
                );
              }
            },
          ),

          const Spacer(),
          const Divider(color: Colors.white12, height: 1),

          // Professor Profile Card & Exit
          Builder(
            builder: (context) {
              final user = AuthService.currentUser;
              final userName = (user != null && user.name.isNotEmpty)
                  ? user.name
                  : 'Prof. Aivhan';
              final userInitial =
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'P';
              final userRole = (user != null &&
                      user.departmentOrSection != null &&
                      user.departmentOrSection!.isNotEmpty)
                  ? user.departmentOrSection!
                  : 'Faculty Lead';

              return Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF1E40AF),
                      child: Text(
                        userInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            userRole,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      tooltip: 'Sign Out',
                      onPressed: () => _confirmSignOut(context),
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

  Widget _buildItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xFF1E293B).withValues(alpha: 0.6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? const Color(0xFF60A5FA)
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
