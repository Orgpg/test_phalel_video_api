class UserPreference {
  final String userId;
  final String role; // LEARNER | TEACHER | BOTH
  final List<String> teachSkills;
  final List<String> learnSkills;
  final String preferredLanguage; // MY | EN
  final DateTime updatedAt;

  UserPreference({
    required this.userId,
    required this.role,
    required this.teachSkills,
    required this.learnSkills,
    required this.preferredLanguage,
    required this.updatedAt,
  });

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      userId: json['userId'] ?? '',
      role: json['role']?.toString().toUpperCase() ?? 'LEARNER',
      teachSkills: List<String>.from(json['teachSkills'] ?? []),
      learnSkills: List<String>.from(json['learnSkills'] ?? []),
      preferredLanguage: json['preferredLanguage']?.toString().toUpperCase() ?? 'MY',
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role.toLowerCase(),
      'teachSkills': teachSkills,
      'learnSkills': learnSkills,
      'preferredLanguage': preferredLanguage.toLowerCase(),
    };
  }
}
