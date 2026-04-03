import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_x.dart';

class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.postId,
    required this.participantIds,
    required this.participantNames,
    required this.createdAt,
    this.lastMessage,
    this.lastSenderId,
    this.lastMessageAt,
    this.unreadCounts = const <String, int>{},
  });

  final String id;
  final String postId;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final String? lastMessage;
  final String? lastSenderId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final Map<String, int> unreadCounts;

  factory ChatRoom.fromMap(String id, Map<String, dynamic> map) {
    return ChatRoom(
      id: id,
      postId: map['postId'] as String? ?? '',
      participantIds: stringListFromDynamic(map['participantIds']),
      participantNames: stringMapFromDynamic(map['participantNames']),
      lastMessage: map['lastMessage'] as String?,
      lastSenderId: map['lastSenderId'] as String?,
      lastMessageAt: map['lastMessageAt'] == null
          ? null
          : dateTimeFromFirestore(map['lastMessageAt']),
      createdAt: dateTimeFromFirestore(map['createdAt']),
      unreadCounts: intMapFromDynamic(map['unreadCounts']),
    );
  }

  factory ChatRoom.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return ChatRoom.fromMap(
      snapshot.id,
      snapshot.data() ?? <String, dynamic>{},
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'postId': postId,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'lastMessageAt': timestampFromDate(lastMessageAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'unreadCounts': unreadCounts,
    };
  }
}
