import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomMode { deep, light, exam }

class RoomModel {
  final String id;
  final String name;
  final String subject;
  final RoomMode mode;
  final int focusMinutes;
  final int breakMinutes;
  final String createdBy;
  final bool isActive;
  final int participantCount;
  final DateTime? timerStartedAt;
  final DateTime createdAt;

  RoomModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.mode,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.createdBy,
    this.isActive = true,
    this.participantCount = 0,
    this.timerStartedAt,
    required this.createdAt,
  });

  String get modeLabel {
    switch (mode) {
      case RoomMode.deep: return 'Deep Work';
      case RoomMode.light: return 'Light Focus';
      case RoomMode.exam: return 'Exam Mode';
    }
  }

  factory RoomModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      name: d['name'] ?? '',
      subject: d['subject'] ?? '',
      mode: RoomMode.values.firstWhere(
        (e) => e.name == (d['mode'] ?? 'deep'),
        orElse: () => RoomMode.deep,
      ),
      focusMinutes: d['focusMinutes'] ?? 50,
      breakMinutes: d['breakMinutes'] ?? 10,
      createdBy: d['createdBy'] ?? '',
      isActive: d['isActive'] ?? true,
      participantCount: d['participantCount'] ?? 0,
      timerStartedAt: (d['timerStartedAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'subject': subject,
    'mode': mode.name,
    'focusMinutes': focusMinutes,
    'breakMinutes': breakMinutes,
    'createdBy': createdBy,
    'isActive': isActive,
    'participantCount': participantCount,
    'timerStartedAt': timerStartedAt != null
        ? Timestamp.fromDate(timerStartedAt!)
        : null,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
