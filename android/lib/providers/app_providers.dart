import 'dart:async';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/enums/app_enums.dart';
import '../firebase_options.dart';
import '../models/analytics_summary.dart';
import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/claim_request.dart';
import '../models/community.dart';
import '../models/item_post.dart';
import '../models/lostly_notification.dart';
import '../models/pickup_schedule.dart';
import '../models/post_match.dart';
import '../models/post_report.dart';
import '../models/post_save_result.dart';
import '../models/user_preferences.dart';
import '../repositories/auth_repository.dart';
import '../repositories/chats_repository.dart';
import '../repositories/claims_repository.dart';
import '../repositories/communities_repository.dart';
import '../repositories/matches_repository.dart';
import '../repositories/notifications_repository.dart';
import '../repositories/pickup_schedules_repository.dart';
import '../repositories/posts_repository.dart';
import '../repositories/reports_repository.dart';
import '../repositories/user_preferences_repository.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../services/camera_service.dart';
import '../services/firestore_service.dart';
import '../services/image_service.dart';
import '../services/location_service.dart';
import '../services/matching_service.dart';
import '../services/notification_service.dart';
import '../services/qr_service.dart';
import '../services/storage_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'SharedPreferences must be overridden in main()',
  ),
);

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final storageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);
final firebaseMessagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);
final localNotificationsProvider = Provider<FlutterLocalNotificationsPlugin>(
  (ref) => FlutterLocalNotificationsPlugin(),
);
final googleSignInProvider = Provider<GoogleSignIn>(
  (ref) => GoogleSignIn.instance,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
    googleServerClientId: DefaultFirebaseOptions.androidGoogleServerClientId,
  ),
);
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(ref.watch(firestoreProvider)),
);
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.watch(storageProvider)),
);
final imageServiceProvider = Provider<ImageService>(
  (ref) => ImageService(ImagePicker()),
);
final cameraServiceProvider = Provider<CameraService>((ref) => CameraService());
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
final qrServiceProvider = Provider<QrService>((ref) => QrService());
final matchingServiceProvider = Provider<MatchingService>(
  (ref) => MatchingService(),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(
    ref.watch(firebaseMessagingProvider),
    ref.watch(localNotificationsProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(firestoreServiceProvider),
  ),
);
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(firestoreServiceProvider)),
);
final postsRepositoryProvider = Provider<PostsRepository>(
  (ref) => PostsRepository(
    ref.watch(firestoreServiceProvider),
    ref.watch(storageServiceProvider),
    ref.watch(qrServiceProvider),
    ref.watch(matchingServiceProvider),
  ),
);
final chatsRepositoryProvider = Provider<ChatsRepository>(
  (ref) => ChatsRepository(ref.watch(firestoreServiceProvider)),
);
final claimsRepositoryProvider = Provider<ClaimsRepository>(
  (ref) => ClaimsRepository(ref.watch(firestoreServiceProvider)),
);
final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(firestoreServiceProvider)),
);
final communitiesRepositoryProvider = Provider<CommunitiesRepository>(
  (ref) => CommunitiesRepository(ref.watch(firestoreServiceProvider)),
);
final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(firestoreServiceProvider)),
);
final matchesRepositoryProvider = Provider<MatchesRepository>(
  (ref) => MatchesRepository(ref.watch(firestoreServiceProvider)),
);
final pickupSchedulesRepositoryProvider = Provider<PickupSchedulesRepository>(
  (ref) => PickupSchedulesRepository(ref.watch(firestoreServiceProvider)),
);
final userPreferencesRepositoryProvider = Provider<UserPreferencesRepository>(
  (ref) => UserPreferencesRepository(ref.watch(firestoreServiceProvider)),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).valueOrNull?.uid,
);

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream<AppUser?>.value(null);
  }
  return ref.watch(userRepositoryProvider).watchUser(userId);
});

