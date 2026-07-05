import 'package:dio/dio.dart';
import '../models/mentor_listing.dart';
import '../network/dio_client.dart';

class MentorService {
  final DioClient _dioClient;

  MentorService(this._dioClient);

  Future<List<MentorListing>> listMentors({String? category, String? search}) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/mobile/mentors',
        queryParameters: {
          if (category != null) 'category': category,
          if (search != null) 'search': search,
        },
      );
      if (response.data['mentors'] != null) {
        return (response.data['mentors'] as List)
            .map((e) => MentorListing.fromJson(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<MentorListing> getMentorDetail(String id) async {
    try {
      final response = await _dioClient.dio.get('/api/mobile/mentors/$id');
      return MentorListing.fromJson(response.data['mentor']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<MentorListing>> getMyListings() async {
    try {
      final response = await _dioClient.dio.get('/api/mobile/mentors/me/listings');
      if (response.data['listings'] != null) {
        return (response.data['listings'] as List)
            .map((e) => MentorListing.fromJson(e))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<MentorListing> createListing({
    required String title,
    required String category,
    required String description,
    required int coinPrice,
    required int durationMinutes,
    bool isActive = true,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/mobile/mentors/me/listings',
        data: {
          'title': title,
          'category': category,
          'description': description,
          'coinPrice': coinPrice,
          'durationMinutes': durationMinutes,
          'isActive': isActive,
        },
      );
      return MentorListing.fromJson(response.data['listing']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<MentorListing> updateListing(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.patch(
        '/api/mobile/mentors/me/listings/$id',
        data: data,
      );
      return MentorListing.fromJson(response.data['listing']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteListing(String id) async {
    try {
      await _dioClient.dio.delete('/api/mobile/mentors/me/listings/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.data != null && e.response?.data['error'] != null) {
      return e.response?.data['error'];
    }
    return e.message ?? 'Mentor service error';
  }
}
