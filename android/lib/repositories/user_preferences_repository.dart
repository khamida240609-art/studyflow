import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_preferences.dart';
import '../services/firestore_service.dart';

class UserPreferencesRepository {
  UserPreferencesRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<UserPreferences?> watchPreferences(String userId) {
    return _firestoreService.userPreferences.doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        return null;
      }
      return UserPreferences.fromSnapshot(snapshot);
    });
  }

  Future<void> save(UserPreferences preferences) {
    return _firestoreService.userPreferences
        .doc(preferences.userId)
        .set(preferences.toMap(), SetOptions(merge: true));
  }

  Future<void> update(String userId, Map<String, dynamic> patch) {
    return _firestoreService.userPreferences.doc(userId).set(<String, dynamic>{
      ...patch,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }
}
