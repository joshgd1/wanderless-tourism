import 'package:dio/dio.dart';
import 'constants.dart';

final dio = Dio(BaseOptions(
  baseUrl: ApiConstants.baseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
));

class ApiClient {
  final Dio _dio = dio;

  Future<List<dynamic>> getGuides() async {
    final resp = await _dio.get('/guides');
    return resp.data as List;
  }

  Future<Map<String, dynamic>> getGuide(String guideId) async {
    final resp = await _dio.get('/guides/$guideId');
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMatches(String touristId, {int topN = 5}) async {
    final resp = await _dio.get('/matches/$touristId', queryParameters: {'top_n': topN});
    return resp.data as List;
  }

  Future<Map<String, dynamic>> getTourist(String touristId) async {
    final resp = await _dio.get('/tourists/$touristId');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTourist(Map<String, dynamic> data) async {
    final resp = await _dio.post('/tourists', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    final resp = await _dio.post('/bookings', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBooking(int bookingId) async {
    final resp = await _dio.get('/bookings/$bookingId');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getItinerary(int bookingId) async {
    final resp = await _dio.get('/itineraries/$bookingId');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createRating(Map<String, dynamic> data) async {
    final resp = await _dio.post('/ratings', data: data);
    return resp.data as Map<String, dynamic>;
  }
}
