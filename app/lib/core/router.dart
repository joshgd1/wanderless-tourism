import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/business/screens/business_login_screen.dart';
import '../features/business/screens/business_dashboard_screen.dart';
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
import '../features/settings/screens/settings_screen.dart';
import '../features/guide/screens/guide_login_screen.dart';
import '../features/guide/screens/guide_dashboard_screen.dart';
import '../features/tracking/screens/tour_tracking_screen.dart';
import '../shared/widgets/main_shell.dart';
import 'auth_provider.dart';
import 'guide_auth_provider.dart';

// Splash screen resolves auth from storage, then redirects
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    // Defer navigation to after first build
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    if (_resolved) return;
    _resolved = true;

    // Wait a tick for auth to load from storage
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      context.go('/discover');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2E1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore,
                size: 40,
                color: Color(0xFF25D366),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'WanderLess',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Color(0xFF25D366)),
          ],
        ),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/business/login', builder: (_, __) => const BusinessLoginScreen()),
      GoRoute(path: '/business/dashboard', builder: (_, __) => const BusinessDashboardScreen()),
      GoRoute(path: '/guide/login', builder: (_, __) => const GuideLoginScreen()),

      // Guide dashboard — protected by guide auth
      GoRoute(
        path: '/guide/dashboard',
        builder: (context, state) {
          final guideAuth = ProviderScope.containerOf(context).read(guideAuthProvider);
          if (!guideAuth.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/guide/login');
            });
            return const SizedBox.shrink();
          }
          return const GuideDashboardScreen();
        },
      ),

      // Onboarding flow (no auth required — accessible for new signups)
      GoRoute(path: '/onboarding', builder: (_, __) => const InterestsScreen()),
      GoRoute(
        path: '/onboarding/experience-type',
        builder: (_, __) => const ExperienceTypeScreen(),
      ),
      GoRoute(
        path: '/onboarding/language',
        builder: (_, __) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/onboarding/travel-style',
        builder: (_, __) => const TravelStyleScreen(),
      ),

      // Protected shell — requires auth (guarded by redirect in shell)
      ShellRoute(
        builder: (context, state, child) {
          final authState = ProviderScope.containerOf(context).read(authProvider);
          // If not authenticated, redirect to login
          if (!authState.isAuthenticated) {
            // Allow if already on a public route
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/login');
            });
            return const SizedBox.shrink();
          }
          return MainShell(child: child);
        },
        routes: [
          GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
          GoRoute(path: '/bookings', builder: (_, __) => const BookingsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Public routes (guide detail, booking — still require auth for actions)
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
        path: '/track/:bookingId',
        builder: (context, state) => TourTrackingScreen(
          bookingId: int.parse(state.pathParameters['bookingId']!),
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
        builder: (_, __) => const CreateTripPlanScreen(),
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
