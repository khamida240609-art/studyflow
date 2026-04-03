import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_x.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.sentAt,
    this.readAt,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime sentAt;
  final DateTime? readAt;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      chatId: map['chatId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      sentAt: dateTimeFromFirestore(map['sentAt']),
      readAt: map['readAt'] == null
          ? null
          : dateTimeFromFirestore(map['readAt']),
    );
  }

  factory ChatMessage.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return ChatMessage.fromMap(
      snapshot.id,
      snapshot.data() ?? <String, dynamic>{},
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'sentAt': Timestamp.fromDate(sentAt),
      'readAt': timestampFromDate(readAt),
    };
  }
}
