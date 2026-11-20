class Profile {
  final int? id;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String name;
  final String email;
  final List<String> skills;
  final List<String> interests;
  final String preferredRole;
  final String availability;
  final Map<String, dynamic> details;

  Profile({
    this.id,
    this.firstName,
    this.middleName,
    this.lastName,
    required this.name,
    required this.email,
    required this.skills,
    this.interests = const [],
    required this.preferredRole,
    required this.availability,
    this.details = const {},
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'],
    firstName: json['first_name'],
    middleName: json['middle_name'],
    lastName: json['last_name'],
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    skills: List<String>.from(json['skills'] ?? []),
    interests: List<String>.from(json['interests'] ?? []),
    preferredRole: json['preferred_role'] ?? '',
    availability: json['availability'] ?? '',
    details: Map<String, dynamic>.from(json['details'] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    if (firstName != null && firstName!.isNotEmpty) 'first_name': firstName,
    if (middleName != null && middleName!.isNotEmpty) 'middle_name': middleName,
    if (lastName != null && lastName!.isNotEmpty) 'last_name': lastName,
    'name': name,
    'email': email,
    'skills': skills,
    'interests': interests,
    'preferred_role': preferredRole,
    'availability': availability,
    'details': details,
  };
}
