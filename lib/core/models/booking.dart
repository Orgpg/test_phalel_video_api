import 'mentor_listing.dart';

enum BookingStatus { PENDING, CONFIRMED, CANCELLED, COMPLETED }

class Booking {
  final String id;
  final String mentorListingId;
  final String learnerUserId;
  final String teacherUserId;
  final BookingStatus status;
  final DateTime scheduledFor;
  final int coinPrice;
  final MentorListing? mentorListing;
  final UserMinimal? learner;
  final UserMinimal? teacher;
  final DateTime? cancelledAt;
  final DateTime? completedAt;

  Booking({
    required this.id,
    required this.mentorListingId,
    required this.learnerUserId,
    required this.teacherUserId,
    required this.status,
    required this.scheduledFor,
    required this.coinPrice,
    this.mentorListing,
    this.learner,
    this.teacher,
    this.cancelledAt,
    this.completedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      mentorListingId: json['mentorListingId'] ?? '',
      learnerUserId: json['learnerUserId'] ?? '',
      teacherUserId: json['teacherUserId'] ?? '',
      status: _parseStatus(json['status']),
      scheduledFor: json['scheduledFor'] != null ? DateTime.parse(json['scheduledFor']) : DateTime.now(),
      coinPrice: json['coinPrice'] ?? 0,
      mentorListing: json['mentorListing'] != null ? MentorListing.fromJson(json['mentorListing']) : null,
      learner: json['learner'] != null ? UserMinimal.fromJson(json['learner']) : null,
      teacher: json['teacher'] != null ? UserMinimal.fromJson(json['teacher']) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }

  static BookingStatus _parseStatus(String? status) {
    switch (status) {
      case 'CONFIRMED': return BookingStatus.CONFIRMED;
      case 'CANCELLED': return BookingStatus.CANCELLED;
      case 'COMPLETED': return BookingStatus.COMPLETED;
      default: return BookingStatus.PENDING;
    }
  }
}

class UserMinimal {
  final String id;
  final String name;
  final String email;

  UserMinimal({required this.id, required this.name, required this.email});

  factory UserMinimal.fromJson(Map<String, dynamic> json) {
    return UserMinimal(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