final userByIdProvider = FutureProvider.family<AppUser?, String>((ref, userId) {
  return ref.watch(userRepositoryProvider).getUser(userId);
});

final onboardingProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
final appLocaleProvider = NotifierProvider<AppLocaleController, Locale>(
  AppLocaleController.new,
);

final userPreferencesProvider = StreamProvider<UserPreferences?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) {
    return Stream<UserPreferences?>.value(null);
  }
  final locale = ref.watch(appLocaleProvider).languageCode;
  return ref
      .watch(userPreferencesRepositoryProvider)
      .watchPreferences(user.id)
      .map(
        (preferences) =>
            preferences ??
            UserPreferences.defaults(
              userId: user.id,
              emailAddress: user.email,
            ).copyWith(localeCode: locale),
      );
});

final allPostsProvider = StreamProvider<List<ItemPost>>(
  (ref) => ref.watch(postsRepositoryProvider).streamPosts(),
);
final lostPostsProvider = StreamProvider<List<ItemPost>>(
  (ref) => ref.watch(postsRepositoryProvider).streamPosts(type: PostType.lost),
);
final foundPostsProvider = StreamProvider<List<ItemPost>>(
  (ref) => ref.watch(postsRepositoryProvider).streamPosts(type: PostType.found),
);
final postProvider = StreamProvider.family<ItemPost?, String>((ref, postId) {
  return ref.watch(postsRepositoryProvider).streamPost(postId);
});
final userPostsProvider = StreamProvider.family<List<ItemPost>, String>((
  ref,
  userId,
) {
  return ref.watch(postsRepositoryProvider).streamUserPosts(userId);
});
final matchSuggestionsProvider =
    StreamProvider.family<List<ItemPost>, ItemPost>((ref, post) {
      return ref.watch(postsRepositoryProvider).matchSuggestions(post);
    });

final postMatchesProvider = StreamProvider.family<List<PostMatch>, String>((
  ref,
  postId,
) {
  return ref.watch(matchesRepositoryProvider).streamMatchesForPost(postId);
});

class PostMatchView {
  const PostMatchView({
    required this.post,
    required this.score,
    required this.reasons,
  });

  final ItemPost post;
  final double score;
  final List<String> reasons;
}

final postMatchViewsProvider =
    Provider.family<AsyncValue<List<PostMatchView>>, String>((ref, postId) {
      final matches = ref.watch(postMatchesProvider(postId));
      final posts = ref.watch(allPostsProvider);

      return matches.when(
        data: (items) {
          return posts.when(
            data: (all) {
              final map = {for (final post in all) post.id: post};
              final views =
                  items
                      .map((match) {
                        final otherId = match.otherPostId(postId);
                        if (otherId == null) {
                          return null;
                        }
                        final matchedPost = map[otherId];
                        if (matchedPost == null) {
                          return null;
                        }
                        return PostMatchView(
                          post: matchedPost,
                          score: match.score,
                          reasons: match.reasons,
                        );
                      })
                      .whereType<PostMatchView>()
                      .toList()
                    ..sort((a, b) => b.score.compareTo(a.score));
              return AsyncValue.data(views);
            },
            loading: () => const AsyncLoading<List<PostMatchView>>(),
            error: (error, stackTrace) =>
                AsyncError<List<PostMatchView>>(error, stackTrace),
          );
        },
        loading: () => const AsyncLoading<List<PostMatchView>>(),
        error: (error, stackTrace) =>
            AsyncError<List<PostMatchView>>(error, stackTrace),
      );
    });

final savedPostsProvider = Provider<AsyncValue<List<ItemPost>>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final posts = ref.watch(allPostsProvider);

  return currentUser.when(
    data: (user) {
      return posts.when(
        data: (items) {
          final savedIds = user?.savedPostIds.toSet() ?? <String>{};
          return AsyncValue.data(
            items.where((item) => savedIds.contains(item.id)).toList(),
          );
        },
        loading: () => const AsyncLoading<List<ItemPost>>(),
        error: (error, stackTrace) =>
            AsyncError<List<ItemPost>>(error, stackTrace),
      );
    },
    loading: () => const AsyncLoading<List<ItemPost>>(),
    error: (error, stackTrace) => AsyncError<List<ItemPost>>(error, stackTrace),
  );
});

