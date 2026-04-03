import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalProvider extends ChangeNotifier {
  int targetSessions = 3;
  int completedSessions = 0;
  DateTime _day = DateTime.now();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    targetSessions = prefs.getInt('goal_target') ?? 3;
    completedSessions = prefs.getInt('goal_completed') ?? 0;
    final storedDay = prefs.getString('goal_day');
    if (storedDay != null) {
      _day = DateTime.parse(storedDay);
    }
    _resetIfNewDay();
    notifyListeners();
  }

  bool get isCompleted => completedSessions >= targetSessions;

  void setTarget(int value) {
    targetSessions = value;
    _persist();
    notifyListeners();
  }

  void onSessionCompleted() {
    _resetIfNewDay();
    completedSessions += 1;
    _persist();
    notifyListeners();
  }

  void _resetIfNewDay() {
    final now = DateTime.now();
    if (_day.year != now.year || _day.month != now.month || _day.day != now.day) {
      _day = now;
      completedSessions = 0;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('goal_target', targetSessions);
    await prefs.setInt('goal_completed', completedSessions);
    await prefs.setString('goal_day', _day.toIso8601String());
  }
}
