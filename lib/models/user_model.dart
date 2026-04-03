import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final int streakCount;
  final int totalSessions;
  final int totalFocusMinutes;
  final int xp;
  final DateTime? lastSessionDate;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.streakCount = 0,
    this.totalSessions = 0,
    this.totalFocusMinutes = 0,
    this.xp = 0,
    this.lastSessionDate,
  });

  int get level => (xp / 500).floor() + 1;

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: d['uid'] ?? doc.id,
      displayName: d['displayName'] ?? '',
      email: d['email'] ?? '',
      streakCount: d['streakCount'] ?? 0,
      totalSessions: d['totalSessions'] ?? 0,
      totalFocusMinutes: d['totalFocusMinutes'] ?? 0,
      xp: d['xp'] ?? 0,
      lastSessionDate: (d['lastSessionDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'streakCount': streakCount,
    'totalSessions': totalSessions,
    'totalFocusMinutes': totalFocusMinutes,
    'xp': xp,
    'lastSessionDate': lastSessionDate != null
        ? Timestamp.fromDate(lastSessionDate!)
        : null,
  };
}
