import 'package:dio/dio.dart';
import 'config.dart';

class ApiClient {
  late final Dio _dio;
  static String? _baseUrl;

  ApiClient() {
    _baseUrl ??= ApiConfig.defaultUrl;
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl!,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  static Future<void> init() async {
    _baseUrl = await ApiConfig.getBaseUrl();
  }

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _authToken = null;
    _dio.options.headers.remove('Authorization');
  }

  Map<String, String> get _authHeaders {
    if (_authToken == null) return {};
    return {'Authorization': 'Bearer $_authToken'};
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final resp = await _dio.post(
      '/auth/register',
      data: {'email': email, 'password': password, 'name': name},
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final resp = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final resp = await _dio.get('/auth/me', options: Options(headers: _authHeaders));
    return resp.data as Map<String, dynamic>;
  }

  // ─── Guides ────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getGuides() async {
    final resp = await _dio.get('/guides');
    return resp.data as List;
  }

  Future<Map<String, dynamic>> getGuide(String guideId) async {
    final resp = await _dio.get('/guides/$guideId');
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMatches(String touristId, {int topN = 5, String? destination}) async {
    final params = <String, dynamic>{'top_n': topN};
    if (destination != null && destination.isNotEmpty) {
      params['destination'] = destination;
    }
    final resp = await _dio.get(
      '/matches/$touristId',
      queryParameters: params,
      options: Options(headers: _authHeaders),
    );
    return resp.data as List;
  }

  // ─── ML Recommendations ──────────────────────────────────────────────────

  /// ML-powered guide recommendations (content-based + collaborative filtering)
  Future<List<dynamic>> getMlGuideRecommendations(
    String touristId, {
    int topN = 5,
    String? destination,
  }) async {
    final params = <String, dynamic>{'top_n': topN};
    if (destination != null && destination.isNotEmpty) {
      params['destination'] = destination;
    }
    final resp = await _dio.get(
      '/recommendations/$touristId/guides',
      queryParameters: params,
      options: Options(headers: _authHeaders),
    );
    return resp.data as List;
  }

  /// ML-powered destination recommendations
  Future<List<dynamic>> getMlDestinationRecommendations(String touristId) async {
    final resp = await _dio.get(
      '/recommendations/$touristId/destinations',
      options: Options(headers: _authHeaders),
    );
    return resp.data as List;
  }

  // ─── Tourist ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTourist(String touristId) async {
    final resp = await _dio.get('/tourists/$touristId');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTourist(Map<String, dynamic> data) async {
    final resp = await _dio.post('/tourists', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePreferences(
    String touristId,
    Map<String, dynamic> data,
  ) async {
    final resp = await _dio.put(
      '/tourists/$touristId/preferences',
      data: data,
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  // ─── Bookings ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    final resp = await _dio.post(
      '/bookings',
      data: data,
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getBookings() async {
    final resp = await _dio.get(
      '/bookings',
      options: Options(headers: _authHeaders),
    );
    return (resp.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getBooking(int bookingId) async {
    final resp = await _dio.get(
      '/bookings/$bookingId',
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getItinerary(int bookingId) async {
    final resp = await _dio.get('/itineraries/$bookingId');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createRating(Map<String, dynamic> data) async {
    final resp = await _dio.post(
      '/ratings',
      data: data,
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  // ─── TripPlan ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createTripPlan(Map<String, dynamic> data) async {
    final resp = await _dio.post(
      '/trip-plans',
      data: data,
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTripPlans({String? touristId, String? guideId, String? status}) async {
    final params = <String, dynamic>{};
    if (touristId != null) params['tourist_id'] = touristId;
    if (guideId != null) params['guide_id'] = guideId;
    if (status != null) params['status'] = status;
    final resp = await _dio.get(
      '/trip-plans',
      queryParameters: params,
      options: Options(headers: _authHeaders),
    );
    return resp.data as List;
  }

  Future<Map<String, dynamic>> getTripPlan(int planId) async {
    final resp = await _dio.get('/trip-plans/$planId');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> acceptTripPlan(int planId) async {
    final resp = await _dio.post(
      '/trip-plans/$planId/accept',
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTripPlan(int planId, Map<String, dynamic> data) async {
    final resp = await _dio.put(
      '/trip-plans/$planId',
      data: data,
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBookingStatus(int bookingId, String status, {String? cancelledBy}) async {
    final data = <String, dynamic>{'status': status};
    if (cancelledBy != null) data['cancelled_by'] = cancelledBy;
    final resp = await _dio.put(
      '/bookings/$bookingId/status',
      data: data,
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  // ─── Business Owner ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> businessLogin({
    required String email,
    required String password,
  }) async {
    final resp = await _dio.post(
      '/business/login',
      data: {'email': email, 'password': password},
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> businessRegister({
    required String email,
    required String password,
    required String businessName,
    String? phone,
  }) async {
    final resp = await _dio.post(
      '/business/register',
      data: {
        'email': email,
        'password': password,
        'business_name': businessName,
        if (phone != null) 'phone': phone,
      },
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> businessMe() async {
    final resp = await _dio.get(
      '/business/me',
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> businessDashboard() async {
    final resp = await _dio.get(
      '/business/dashboard',
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> businessGuides() async {
    final resp = await _dio.get(
      '/business/guides',
      options: Options(headers: _authHeaders),
    );
    return resp.data as List;
  }
}
