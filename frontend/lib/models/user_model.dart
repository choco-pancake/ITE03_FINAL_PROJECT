enum UserRole { student, professor }

enum ProfileCompletionStatus { complete, incomplete, uninitialized }

enum ProficiencyLevel { beginner, intermediate, advanced }

class UserModel {
  final String id;
  final String email;
  final UserRole role;
  String firstName;
  String middleName;
  String lastName;
  String studentId;
  String block;
  String photoUrl;
  ProfileCompletionStatus profileStatus;
  ProficiencyLevel proficiencyRating;
  bool isDraft;

  // Step 2 profile details
  List<String> technicalSkills;
  Map<String, int> skillLevels;
  List<String> preferredRoles; // 1 to 3 ordered by priority
  List<String> interests;
  List<String> availableDays;
  String preferredMeetingTime;
  int weeklyCommonHours;
  String collaborationMode; // On-campus, Online, Hybrid
  String previousExperience;
  List<String> toolsAndTechnologies;

  // References
  String? assignedTeamId;
  List<String> enrolledClassIds;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.studentId = '',
    this.block = 'BSCS 4-A',
    this.photoUrl = '',
    this.profileStatus = ProfileCompletionStatus.uninitialized,
    this.proficiencyRating = ProficiencyLevel.intermediate,
    this.isDraft = false,
    List<String>? technicalSkills,
    Map<String, int>? skillLevels,
    List<String>? preferredRoles,
    List<String>? interests,
    List<String>? availableDays,
    this.preferredMeetingTime = 'Afternoon (1:00 PM - 5:00 PM)',
    this.weeklyCommonHours = 8,
    this.collaborationMode = 'Hybrid',
    this.previousExperience = '',
    List<String>? toolsAndTechnologies,
    this.assignedTeamId,
    List<String>? enrolledClassIds,
  })  : technicalSkills = technicalSkills ?? [],
        skillLevels = skillLevels ?? {},
        preferredRoles = preferredRoles ?? [],
        interests = interests ?? [],
        availableDays = availableDays ?? ['Monday', 'Wednesday', 'Friday'],
        toolsAndTechnologies = toolsAndTechnologies ?? [],
        enrolledClassIds = enrolledClassIds ?? [];

  int getSkillLevel(String skill) {
    if (skillLevels.containsKey(skill)) return skillLevels[skill]!;
    if (!technicalSkills.contains(skill)) return 0;
    switch (proficiencyRating) {
      case ProficiencyLevel.beginner:
        return 2;
      case ProficiencyLevel.intermediate:
        return 3;
      case ProficiencyLevel.advanced:
        return 5;
    }
  }

  String get fullName => '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName'.trim();
  String get displayName => fullName.isNotEmpty ? fullName : email.split('@').first;

  // Auto-rate proficiency level based on skills, tools, and previous experience
  void recalculateProficiency() {
    int score = technicalSkills.length * 2 + toolsAndTechnologies.length;
    if (previousExperience.trim().length > 80) score += 4;
    if (score <= 5) {
      proficiencyRating = ProficiencyLevel.beginner;
    } else if (score <= 12) {
      proficiencyRating = ProficiencyLevel.intermediate;
    } else {
      proficiencyRating = ProficiencyLevel.advanced;
    }
  }

  // Update profile status based on completeness
  void recalculateProfileStatus() {
    if (role == UserRole.professor) {
      profileStatus = ProfileCompletionStatus.complete;
      return;
    }
    if (firstName.trim().isEmpty || lastName.trim().isEmpty || studentId.trim().isEmpty) {
      profileStatus = ProfileCompletionStatus.uninitialized;
      return;
    }
    if (technicalSkills.isEmpty || preferredRoles.isEmpty || interests.isEmpty || availableDays.isEmpty) {
      profileStatus = isDraft ? ProfileCompletionStatus.incomplete : ProfileCompletionStatus.incomplete;
      return;
    }
    profileStatus = ProfileCompletionStatus.complete;
  }

  UserModel copyWith({
    String? email,
    String? firstName,
    String? middleName,
    String? lastName,
    String? studentId,
    String? block,
    String? photoUrl,
    ProfileCompletionStatus? profileStatus,
    ProficiencyLevel? proficiencyRating,
    bool? isDraft,
    List<String>? technicalSkills,
    Map<String, int>? skillLevels,
    List<String>? preferredRoles,
    List<String>? interests,
    List<String>? availableDays,
    String? preferredMeetingTime,
    int? weeklyCommonHours,
    String? collaborationMode,
    String? previousExperience,
    List<String>? toolsAndTechnologies,
    String? assignedTeamId,
    List<String>? enrolledClassIds,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      role: role,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      studentId: studentId ?? this.studentId,
      block: block ?? this.block,
      photoUrl: photoUrl ?? this.photoUrl,
      profileStatus: profileStatus ?? this.profileStatus,
      proficiencyRating: proficiencyRating ?? this.proficiencyRating,
      isDraft: isDraft ?? this.isDraft,
      technicalSkills: technicalSkills ?? List.from(this.technicalSkills),
      skillLevels: skillLevels ?? Map.from(this.skillLevels),
      preferredRoles: preferredRoles ?? List.from(this.preferredRoles),
      interests: interests ?? List.from(this.interests),
      availableDays: availableDays ?? List.from(this.availableDays),
      preferredMeetingTime: preferredMeetingTime ?? this.preferredMeetingTime,
      weeklyCommonHours: weeklyCommonHours ?? this.weeklyCommonHours,
      collaborationMode: collaborationMode ?? this.collaborationMode,
      previousExperience: previousExperience ?? this.previousExperience,
      toolsAndTechnologies: toolsAndTechnologies ?? List.from(this.toolsAndTechnologies),
      assignedTeamId: assignedTeamId ?? this.assignedTeamId,
      enrolledClassIds: enrolledClassIds ?? List.from(this.enrolledClassIds),
    );
  }
}
