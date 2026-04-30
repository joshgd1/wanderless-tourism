import 'package:dio/dio.dart';
import 'config.dart';

class ApiClient {
  static Dio? _dio;
  static String? _baseUrl;
  static String? _authToken;

  static Dio get _dioInstance {
    _dio ??= Dio(BaseOptions(
      baseUrl: _baseUrl ?? ApiConfig.defaultUrl ?? 'http://localhost:8000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    return _dio!;
  }

  ApiClient() {
    _baseUrl ??= ApiConfig.defaultUrl;
  }

  static Future<void> init() async {
    _baseUrl = await ApiConfig.getBaseUrl();
  }

  void setAuthToken(String token) {
    _authToken = token;
    _dioInstance.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _authToken = null;
    _dioInstance.options.headers.remove('Authorization');
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
    final resp = await _dioInstance.post(
      '/auth/register',
      data: {'email': email, 'password': password, 'name': name},
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final resp = await _dioInstance.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final resp = await _dioInstance.get('/auth/me', options: Options(headers: _authHeaders));
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> guideLogin({
    required String email,
    required String password,
  }) async {
    final resp = await _dioInstance.post(
      '/guides/login',
      data: {'email': email, 'password': password},
    );
    return resp.data as Map<String, dynamic>;
  }

  // ─── Guides ────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getGuides() async {
    final resp = await _dioInstance.get('/guides');
    return resp.data as List;
  }

  Future<Map<String, dynamic>> getGuide(String guideId) async {
    final resp = await _dioInstance.get('/guides/$guideId');
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMatches(String touristId, {int topN = 5, String? destination}) async {
    final params = <String, dynamic>{'top_n': topN};
    if (destination != null && destination.isNotEmpty) {
      params['destination'] = destination;
    }
    final resp = await _dioInstance.get(
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
    final resp = await _dioInstance.get(
      '/recommendations/$touristId/guides',
      queryParameters: params,
      options: Options(headers: _authHeaders),
    );
    return resp.data as List;
  }

  /// ML-powered destination recommendations
  Future<List<dynamic>> getMlDestinationRecommendations(String touristId) async {
    final resp = await _dioInstance.get(
      '/recommendations/$touristId/destinations',
      options: Options(headers: _authHeaders),
    );
    return resp.data as List;
  }

  // ─── Tourist ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTourist(String touristId) async {
    final resp = await _dioInstance.get('/tourists/$touristId');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTourist(Map<String, dynamic> data) async {
    final resp = await _dioInstance.post('/tourists', data: data);
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePreferences(
    String touristId,
    Map<String, dynamic> data,
  ) async {
    final resp = await _dioInstance.put(
      '/tourists/$touristId/preferences',
      data: data,
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  // ─── Bookings ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    final resp = await _dioInstance.post(
      '/bookings',
      data: data,
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getBookings() async {
    final resp = await _dioInstance.get(
      '/bookings',
      options: Options(headers: _authHeaders),
    );
    return (resp.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getGuideBookings() async {
    final resp = await _dioInstance.get(
      '/guide/bookings',
      options: Options(headers: _authHeaders),
    );
    return (resp.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getBooking(int bookingId) async {
    final resp = await _dioInstance.get(
      '/bookings/$bookingId',
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getItinerary(int bookingId) async {
    final resp = await _dioInstance.get('/itineraries/$bookingId');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createRating(Map<String, dynamic> data) async {
    final resp = await _dioInstance.post(
      '/ratings',
      data: data,
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  // ─── TripPlan ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createTripPlan(Map<String, dynamic> data) async {
    final resp = await _dioInstance.post(
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
    final resp = await _dioInstance.get(
      '/trip-plans',
      queryParameters: params,
      options: Options(headers: _authHeaders),
    );
    return resp.data as List;
  }

  Future<Map<String, dynamic>> getTripPlan(int planId) async {
    final resp = await _dioInstance.get('/trip-plans/$planId');
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> acceptTripPlan(int planId) async {
    final resp = await _dioInstance.post(
      '/trip-plans/$planId/accept',
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTripPlan(int planId, Map<String, dynamic> data) async {
    final resp = await _dioInstance.put(
      '/trip-plans/$planId',
      data: data,
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBookingStatus(int bookingId, String status, {String? cancelledBy}) async {
    final data = <String, dynamic>{'status': status};
    if (cancelledBy != null) data['cancelled_by'] = cancelledBy;
    final resp = await _dioInstance.put(
      '/bookings/$bookingId/status',
      data: data,
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  // ─── Location tracking ─────────────────────────────────────────────────────

  /// Update GPS location for the current user (guide or tourist)
  Future<Map<String, dynamic>> updateLocation({
    required int bookingId,
    required String role, // 'guide' or 'tourist'
    required double lat,
    required double lng,
  }) async {
    final resp = await _dioInstance.put(
      '/bookings/$bookingId/location',
      data: {
        'role': role,
        'lat': lat,
        'lng': lng,
      },
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  /// Get current location of both guide and tourist for a booking
  Future<Map<String, dynamic>> getLocation(int bookingId) async {
    final resp = await _dioInstance.get(
      '/bookings/$bookingId/location',
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  // ─── Business Owner ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> businessLogin({
    required String email,
    required String password,
  }) async {
    final resp = await _dioInstance.post(
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
    final resp = await _dioInstance.post(
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
    final resp = await _dioInstance.get(
      '/business/me',
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> businessDashboard() async {
    final resp = await _dioInstance.get(
      '/business/dashboard',
      options: Options(headers: _authHeaders),
    );
    return resp.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> businessGuides() async {
    final resp = await _dioInstance.get(
      '/business/guides',
      options: Options(headers: _authHeaders),
    );
    return resp.data as List;
  }
}
