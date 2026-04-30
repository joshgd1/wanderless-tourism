import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/discover/screens/discover_screen.dart';
import '../features/guide_detail/screens/guide_detail_screen.dart';
import '../features/booking/screens/booking_flow/booking_flow_screen.dart';
import '../features/itinerary/screens/itinerary_screen.dart';
import '../features/ratings/screens/rate_experience_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/bookings/screens/bookings_screen.dart';
import '../features/onboarding/screens/interests_screen.dart';
import '../features/onboarding/screens/experience_type_screen.dart';
import '../features/onboarding/screens/language_screen.dart';
import '../features/onboarding/screens/travel_style_screen.dart';
import '../features/trip_plan/screens/create_trip_plan_screen.dart';
import '../features/trip_plan/screens/trip_plan_list_screen.dart';
import '../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const InterestsScreen(),
      ),
      GoRoute(
        path: '/onboarding/experience-type',
        builder: (context, state) => const ExperienceTypeScreen(),
      ),
      GoRoute(
        path: '/onboarding/language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/onboarding/travel-style',
        builder: (context, state) => const TravelStyleScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const BookingsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/guide/:guideId',
        builder: (context, state) => GuideDetailScreen(
          guideId: state.pathParameters['guideId']!,
        ),
      ),
      GoRoute(
        path: '/book/:guideId',
        builder: (context, state) => BookingFlowScreen(
          guideId: state.pathParameters['guideId']!,
        ),
      ),
      GoRoute(
        path: '/itinerary/:bookingId',
        builder: (context, state) => ItineraryScreen(
          bookingId: int.parse(state.pathParameters['bookingId']!),
          guideId: state.uri.queryParameters['guideId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/rate/:bookingId',
        builder: (context, state) => RateExperienceScreen(
          bookingId: int.parse(state.pathParameters['bookingId']!),
          guideId: state.uri.queryParameters['guideId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/trip-plan/create',
        builder: (context, state) => const CreateTripPlanScreen(),
      ),
      GoRoute(
        path: '/trip-plans',
        builder: (context, state) {
          final isGuide = state.uri.queryParameters['guide'] == 'true';
          return TripPlanListScreen(isGuideView: isGuide);
        },
      ),
    ],
  );
});
