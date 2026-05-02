// NOTE: baseUrl is read from ApiConfig (SharedPreferences) at runtime.
// Falls back to ApiConfig.defaultUrl (render.com) — this is a compile-time placeholder only.
class ApiConstants {
  static const String baseUrl = 'https://wanderless-tourism.onrender.com/api';
}

class AppConstants {
  static const int maxGroupSize = 10;
  static const double maxTourHours = 12.0;
}
