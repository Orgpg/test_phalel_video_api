class UserVerification {
  final String userId;
  final String fullName;
  final String nrcNumber;
  final String phone;
  final String dateOfBirth;
  final String gender; // MALE | FEMALE | OTHER
  final String nrcFrontUrl;
  final String nrcBackUrl;
  final String selfieUrl;
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
    required this.nrcFrontUrl,
    required this.nrcBackUrl,
    required this.selfieUrl,
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
      nrcFrontUrl: json['nrcFrontUrl'] ?? '',
      nrcBackUrl: json['nrcBackUrl'] ?? '',
      selfieUrl: json['selfieUrl'] ?? '',
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
    return {
      'fullName': fullName,
      'nrcNumber': nrcNumber,
      'phone': phone,
      'dateOfBirth': dateOfBirth,
      'gender': gender.toLowerCase(),
      'nrcFrontUrl': nrcFrontUrl,
      'nrcBackUrl': nrcBackUrl,
      'selfieUrl': selfieUrl,
    };
  }
}
