import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/app_enums.dart';
import '../core/utils/firestore_x.dart';

class LostlyNotification {
  const LostlyNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.referenceId,
    this.isRead = false,
    this.data = const <String, String>{},
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? referenceId;
  final bool isRead;
  final Map<String, String> data;
  final DateTime createdAt;

  factory LostlyNotification.fromMap(String id, Map<String, dynamic> map) {
    return LostlyNotification(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => NotificationType.status,
      ),
      referenceId: map['referenceId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      data: stringMapFromDynamic(map['data']),
      createdAt: dateTimeFromFirestore(map['createdAt']),
    );
  }

  factory LostlyNotification.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return LostlyNotification.fromMap(
      snapshot.id,
      snapshot.data() ?? <String, dynamic>{},
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.value,
      'referenceId': referenceId,
      'isRead': isRead,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
