import '../models/student_stats.dart';

class TeacherService {
  List<StudentStats> getStudents() {
    return const [
      StudentStats(
        id: 's1',
        name: 'Aruzhan K.',
        totalSessions: 42,
        avgDuration: 38.5,
        weeklyActivity: [3, 4, 2, 5, 4, 1, 0],
      ),
      StudentStats(
        id: 's2',
        name: 'Dias T.',
        totalSessions: 27,
        avgDuration: 44.0,
        weeklyActivity: [1, 2, 3, 2, 3, 2, 1],
      ),
      StudentStats(
        id: 's3',
        name: 'Mira S.',
        totalSessions: 58,
        avgDuration: 51.2,
        weeklyActivity: [4, 5, 4, 6, 3, 2, 1],
      ),
    ];
  }
}
