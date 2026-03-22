import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.phone,
    this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? phone;
  final String? photoUrl;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      displayName: d['displayName'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phone: d['phone'] as String?,
      photoUrl: d['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}
