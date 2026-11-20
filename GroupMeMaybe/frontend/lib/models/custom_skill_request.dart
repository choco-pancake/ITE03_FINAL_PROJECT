enum SkillApprovalStatus { pending, underReview, approved, rejected }

extension SkillApprovalStatusX on SkillApprovalStatus {
  String get label => switch (this) {
    SkillApprovalStatus.pending => 'Pending',
    SkillApprovalStatus.underReview => 'Under Review',
    SkillApprovalStatus.approved => 'Approved',
    SkillApprovalStatus.rejected => 'Rejected',
  };
}

class CustomSkillRequest {
  final String id;
  final String studentName;
  final String studentId;
  final String block;
  final String skillName;
  final String domain;
  final DateTime submittedAt;
  SkillApprovalStatus status;
  String? remarks;

  CustomSkillRequest({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.block,
    required this.skillName,
    required this.domain,
    required this.submittedAt,
    this.status = SkillApprovalStatus.pending,
    this.remarks,
  });

  factory CustomSkillRequest.fromJson(Map<String, dynamic> json) =>
      CustomSkillRequest(
        id: (json['id'] ?? '').toString(),
        studentName: (json['student_name'] ?? '').toString(),
        studentId: (json['student_id'] ?? '').toString(),
        block: (json['block'] ?? '').toString(),
        skillName: (json['skill_name'] ?? '').toString(),
        domain: (json['domain'] ?? '').toString(),
        submittedAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        status: SkillApprovalStatus.values.firstWhere(
          (value) =>
              value.name.toLowerCase() ==
              (json['status']?.toString() ?? 'pending')
                  .replaceAll('_', '')
                  .toLowerCase(),
          orElse: () => SkillApprovalStatus.pending,
        ),
        remarks: json['remarks'] as String?,
      );

  CustomSkillRequest copyWith({SkillApprovalStatus? status, String? remarks}) {
    return CustomSkillRequest(
      id: id,
      studentName: studentName,
      studentId: studentId,
      block: block,
      skillName: skillName,
      domain: domain,
      submittedAt: submittedAt,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
    );
  }
}
