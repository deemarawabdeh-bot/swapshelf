import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthService {
  AuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    String? phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(displayName);
    final user = AppUser(
      uid: uid,
      displayName: displayName,
      email: email,
      phone: phone,
    );
    await _firestore.collection('users').doc(uid).set(user.toFirestore());
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
    await ref.update({
      'displayName': displayName,
      'phone': phone.isEmpty ? FieldValue.delete() : phone,
    });
    await _auth.currentUser?.updateDisplayName(displayName);
  }
}