final chatsProvider = StreamProvider<List<ChatRoom>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream<List<ChatRoom>>.value(const <ChatRoom>[]);
  }
  return ref.watch(chatsRepositoryProvider).streamChats(userId);
});

final messagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  chatId,
) {
  return ref.watch(chatsRepositoryProvider).streamMessages(chatId);
});

final claimsForPostProvider = StreamProvider.family<List<ClaimRequest>, String>(
  (ref, postId) {
    return ref.watch(claimsRepositoryProvider).streamClaimsForPost(postId);
  },
);

final myClaimsProvider = StreamProvider<List<ClaimRequest>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream<List<ClaimRequest>>.value(const <ClaimRequest>[]);
  }
  return ref.watch(claimsRepositoryProvider).streamClaimsForUser(userId);
});

final pickupScheduleForClaimProvider =
    StreamProvider.family<PickupSchedule?, String>((ref, claimId) {
      return ref
          .watch(pickupSchedulesRepositoryProvider)
          .watchForClaim(claimId);
    });

final notificationsProvider = StreamProvider<List<LostlyNotification>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream<List<LostlyNotification>>.value(const <LostlyNotification>[]);
  }
  return ref.watch(notificationsRepositoryProvider).streamForUser(userId);
});

final notificationSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<List<LostlyNotification>>>(notificationsProvider, (
    _,
    next,
  ) {
    next.whenData(
      (notifications) => ref
          .read(notificationServiceProvider)
          .syncFirestoreNotifications(notifications),
    );
  });
});

final communitiesProvider = StreamProvider<List<Community>>(
  (ref) => ref.watch(communitiesRepositoryProvider).streamCommunities(),
);

final reportsProvider = StreamProvider<List<PostReport>>(
  (ref) => ref.watch(reportsRepositoryProvider).streamReports(),
);

final communityByIdProvider = Provider.family<Community?, String>((
  ref,
  communityId,
) {
  return ref
      .watch(communitiesProvider)
      .valueOrNull
      ?.firstWhere(
        (community) => community.id == communityId,
        orElse: () => Community(
          id: communityId,
          name: communityId,
          description: '',
          type: CommunityType.campus,
          locationName: '',
        ),
      );
});

final appAnalyticsProvider = Provider<AsyncValue<AnalyticsSummary>>((ref) {
  final posts = ref.watch(allPostsProvider);
  return posts.when(
    data: (items) => AsyncValue.data(
      AnalyticsSummary(
        lostCount: items.where((post) => post.type == PostType.lost).length,
        foundCount: items.where((post) => post.type == PostType.found).length,
        returnedCount: items
            .where((post) => post.status == PostStatus.returned)
            .length,
        activeCount: items
            .where((post) => post.status != PostStatus.returned)
            .length,
        priorityDocumentCount: items
            .where((post) => post.isPriorityDocument)
            .length,
        rewardedCount: items.where((post) => post.rewardAmount > 0).length,
      ),
    ),
    loading: () => const AsyncLoading<AnalyticsSummary>(),
    error: (error, stackTrace) =>
        AsyncError<AnalyticsSummary>(error, stackTrace),
  );
});

