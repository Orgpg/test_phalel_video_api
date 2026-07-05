class MentorListing {
  final String id;
  final String teacherId;
  final String title;
  final String category;
  final String description;
  final int coinPrice;
  final int durationMinutes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MentorTeacher? teacher;

  MentorListing({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.category,
    required this.description,
    required this.coinPrice,
    required this.durationMinutes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.teacher,
  });

  factory MentorListing.fromJson(Map<String, dynamic> json) {
    return MentorListing(
      id: json['id'] ?? '',
      teacherId: json['teacherId'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      coinPrice: json['coinPrice'] ?? 0,
      durationMinutes: json['durationMinutes'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      teacher: json['teacher'] != null ? MentorTeacher.fromJson(json['teacher']) : null,
    );
  }
}

class MentorTeacher {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? bio;
  final String? avatarKey;

  MentorTeacher({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.bio,
    this.avatarKey,
  });

  factory MentorTeacher.fromJson(Map<String, dynamic> json) {
    return MentorTeacher(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'],
      avatarKey: json['avatarKey'],
    );
  }
}
