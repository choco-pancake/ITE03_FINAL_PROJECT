import 'package:flutter/material.dart';

import '../landing_screen.dart';
import '../student_classes_screen.dart';
import '../student_dashboard_screen.dart';
import '../student_groups_screen.dart';
import '../student_settings_screen.dart';

enum StudentNavDestination {
  dashboard,
  classes,
  groups,
  settings,
}

class StudentSidebar extends StatelessWidget {
  final StudentNavDestination currentDestination;

  const StudentSidebar({
    super.key,
    required this.currentDestination,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          right: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo & Brand Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'GroupMeMaybe',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),

          // Navigation Items
          _buildItem(
            context: context,
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            isSelected: currentDestination == StudentNavDestination.dashboard,
            onTap: () {
              if (currentDestination != StudentNavDestination.dashboard) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
                );
              }
            },
          ),
          _buildItem(
            context: context,
            icon: Icons.school_outlined,
            title: 'Classes',
            isSelected: currentDestination == StudentNavDestination.classes,
            onTap: () {
              if (currentDestination != StudentNavDestination.classes) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentClassesScreen()),
                );
              }
            },
          ),
          _buildItem(
            context: context,
            icon: Icons.groups_outlined,
            title: 'Groups (Teams)',
            isSelected: currentDestination == StudentNavDestination.groups,
            onTap: () {
              if (currentDestination != StudentNavDestination.groups) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentGroupsScreen()),
                );
              }
            },
          ),
          _buildItem(
            context: context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            isSelected: currentDestination == StudentNavDestination.settings,
            onTap: () {
              if (currentDestination != StudentNavDestination.settings) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentSettingsScreen()),
                );
              }
            },
          ),

          const Spacer(),
          const Divider(color: Colors.white12, height: 1),

          // Log Out
          _buildItem(
            context: context,
            icon: Icons.logout,
            title: 'Log Out',
            isSelected: false,
            color: Colors.redAccent,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LandingScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 14),
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
    Color? color,
  }) {
    final itemColor = color ?? (isSelected ? Colors.white : const Color(0xFF94A3B8));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? const Border(left: BorderSide(color: Color(0xFF3B82F6), width: 3))
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: itemColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: itemColor,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
