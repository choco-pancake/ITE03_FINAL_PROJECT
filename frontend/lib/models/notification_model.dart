enum NotificationType {
  teamFormed,
  requestDecision,
  deadlineReminder,
  customSkill,
  general,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String recipientId; // userId or 'all' or 'professor'
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.recipientId,
    this.type = NotificationType.general,
    this.isRead = false,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
