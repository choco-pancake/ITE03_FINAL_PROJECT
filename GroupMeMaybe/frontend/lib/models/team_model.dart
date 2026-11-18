class TeamMember {
  final String userId;
  final String name;
  final String photoUrl;
  final String block;
  String assignedRole;
  final List<String> skills;
  final List<String> interests;
  final List<String> availableDays;
  final int weeklyCommonHours;
  final bool isLocked;
  final Map<String, int> skillLevels;

  TeamMember({
    required this.userId,
    required this.name,
    this.photoUrl = '',
    required this.block,
    required this.assignedRole,
    List<String>? skills,
    List<String>? interests,
    List<String>? availableDays,
    this.weeklyCommonHours = 8,
    this.isLocked = true,
    Map<String, int>? skillLevels,
  })  : skills = skills ?? [],
        interests = interests ?? [],
        availableDays = availableDays ?? [],
        skillLevels = skillLevels ?? {};
}

class TeamModel {
  final String id;
  String name;
  final String activityId;
  final String classId;
  String leaderId;
  List<TeamMember> members;
  int capacity;
  bool isConfirmed;

  // Hybrid tags & metrics
  bool isStudentFormed;
  bool isAutoFilled;
  double? previousScore;

  // Compatibility Scores (0.0 to 100.0)
  double skillCoverage;
  double interestMatch;
  double availabilityOverlap;
  double overallCompatibility;

  TeamModel({
    required this.id,
    required this.name,
    required this.activityId,
    required this.classId,
    required this.leaderId,
    List<TeamMember>? members,
    this.capacity = 4,
    this.isConfirmed = false,
    this.isStudentFormed = true,
    this.isAutoFilled = false,
    this.previousScore,
    this.skillCoverage = 85.0,
    this.interestMatch = 80.0,
    this.availabilityOverlap = 90.0,
    this.overallCompatibility = 85.0,
  }) : members = members ?? [];

  bool get isFull => members.length >= capacity;
  int get openSlots => capacity - members.length;
  double get scoreDelta => previousScore != null ? (overallCompatibility - previousScore!) : 0.0;

  TeamModel copyWith({
    String? name,
    String? leaderId,
    List<TeamMember>? members,
    int? capacity,
    bool? isConfirmed,
    bool? isStudentFormed,
    bool? isAutoFilled,
    double? previousScore,
    double? skillCoverage,
    double? interestMatch,
    double? availabilityOverlap,
    double? overallCompatibility,
  }) {
    return TeamModel(
      id: id,
      name: name ?? this.name,
      activityId: activityId,
      classId: classId,
      leaderId: leaderId ?? this.leaderId,
      members: members ?? List.from(this.members),
      capacity: capacity ?? this.capacity,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isStudentFormed: isStudentFormed ?? this.isStudentFormed,
      isAutoFilled: isAutoFilled ?? this.isAutoFilled,
      previousScore: previousScore ?? this.previousScore,
      skillCoverage: skillCoverage ?? this.skillCoverage,
      interestMatch: interestMatch ?? this.interestMatch,
      availabilityOverlap: availabilityOverlap ?? this.availabilityOverlap,
      overallCompatibility: overallCompatibility ?? this.overallCompatibility,
    );
  }
}
