enum GroupingMethod { manual, auto, hybrid }

enum ActivityStatus { draft, open, groupingInProgress, completed }

class ActivityModel {
  final String id;
  final String classId;
  final String className;
  String title;
  String description;
  GroupingMethod groupingMethod;
  int groupCapacity; // Team size
  int neededGroups; // Number of groups needed
  List<String> requiredSkills;
  List<String> preferredSkills;
  String minProficiencyLevel; // Beginner, Intermediate, Advanced
  int minCommonHours;
  DateTime groupingDeadline;
  DateTime studentModificationDeadline;
  ActivityStatus status;

  ActivityModel({
    required this.id,
    required this.classId,
    required this.className,
    required this.title,
    required this.description,
    this.groupingMethod = GroupingMethod.auto,
    this.groupCapacity = 4,
    this.neededGroups = 6,
    List<String>? requiredSkills,
    List<String>? preferredSkills,
    this.minProficiencyLevel = 'Intermediate',
    this.minCommonHours = 6,
    required this.groupingDeadline,
    required this.studentModificationDeadline,
    this.status = ActivityStatus.open,
  })  : requiredSkills = requiredSkills ?? [],
        preferredSkills = preferredSkills ?? [];

  String get groupingMethodLabel {
    switch (groupingMethod) {
      case GroupingMethod.manual:
        return 'Manual';
      case GroupingMethod.auto:
        return 'Auto';
      case GroupingMethod.hybrid:
        return 'Hybrid';
    }
  }

  String get statusLabel {
    switch (status) {
      case ActivityStatus.draft:
        return 'Draft';
      case ActivityStatus.open:
        return 'Open';
      case ActivityStatus.groupingInProgress:
        return 'Grouping In Progress';
      case ActivityStatus.completed:
        return 'Completed';
    }
  }

  ActivityModel copyWith({
    String? classId,
    String? className,
    String? title,
    String? description,
    GroupingMethod? groupingMethod,
    int? groupCapacity,
    int? neededGroups,
    List<String>? requiredSkills,
    List<String>? preferredSkills,
    String? minProficiencyLevel,
    int? minCommonHours,
    DateTime? groupingDeadline,
    DateTime? studentModificationDeadline,
    ActivityStatus? status,
  }) {
    return ActivityModel(
      id: id,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      title: title ?? this.title,
      description: description ?? this.description,
      groupingMethod: groupingMethod ?? this.groupingMethod,
      groupCapacity: groupCapacity ?? this.groupCapacity,
      neededGroups: neededGroups ?? this.neededGroups,
      requiredSkills: requiredSkills ?? List.from(this.requiredSkills),
      preferredSkills: preferredSkills ?? List.from(this.preferredSkills),
      minProficiencyLevel: minProficiencyLevel ?? this.minProficiencyLevel,
      minCommonHours: minCommonHours ?? this.minCommonHours,
      groupingDeadline: groupingDeadline ?? this.groupingDeadline,
      studentModificationDeadline: studentModificationDeadline ?? this.studentModificationDeadline,
      status: status ?? this.status,
    );
  }
}
