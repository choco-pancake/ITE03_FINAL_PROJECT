import 'package:flutter/material.dart';

import 'bottom_right_notification.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../landing_screen.dart';
import '../login_screen.dart';
import '../professor_dashboard_screen.dart';
import '../professor_settings_screen.dart';
import '../student_dashboard_screen.dart';
import '../student_settings_screen.dart';
import '../student_groups_screen.dart';
import '../student_classes_screen.dart';
import '../professor_activities_screen.dart';
import '../professor_classes_screen.dart';
import '../../models/portal_notification.dart';

class PortalTopActions extends StatefulWidget {
  const PortalTopActions({super.key, this.onProfile});

  final VoidCallback? onProfile;

  @override
  State<PortalTopActions> createState() => _PortalTopActionsState();
}

class _PortalTopActionsState extends State<PortalTopActions> {
  final _service = NotificationService();
  NotificationSnapshot _snapshot = const NotificationSnapshot([], 0);
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (AuthService.authToken == null) return;
    setState(() => _loading = true);
    try {
      final snapshot = await _service.getNotifications();
      if (mounted) setState(() => _snapshot = snapshot);
    } catch (_) {
      // Keep the last loaded items while the server is unavailable.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showNotifications() async {
    await _refresh();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: 420,
          height: 360,
          child: _snapshot.items.isEmpty
              ? const Center(child: Text('No notifications yet.'))
              : ListView.separated(
                  itemCount: _snapshot.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _snapshot.items[index];
                    return ListTile(
                      leading: Icon(
                        item.kind == 'group_deadline'
                            ? Icons.schedule
                            : Icons.notifications_outlined,
                        color: item.readAt == null
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFF64748B),
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: item.readAt == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(item.message),
                      onTap: () async {
                        try {
                          await _service.markRead(item.id);
                          await _refresh();
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          _handleNotificationClick(item);
                        } catch (error) {
                          if (dialogContext.mounted) {
                            AppNotification.showError(
                              dialogContext,
                              error.toString().replaceAll(
                                'Exception: ',
                                '',
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationClick(PortalNotification item) {
    if (!mounted) return;
    final user = AuthService.currentUser;
    final isProf = user?.isProfessor == true;

    // 1. Custom Skill Request -> Professor Dashboard (scroll to skills section)
    if (item.kind == 'skill_request' || item.target == 'skill_requests') {
      if (isProf) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfessorDashboardScreen(scrollToSkills: true),
          ),
        );
      }
      return;
    }

    // 2. Skill Approval Decision -> Student Profile & Settings (Skill section)
    if (item.kind == 'skill_decision' || item.target == 'skills') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const StudentSettingsScreen(initialTab: 0),
        ),
      );
      return;
    }

    // 3. Group Deadline or Activity -> Groups (Student) or Activities (Professor)
    if (item.kind == 'group_deadline' ||
        item.target == 'groups' ||
        item.target == 'activities') {
      if (isProf) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfessorActivitiesScreen(),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const StudentGroupsScreen(),
          ),
        );
      }
      return;
    }

    // 4. Classes
    if (item.target == 'classes') {
      if (isProf) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfessorClassesScreen(),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const StudentClassesScreen(),
          ),
        );
      }
      return;
    }
  }

  void _openProfile() {
    if (widget.onProfile != null) {
      widget.onProfile!();
      return;
    }
    if (AuthService.currentUser?.isAdmin == true) {
      return;
    }
    final destination = AuthService.currentUser?.isProfessor == true
        ? const ProfessorSettingsScreen()
        : const StudentSettingsScreen(initialTab: 0);
    Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
  }

  Future<void> _openAccountMenu() async {
    final accounts = await AuthService.getKnownAccounts();
    final user = AuthService.currentUser;
    final otherAccounts = accounts
        .where(
          (a) =>
              a.user.email.trim().toLowerCase() !=
              (user?.email.trim().toLowerCase() ?? ''),
        )
        .take(3)
        .toList();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF1E40AF),
              child: Text(
                (user?.effectiveFirstName ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Account',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: user?.isAdmin == true
                    ? const Color(0xFFF3E8FF)
                    : user?.isProfessor == true
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user?.isAdmin == true
                    ? 'Department Chair'
                    : user?.isProfessor == true
                        ? 'Professor'
                        : 'Student',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: user?.isAdmin == true
                      ? const Color(0xFF581C87)
                      : user?.isProfessor == true
                          ? const Color(0xFF92400E)
                          : const Color(0xFF1E40AF),
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF1E40AF),
                ),
                title: Text(
                  user?.isProfessor == true
                      ? 'Faculty Settings'
                      : 'My Profile & Settings',
                ),
                onTap: () {
                  Navigator.pop(dialogCtx);
                  _openProfile();
                },
              ),
              const Divider(height: 20),
              const Text(
                'SWITCH ACCOUNT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              if (otherAccounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No other saved accounts on this device.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                )
              else
                ...otherAccounts.map((account) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFE2E8F0),
                      child: Text(
                        account.user.effectiveFirstName
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    title: Text(
                      account.user.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${account.user.email} • ${account.user.isProfessor ? "Professor" : "Student"}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(dialogCtx);
                      await AuthService.switchToAccount(account);
                      if (!mounted) return;
                      final dest = account.user.isProfessor
                          ? const ProfessorDashboardScreen()
                          : const StudentDashboardScreen();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => dest),
                        (_) => false,
                      );
                    },
                  );
                }),
              const SizedBox(height: 6),
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(
                  Icons.person_add_alt_outlined,
                  color: Color(0xFF1E40AF),
                ),
                title: const Text(
                  'Add another account',
                  style: TextStyle(
                    color: Color(0xFF1E40AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(dialogCtx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
              const Divider(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.logout, color: Color(0xFFDC2626)),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(dialogCtx);
                  await _logOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 10),
            Text(
              'Log Out',
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

    if (confirmed == true && mounted) {
      await AuthService().logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: _showNotifications,
          icon: _snapshot.unreadCount == 0
              ? const Icon(Icons.notifications_outlined)
              : Badge(
                  label: Text(
                    _snapshot.unreadCount > 99
                        ? '99+'
                        : '${_snapshot.unreadCount}',
                  ),
                  child: const Icon(Icons.notifications_outlined),
                ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _openAccountMenu,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1E40AF),
              child: Text(
                (user?.effectiveFirstName ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        if (_loading)
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        const SizedBox(width: 12),
      ],
    );
  }
}
