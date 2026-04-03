import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/study_session.dart';
import '../services/study_session_service.dart';

class SessionProvider extends ChangeNotifier {
  final StudySessionService _service;
  String _userId;

  SessionProvider(this._service, {required String userId}) : _userId = userId {
    _sub = _service.sessionsStream(_userId).listen((items) {
      sessions = items;
      notifyListeners();
    });
  }

  List<StudySession> sessions = [];
  DateTime? _start;
  String _category = 'General';
  Timer? _ticker;
  int elapsedSeconds = 0;
  StreamSubscription<List<StudySession>>? _sub;

  bool get isRunning => _start != null;
  String get category => _category;
  String get userId => _userId;

  void start({required String category}) {
    if (isRunning) return;
    _category = category;
    _start = DateTime.now();
    elapsedSeconds = 0;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds += 1;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<StudySession?> stop() async {
    if (!isRunning) return null;
    final end = DateTime.now();
    final start = _start!;
    _ticker?.cancel();
    _ticker = null;
    _start = null;
    final minutes = (end.difference(start).inSeconds / 60).ceil();
    final session = StudySession(
      id: const Uuid().v4(),
      userId: _userId,
      durationMinutes: minutes,
      startedAt: start,
      endedAt: end,
      category: _category,
    );
    await _service.addSession(session);
    elapsedSeconds = 0;
    notifyListeners();
    return session;
  }

  void updateUser(String newUserId) {
    if (newUserId == _userId) return;
    _userId = newUserId;
    _sub?.cancel();
    _sub = _service.sessionsStream(_userId).listen((items) {
      sessions = items;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
