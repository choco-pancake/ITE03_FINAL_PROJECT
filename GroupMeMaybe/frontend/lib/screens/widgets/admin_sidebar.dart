import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../landing_screen.dart';

enum AdminNavDestination {
  overview,
  faculty,
  academicTerms,
  students,
}

class AdminSidebar extends StatelessWidget {
  final AdminNavDestination currentDestination;
  final ValueChanged<AdminNavDestination>? onDestinationSelected;

  const AdminSidebar({
    super.key,
    required this.currentDestination,
    this.onDestinationSelected,
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
          'Are you sure you want to log out of the Administrator Portal?',
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
    final user = AuthService.currentUser;

    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Column(
        children: [
          // Header Logo & Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF581C87),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GroupMeMaybe',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4C1D95),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ADMIN PORTAL',
                          style: TextStyle(
                            color: Color(0xFFDDD6FE),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 12),

          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildNavItem(
                  context,
                  destination: AdminNavDestination.overview,
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard,
                  label: 'Overview',
                ),
                _buildNavItem(
                  context,
                  destination: AdminNavDestination.faculty,
                  icon: Icons.badge_outlined,
                  selectedIcon: Icons.badge,
                  label: 'Faculty & Codes',
                ),
                _buildNavItem(
                  context,
                  destination: AdminNavDestination.academicTerms,
                  icon: Icons.calendar_month_outlined,
                  selectedIcon: Icons.calendar_month,
                  label: 'Academic Terms',
                ),
                _buildNavItem(
                  context,
                  destination: AdminNavDestination.students,
                  icon: Icons.people_alt_outlined,
                  selectedIcon: Icons.people_alt,
                  label: 'Students Directory',
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1E293B), height: 1),

          // User Card & Sign Out
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF6B21A8),
                    child: Text(
                      (user?.effectiveFirstName ?? 'A')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Department Chair',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Administrator',
                          style: TextStyle(
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
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                    tooltip: 'Log Out',
                    onPressed: () => _confirmSignOut(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required AdminNavDestination destination,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = currentDestination == destination;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (onDestinationSelected != null) {
              onDestinationSelected!(destination);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF581C87) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
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
