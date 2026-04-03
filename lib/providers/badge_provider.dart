import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badge.dart';
import '../models/study_session.dart';

class BadgeProvider extends ChangeNotifier {
  List<Badge> badges = const [];
  String? selectedBadgeId;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedIds = prefs.getStringList('badges_unlocked') ?? [];
    selectedBadgeId = prefs.getString('badge_selected');
    badges = _allBadges
        .map((b) => b.copyWith(unlocked: unlockedIds.contains(b.id)))
        .toList();
    notifyListeners();
  }

  Future<List<Badge>> evaluate(List<StudySession> sessions) async {
    final unlocked = <String>{};
    for (final b in badges) {
      if (b.unlocked) unlocked.add(b.id);
    }

    final total = sessions.length;
    final streak = _calculateStreak(sessions);
    final morning = sessions.any((s) => s.startedAt.hour < 9);
    final night = sessions.any((s) => s.startedAt.hour >= 22);
    final todayCount = sessions.where(_isToday).length;

    if (total >= 1) unlocked.add('first_session');
    if (streak >= 3) unlocked.add('streak_3');
    if (streak >= 7) unlocked.add('streak_7');
    if (streak >= 30) unlocked.add('streak_30');
    if (morning) unlocked.add('morning');
    if (night) unlocked.add('night');
    if (todayCount >= 3) unlocked.add('marathon');

    badges = _allBadges
        .map((b) => b.copyWith(unlocked: unlocked.contains(b.id)))
        .toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('badges_unlocked', unlocked.toList());
    notifyListeners();
    return badges.where((b) => b.unlocked).toList();
  }

  Future<void> selectBadge(String id) async {
    selectedBadgeId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('badge_selected', id);
    notifyListeners();
  }

  Badge? get selectedBadge {
    if (selectedBadgeId == null) return null;
    return badges.firstWhere((b) => b.id == selectedBadgeId, orElse: () => badges.first);
  }

  int _calculateStreak(List<StudySession> sessions) {
    if (sessions.isEmpty) return 0;
    final days = sessions
        .map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime? current = days.isEmpty ? null : days.first;
    for (final d in days) {
      if (current == null) break;
      if (d == current) {
        streak += 1;
        current = current.subtract(const Duration(days: 1));
      } else if (d.isBefore(current)) {
        break;
      }
    }
    return streak;
  }

  bool _isToday(StudySession s) {
    final now = DateTime.now();
    return s.startedAt.year == now.year &&
        s.startedAt.month == now.month &&
        s.startedAt.day == now.day;
  }
}

const List<Badge> _allBadges = [
  Badge(id: 'first_session', title: 'First Session', description: 'Complete your first study session', icon: '🎉'),
  Badge(id: 'streak_3', title: '3-Day Streak', description: 'Study 3 days in a row', icon: '🔥'),
  Badge(id: 'streak_7', title: '7-Day Streak', description: 'Study 7 days in a row', icon: '📆'),
  Badge(id: 'morning', title: 'Morning Study', description: 'Study before 9 AM', icon: '🌅'),
  Badge(id: 'night', title: 'Night Owl', description: 'Study after 10 PM', icon: '🌙'),
  Badge(id: 'marathon', title: 'Marathon', description: '3+ sessions in one day', icon: '🏃'),
];
