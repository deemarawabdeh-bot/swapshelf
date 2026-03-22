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
}
