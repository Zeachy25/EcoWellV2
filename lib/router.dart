import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/activities/activities_screen.dart';
import 'features/activities/box_breathing_screen.dart';
import 'features/activities/breathing_screen.dart';
import 'features/activities/grounding_screen.dart';
import 'features/activities/walk/walk_screen.dart';
import 'features/ai/ai_assistant_screen.dart';
import 'features/assessment/post_visit_assessment_screen.dart';
import 'features/assessment/pre_visit_assessment_screen.dart';
import 'features/assessment/stress_result_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/community/community_feed_screen.dart';
import 'features/community/create_post_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/dashboard/visit_history_screen.dart';
import 'features/explore/explore_map_screen.dart';
import 'features/explore/green_space_detail_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/home_shell.dart';
import 'features/navigation/navigation_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/streak/daily_streak_dialog.dart';
import 'features/visit/active_visit_screen.dart';
import 'features/weather/weather_screen.dart';
import 'providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loggedIn = auth.isAuthenticated;
      final location = state.matchedLocation;
      final isPublicRoute = location == '/splash' ||
          location == '/onboarding' ||
          location == '/login' ||
          location == '/register';

      if (!loggedIn && !isPublicRoute) return '/login';
      if (loggedIn && (location == '/login' || location == '/register' || location == '/onboarding')) {
        return '/home';
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Text('Route error: ${state.error}'),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreMapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (context, state) => const CommunityFeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/green-space/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'gs-001';
          return GreenSpaceDetailScreen(spaceId: id);
        },
      ),
      GoRoute(
        path: '/navigate',
        builder: (context, state) {
          final id = state.uri.queryParameters['spaceId'] ?? 'gs-001';
          return NavigationScreen(spaceId: id);
        },
      ),
      GoRoute(
        path: '/assessment',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'pre';
          final spaceId = state.uri.queryParameters['spaceId'] ?? 'gs-001';
          if (mode == 'post') {
            return PostVisitAssessmentScreen(spaceId: spaceId);
          }
          return PreVisitAssessmentScreen(spaceId: spaceId);
        },
      ),
      GoRoute(
        path: '/active-visit',
        builder: (context, state) => const ActiveVisitScreen(),
      ),
      GoRoute(
        path: '/stress-result',
        builder: (context, state) {
          final pre = int.tryParse(state.uri.queryParameters['pre'] ?? '12') ?? 12;
          final post = int.tryParse(state.uri.queryParameters['post'] ?? '5') ?? 5;
          final reduction = int.tryParse(state.uri.queryParameters['reduction'] ?? '7') ?? 7;
          final spaceName = state.uri.queryParameters['spaceName'] ?? 'Guang-guang Mangrove Park';
          return StressResultScreen(
            preScore: pre,
            postScore: post,
            reduction: reduction,
            spaceName: spaceName,
          );
        },
      ),
      GoRoute(
        path: '/activities',
        builder: (context, state) => const ActivitiesScreen(),
      ),
      GoRoute(
        path: '/activities/breathing',
        builder: (context, state) => const BreathingScreen(),
      ),
      GoRoute(
        path: '/activities/box-breathing',
        builder: (context, state) => const BoxBreathingScreen(),
      ),
      GoRoute(
        path: '/activities/grounding',
        builder: (context, state) => const GroundingScreen(),
      ),
      GoRoute(
        path: '/walk',
        builder: (context, state) => const WalkScreen(),
      ),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/ai-assistant',
        builder: (context, state) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: '/weather',
        builder: (context, state) => const WeatherScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/visit-history',
        builder: (context, state) => const VisitHistoryScreen(),
      ),
      GoRoute(
        path: '/streak',
        builder: (context, state) => const DailyStreakScreen(),
      ),
    ],
  );
});