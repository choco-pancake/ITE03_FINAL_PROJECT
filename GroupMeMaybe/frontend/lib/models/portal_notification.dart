class PortalNotification {
  const PortalNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.kind,
    this.target,
    required this.createdAt,
    this.readAt,
  });

  final int id;
  final String title;
  final String message;
  final String kind;
  final String? target;
  final DateTime createdAt;
  final DateTime? readAt;

  factory PortalNotification.fromJson(Map<String, dynamic> json) =>
      PortalNotification(
        id: json['id'] as int,
        title: (json['title'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
        kind: (json['kind'] ?? '').toString(),
        target: json['target'] as String?,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        readAt: json['read_at'] == null
            ? null
            : DateTime.tryParse(json['read_at']?.toString() ?? ''),
      );
}
