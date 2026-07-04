import 'user_preference.dart';
import 'user_verification.dart';

class MobileUser {
  final String id;
  final String username;
  final String email;
  final String name;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserPreference? preference;
  final UserVerification? verification;

  MobileUser({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.preference,
    this.verification,
  });

  factory MobileUser.fromJson(Map<String, dynamic> json) {
    // Sometimes the user object is nested, sometimes flat depending on endpoint
    final userJson = json['user'] ?? json;
    
    return MobileUser(
      id: userJson['id'] ?? '',
      username: userJson['username'] ?? '',
      email: userJson['email'] ?? '',
      name: userJson['name'] ?? userJson['username'] ?? '',
      role: userJson['role'] ?? 'STUDENT',
      createdAt: userJson['createdAt'] != null 
          ? DateTime.parse(userJson['createdAt']) 
          : DateTime.now(),
      updatedAt: userJson['updatedAt'] != null 
          ? DateTime.parse(userJson['updatedAt']) 
          : DateTime.now(),
      preference: json['preference'] != null 
          ? UserPreference.fromJson(json['preference']) 
          : null,
      verification: json['verification'] != null 
          ? UserVerification.fromJson(json['verification']) 
          : null,
    );
  }

  MobileUser copyWith({
    String? username,
    String? name,
    UserPreference? preference,
    UserVerification? verification,
  }) {
    return MobileUser(
      id: id,
      username: username ?? this.username,
      email: email,
      name: name ?? this.name,
      role: role,
      createdAt: createdAt,
      updatedAt: updatedAt,
      preference: preference ?? this.preference,
      verification: verification ?? this.verification,
    );
  }
}
