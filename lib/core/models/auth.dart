import 'user.dart';

class AuthResponse {
  const AuthResponse({required this.access, required this.refresh, required this.user});

  final String access;
  final String refresh;
  final AppUser user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      user: AppUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    );
  }
}
