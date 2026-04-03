import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService(
    this._auth,
    this._googleSignIn, {
    required this.googleServerClientId,
  });

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final String googleServerClientId;
  Future<void>? _googleInitFuture;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleInitialized() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (googleServerClientId.trim().isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-server-client-id',
          message:
              'Google Sign-In Android requires a Web OAuth client ID '
              '(serverClientId). Add it with '
              '--dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
        );
      }
    }

    return _googleInitFuture ??= _googleSignIn.initialize(
      serverClientId: googleServerClientId.trim().isEmpty
          ? null
          : googleServerClientId.trim(),
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    try {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Не удалось получить Google ID token.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return _auth.signInWithCredential(credential);
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('cancel') || message.contains('canceled')) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Google sign-out should not block a regular Firebase logout.
    }

    await _auth.signOut();
  }
}
