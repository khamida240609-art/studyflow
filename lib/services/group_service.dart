import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_config.dart';

class GroupService {
  final FirebaseFirestore? _db =
      AppConfig.kUseMockData ? null : FirebaseFirestore.instance;

  // Mock storage
  final Map<String, Map<String, dynamic>> _mockGroups = {};
  final Map<String, List<Map<String, dynamic>>> _mockParticipants = {};
  final Map<String, List<Map<String, dynamic>>> _mockMessages = {};
  final Map<String, StreamController<List<Map<String, dynamic>>>> _partCtrls = {};
  final Map<String, StreamController<List<Map<String, dynamic>>>> _msgCtrls = {};

  Future<Map<String, String>> createGroup({
    required String name,
    required String password,
    required String createdBy,
    required String createdByName,
  }) async {
    final code = _generateCode();
    if (_db == null) {
      final id = 'mock-${DateTime.now().millisecondsSinceEpoch}';
      _mockGroups[id] = {
        'name': name,
        'code': code,
        'password': password,
        'createdBy': createdBy,
      };
      _mockParticipants[id] = [
        {
          'uid': createdBy,
          'name': createdByName,
          'status': 'Studying',
          'totalMinutes': 0,
          'joinedAt': DateTime.now().toIso8601String(),
        }
      ];
      _emitParticipants(id);
      return {'id': id, 'code': code};
    }
    final ref = _db!.collection('groups').doc();
    await ref.set({
      'name': name,
      'code': code,
      'password': password,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await ref.collection('participants').doc(createdBy).set({
      'uid': createdBy,
      'name': createdByName,
      'status': 'Studying',
      'totalMinutes': 0,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    return {'id': ref.id, 'code': code};
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> findByCodeAndName(
    String code,
    String name,
  ) async {
    if (_db == null) {
      for (final entry in _mockGroups.entries) {
        final g = entry.value;
        if (g['code'] == code && g['name'] == name) {
          return _MockDoc(entry.key, g);
        }
      }
      return null;
    }
    final snap = await _db!
        .collection('groups')
        .where('code', isEqualTo: code)
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first;
  }

  Stream<List<Map<String, dynamic>>> participantsStream(String groupId) {
    if (_db == null) {
      _partCtrls.putIfAbsent(
        groupId,
        () => StreamController<List<Map<String, dynamic>>>.broadcast(),
      );
      _emitParticipants(groupId);
      return _partCtrls[groupId]!.stream;
    }
    return _db!
        .collection('groups')
        .doc(groupId)
        .collection('participants')
        .orderBy('joinedAt')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> joinGroup({
    required String groupId,
    required String uid,
    required String name,
  }) async {
    if (_db == null) {
      final list = _mockParticipants.putIfAbsent(groupId, () => []);
      final existing = list.indexWhere((p) => p['uid'] == uid);
      final data = {
        'uid': uid,
        'name': name,
        'status': 'Online',
        'totalMinutes': existing == -1 ? 0 : list[existing]['totalMinutes'] ?? 0,
        'joinedAt': DateTime.now().toIso8601String(),
      };
      if (existing == -1) {
        list.add(data);
      } else {
        list[existing] = data;
      }
      _emitParticipants(groupId);
      return;
    }
    await _db!
        .collection('groups')
        .doc(groupId)
        .collection('participants')
        .doc(uid)
        .set({
      'uid': uid,
      'name': name,
      'status': 'Online',
      'totalMinutes': 0,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateStatus({
    required String groupId,
    required String uid,
    required String status,
  }) async {
    if (_db == null) {
      final list = _mockParticipants[groupId] ?? [];
      final i = list.indexWhere((p) => p['uid'] == uid);
      if (i != -1) {
        list[i] = {...list[i], 'status': status};
        _emitParticipants(groupId);
      }
      return;
    }
    await _db!
        .collection('groups')
        .doc(groupId)
        .collection('participants')
        .doc(uid)
        .set({'status': status}, SetOptions(merge: true));
  }

  Future<void> addStudyMinutes({
    required String groupId,
    required String uid,
    required int minutes,
  }) async {
    if (_db == null) {
      final list = _mockParticipants[groupId] ?? [];
      final i = list.indexWhere((p) => p['uid'] == uid);
      if (i != -1) {
        final current = list[i]['totalMinutes'] ?? 0;
        list[i] = {...list[i], 'totalMinutes': current + minutes};
        _emitParticipants(groupId);
      }
      return;
    }
    await _db!
        .collection('groups')
        .doc(groupId)
        .collection('participants')
        .doc(uid)
        .update({'totalMinutes': FieldValue.increment(minutes)});
  }

  Stream<List<Map<String, dynamic>>> messagesStream(String groupId) {
    if (_db == null) {
      _msgCtrls.putIfAbsent(
        groupId,
        () => StreamController<List<Map<String, dynamic>>>.broadcast(),
      );
      _emitMessages(groupId);
      return _msgCtrls[groupId]!.stream;
    }
    return _db!
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> sendMessage({
    required String groupId,
    required String uid,
    required String name,
    required String text,
  }) async {
    if (_db == null) {
      final list = _mockMessages.putIfAbsent(groupId, () => []);
      list.add({
        'uid': uid,
        'name': name,
        'text': text,
        'createdAt': DateTime.now().toIso8601String(),
      });
      _emitMessages(groupId);
      return;
    }
    await _db!
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .add({
      'uid': uid,
      'name': name,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _generateCode() {
    final ms = DateTime.now().millisecondsSinceEpoch % 100000;
    return 'SF$ms';
  }

  void _emitParticipants(String groupId) {
    final ctrl = _partCtrls[groupId];
    if (ctrl != null) {
      ctrl.add(List<Map<String, dynamic>>.unmodifiable(
          _mockParticipants[groupId] ?? []));
    }
  }

  void _emitMessages(String groupId) {
    final ctrl = _msgCtrls[groupId];
    if (ctrl != null) {
      ctrl.add(List<Map<String, dynamic>>.unmodifiable(
          _mockMessages[groupId] ?? []));
    }
  }
}

class _MockDoc implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;
  _MockDoc(this._id, this._data);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  String get id => _id;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
