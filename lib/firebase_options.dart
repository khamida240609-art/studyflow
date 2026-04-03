// МАҢЫЗДЫ: Бұл файлды "flutterfire configure" командасымен автоматты түрде генерациялаңыз!
// Нұсқаулар:
//   1. dart pub global activate flutterfire_cli
//   2. flutterfire configure
//   3. Өзіңіздің Firebase жобаңызды таңдаңыз
//
// Сол кезде бұл файл толтырылады. Мысал үшін placeholder қалдырылды.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  // TODO: "flutterfire configure" іске қосқаннан кейін мына мәндерді ауыстырыңыз
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCei0lML1ieyRV2bTsycg7C0hcYkkdv_08',
    appId: '1:709091210970:web:8970111c49d294114457e3',
    messagingSenderId: '709091210970',
    projectId: 'studysprint-5ca96',
    authDomain: 'studysprint-5ca96.firebaseapp.com',
    storageBucket: 'studysprint-5ca96.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBfF6AafuphEqsbml-BOl0s0C82BNmfwWA',
    appId: '1:709091210970:android:c9272a2287d683074457e3',
    messagingSenderId: '709091210970',
    projectId: 'studysprint-5ca96',
    storageBucket: 'studysprint-5ca96.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.studysprint',
  );
}
