class SkillDistributionItem {
  final String skill;
  final int count;
  final int totalStudents;
  final double percentage;
  final bool isRequired;
  final bool isScarce;

  SkillDistributionItem({
    required this.skill,
    required this.count,
    required this.totalStudents,
    required this.percentage,
    required this.isRequired,
    required this.isScarce,
  });

  factory SkillDistributionItem.fromJson(Map<String, dynamic> json) {
    return SkillDistributionItem(
      skill: json['skill'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      totalStudents: json['total_students'] as int? ?? 30,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      isRequired: json['is_required'] as bool? ?? false,
      isScarce: json['is_scarce'] as bool? ?? false,
    );
  }
}

class ScarceSkillDeficit {
  final String skill;
  final int count;
  final int needed;
  final int deficit;

  ScarceSkillDeficit({
    required this.skill,
    required this.count,
    required this.needed,
    required this.deficit,
  });

  factory ScarceSkillDeficit.fromJson(Map<String, dynamic> json) {
    return ScarceSkillDeficit(
      skill: json['skill'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      needed: json['needed'] as int? ?? 0,
      deficit: json['deficit'] as int? ?? 0,
    );
  }
}

class ScarcityReport {
  final int activityId;
  final String activityTitle;
  final String className;
  final String groupingMethod;
  final int totalStudents;
  final int numberOfGroups;
  final int groupCapacity;
  final List<SkillDistributionItem> skillsDistribution;
  final List<ScarceSkillDeficit> scarceSkills;
  final bool hasScarcity;
  final int unassignedStudentsCount;
  final String message;

  ScarcityReport({
    required this.activityId,
    required this.activityTitle,
    required this.className,
    required this.groupingMethod,
    required this.totalStudents,
    required this.numberOfGroups,
    required this.groupCapacity,
    required this.skillsDistribution,
    required this.scarceSkills,
    required this.hasScarcity,
    required this.unassignedStudentsCount,
    required this.message,
  });

  factory ScarcityReport.fromJson(Map<String, dynamic> json) {
    return ScarcityReport(
      activityId: json['activity_id'] as int? ?? 0,
      activityTitle: json['activity_title'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      groupingMethod: json['grouping_method'] as String? ?? 'auto',
      totalStudents: json['total_students'] as int? ?? 30,
      numberOfGroups: json['number_of_groups'] as int? ?? 6,
      groupCapacity: json['group_capacity'] as int? ?? 5,
      skillsDistribution: (json['skills_distribution'] as List?)
              ?.map((e) => SkillDistributionItem.fromJson(e))
              .toList() ??
          [],
      scarceSkills: (json['scarce_skills'] as List?)
              ?.map((e) => ScarceSkillDeficit.fromJson(e))
              .toList() ??
          [],
      hasScarcity: json['has_scarcity'] as bool? ?? false,
      unassignedStudentsCount: json['unassigned_students_count'] as int? ?? 0,
      message: json['message'] as String? ?? '',
    );
  }
}
