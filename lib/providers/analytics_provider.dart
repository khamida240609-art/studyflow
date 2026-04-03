import 'package:flutter/foundation.dart';
import '../models/study_session.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _service;
  List<String> insights = [];
  bool loading = false;

  AnalyticsProvider(this._service);

  Future<void> generate(List<StudySession> sessions) async {
    loading = true;
    notifyListeners();
    insights = await _service.generateInsights(sessions);
    loading = false;
    notifyListeners();
  }

  Future<void> ask(List<StudySession> sessions, String question) async {
    loading = true;
    notifyListeners();
    insights = await _service.generateInsights(sessions, question: question);
    loading = false;
    notifyListeners();
  }
}
