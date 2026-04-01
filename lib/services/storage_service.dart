import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadItemImage(XFile file, String itemId) async {
    final name = file.name.isNotEmpty ? file.name : 'photo.jpg';
    final ref = _storage.ref().child('items').child(itemId).child(name);
    try {
      final upload = await ref.putFile(File(file.path));
      return upload.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found' || e.code == 'bucket-not-found') {
        throw Exception(
          'Firebase Storage bucket is not ready. In Firebase Console, enable Storage for this project and try again.',
        );
      }
      rethrow;
    }
  }
}
