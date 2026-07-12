import 'user_preference.dart';
import 'user_verification.dart';

class AvatarMeta {
  final String? objectKey;
  final String? bucketName;
  final String? fileName;
  final int? fileSize;
  final String? fileType;

  AvatarMeta({
    this.objectKey,
    this.bucketName,
    this.fileName,
    this.fileSize,
    this.fileType,
  });

  factory AvatarMeta.fromJson(Map<String, dynamic> json) {
    return AvatarMeta(
      objectKey: json['objectKey'],
      bucketName: json['bucketName'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      fileType: json['fileType'],
    );
  }
}

class MobileUserStats {
  final int followers;
  final int following;
  final int authoredPosts;
  final int uploadedVideos;

  MobileUserStats({
    this.followers = 0,
    this.following = 0,
    this.authoredPosts = 0,
    this.uploadedVideos = 0,
  });

  factory MobileUserStats.fromJson(Map<String, dynamic> json) {
    return MobileUserStats(
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      authoredPosts: json['authoredPosts'] ?? 0,
      uploadedVideos: json['uploadedVideos'] ?? 0,
    );
  }
}

class MobileUserViewerState {
  final bool self;
  final bool followed;
  final String friendStatus; // NONE, REQUEST_SENT, REQUEST_RECEIVED, FRIENDS

  MobileUserViewerState({
    this.self = false,
    this.followed = false,
    this.friendStatus = 'NONE',
  });

  factory MobileUserViewerState.fromJson(Map<String, dynamic> json) {
    return MobileUserViewerState(
      self: json['self'] ?? false,
      followed: json['followed'] ?? false,
      friendStatus: json['friendStatus'] ?? 'NONE',
    );
  }
}

class MobileUser {
  final String id;
  final String username;
  final String email;
  final String name;
  final String role;
  final String? bio;
  final String? phone;
  final String? avatarUrl;
  final AvatarMeta? avatar;
  final String? accountStatus;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserPreference? preference;
  final UserVerification? verification;
  final MobileUserStats? stats;
  final MobileUserViewerState? viewerState;

  MobileUser({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.role,
    this.bio,
    this.phone,
    this.avatarUrl,
    this.avatar,
    this.accountStatus,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.preference,
    this.verification,
    this.stats,
    this.viewerState,
  });

  factory MobileUser.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] ?? json;
    
    return MobileUser(
      id: userJson['id'] ?? '',
      username: userJson['username'] ?? '',
      email: userJson['email'] ?? '',
      name: userJson['name'] ?? userJson['username'] ?? '',
      role: userJson['role'] ?? 'STUDENT',
      bio: userJson['bio'],
      phone: userJson['phone'],
      avatarUrl: userJson['avatarUrl'],
      avatar: userJson['avatar'] != null ? AvatarMeta.fromJson(userJson['avatar']) : null,
      accountStatus: userJson['accountStatus'],
      emailVerifiedAt: userJson['emailVerifiedAt'] != null 
          ? DateTime.parse(userJson['emailVerifiedAt']) 
          : null,
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
      stats: userJson['stats'] != null ? MobileUserStats.fromJson(userJson['stats']) : null,
      viewerState: userJson['viewerState'] != null ? MobileUserViewerState.fromJson(userJson['viewerState']) : null,
    );
  }

  MobileUser copyWith({
    String? username,
    String? name,
    String? bio,
    String? phone,
    String? avatarUrl,
    AvatarMeta? avatar,
    UserPreference? preference,
    UserVerification? verification,
    String? accountStatus,
    DateTime? emailVerifiedAt,
    MobileUserStats? stats,
    MobileUserViewerState? viewerState,
  }) {
    return MobileUser(
      id: id,
      username: username ?? this.username,
      email: email,
      name: name ?? this.name,
      role: role,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatar: avatar ?? this.avatar,
      accountStatus: accountStatus ?? this.accountStatus,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      preference: preference ?? this.preference,
      verification: verification ?? this.verification,
      stats: stats ?? this.stats,
      viewerState: viewerState ?? this.viewerState,
    );
  }
}
