import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_config.dart';
import '../models/study_session.dart';

class AnalyticsService {
  Future<List<String>> generateInsights(List<StudySession> sessions, {String? question}) async {
    if (AppConfig.geminiApiKey.isEmpty) {
      return _mockInsights(sessions, question: question);
    }
    return _geminiInsights(sessions, question: question);
  }

  Future<List<String>> _geminiInsights(List<StudySession> sessions, {String? question}) async {
    final prompt = _buildPrompt(sessions, question: question);
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${AppConfig.geminiApiKey}',
    );
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {'temperature': 0.6, 'maxOutputTokens': 256},
      }),
    );
    if (res.statusCode != 200) {
      return _mockInsights(sessions);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
    if (text == null || text.isEmpty) return _mockInsights(sessions);
    return text.split('\n').where((e) => e.trim().isNotEmpty).toList();
  }

  List<String> _mockInsights(List<StudySession> sessions, {String? question}) {
    if (sessions.isEmpty) {
      return [
        'No sessions yet — start your first study sprint!',
        'Try 25–45 minute sessions for a strong focus baseline.',
      ];
    }
    final avg = sessions.map((s) => s.durationMinutes).reduce((a, b) => a + b) / sessions.length;
    final byDay = <int, int>{};
    for (final s in sessions) {
      byDay[s.startedAt.weekday] = (byDay[s.startedAt.weekday] ?? 0) + 1;
    }
    final bestDay = byDay.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final dayName = _weekdayName(bestDay.first.key);
    final list = [
      'Your average session duration is ${avg.toStringAsFixed(1)} minutes.',
      'Your most productive day is $dayName.',
      'You are most consistent when you study after school hours.',
    ];
    if (question != null && question.trim().isNotEmpty) {
      list.insert(0, 'Answer to your question: keep sessions consistent and short.');
    }
    return list;
  }

  String _buildPrompt(List<StudySession> sessions, {String? question}) {
    final lines = sessions.map((s) =>
        '${s.startedAt.toIso8601String()},${s.durationMinutes},${s.category}').join('\n');
    final q = (question != null && question.trim().isNotEmpty)
        ? 'User question: $question\n'
        : '';
    return 'You are a study coach. $q Given sessions as CSV (date,duration,category), '
        'write 3 short insights for the student. Keep it under 3 bullet points.\n$lines';
  }

  String _weekdayName(int d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(d - 1).clamp(0, 6)];
  }
}
