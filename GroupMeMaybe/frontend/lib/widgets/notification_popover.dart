import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../state/app_state.dart';

class NotificationBellWidget extends StatelessWidget {
  final AppState appState;

  const NotificationBellWidget({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final userNotifs = appState.userNotifications;
    final unreadCount = appState.unreadNotificationsCount;
    final topThree = userNotifs.take(3).toList();

    return PopupMenuButton<int>(
      tooltip: 'Notifications',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.notifications_outlined, size: 22, color: Color(0xFF334155)),
      ),
      itemBuilder: (context) {
        if (topThree.isEmpty) {
          return [
            const PopupMenuItem<int>(
              enabled: false,
              child: SizedBox(
                width: 320,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No notifications yet', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ),
            ),
          ];
        }

        return [
          PopupMenuItem<int>(
            enabled: false,
            child: SizedBox(
              width: 340,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Notifications',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: () {
                        appState.markAllNotificationsRead();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
          ...topThree.map(
            (notif) => PopupMenuItem<int>(
              enabled: false,
              child: Container(
                width: 340,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _getNotifColor(notif.type).withValues(alpha: 0.15),
                      child: Icon(_getNotifIcon(notif.type), size: 16, color: _getNotifColor(notif.type)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                    fontSize: 13,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                notif.timeAgo,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            notif.message,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<int>(
            value: 999,
            child: SizedBox(
              width: 340,
              child: Center(
                child: Text(
                  'View All (${userNotifs.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ];
      },
      onSelected: (value) {
        if (value == 999) {
          _showAllNotificationsDialog(context, appState);
        }
      },
    );
  }

  static IconData _getNotifIcon(NotificationType type) {
    switch (type) {
      case NotificationType.teamFormed:
        return Icons.group;
      case NotificationType.requestDecision:
        return Icons.fact_check_outlined;
      case NotificationType.deadlineReminder:
        return Icons.alarm;
      case NotificationType.customSkill:
        return Icons.stars;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  static Color _getNotifColor(NotificationType type) {
    switch (type) {
      case NotificationType.teamFormed:
        return const Color(0xFF6366F1);
      case NotificationType.requestDecision:
        return const Color(0xFF10B981);
      case NotificationType.deadlineReminder:
        return const Color(0xFFF59E0B);
      case NotificationType.customSkill:
        return const Color(0xFF8B5CF6);
      case NotificationType.general:
        return const Color(0xFF0EA5E9);
    }
  }

  static void _showAllNotificationsDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) {
        final allNotifs = appState.userNotifications;
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: Color(0xFF4F46E5)),
                  SizedBox(width: 10),
                  Text('All Notifications'),
                ],
              ),
              TextButton(
                onPressed: () {
                  appState.markAllNotificationsRead();
                  Navigator.pop(ctx);
                },
                child: const Text('Mark all as read'),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: 400,
            child: allNotifs.isEmpty
                ? const Center(child: Text('No notifications on record.'))
                : ListView.separated(
                    itemCount: allNotifs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (c, idx) {
                      final n = allNotifs[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getNotifColor(n.type).withValues(alpha: 0.15),
                          child: Icon(_getNotifIcon(n.type), color: _getNotifColor(n.type), size: 20),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                            Text(n.timeAgo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(n.message, style: const TextStyle(fontSize: 13)),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
