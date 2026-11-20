import 'package:flutter/material.dart';

import 'bottom_right_notification.dart';
import '../../services/profile_service.dart';
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
            isLocked: false,
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
            isLocked: !ProfileService.isProfileComplete,
            onTap: () async {
              if (!ProfileService.isProfileComplete) {
                final isComplete = await ProfileService().checkProfileComplete();
                if (!isComplete) {
                  if (context.mounted) {
                    AppNotification.showWarning(
                      context,
                      'Please complete your profile in Settings before accessing classes.',
                    );
                  }
                  return;
                }
              }
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
            isLocked: !ProfileService.isProfileComplete,
            onTap: () async {
              if (!ProfileService.isProfileComplete) {
                final isComplete = await ProfileService().checkProfileComplete();
                if (!isComplete) {
                  if (context.mounted) {
                    AppNotification.showWarning(
                      context,
                      'Please complete your profile in Settings before accessing team groups.',
                    );
                  }
                  return;
                }
              }
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
            isLocked: false,
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
          const SizedBox(height: 16),
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
    bool isLocked = false,
    Color? color,
  }) {
    final itemColor = isLocked
        ? const Color(0xFF64748B)
        : (color ?? (isSelected ? Colors.white : const Color(0xFF94A3B8)));
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
              if (isLocked)
                const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF64748B),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
