class Profile {
  final int? id;
  final String name;
  final String email;
  final List<String> skills;
  final List<String> interests;
  final String preferredRole;
  final String availability;

  Profile({
    this.id,
    required this.name,
    required this.email,
    required this.skills,
    this.interests = const [],
    required this.preferredRole,
    required this.availability,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    skills: List<String>.from(json['skills'] ?? []),
    interests: List<String>.from(json['interests'] ?? []),
    preferredRole: json['preferred_role'],
    availability: json['availability'],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'skills': skills,
    'interests': interests,
    'preferred_role': preferredRole,
    'availability': availability,
  };
}
