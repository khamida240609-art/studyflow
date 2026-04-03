class StudentStats {
  final String id;
  final String name;
  final int totalSessions;
  final double avgDuration;
  final List<int> weeklyActivity;

  const StudentStats({
    required this.id,
    required this.name,
    required this.totalSessions,
    required this.avgDuration,
    required this.weeklyActivity,
  });
}
