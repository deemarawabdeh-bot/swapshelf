import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_listing.dart';

class ItemService {
  ItemService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('items');

  /// New Firestore document reference (use its id before upload to Storage).
  DocumentReference<Map<String, dynamic>> newItemDoc() => _items.doc();

  Stream<List<ItemListing>> watchItems({bool? freeOnly}) {
    return _items.orderBy('createdAt', descending: true).snapshots().map((snap) {
      var list = snap.docs.map(ItemListing.fromFirestore).toList();
      list = list.where((e) => e.isAvailable).toList();
      if (freeOnly == true) {
        list = list.where((e) => e.isFree).toList();
      }
      return list;
    });
  }

  Stream<List<ItemListing>> watchMyItems(String ownerId) {
    return _items.where('ownerId', isEqualTo: ownerId).snapshots().map((snap) {
      final list = snap.docs.map(ItemListing.fromFirestore).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<ItemListing?> watchItem(String id) {
    return _items.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ItemListing.fromFirestore(doc);
    });
  }

  Future<ItemListing?> getItem(String id) async {
    final doc = await _items.doc(id).get();
    if (!doc.exists) return null;
    return ItemListing.fromFirestore(doc);
  }

  Future<void> setItem(String id, ItemListing listing) async {
    await _items.doc(id).set(listing.toFirestore());
  }

  Future<void> deleteItem(String id) async {
    await _items.doc(id).delete();
  }

  Future<void> updateItem(ItemListing listing) async {
    await _items.doc(listing.id).set(
      {
        ...listing.toFirestore(),
        'createdAt': listing.createdAt,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateStatus(String id, String status) async {
    await _items.doc(id).set(
      {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
