import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Replace this file by running `flutterfire configure` with your real project.
class DefaultFirebaseOptions {
  /// Paste your Web OAuth client ID here if you want to keep it in code:
  /// `1234567890-xxxxx.apps.googleusercontent.com`
  ///
  /// Preferred Android fallback:
  /// 1. Enable Google provider in Firebase Auth
  /// 2. Add a Web app in Firebase
  /// 3. Re-download `android/app/google-services.json`
  static const String androidGoogleServerClientIdManual =
      '351213312840-q19mfgfj30jf28m40dbbgtqj8lq27scv.apps.googleusercontent.com';

  /// On Android, `google_sign_in` 7.x requires the Web OAuth client ID as
  /// `serverClientId`. Provide it with:
  /// `--dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com`
  static const String androidGoogleServerClientIdFromEnv =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');

  static String get androidGoogleServerClientId {
    if (androidGoogleServerClientIdManual.trim().isNotEmpty) {
      return androidGoogleServerClientIdManual.trim();
    }
    return androidGoogleServerClientIdFromEnv.trim();
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return android;
      case TargetPlatform.fuchsia:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:123456789012:web:lostlydemo123456',
    messagingSenderId: '123456789012',
    projectId: 'lostly-demo',
    authDomain: 'lostly-demo.firebaseapp.com',
    storageBucket: 'lostly-demo.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDDuDgHYDk8MMtaDHAl_-bje5B3-BteHYU',
    appId: '1:351213312840:android:4783f230ac9f66aa91717d',
    messagingSenderId: '351213312840',
    projectId: 'lostly-f5b5d',
    storageBucket: 'lostly-f5b5d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:123456789012:ios:lostlydemo123456',
    messagingSenderId: '123456789012',
    projectId: 'lostly-demo',
    storageBucket: 'lostly-demo.firebasestorage.app',
    iosBundleId: 'com.lostly.app',
  );
}
