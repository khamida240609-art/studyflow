import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screens.dart';
import '../features/chat/chat_screens.dart';
import '../features/community/community_screens.dart';
import '../features/home/home_screens.dart';
import '../features/items/item_screens.dart';
import '../features/profile/profile_screens.dart';
import '../features/search/search_screens.dart';
import '../providers/app_providers.dart';
import '../shared/shell_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingDone = ref.watch(onboardingProvider);
  final authState = ref.watch(authStateProvider);
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.asData?.value != null;
      final isAdmin = currentUser.asData?.value?.isAdmin ?? false;
      final isUserProfileLoading = currentUser.isLoading;
      final location = state.matchedLocation;
      final isSplash = location == '/';
      final isWelcome = location == '/welcome';
      final isAuthRoute = location == '/login' || location == '/signup';
      final isAdminRoute = location == '/admin';

      if (isLoading) {
        return isSplash ? null : '/';
      }

      if (!onboardingDone) {
        return isWelcome ? null : '/welcome';
      }

      if (!isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }

      if (isSplash || isWelcome || isAuthRoute) {
        return '/home';
      }

      if (isAdminRoute && isUserProfileLoading) {
        return null;
      }

      if (isAdminRoute && !isAdmin) {
        return '/profile';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: HomeDashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: SearchScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/create',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: CreateHubScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: ChatListScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: UserProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/lost', builder: (_, __) => const LostItemsFeedScreen()),
      GoRoute(path: '/found', builder: (_, __) => const FoundItemsFeedScreen()),
      GoRoute(
        path: '/create/lost',
        builder: (_, __) => const CreateLostItemScreen(),
      ),
      GoRoute(
        path: '/create/found',
        builder: (_, __) => const CreateFoundItemScreen(),
      ),
      GoRoute(
        path: '/item/:postId',
        builder: (_, state) =>
            ItemDetailsScreen(postId: state.pathParameters['postId']!),
      ),
      GoRoute(
        path: '/item/:postId/edit',
        builder: (_, state) =>
            EditPostScreen(postId: state.pathParameters['postId']!),
      ),
      GoRoute(
        path: '/item/:postId/qr',
        builder: (_, state) =>
            QrGeneratorScreen(postId: state.pathParameters['postId']!),
      ),
      GoRoute(path: '/camera', builder: (_, __) => const CameraCaptureScreen()),
      GoRoute(path: '/scanner', builder: (_, __) => const QrScannerScreen()),
      GoRoute(
        path: '/chat/:chatId',
        builder: (_, state) => ChatDetailScreen(
          chatId: state.pathParameters['chatId']!,
          otherUserId: state.uri.queryParameters['otherUserId'] ?? '',
          otherUserName: Uri.decodeComponent(
            state.uri.queryParameters['otherUserName'] ?? 'Пользователь Lostly',
          ),
        ),
      ),
      GoRoute(
        path: '/claim/:postId',
        builder: (_, state) => ClaimRequestScreen(
          postId: state.pathParameters['postId']!,
          ownerId: state.uri.queryParameters['ownerId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/verification/:postId',
        builder: (_, state) {
          final extra =
              state.extra as Map<String, String>? ?? <String, String>{};
          return OwnershipVerificationScreen(
            postId: state.pathParameters['postId']!,
            ownerId: state.uri.queryParameters['ownerId'] ?? '',
            claimMessage: extra['message'] ?? '',
            evidence: extra['evidence'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/pickup/:claimId',
        builder: (_, state) => PickupScheduleScreen(
          claimId: state.pathParameters['claimId']!,
          postId: state.uri.queryParameters['postId'] ?? '',
          ownerId: state.uri.queryParameters['ownerId'] ?? '',
          claimantId: state.uri.queryParameters['claimantId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(path: '/saved', builder: (_, __) => const SavedPostsScreen()),
      GoRoute(path: '/map', builder: (_, __) => const MapViewScreen()),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/community',
        builder: (_, __) => const CommunityBoardScreen(),
      ),
      GoRoute(
        path: '/report/:postId',
        builder: (_, state) =>
            ReportFakePostScreen(postId: state.pathParameters['postId']!),
      ),
      GoRoute(path: '/admin', builder: (_, __) => const AdminPanelScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});
