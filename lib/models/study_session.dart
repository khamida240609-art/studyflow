class StudySession {
  final String id;
  final String userId;
  final int durationMinutes;
  final DateTime startedAt;
  final DateTime endedAt;
  final String category;

  StudySession({
    required this.id,
    required this.userId,
    required this.durationMinutes,
    required this.startedAt,
    required this.endedAt,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'durationMinutes': durationMinutes,
    'startedAt': startedAt,
    'endedAt': endedAt,
    'category': category,
  };

  factory StudySession.fromMap(String id, Map<String, dynamic> map) {
    return StudySession(
      id: id,
      userId: map['userId'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 0,
      startedAt: DateTime.parse(map['startedAt'] as String),
      endedAt: DateTime.parse(map['endedAt'] as String),
      category: map['category'] ?? 'General',
    );
  }
}
