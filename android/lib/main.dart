import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/localization/app_localizations.dart';
import 'firebase_options.dart';
import 'providers/app_providers.dart';
import 'routes/app_router.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'ru';
  await initializeDateFormatting('ru');
  await initializeDateFormatting('en');
  await initializeDateFormatting('kk');

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  final preferences = await SharedPreferences.getInstance();
  final localNotifications = FlutterLocalNotificationsPlugin();

  final notificationService = NotificationService(
    FirebaseMessaging.instance,
    localNotifications,
  );

  try {
    await notificationService.initialize();
  } catch (error) {
    debugPrint('Notification initialization warning: $error');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        localNotificationsProvider.overrideWithValue(localNotifications),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const LostlyApp(),
    ),
  );
}

class LostlyApp extends ConsumerStatefulWidget {
  const LostlyApp({super.key});

  @override
  ConsumerState<LostlyApp> createState() => _LostlyAppState();
}

class _LostlyAppState extends ConsumerState<LostlyApp> {
  StreamSubscription<AppNotificationRoute>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationSubscription = ref
          .read(notificationServiceProvider)
          .routeStream
          .listen(_handleRoute);
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _handleRoute(AppNotificationRoute route) {
    final router = ref.read(routerProvider);
    final chatId = route.data['chatId'];
    final otherUserId = route.data['otherUserId'];
    final otherUserName = route.data['otherUserName'];
    final postId = route.data['postId'] ?? route.referenceId;

    if (chatId != null && chatId.isNotEmpty) {
      final query = <String, String>{
        if (otherUserId != null && otherUserId.isNotEmpty)
          'otherUserId': otherUserId,
        if (otherUserName != null && otherUserName.isNotEmpty)
          'otherUserName': otherUserName,
      };
      router.push(
        Uri(path: '/chat/$chatId', queryParameters: query).toString(),
      );
      return;
    }

    if (postId != null && postId.isNotEmpty) {
      router.push('/item/$postId');
      return;
    }

    router.push('/notifications');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationSyncProvider);

    ref.listen(authStateProvider, (_, next) {
      if (next.valueOrNull != null) {
        ref.read(profileActionControllerProvider.notifier).syncFcmToken();
      }
    });

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(appLocaleProvider);
    Intl.defaultLocale = locale.languageCode;
    return MaterialApp.router(
      title: 'Lostly',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
