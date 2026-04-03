# StudyFlow

StudyFlow is a smart study companion app for students: Pomodoro focus sessions, group study accountability, and AI-powered insights.

## Қадамдар (How to run)

### 1. Firebase жобасын жасаңыз
1. https://console.firebase.google.com → жаңа жоба
2. **Authentication** → Email/Password қосыңыз
3. **Firestore Database** → жасаңыз (test mode)
4. **Cloud Messaging** → қосыңыз

### 2. FlutterFire CLI орнатыңыз
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
`lib/firebase_options.dart` файлы автоматты жасалады.

### 3. Dependency орнатыңыз
```bash
flutter pub get
```

### 4. Іске қосыңыз
```bash
flutter run                   # телефон/эмулятор
flutter run -d chrome         # браузер
flutter build apk             # Android APK
```

## Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    match /rooms/{roomId} {
      allow read: if request.auth != null;
      allow create, update: if request.auth != null;
      match /participants/{uid} {
        allow read: if request.auth != null;
        allow write: if request.auth.uid == uid;
      }
      match /messages/{msgId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
      }
    }
    match /sessions/{sessionId} {
      allow read, write: if request.auth != null
        && request.auth.uid == resource.data.uid;
    }
  }
}
```

## Firestore индекстер

Firestore консолінде мына composite index жасаңыз:
- Collection: `rooms`
- Fields: `isActive ASC`, `participantCount DESC`

## Папка структурасы
```
lib/
├── main.dart
├── firebase_options.dart        ← flutterfire configure жасайды
├── models/
│   ├── user_model.dart
│   ├── room_model.dart
│   └── message_model.dart      (SessionModel да осында)
├── services/
│   ├── auth_service.dart
│   ├── room_service.dart
│   └── session_service.dart
├── screens/
│   ├── auth/login_screen.dart
│   ├── auth/register_screen.dart
│   ├── home/home_screen.dart
│   ├── room/room_screen.dart
│   └── profile/profile_screen.dart
├── widgets/
│   ├── timer_widget.dart
│   ├── room_card.dart
│   └── create_room_dialog.dart
└── utils/
    ├── theme.dart
    └── router.dart
```
