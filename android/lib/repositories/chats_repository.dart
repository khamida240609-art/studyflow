import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/app_enums.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../services/firestore_service.dart';

class ChatsRepository {
  ChatsRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<List<ChatRoom>> streamChats(String userId) {
    return _firestoreService.chats
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ChatRoom.fromSnapshot).toList()
            ..sort(
              (a, b) => (b.lastMessageAt ?? b.createdAt).compareTo(
                a.lastMessageAt ?? a.createdAt,
              ),
            ),
        );
  }

  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _firestoreService.messages
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ChatMessage.fromSnapshot).toList()
                ..sort((a, b) => a.sentAt.compareTo(b.sentAt)),
        );
  }

  Future<String> getOrCreateChat({
    required String postId,
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
  }) async {
    final snapshot = await _firestoreService.chats
        .where('participantIds', arrayContains: currentUserId)
        .get();

    for (final doc in snapshot.docs) {
      final room = ChatRoom.fromSnapshot(doc);
      if (room.postId == postId && room.participantIds.contains(otherUserId)) {
        return room.id;
      }
    }

    final chatRef = _firestoreService.chats.doc();
    final room = ChatRoom(
      id: chatRef.id,
      postId: postId,
      participantIds: <String>[currentUserId, otherUserId],
      participantNames: <String, String>{
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      },
      createdAt: DateTime.now(),
      unreadCounts: <String, int>{currentUserId: 0, otherUserId: 0},
    );

    await chatRef.set(room.toMap());
    return chatRef.id;
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final messageRef = _firestoreService.messages.doc();
    final message = ChatMessage(
      id: messageRef.id,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: trimmed,
      sentAt: now,
    );

    final chatSnapshot = await _firestoreService.chats.doc(chatId).get();
    final room = chatSnapshot.exists
        ? ChatRoom.fromSnapshot(chatSnapshot)
        : null;
    final unreadCounts = <String, int>{...?room?.unreadCounts};
    unreadCounts[receiverId] = (unreadCounts[receiverId] ?? 0) + 1;
    unreadCounts[senderId] = 0;

    await messageRef.set(message.toMap());
    await _firestoreService.chats.doc(chatId).set(<String, dynamic>{
      'lastMessage': trimmed,
      'lastMessageAt': Timestamp.fromDate(now),
      'lastSenderId': senderId,
      'unreadCounts': unreadCounts,
    }, SetOptions(merge: true));

    await _firestoreService.notifications.add(<String, dynamic>{
      'userId': receiverId,
      'title': 'Новое сообщение',
      'body': trimmed,
      'type': NotificationType.message.value,
      'referenceId': chatId,
      'isRead': false,
      'data': <String, String>{
        'chatId': chatId,
        'postId': room?.postId ?? '',
        'otherUserId': senderId,
        'otherUserName': room?.participantNames[senderId] ?? 'Lostly',
      },
      'createdAt': Timestamp.fromDate(now),
    });
  }

  Future<void> markChatRead({
    required String chatId,
    required String userId,
  }) async {
    final unreadSnapshot = await _firestoreService.messages
        .where('chatId', isEqualTo: chatId)
        .where('receiverId', isEqualTo: userId)
        .get();

    final batch = _firestoreService.firestore.batch();
    for (final doc in unreadSnapshot.docs) {
      final message = ChatMessage.fromSnapshot(doc);
      if (message.readAt == null) {
        batch.update(doc.reference, <String, dynamic>{
          'readAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    }

    batch.set(_firestoreService.chats.doc(chatId), <String, dynamic>{
      'unreadCounts': <String, int>{userId: 0},
    }, SetOptions(merge: true));
    await batch.commit();
  }
}