final userAnalyticsProvider = Provider<AsyncValue<AnalyticsSummary>>((ref) {
  final user = ref.watch(currentUserProvider);
  final posts = ref.watch(allPostsProvider);

  return user.when(
    data: (profile) {
      if (profile == null) {
        return const AsyncLoading<AnalyticsSummary>();
      }
      return posts.when(
        data: (items) {
          final mine = items
              .where((post) => post.userId == profile.id)
              .toList();
          return AsyncValue.data(
            AnalyticsSummary(
              lostCount: mine
                  .where((post) => post.type == PostType.lost)
                  .length,
              foundCount: mine
                  .where((post) => post.type == PostType.found)
                  .length,
              returnedCount: mine
                  .where((post) => post.status == PostStatus.returned)
                  .length,
              activeCount: mine
                  .where((post) => post.status != PostStatus.returned)
                  .length,
              priorityDocumentCount: mine
                  .where((post) => post.isPriorityDocument)
                  .length,
              rewardedCount: mine.where((post) => post.rewardAmount > 0).length,
            ),
          );
        },
        loading: () => const AsyncLoading<AnalyticsSummary>(),
        error: (error, stackTrace) =>
            AsyncError<AnalyticsSummary>(error, stackTrace),
      );
    },
    loading: () => const AsyncLoading<AnalyticsSummary>(),
    error: (error, stackTrace) =>
        AsyncError<AnalyticsSummary>(error, stackTrace),
  );
});

final availableCamerasProvider = FutureProvider<List<CameraDescription>>(
  (ref) => ref.watch(cameraServiceProvider).loadAvailableCameras(),
);

final authControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, void>(AuthController.new);
final postActionControllerProvider =
    AsyncNotifierProvider.autoDispose<PostActionController, void>(
      PostActionController.new,
    );
final chatActionControllerProvider =
    AsyncNotifierProvider.autoDispose<ChatActionController, void>(
      ChatActionController.new,
    );
final claimActionControllerProvider =
    AsyncNotifierProvider.autoDispose<ClaimActionController, void>(
      ClaimActionController.new,
    );
final profileActionControllerProvider =
    AsyncNotifierProvider.autoDispose<ProfileActionController, void>(
      ProfileActionController.new,
    );
final reportActionControllerProvider =
    AsyncNotifierProvider.autoDispose<ReportActionController, void>(
      ReportActionController.new,
    );
final preferencesActionControllerProvider =
    AsyncNotifierProvider.autoDispose<PreferencesActionController, void>(
      PreferencesActionController.new,
    );
final pickupScheduleActionControllerProvider =
    AsyncNotifierProvider.autoDispose<PickupScheduleActionController, void>(
      PickupScheduleActionController.new,
    );

class OnboardingController extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(sharedPreferencesProvider).getBool('lostly.onboarding') ??
        false;
  }

  Future<void> complete() async {
    state = true;
    await ref
        .read(sharedPreferencesProvider)
        .setBool('lostly.onboarding', true);
  }
}

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final rawValue =
        ref.read(sharedPreferencesProvider).getString('lostly.themeMode') ??
        ThemeMode.system.name;
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == rawValue,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref
        .read(sharedPreferencesProvider)
        .setString('lostly.themeMode', mode.name);
  }
}

class AppLocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final languageCode =
        ref.read(sharedPreferencesProvider).getString('lostly.locale') ?? 'ru';
    return Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref
        .read(sharedPreferencesProvider)
        .setString('lostly.locale', locale.languageCode);
  }
}

class AuthController extends AsyncNotifier<void> {
  bool _isDisposed = false;

