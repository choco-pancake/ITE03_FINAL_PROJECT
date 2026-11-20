import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../landing_screen.dart';
import '../student_classes_screen.dart';
import '../student_dashboard_screen.dart';
import '../student_groups_screen.dart';
import '../student_settings_screen.dart';

enum StudentNavDestination { dashboard, classes, groups, settings }

class StudentSidebar extends StatelessWidget {
  final StudentNavDestination currentDestination;
  final Future<bool> Function()? onBeforeNavigate;

  const StudentSidebar({
    super.key,
    required this.currentDestination,
    this.onBeforeNavigate,
  });

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
                          'STUDENT PORTAL',
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

          // Navigation Items
          _buildItem(
            context: context,
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            isSelected: currentDestination == StudentNavDestination.dashboard,
            onTap: () async {
              if (currentDestination != StudentNavDestination.dashboard) {
                if (onBeforeNavigate != null) {
                  final canProceed = await onBeforeNavigate!();
                  if (!canProceed) return;
                }
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentDashboardScreen(),
                  ),
                );
              }
            },
          ),
          _buildItem(
            context: context,
            icon: Icons.school_outlined,
            title: 'Classes',
            isSelected: currentDestination == StudentNavDestination.classes,
            onTap: () async {
              if (currentDestination != StudentNavDestination.classes) {
                if (onBeforeNavigate != null) {
                  final canProceed = await onBeforeNavigate!();
                  if (!canProceed) return;
                }
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentClassesScreen(),
                  ),
                );
              }
            },
          ),
          _buildItem(
            context: context,
            icon: Icons.groups_outlined,
            title: 'Groups (Teams)',
            isSelected: currentDestination == StudentNavDestination.groups,
            onTap: () async {
              if (currentDestination != StudentNavDestination.groups) {
                if (onBeforeNavigate != null) {
                  final canProceed = await onBeforeNavigate!();
                  if (!canProceed) return;
                }
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentGroupsScreen(),
                  ),
                );
              }
            },
          ),
          _buildItem(
            context: context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            isSelected: currentDestination == StudentNavDestination.settings,
            onTap: () async {
              if (currentDestination != StudentNavDestination.settings) {
                if (onBeforeNavigate != null) {
                  final canProceed = await onBeforeNavigate!();
                  if (!canProceed) return;
                }
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentSettingsScreen(),
                  ),
                );
              }
            },
          ),

          const Spacer(),
          const Divider(color: Colors.white12, height: 1),

          // Student User Card
          Builder(
            builder: (context) {
              final user = AuthService.currentUser;
              final name = (user != null && user.name.isNotEmpty)
                  ? user.name
                  : 'Student User';
              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
              final dept = (user != null &&
                      user.departmentOrSection != null &&
                      user.departmentOrSection!.isNotEmpty)
                  ? user.departmentOrSection!
                  : 'Student Lead';

              return Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF1E40AF),
                      child: Text(
                        initial,
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
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            dept,
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
    Color? color,
  }) {
    final itemColor =
        color ?? (isSelected ? Colors.white : const Color(0xFF94A3B8));
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
                ? const Border(
                    left: BorderSide(color: Color(0xFF3B82F6), width: 3),
                  )
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
