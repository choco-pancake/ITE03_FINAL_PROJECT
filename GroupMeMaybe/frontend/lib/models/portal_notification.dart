class PortalNotification {
  const PortalNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.kind,
    required this.createdAt,
    this.readAt,
  });

  final int id;
  final String title;
  final String message;
  final String kind;
  final DateTime createdAt;
  final DateTime? readAt;

  factory PortalNotification.fromJson(Map<String, dynamic> json) =>
      PortalNotification(
        id: json['id'] as int,
        title: json['title'] as String,
        message: json['message'] as String,
        kind: json['kind'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        readAt: json['read_at'] == null
            ? null
            : DateTime.parse(json['read_at'] as String),
      );
}
