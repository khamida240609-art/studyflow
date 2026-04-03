import 'package:flutter/foundation.dart';
import '../models/student_stats.dart';
import '../services/teacher_service.dart';

class TeacherProvider extends ChangeNotifier {
  final TeacherService _service;
  List<StudentStats> students = const [];

  TeacherProvider(this._service) {
    students = _service.getStudents();
  }
}
