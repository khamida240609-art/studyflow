import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';
import '../screens/home_shell.dart';
import '../screens/home_screen.dart';
import '../screens/group_screen.dart';
import '../screens/badges_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/teacher_dashboard_screen.dart';
import '../screens/profile_screen.dart';

class AppRouter {
  static GoRouter init(AuthService auth) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final isLoggedIn = auth.isLoggedIn;
        final isAuthRoute = state.matchedLocation == '/login';
        if (!isLoggedIn && !isAuthRoute) return '/login';
        if (isLoggedIn && isAuthRoute) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const AuthScreen()),
        ShellRoute(
          builder: (context, state, child) => HomeShell(child: child),
          routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/group', builder: (_, __) => const GroupScreen()),
          GoRoute(path: '/badges', builder: (_, __) => const BadgesScreen()),
          GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(path: '/teacher', builder: (_, __) => const TeacherDashboardScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      ],
      errorBuilder: (_, state) => Scaffold(
        body: Center(child: Text('Page not found: ${state.error}')),
      ),
    );
  }
}
