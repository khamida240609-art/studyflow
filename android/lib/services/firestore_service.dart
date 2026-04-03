import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get users =>
      firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get posts =>
      firestore.collection('posts');

  CollectionReference<Map<String, dynamic>> get chats =>
      firestore.collection('chats');

  CollectionReference<Map<String, dynamic>> get messages =>
      firestore.collection('messages');

  CollectionReference<Map<String, dynamic>> get claims =>
      firestore.collection('claims');

  CollectionReference<Map<String, dynamic>> get notifications =>
      firestore.collection('notifications');

  CollectionReference<Map<String, dynamic>> get reports =>
      firestore.collection('reports');

  CollectionReference<Map<String, dynamic>> get communities =>
      firestore.collection('communities');

  CollectionReference<Map<String, dynamic>> get matches =>
      firestore.collection('matches');

  CollectionReference<Map<String, dynamic>> get pickupSchedules =>
      firestore.collection('pickup_schedules');

  CollectionReference<Map<String, dynamic>> get userPreferences =>
      firestore.collection('user_preferences');
}
