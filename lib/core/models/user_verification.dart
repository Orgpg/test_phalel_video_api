class UserVerification {
  final String userId;
  final String fullName;
  final String nrcNumber;
  final String phone;
  final String dateOfBirth;
  final String gender; // MALE | FEMALE | OTHER
  final String? nrcFrontUrl;
  final String? nrcBackUrl;
  final String? selfieUrl;
  final String? nrcFrontObjectKey;
  final String? nrcBackObjectKey;
  final String? selfieObjectKey;
  final String? imageBucketName;
  final String status; // PENDING | VERIFIED | REJECTED
  final DateTime submittedAt;
  final DateTime? verifiedAt;
  final String? reviewedBy;

  UserVerification({
    required this.userId,
    required this.fullName,
    required this.nrcNumber,
    required this.phone,
    required this.dateOfBirth,
    required this.gender,
    this.nrcFrontUrl,
    this.nrcBackUrl,
    this.selfieUrl,
    this.nrcFrontObjectKey,
    this.nrcBackObjectKey,
    this.selfieObjectKey,
    this.imageBucketName,
    required this.status,
    required this.submittedAt,
    this.verifiedAt,
    this.reviewedBy,
  });

  factory UserVerification.fromJson(Map<String, dynamic> json) {
    return UserVerification(
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      nrcNumber: json['nrcNumber'] ?? '',
      phone: json['phone'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      gender: json['gender']?.toString().toUpperCase() ?? 'MALE',
      nrcFrontUrl: json['nrcFrontUrl'],
      nrcBackUrl: json['nrcBackUrl'],
      selfieUrl: json['selfieUrl'],
      nrcFrontObjectKey: json['nrcFrontObjectKey'],
      nrcBackObjectKey: json['nrcBackObjectKey'],
      selfieObjectKey: json['selfieObjectKey'],
      imageBucketName: json['imageBucketName'],
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      submittedAt: json['submittedAt'] != null 
          ? DateTime.parse(json['submittedAt']) 
          : DateTime.now(),
      verifiedAt: json['verifiedAt'] != null 
          ? DateTime.parse(json['verifiedAt']) 
          : null,
      reviewedBy: json['reviewedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'fullName': fullName,
      'nrcNumber': nrcNumber,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'gender': gender.toLowerCase(),
    };

    if (nrcFrontObjectKey != null) map['nrcFrontObjectKey'] = nrcFrontObjectKey!;
    if (nrcBackObjectKey != null) map['nrcBackObjectKey'] = nrcBackObjectKey!;
    if (selfieObjectKey != null) map['selfieObjectKey'] = selfieObjectKey!;
    
    // Support legacy URL fields if needed, but the prompt says do not send them when using MinIO
    // So we only send what's provided.
    if (nrcFrontUrl != null) map['nrcFrontUrl'] = nrcFrontUrl!;
    if (nrcBackUrl != null) map['nrcBackUrl'] = nrcBackUrl!;
    if (selfieUrl != null) map['selfieUrl'] = selfieUrl!;

    return map;
  }
}
