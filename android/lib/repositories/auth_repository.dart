import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthRepository {
  AuthRepository(this._authService, this._firestoreService);

  final AuthService _authService;
  final FirestoreService _firestoreService;

  Stream<User?> authStateChanges() => _authService.authStateChanges();

  Future<void> _ensureUserProfile({
    required User user,
    String? displayName,
  }) async {
    final now = DateTime.now();
    final userDoc = _firestoreService.users.doc(user.uid);
    final snapshot = await userDoc.get();
    final resolvedName =
        (displayName ?? user.displayName ?? '').trim().isNotEmpty
        ? (displayName ?? user.displayName ?? '').trim()
        : (user.email?.split('@').first.trim().isNotEmpty ?? false)
        ? user.email!.split('@').first.trim()
        : 'Lostly user';

    if (snapshot.exists) {
      await userDoc.set(<String, dynamic>{
        'email': (user.email ?? '').trim(),
        'displayName': resolvedName,
        'photoUrl': user.photoURL,
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));
    } else {
      final profile = AppUser(
        id: user.uid,
        email: (user.email ?? '').trim(),
        displayName: resolvedName,
        photoUrl: user.photoURL,
        createdAt: now,
        updatedAt: now,
        communityIds: const <String>['campus'],
      );
      await userDoc.set(profile.toMap());
    }

    final preferencesDoc = _firestoreService.userPreferences.doc(user.uid);
    final preferencesSnapshot = await preferencesDoc.get();
    if (preferencesSnapshot.exists) {
      await preferencesDoc.set(<String, dynamic>{
        'emailAddress': (user.email ?? '').trim(),
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));
    } else {
      await preferencesDoc.set(<String, dynamic>{
        'localeCode': 'ru',
        'pushEnabled': true,
        'emailAlertsEnabled': false,
        'smsAlertsEnabled': false,
        'matchAlertsEnabled': true,
        'claimAlertsEnabled': true,
        'reminderAlertsEnabled': true,
        'emailAddress': (user.email ?? '').trim(),
        'updatedAt': Timestamp.fromDate(now),
      });
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _authService.signUp(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw Exception('Unable to create account.');
    }

    await user.updateDisplayName(displayName);
    await user.reload();
    final refreshedUser = _authService.currentUser ?? user;
    await _ensureUserProfile(
      user: refreshedUser,
      displayName: displayName.trim(),
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await _authService.signIn(email: email, password: password);
  }

  Future<bool> signInWithGoogle() async {
    final credential = await _authService.signInWithGoogle();
    final user = credential?.user;
    if (user == null) {
      return false;
    }

    await _ensureUserProfile(user: user);
    return true;
  }

  Future<void> signOut() => _authService.signOut();
}
