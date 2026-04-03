import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class SessionService extends ChangeNotifier {
  FirebaseFirestore? _db;

  String? _activeSessionId;

  SessionService() {
    if (!AuthService.kUseMockAuth) {
      _db = FirebaseFirestore.instance;
    }
  }

  Future<String> startSession(String uid, String roomId) async {
    if (AuthService.kUseMockAuth) {
      _activeSessionId = 'mock-session';
      return _activeSessionId!;
    }
    final ref = _db!.collection('sessions').doc();
    await ref.set({
      'uid': uid,
      'roomId': roomId,
      'startedAt': FieldValue.serverTimestamp(),
      'completedAt': null,
      'leftEarly': false,
      'sprintsCompleted': 0,
      'xpEarned': 0,
    });
    _activeSessionId = ref.id;
    return ref.id;
  }

  Future<void> completeSession({
    required String uid,
    required String roomId,
    required int sprintsCompleted,
    required int focusMinutesPerSprint,
    bool leftEarly = false,
  }) async {
    if (AuthService.kUseMockAuth) {
      _activeSessionId = null;
      notifyListeners();
      return;
    }
    final xp = leftEarly ? 0 : sprintsCompleted * 50;
    final focusMinutes = sprintsCompleted * focusMinutesPerSprint;

    // Save session record
    if (_activeSessionId != null) {
      await _db!.collection('sessions').doc(_activeSessionId).update({
        'completedAt': FieldValue.serverTimestamp(),
        'leftEarly': leftEarly,
        'sprintsCompleted': sprintsCompleted,
        'xpEarned': xp,
      });
    }

    if (!leftEarly) {
      // Update user stats + streak
      final userRef = _db!.collection('users').doc(uid);
      final userSnap = await userRef.get();
      final data = userSnap.data();

      final lastDate = (data?['lastSessionDate'] as Timestamp?)?.toDate();
      final now = DateTime.now();
      final isConsecutive = lastDate != null &&
          now.difference(lastDate).inHours < 36;

      await userRef.update({
        'lastSessionDate': FieldValue.serverTimestamp(),
        'totalSessions': FieldValue.increment(1),
        'totalFocusMinutes': FieldValue.increment(focusMinutes),
        'xp': FieldValue.increment(xp),
        'streakCount': isConsecutive
            ? FieldValue.increment(1)
            : 1,
      });
    }

    _activeSessionId = null;
    notifyListeners();
  }
}
