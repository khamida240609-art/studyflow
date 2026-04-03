import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';

class RoomService extends ChangeNotifier {
  FirebaseFirestore? _db;
  final List<RoomModel> _mockRooms = [];
  final StreamController<List<RoomModel>> _mockRoomsCtl =
      StreamController<List<RoomModel>>.broadcast();

  RoomService() {
    if (!AuthService.kUseMockAuth) {
      _db = FirebaseFirestore.instance;
    } else {
      _mockRoomsCtl.add(const <RoomModel>[]);
    }
  }

  // Real-time stream of active rooms
  Stream<List<RoomModel>> get activeRoomsStream {
    if (AuthService.kUseMockAuth) {
      return _mockRoomsCtl.stream;
    }
    return _db!
        .collection('rooms')
        .where('isActive', isEqualTo: true)
        .orderBy('participantCount', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(RoomModel.fromDoc).toList());
  }

  // Real-time participants stream
  Stream<List<Map<String, dynamic>>> participantsStream(String roomId) {
    if (AuthService.kUseMockAuth) {
      return Stream.value(const <Map<String, dynamic>>[]);
    }
    return _db!
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // Real-time messages stream
  Stream<List<MessageModel>> messagesStream(String roomId) {
    if (AuthService.kUseMockAuth) {
      return Stream.value(const <MessageModel>[]);
    }
    return _db!
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromDoc).toList());
  }

  Future<RoomModel?> getRoom(String roomId) async {
    if (AuthService.kUseMockAuth) {
      return _findMockRoom(roomId);
    }
    final doc = await _db!.collection('rooms').doc(roomId).get();
    if (!doc.exists) return null;
    return RoomModel.fromDoc(doc);
  }

  Future<String> createRoom({
    required String name,
    required String subject,
    required RoomMode mode,
    required int focusMinutes,
    required int breakMinutes,
    required String createdBy,
  }) async {
    if (AuthService.kUseMockAuth) {
      final id = 'mock-${DateTime.now().millisecondsSinceEpoch}';
      final room = RoomModel(
        id: id,
        name: name,
        subject: subject,
        mode: mode,
        focusMinutes: focusMinutes,
        breakMinutes: breakMinutes,
        createdBy: createdBy,
        participantCount: 0,
        createdAt: DateTime.now(),
      );
      _mockRooms.add(room);
      _mockRoomsCtl.add(List<RoomModel>.unmodifiable(_mockRooms));
      return id;
    }
    final ref = _db!.collection('rooms').doc();
    final room = RoomModel(
      id: ref.id,
      name: name,
      subject: subject,
      mode: mode,
      focusMinutes: focusMinutes,
      breakMinutes: breakMinutes,
      createdBy: createdBy,
      participantCount: 0,
      createdAt: DateTime.now(),
    );
    await ref.set(room.toMap());
    return ref.id;
  }

  Future<void> joinRoom(String roomId, String uid, String displayName) async {
    if (AuthService.kUseMockAuth) {
      _updateMockRoom(roomId, deltaParticipants: 1);
      return;
    }
    final batch = _db!.batch();

    final partRef = _db!
        .collection('rooms').doc(roomId)
        .collection('participants').doc(uid);
    batch.set(partRef, {
      'uid': uid,
      'displayName': displayName,
      'joinedAt': FieldValue.serverTimestamp(),
      'leftEarly': false,
    });

    final roomRef = _db!.collection('rooms').doc(roomId);
    batch.update(roomRef, {
      'participantCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> leaveRoom(String roomId, String uid, {bool early = false}) async {
    if (AuthService.kUseMockAuth) {
      _updateMockRoom(roomId, deltaParticipants: -1);
      return;
    }
    final batch = _db!.batch();

    final partRef = _db!
        .collection('rooms').doc(roomId)
        .collection('participants').doc(uid);
    batch.update(partRef, {'leftEarly': early});

    final roomRef = _db!.collection('rooms').doc(roomId);
    batch.update(roomRef, {
      'participantCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  Future<void> sendMessage(
    String roomId,
    String senderUid,
    String senderName,
    String text,
  ) async {
    if (AuthService.kUseMockAuth) return;
    await _db!
        .collection('rooms').doc(roomId)
        .collection('messages')
        .add({
      'senderUid': senderUid,
      'senderName': senderName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> startRoomTimer(String roomId) async {
    if (AuthService.kUseMockAuth) return;
    await _db!.collection('rooms').doc(roomId).update({
      'timerStartedAt': FieldValue.serverTimestamp(),
    });
  }

  RoomModel? _findMockRoom(String roomId) {
    for (final r in _mockRooms) {
      if (r.id == roomId) return r;
    }
    return null;
  }

  void _updateMockRoom(String roomId, {required int deltaParticipants}) {
    final index = _mockRooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return;
    final r = _mockRooms[index];
    final nextCount = max(0, r.participantCount + deltaParticipants);
    _mockRooms[index] = RoomModel(
      id: r.id,
      name: r.name,
      subject: r.subject,
      mode: r.mode,
      focusMinutes: r.focusMinutes,
      breakMinutes: r.breakMinutes,
      createdBy: r.createdBy,
      isActive: r.isActive,
      participantCount: nextCount,
      timerStartedAt: r.timerStartedAt,
      createdAt: r.createdAt,
    );
    _mockRoomsCtl.add(List<RoomModel>.unmodifiable(_mockRooms));
  }

  @override
  void dispose() {
    _mockRoomsCtl.close();
    super.dispose();
  }
}
