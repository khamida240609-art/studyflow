import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'app_config.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/study_session_service.dart';
import 'services/analytics_service.dart';
import 'services/teacher_service.dart';
import 'services/group_service.dart';
import 'providers/session_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/badge_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/teacher_provider.dart';
import 'providers/group_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/router.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) {
    return Material(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            details.exceptionAsString(),
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  if (!AuthService.kUseMockAuth && !AppConfig.kUseMockData) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.init();
  }
  runApp(const StudyFlowApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('[FCM] onBackgroundMessage: ${message.messageId}');
}

class StudyFlowApp extends StatefulWidget {
  const StudyFlowApp({super.key});

  @override
  State<StudyFlowApp> createState() => _StudyFlowAppState();
}

class _StudyFlowAppState extends State<StudyFlowApp> {
  late final AuthService _auth;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthService();
    _router = AppRouter.init(_auth);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider(create: (_) => GoalProvider()..load()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()..load()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        Provider(create: (_) => GroupService()),
        ChangeNotifierProvider(
          create: (context) => GroupProvider(context.read<GroupService>()),
        ),
        Provider(create: (_) => StudySessionService()),
        Provider(create: (_) => AnalyticsService()),
        Provider(create: (_) => TeacherService()),
        ChangeNotifierProxyProvider<AuthService, SessionProvider>(
          create: (context) => SessionProvider(
            context.read<StudySessionService>(),
            userId: context.read<AuthService>().userId ?? 'local-user',
          ),
          update: (context, auth, session) {
            session!.updateUser(auth.userId ?? 'local-user');
            return session;
          },
        ),
        ChangeNotifierProvider(
          create: (context) => AnalyticsProvider(
            context.read<AnalyticsService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TeacherProvider(
            context.read<TeacherService>(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final mode = context.watch<ThemeProvider>().mode;
          return MaterialApp.router(
            title: 'StudyFlow',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: mode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
