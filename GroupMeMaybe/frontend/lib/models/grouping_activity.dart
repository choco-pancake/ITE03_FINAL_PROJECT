class GroupingActivity {
  final int? id;
  final int? academicClassId;
  final String className;
  final String title;
  final String? description;
  final String groupingMethod; // auto, manual, hybrid
  final int groupCapacity;
  final int numberOfGroups;
  final List<String> requiredSkills;
  final List<String> preferredSkills;
  final String minProficiencyLevel; // Beginner, Intermediate, Advanced
  final int minCommonHours;
  final DateTime groupingDeadline;
  final DateTime? studentModificationDeadline;
  final String status; // draft, open, grouping in progress, completed
  final int studentsCount;
  final List<dynamic>? formedTeams;

  GroupingActivity({
    this.id,
    this.academicClassId,
    required this.className,
    required this.title,
    this.description,
    required this.groupingMethod,
    this.groupCapacity = 5,
    this.numberOfGroups = 6,
    required this.requiredSkills,
    this.preferredSkills = const [],
    this.minProficiencyLevel = 'Intermediate',
    this.minCommonHours = 5,
    required this.groupingDeadline,
    this.studentModificationDeadline,
    this.status = 'open',
    this.studentsCount = 30,
    this.formedTeams,
  });

  factory GroupingActivity.fromJson(Map<String, dynamic> json) {
    return GroupingActivity(
      id: json['id'] as int?,
      academicClassId: json['academic_class_id'] as int?,
      className: json['class_name'] as String? ?? 'General Class',
      title: json['title'] as String? ?? 'Untitled Activity',
      description: json['description'] as String?,
      groupingMethod: json['grouping_method'] as String? ?? 'auto',
      groupCapacity: json['group_capacity'] is int
          ? json['group_capacity'] as int
          : int.tryParse(json['group_capacity']?.toString() ?? '5') ?? 5,
      numberOfGroups: json['number_of_groups'] is int
          ? json['number_of_groups'] as int
          : int.tryParse(json['number_of_groups']?.toString() ?? '6') ?? 6,
      requiredSkills: (json['required_skills'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      preferredSkills: (json['preferred_skills'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      minProficiencyLevel:
          json['min_proficiency_level'] as String? ?? 'Intermediate',
      minCommonHours: json['min_common_hours'] is int
          ? json['min_common_hours'] as int
          : int.tryParse(json['min_common_hours']?.toString() ?? '5') ?? 5,
      groupingDeadline: json['grouping_deadline'] != null
          ? DateTime.tryParse(json['grouping_deadline'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      studentModificationDeadline:
          json['student_modification_deadline'] != null
              ? DateTime.tryParse(
                  json['student_modification_deadline'].toString())
              : null,
      status: json['status'] as String? ?? 'open',
      studentsCount: json['students_count'] is int
          ? json['students_count'] as int
          : int.tryParse(json['students_count']?.toString() ?? '30') ?? 30,
      formedTeams: json['formed_teams'] as List?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (academicClassId != null) 'academic_class_id': academicClassId,
        'class_name': className,
        'title': title,
        'description': description,
        'grouping_method': groupingMethod,
        'group_capacity': groupCapacity,
        'number_of_groups': numberOfGroups,
        'required_skills': requiredSkills,
        'preferred_skills': preferredSkills,
        'min_proficiency_level': minProficiencyLevel,
        'min_common_hours': minCommonHours,
        'grouping_deadline': groupingDeadline.toIso8601String(),
        if (studentModificationDeadline != null)
          'student_modification_deadline':
              studentModificationDeadline!.toIso8601String(),
        'status': status,
        'students_count': studentsCount,
        if (formedTeams != null) 'formed_teams': formedTeams,
      };

  GroupingActivity copyWith({
    int? id,
    int? academicClassId,
    String? className,
    String? title,
    String? description,
    String? groupingMethod,
    int? groupCapacity,
    int? numberOfGroups,
    List<String>? requiredSkills,
    List<String>? preferredSkills,
    String? minProficiencyLevel,
    int? minCommonHours,
    DateTime? groupingDeadline,
    DateTime? studentModificationDeadline,
    String? status,
    int? studentsCount,
    List<dynamic>? formedTeams,
  }) {
    return GroupingActivity(
      id: id ?? this.id,
      academicClassId: academicClassId ?? this.academicClassId,
      className: className ?? this.className,
      title: title ?? this.title,
      description: description ?? this.description,
      groupingMethod: groupingMethod ?? this.groupingMethod,
      groupCapacity: groupCapacity ?? this.groupCapacity,
      numberOfGroups: numberOfGroups ?? this.numberOfGroups,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      preferredSkills: preferredSkills ?? this.preferredSkills,
      minProficiencyLevel: minProficiencyLevel ?? this.minProficiencyLevel,
      minCommonHours: minCommonHours ?? this.minCommonHours,
      groupingDeadline: groupingDeadline ?? this.groupingDeadline,
      studentModificationDeadline:
          studentModificationDeadline ?? this.studentModificationDeadline,
      status: status ?? this.status,
      studentsCount: studentsCount ?? this.studentsCount,
      formedTeams: formedTeams ?? this.formedTeams,
    );
  }
}
