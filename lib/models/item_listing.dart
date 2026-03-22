import 'package:cloud_firestore/cloud_firestore.dart';

class ItemListing {
  const ItemListing({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.isFree,
    this.price,
    this.category,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String ownerId;
  final String ownerName;
  final bool isFree;
  final double? price;
  final String? category;
  final DateTime createdAt;

  String get priceLabel {
    if (isFree) return 'Free';
    if (price == null) return 'Priced';
    return price!.toStringAsFixed(2);
  }

  factory ItemListing.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    DateTime created;
    if (ts is Timestamp) {
      created = ts.toDate();
    } else {
      created = DateTime.now();
    }
    return ItemListing(
      id: doc.id,
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      imageUrl: d['imageUrl'] as String? ?? '',
      ownerId: d['ownerId'] as String? ?? '',
      ownerName: d['ownerName'] as String? ?? 'Student',
      isFree: d['isFree'] as bool? ?? true,
      price: (d['price'] as num?)?.toDouble(),
      category: d['category'] as String?,
      createdAt: created,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'isFree': isFree,
      'price': isFree ? null : price,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
