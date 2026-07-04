import 'mobile_user.dart';

class AuthResponse {
  final String token;
  final MobileUser user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      user: MobileUser.fromJson(json),
    );
  }
}
