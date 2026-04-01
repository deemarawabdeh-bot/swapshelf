import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _ensureUserProfile(cred.user);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_firebaseAuthMessage(e));
    } on FirebaseException {
      throw const AuthFailure(
        'Signed in, but we could not load your profile right now. Please try again.',
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String phone,
  }) async {
    UserCredential? cred;
    final normalizedEmail = email.trim();
    final normalizedName = displayName.trim();
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      throw const AuthFailure('Phone number is required for registration.');
    }

    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final uid = cred.user!.uid;
      await cred.user!.updateDisplayName(normalizedName);
      final user = AppUser(
        uid: uid,
        displayName: normalizedName,
        email: normalizedEmail,
        phone: normalizedPhone,
      );
      await _firestore.collection('users').doc(uid).set({
        ...user.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_firebaseAuthMessage(e));
    } on FirebaseException {
      // Roll back auth user if profile creation fails.
      try {
        await cred?.user?.delete();
      } catch (_) {}
      throw const AuthFailure(
        'Account was created, but profile setup failed. Please try again.',
      );
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<AppUser?> fetchProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String phone,
  }) async {
    final ref = _firestore.collection('users').doc(uid);
    await ref.set({
      'displayName': displayName.trim(),
      'phone': phone.trim().isEmpty ? FieldValue.delete() : phone.trim(),
    }, SetOptions(merge: true));
    await _auth.currentUser?.updateDisplayName(displayName.trim());
  }

  Future<void> _ensureUserProfile(User? user) async {
    if (user == null) return;
    final ref = _firestore.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (doc.exists) return;

    await ref.set({
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _firebaseAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a bit and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and retry.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Auth.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
