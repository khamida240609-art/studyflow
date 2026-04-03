import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  // Temporary mock auth: set to false when Firebase is configured.
  static const bool kUseMockAuth = false;

  FirebaseAuth? _auth;
  FirebaseFirestore? _db;

  User? get currentUser => kUseMockAuth ? null : _auth?.currentUser;
  Stream<User?> get authStateChanges =>
      kUseMockAuth ? const Stream<User?>.empty() : _auth!.authStateChanges();
  bool get isLoggedIn => kUseMockAuth ? _mockLoggedIn : currentUser != null;
  String? get userId => kUseMockAuth ? _mockUid : currentUser?.uid;
  String get displayName {
    final modelName = userModel?.displayName.trim() ?? '';
    if (modelName.isNotEmpty && modelName.toLowerCase() != 'guest') {
      return modelName;
    }
    final authName = currentUser?.displayName?.trim() ?? '';
    if (authName.isNotEmpty && authName.toLowerCase() != 'guest') {
      return authName;
    }
    final email = currentUser?.email?.trim() ?? userModel?.email.trim() ?? '';
    if (email.isNotEmpty) {
      return email.contains('@') ? email.split('@').first : email;
    }
    return 'Guest';
  }

  String get email {
    final modelEmail = userModel?.email.trim() ?? '';
    if (modelEmail.isNotEmpty) return modelEmail;
    return currentUser?.email?.trim() ?? '';
  }

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  bool _mockLoggedIn = false;
  String? _mockUid;

  AuthService() {
    if (!kUseMockAuth) {
      _auth = FirebaseAuth.instance;
      _db = FirebaseFirestore.instance;
      _auth!.authStateChanges().listen((user) {
        if (user != null) {
          // Notify router immediately so it can redirect off /login.
          notifyListeners();
          _loadUserModel(user.uid);
        } else {
          _userModel = null;
          notifyListeners();
        }
      });
    }
  }

  Future<void> _loadUserModel(String uid) async {
    if (kUseMockAuth) return;
    try {
      final doc = await _db!.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromDoc(doc);
        notifyListeners();
      }
    } catch (_) {
      // Ignore Firestore errors to avoid blocking login
    }
  }

  Future<String?> signUp(String email, String password, String name) async {
    if (kUseMockAuth) {
      _mockUid = _mockUid ?? 'mock-user';
      _mockLoggedIn = true;
      _userModel = UserModel(
        uid: _mockUid!,
        displayName: name.isNotEmpty ? name : 'Guest',
        email: email,
      );
      notifyListeners();
      return null;
    }
    try {
      final cred = await _auth!
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));
      try {
        if (name.trim().isNotEmpty) {
          await cred.user!.updateDisplayName(name.trim());
        }
      } catch (_) {}
      try {
        await _db!.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'displayName': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'streakCount': 0,
          'lastSessionDate': null,
          'totalSessions': 0,
          'totalFocusMinutes': 0,
          'xp': 0,
        });
      } catch (_) {}
      await cred.user!.sendEmailVerification();
      _loadUserModel(cred.user!.uid);
      notifyListeners();
      return 'Verification email sent. Please verify and login.';
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    } catch (_) {
      return 'Network or Firebase error. Try again.';
    }
  }

  Future<String?> login(String email, String password) async {
    if (kUseMockAuth) {
      _mockUid = _mockUid ?? 'mock-user';
      _mockLoggedIn = true;
      final fallbackName = email.contains('@') ? email.split('@').first : 'Guest';
      _userModel = UserModel(
        uid: _mockUid!,
        displayName: fallbackName.isNotEmpty ? fallbackName : 'Guest',
        email: email,
      );
      notifyListeners();
      return null;
    }
    try {
      await _auth!
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));
      final user = _auth!.currentUser;
      if (user == null) {
        return 'Login failed. Try again.';
      }
      await user.reload();
      final refreshed = _auth!.currentUser;
      if (refreshed == null || !refreshed.emailVerified) {
        await _auth!.signOut();
        notifyListeners();
        return 'Please verify your email';
      }
      _loadUserModel(refreshed.uid);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    } catch (_) {
      return 'Network or Firebase error. Try again.';
    }
  }

  Future<void> logout() async {
    if (kUseMockAuth) {
      _mockLoggedIn = false;
      _userModel = null;
      notifyListeners();
      return;
    }
    await _auth!.signOut();
    _userModel = null;
    notifyListeners();
  }

  Future<String?> signInWithGoogle() async {
    if (kUseMockAuth) {
      _mockUid = _mockUid ?? 'mock-user';
      _mockLoggedIn = true;
      _userModel = UserModel(
        uid: _mockUid!,
        displayName: 'Google User',
        email: 'google@example.com',
      );
      notifyListeners();
      return null;
    }
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        try {
          await _auth!.signInWithPopup(provider).timeout(const Duration(seconds: 20));
        } on FirebaseAuthException catch (e) {
          // Popup blocked or unsupported -> fallback to redirect
          if (e.code == 'popup-blocked' || e.code == 'operation-not-supported-in-this-environment') {
            await _auth!.signInWithRedirect(provider).timeout(const Duration(seconds: 20));
          } else {
            rethrow;
          }
        }
        final user = _auth!.currentUser;
        if (user == null) return 'Login failed. Try again.';
        _loadUserModel(user.uid);
        notifyListeners();
        return null;
      }

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return 'Google sign-in cancelled';
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth!.signInWithCredential(credential).timeout(const Duration(seconds: 15));
      final user = _auth!.currentUser;
      if (user == null) return 'Login failed. Try again.';
      _loadUserModel(user.uid);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    } catch (_) {
      return 'Network or Firebase error. Try again.';
    }
  }

  Future<void> refreshUserModel() async {
    if (kUseMockAuth) return;
    if (currentUser != null) await _loadUserModel(currentUser!.uid);
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found': return 'Пайдаланушы табылмады';
      case 'wrong-password': return 'Қате пароль';
      case 'email-already-in-use': return 'Бұл email тіркелген';
      case 'weak-password': return 'Пароль тым қысқа';
      case 'invalid-email': return 'Email дұрыс емес';
      case 'account-exists-with-different-credential': return 'Бұл email басқа әдіспен тіркелген';
      case 'popup-closed-by-user': return 'Google кіруі жабылды';
      default: return 'Қате болды: $code';
    }
  }
}
