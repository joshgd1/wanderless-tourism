import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../core/auth_provider.dart';
import '../../../shared/models/trip_plan.dart';
import '../../../shared/models/guide.dart';

final myTripPlansProvider = FutureProvider<List<TripPlan>>((ref) async {
  final authState = ref.watch(authProvider);
  final touristId = authState.touristId;
  if (touristId == null) return [];
  final api = ApiClient();
  final data = await api.getTripPlans(touristId: touristId);
  return data.map((e) => TripPlan.fromJson(e as Map<String, dynamic>)).toList();
});

/// Provider for the guide's open trip plan requests — refreshed on guide login
final openTripPlansProvider = FutureProvider<List<TripPlan>>((ref) async {
  final api = ApiClient();
  final data = await api.getTripPlans(status: 'OPEN');
  return data.map((e) => TripPlan.fromJson(e as Map<String, dynamic>)).toList();
});

/// Provider for guide open requests fetched from the guide endpoint.
/// Invalidated on guide login so the guide dashboard refreshes with live data.
final guideOpenRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ApiClient();
  final data = await api.getGuideOpenRequests();
  return data.cast<Map<String, dynamic>>();
});
