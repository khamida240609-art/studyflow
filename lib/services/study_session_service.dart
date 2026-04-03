import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_config.dart';
import '../models/study_session.dart';

class StudySessionService {
  final FirebaseFirestore? _db;
  final List<StudySession> _mockSessions = [];
  final StreamController<List<StudySession>> _mockStream =
      StreamController<List<StudySession>>.broadcast();

  StudySessionService()
      : _db = AppConfig.kUseMockData ? null : FirebaseFirestore.instance;

  Stream<List<StudySession>> sessionsStream(String userId) {
    if (AppConfig.kUseMockData) {
      return _mockStream.stream;
    }
    return _db!
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return StudySession(
                id: d.id,
                userId: data['userId'] ?? '',
                durationMinutes: data['durationMinutes'] ?? 0,
                startedAt: (data['startedAt'] as Timestamp).toDate(),
                endedAt: (data['endedAt'] as Timestamp).toDate(),
                category: data['category'] ?? 'General',
              );
            }).toList());
  }

  Future<void> addSession(StudySession session) async {
    if (AppConfig.kUseMockData) {
      _mockSessions.insert(0, session);
      _mockStream.add(List<StudySession>.unmodifiable(_mockSessions));
      return;
    }
    await _db!.collection('sessions').add({
      'userId': session.userId,
      'durationMinutes': session.durationMinutes,
      'startedAt': Timestamp.fromDate(session.startedAt),
      'endedAt': Timestamp.fromDate(session.endedAt),
      'category': session.category,
    });
  }

  void dispose() {
    _mockStream.close();
  }
}