  @override
  FutureOr<void> build() {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
    });
  }

  void _setStateSafely(AsyncValue<void> next) {
    if (_isDisposed) {
      return;
    }
    state = next;
  }

  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    _setStateSafely(const AsyncLoading());
    final authRepository = ref.read(authRepositoryProvider);
    final keepAliveLink = ref.keepAlive();

    try {
      await authRepository.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      _setStateSafely(const AsyncData(null));
    } catch (error, stackTrace) {
      _setStateSafely(AsyncError(error, stackTrace));
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _setStateSafely(const AsyncLoading());
    final authRepository = ref.read(authRepositoryProvider);
    final keepAliveLink = ref.keepAlive();

    try {
      await authRepository.signIn(email: email, password: password);
      _setStateSafely(const AsyncData(null));
    } catch (error, stackTrace) {
      _setStateSafely(AsyncError(error, stackTrace));
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }

  Future<bool> signInWithGoogle() async {
    _setStateSafely(const AsyncLoading());
    final authRepository = ref.read(authRepositoryProvider);
    final keepAliveLink = ref.keepAlive();

    try {
      final didSignIn = await authRepository.signInWithGoogle();
      _setStateSafely(const AsyncData(null));
      return didSignIn;
    } catch (error, stackTrace) {
      _setStateSafely(AsyncError(error, stackTrace));
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }

  Future<void> signOut() async {
    _setStateSafely(const AsyncLoading());
    final authRepository = ref.read(authRepositoryProvider);
    final keepAliveLink = ref.keepAlive();

    try {
      await authRepository.signOut();
      _setStateSafely(const AsyncData(null));
    } catch (error, stackTrace) {
      _setStateSafely(AsyncError(error, stackTrace));
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }
}

class PostActionController extends AsyncNotifier<void> {
  bool _isDisposed = false;

  @override
  FutureOr<void> build() {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
    });
  }

  void _setStateSafely(AsyncValue<void> next) {
    if (_isDisposed) {
      return;
    }
    state = next;
  }

  Future<PostSaveResult> createPost({
    required PostType type,
    required String title,
    required String description,
    required String category,
    required String locationName,
    required double latitude,
    required double longitude,
    required String communityId,
    required List<String> imagePaths,
    required double rewardAmount,
    required bool isAnonymous,
    String? documentType,
  }) async {
    _setStateSafely(const AsyncLoading());
    final author = ref.read(currentUserProvider).valueOrNull;
    if (author == null) {
      throw Exception('Please log in first.');
    }
    final postsRepository = ref.read(postsRepositoryProvider);
    final keepAliveLink = ref.keepAlive();

    try {
      final result = await postsRepository.createPost(
        author: author,
        type: type,
        title: title,
        description: description,
        category: category,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        communityId: communityId,
        imagePaths: imagePaths,
        rewardAmount: rewardAmount,
        isAnonymous: isAnonymous,
        documentType: documentType,
      );
      _setStateSafely(const AsyncData(null));
      return result;
    } catch (error, stackTrace) {
      _setStateSafely(AsyncError(error, stackTrace));
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }

  Future<PostSaveResult> updatePost({
    required ItemPost existing,
    required String title,
    required String description,
    required String category,
    required String locationName,
    required double latitude,
    required double longitude,
    required String communityId,
    required List<String> imagePaths,
    required double rewardAmount,
    required bool isAnonymous,
    String? documentType,
  }) async {
    _setStateSafely(const AsyncLoading());
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) {
      throw Exception('Please log in first.');
    }
    if (currentUser.id != existing.userId && !currentUser.isAdmin) {
      throw Exception('You can edit only your own posts.');
    }
    final postsRepository = ref.read(postsRepositoryProvider);
    final keepAliveLink = ref.keepAlive();

    try {
      final result = await postsRepository.updatePost(
        existing: existing,
        title: title,
        description: description,
        category: category,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        communityId: communityId,
        imagePaths: imagePaths,
        rewardAmount: rewardAmount,
        isAnonymous: isAnonymous,
        documentType: documentType,
      );
      _setStateSafely(const AsyncData(null));
      return result;
    } catch (error, stackTrace) {
      _setStateSafely(AsyncError(error, stackTrace));
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }

  Future<void> deletePost(ItemPost post) async {
    _setStateSafely(const AsyncLoading());
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) {
      throw Exception('Please log in first.');
    }
    if (currentUser.id != post.userId && !currentUser.isAdmin) {
      throw Exception('You can delete only your own posts.');
    }
    final postsRepository = ref.read(postsRepositoryProvider);
    final keepAliveLink = ref.keepAlive();

    try {
      await postsRepository.deletePost(post);
      _setStateSafely(const AsyncData(null));
    } catch (error, stackTrace) {
      _setStateSafely(AsyncError(error, stackTrace));
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }

  Future<void> updateStatus({
    required String postId,
    required PostStatus status,
    String? notifyUserId,
  }) async {
    _setStateSafely(const AsyncLoading());
    final postsRepository = ref.read(postsRepositoryProvider);
    final keepAliveLink = ref.keepAlive();

    try {
      await postsRepository.updateStatus(
        postId: postId,
        status: status,
        notifyUserId: notifyUserId,
      );
      _setStateSafely(const AsyncData(null));
    } catch (error, stackTrace) {
      _setStateSafely(AsyncError(error, stackTrace));
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }

  Future<void> toggleSave(String postId, bool isSaved) async {
    _setStateSafely(const AsyncLoading());
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('Please log in first.');
    }
    final userRepository = ref.read(userRepositoryProvider);
    final keepAliveLink = ref.keepAlive();

    try {
      await userRepository.toggleSavedPost(
        userId: userId,
        postId: postId,
        isSaved: isSaved,
      );
      _setStateSafely(const AsyncData(null));
    } catch (error, stackTrace) {
      _setStateSafely(AsyncError(error, stackTrace));
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }
}

class ChatActionController extends AsyncNotifier<void> {
  bool _isDisposed = false;

  @override
  FutureOr<void> build() {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
    });
  }

  void _setStateSafely(AsyncValue<void> next) {
    if (_isDisposed) {
      return;
    }
    state = next;
  }

  Future<String> openChat({
    required String postId,
    required String otherUserId,
    required String otherUserName,
  }) async {
    _setStateSafely(const AsyncLoading());
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) {
      throw Exception('Please log in first.');
    }
    final chatsRepository = ref.read(chatsRepositoryProvider);
    final keepAliveLink = ref.keepAlive();

    try {
      final chatId = await chatsRepository.getOrCreateChat(
        postId: postId,
        currentUserId: currentUser.id,
        otherUserId: otherUserId,
        currentUserName: currentUser.displayName,
        otherUserName: otherUserName,
      );
      _setStateSafely(const AsyncData(null));
      return chatId;
    } catch (error, stackTrace) {
      _setStateSafely(AsyncError(error, stackTrace));
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String text,
  }) async {
    _setStateSafely(const AsyncLoading());
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('Please log in first.');
    }
    final chatsRepository = ref.read(chatsRepositoryProvider);
    final keepAliveLink = ref.keepAlive();

    try {
      await chatsRepository.sendMessage(
        chatId: chatId,
        senderId: userId,
        receiverId: receiverId,
        text: text,
      );
      _setStateSafely(const AsyncData(null));
    } catch (error, stackTrace) {
      _setStateSafely(AsyncError(error, stackTrace));
      rethrow;
    } finally {
      keepAliveLink.close();
    }
  }

  Future<void> markRead({required String chatId}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }
    final chatsRepository = ref.read(chatsRepositoryProvider);
    final keepAliveLink = ref.keepAlive();

    try {
      await chatsRepository.markChatRead(chatId: chatId, userId: userId);
    } finally {
      keepAliveLink.close();
    }
  }
}

class ClaimActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submitClaim({
    required String postId,
    required String ownerId,
    required String message,
    required String evidence,
    required Map<String, String> answers,
  }) async {
    state = const AsyncLoading();
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) {
      throw Exception('Please log in first.');
    }

    final claim = ClaimRequest(
      id: '',
      postId: postId,
      claimantId: currentUser.id,
      claimantName: currentUser.displayName,
      ownerId: ownerId,
      message: message,
      evidence: evidence,
      answers: answers,
      verificationChecklist: {
        for (final entry in answers.entries)
          entry.key: entry.value.trim().isNotEmpty,
      },
      status: ClaimStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = await AsyncValue.guard(
      () => ref.read(claimsRepositoryProvider).createClaim(claim),
    );
  }

  Future<void> updateClaimStatus({
    required ClaimRequest claim,
    required ClaimStatus status,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(claimsRepositoryProvider)
          .updateClaimStatus(claim: claim, status: status),
    );
  }
}

class ProfileActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updateProfile({
    required AppUser user,
    required String displayName,
    required String bio,
    String? photoUrl,
    List<String>? communityIds,
  }) async {
    state = const AsyncLoading();
    final updatedUser = user.copyWith(
      displayName: displayName.trim(),
      bio: bio.trim(),
      photoUrl: photoUrl ?? user.photoUrl,
      communityIds: communityIds ?? user.communityIds,
      updatedAt: DateTime.now(),
    );
    state = await AsyncValue.guard(
      () => ref.read(userRepositoryProvider).updateProfile(updatedUser),
    );
  }

  Future<void> syncFcmToken() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    await ref
        .read(userRepositoryProvider)
        .saveFcmToken(
          userId,
          await ref.read(notificationServiceProvider).getFcmToken(),
        );
  }
}

class ReportActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createReport({
    required String postId,
    required String reason,
    required String details,
  }) async {
    state = const AsyncLoading();
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw Exception('Please log in first.');
    }

    final report = PostReport(
      id: '',
      postId: postId,
      reporterId: userId,
      reason: reason,
      details: details,
      createdAt: DateTime.now(),
    );

    state = await AsyncValue.guard(
      () => ref.read(reportsRepositoryProvider).createReport(report),
    );
  }

  Future<void> resolveReport(String reportId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(reportsRepositoryProvider).resolveReport(reportId),
    );
  }
}

class PreferencesActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> savePreferences({required UserPreferences preferences}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(userPreferencesRepositoryProvider)
          .save(preferences.copyWith(updatedAt: DateTime.now()));
      await ref
          .read(appLocaleProvider.notifier)
          .setLocale(Locale(preferences.localeCode));
    });
  }
}

class PickupScheduleActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<String> createOrUpdateSchedule({
    required PickupSchedule schedule,
  }) async {
    state = const AsyncLoading();

    try {
      final scheduleId = await ref
          .read(pickupSchedulesRepositoryProvider)
          .createOrUpdate(schedule);

      await ref
          .read(claimsRepositoryProvider)
          .attachPickupScheduleId(
            claimId: schedule.claimId,
            pickupScheduleId: scheduleId,
          );

      await ref
          .read(notificationsRepositoryProvider)
          .createNotification(
            userId: schedule.claimantId,
            title: 'Назначена передача вещи',
            body:
                'Владелец назначил встречу на ${schedule.locationName}. Проверьте дату и время.',
            type: NotificationType.reminder,
            referenceId: schedule.postId,
            data: <String, String>{
              'postId': schedule.postId,
              'claimId': schedule.claimId,
              'scheduleId': scheduleId,
            },
          );
      await ref
          .read(notificationsRepositoryProvider)
          .createNotification(
            userId: schedule.ownerId,
            title: 'Встреча для возврата сохранена',
            body:
                'Напоминание о встрече включено для ${schedule.locationName}.',
            type: NotificationType.reminder,
            referenceId: schedule.postId,
            data: <String, String>{
              'postId': schedule.postId,
              'claimId': schedule.claimId,
              'scheduleId': scheduleId,
            },
          );

      state = const AsyncData(null);
      return scheduleId;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateStatus({
    required String scheduleId,
    required PickupScheduleStatus status,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(pickupSchedulesRepositoryProvider)
          .updateStatus(scheduleId: scheduleId, status: status),
    );
  }
}

extension AsyncValueX<T> on AsyncValue<T> {
  T? get valueOrNull => asData?.value;
}
