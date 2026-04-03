import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/enums/app_enums.dart';
import '../firebase_options.dart';
import '../models/lostly_notification.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

class AppNotificationRoute {
  const AppNotificationRoute({
    required this.type,
    required this.referenceId,
    this.data = const <String, String>{},
  });

  final String type;
  final String? referenceId;
  final Map<String, String> data;
}

class NotificationService {
  NotificationService(this._messaging, this._localNotifications);

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Set<String> _shownFirestoreNotifications = <String>{};
  final StreamController<AppNotificationRoute> _routeController =
      StreamController<AppNotificationRoute>.broadcast();

  Stream<AppNotificationRoute> get routeStream => _routeController.stream;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: iOS);

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }
        final route = _decodePayload(payload);
        if (route != null) {
          _routeController.add(route);
        }
      },
    );
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) {
        return;
      }
      await showLocalNotification(
        id: notification.hashCode,
        title: notification.title ?? 'Lostly',
        body: notification.body ?? '',
        payload: _encodePayload(
          type: message.data['type'] ?? 'status',
          referenceId: message.data['referenceId'] ?? message.data['postId'],
          data: message.data.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        ),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _routeController.add(
        AppNotificationRoute(
          type: message.data['type'] ?? 'status',
          referenceId: message.data['referenceId'] ?? message.data['postId'],
          data: message.data.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        ),
      );
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _routeController.add(
        AppNotificationRoute(
          type: initialMessage.data['type'] ?? 'status',
          referenceId:
              initialMessage.data['referenceId'] ??
              initialMessage.data['postId'],
          data: initialMessage.data.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        ),
      );
    }
  }

  Future<String?> getFcmToken() => _messaging.getToken();

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) {
    const androidDetails = AndroidNotificationDetails(
      'lostly_alerts',
      'Уведомления Lostly',
      channelDescription: 'Оповещения о чатах, заявках и совпадениях в Lostly',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    return _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  Future<void> syncFirestoreNotifications(
    List<LostlyNotification> notifications,
  ) async {
    for (final notification in notifications.where((item) => !item.isRead)) {
      if (_shownFirestoreNotifications.add(notification.id)) {
        await showLocalNotification(
          id: notification.id.hashCode,
          title: notification.title,
          body: notification.body,
          payload: _encodePayload(
            type: notification.type.value,
            referenceId: notification.referenceId,
            data: notification.data,
          ),
        );
      }
    }
  }

  String _encodePayload({
    required String type,
    String? referenceId,
    Map<String, String> data = const <String, String>{},
  }) {
    return jsonEncode(<String, dynamic>{
      'type': type,
      'referenceId': referenceId,
      'data': data,
    });
  }

  AppNotificationRoute? _decodePayload(String payload) {
    try {
      final raw = jsonDecode(payload);
      if (raw is! Map<String, dynamic>) {
        return null;
      }
      final data =
          (raw['data'] as Map<dynamic, dynamic>? ?? <dynamic, dynamic>{}).map(
            (key, value) => MapEntry('$key', '$value'),
          );
      return AppNotificationRoute(
        type: raw['type'] as String? ?? 'status',
        referenceId: raw['referenceId'] as String?,
        data: data,
      );
    } catch (_) {
      return null;
    }
  }
}
