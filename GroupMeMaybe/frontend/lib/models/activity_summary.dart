class ActivitySummary {
  final int total;
  final int active;
  final int upcoming;
  final int completed;
  final int draft;

  const ActivitySummary({
    this.total = 0,
    this.active = 0,
    this.upcoming = 0,
    this.completed = 0,
    this.draft = 0,
  });

  factory ActivitySummary.fromJson(Map<String, dynamic> json) {
    return ActivitySummary(
      total: json['total'] as int? ?? 0,
      active: json['active'] as int? ?? 0,
      upcoming: json['upcoming'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      draft: json['draft'] as int? ?? 0,
    );
  }
}
