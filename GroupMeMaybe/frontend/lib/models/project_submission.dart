class ProjectSubmission {
  const ProjectSubmission({
    required this.id,
    required this.activityId,
    required this.teamName,
    required this.fileName,
    required this.submittedAt,
    this.grade,
    this.feedback,
  });

  final int id;
  final int activityId;
  final String teamName;
  final String fileName;
  final DateTime submittedAt;
  final double? grade;
  final String? feedback;

  factory ProjectSubmission.fromJson(Map<String, dynamic> json) => ProjectSubmission(
    id: json['id'] as int,
    activityId: json['grouping_activity_id'] as int,
    teamName: json['team_name']?.toString() ?? '',
    fileName: json['file_name']?.toString() ?? '',
    submittedAt: DateTime.tryParse(json['submitted_at']?.toString() ?? '') ?? DateTime.now(),
    grade: double.tryParse(json['grade']?.toString() ?? ''),
    feedback: json['feedback']?.toString(),
  );
}
