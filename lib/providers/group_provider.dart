import 'package:flutter/foundation.dart';
import '../services/group_service.dart';

class GroupProvider extends ChangeNotifier {
  final GroupService _service;
  GroupProvider(this._service);

  String? groupId;
  String? groupCode;
  String? groupName;
  List<Map<String, dynamic>> participants = const [];

  bool get inGroup => groupCode != null;

  Future<bool> createGroup({
    required String name,
    required String password,
    required String uid,
    required String userName,
  }) async {
    groupName = name;
    final res = await _service.createGroup(
      name: name,
      password: password,
      createdBy: uid,
      createdByName: userName,
    );
    groupId = res['id'];
    groupCode = res['code'];
    _listenParticipants();
    notifyListeners();
    return true;
  }

  Future<bool> joinGroup(String code, String name, String uid) async {
    final doc = await _service.findByCodeAndName(code, name);
    if (doc == null) return false;
    groupId = doc.id;
    groupCode = code;
    groupName = name;
    await _service.joinGroup(groupId: groupId!, uid: uid, name: name);
    _listenParticipants();
    notifyListeners();
    return true;
  }

  void leaveGroup() {
    groupCode = null;
    groupName = null;
    groupId = null;
    notifyListeners();
  }

  void _listenParticipants() {
    if (groupId == null) return;
    _service.participantsStream(groupId!).listen((items) {
      participants = items;
      notifyListeners();
    });
  }

  Future<void> setStatus(String uid, String status) async {
    if (groupId == null) return;
    await _service.updateStatus(groupId: groupId!, uid: uid, status: status);
  }

  Future<void> addStudyMinutes(String uid, int minutes) async {
    if (groupId == null) return;
    await _service.addStudyMinutes(groupId: groupId!, uid: uid, minutes: minutes);
  }

  Stream<List<Map<String, dynamic>>> messagesStream() {
    if (groupId == null) return const Stream.empty();
    return _service.messagesStream(groupId!);
  }

  Future<void> sendMessage(String uid, String name, String text) async {
    if (groupId == null) return;
    await _service.sendMessage(groupId: groupId!, uid: uid, name: name, text: text);
  }
}
