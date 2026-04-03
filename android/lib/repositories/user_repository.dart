import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../services/firestore_service.dart';

class UserRepository {
  UserRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<AppUser?> watchUser(String userId) {
    return _firestoreService.users.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return AppUser.fromSnapshot(snapshot);
    });
  }

  Future<AppUser?> getUser(String userId) async {
    final snapshot = await _firestoreService.users.doc(userId).get();
    if (!snapshot.exists) {
      return null;
    }
    return AppUser.fromSnapshot(snapshot);
  }

  Future<void> updateProfile(AppUser user) {
    return _firestoreService.users
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> toggleSavedPost({
    required String userId,
    required String postId,
    required bool isSaved,
  }) {
    return _firestoreService.users.doc(userId).set(<String, dynamic>{
      'savedPostIds': isSaved
          ? FieldValue.arrayRemove(<String>[postId])
          : FieldValue.arrayUnion(<String>[postId]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Future<void> saveFcmToken(String userId, String? token) {
    return _firestoreService.users.doc(userId).set(<String, dynamic>{
      'fcmToken': token,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }
}
