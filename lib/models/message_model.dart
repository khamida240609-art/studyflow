import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderUid;
  final String senderName;
  final String text;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderUid: d['senderUid'] ?? '',
      senderName: d['senderName'] ?? '',
      text: d['text'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'senderUid': senderUid,
    'senderName': senderName,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class SessionModel {
  final String id;
  final String uid;
  final String roomId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool leftEarly;
  final int sprintsCompleted;
  final int xpEarned;

  SessionModel({
    required this.id,
    required this.uid,
    required this.roomId,
    required this.startedAt,
    this.completedAt,
    this.leftEarly = false,
    this.sprintsCompleted = 0,
    this.xpEarned = 0,
  });

  factory SessionModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id,
      uid: d['uid'] ?? '',
      roomId: d['roomId'] ?? '',
      startedAt: (d['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
      leftEarly: d['leftEarly'] ?? false,
      sprintsCompleted: d['sprintsCompleted'] ?? 0,
      xpEarned: d['xpEarned'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'roomId': roomId,
    'startedAt': FieldValue.serverTimestamp(),
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'leftEarly': leftEarly,
    'sprintsCompleted': sprintsCompleted,
    'xpEarned': xpEarned,
  };
}
