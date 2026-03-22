import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadItemImage(XFile file, String itemId) async {
    final name = file.name.isNotEmpty ? file.name : 'photo.jpg';
    final ref = _storage.ref().child('items').child(itemId).child(name);
    final upload = await ref.putFile(File(file.path));
    return upload.ref.getDownloadURL();
  }
}
