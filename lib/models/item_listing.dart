import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

class ItemListing {
  const ItemListing({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.imageBytes,
    required this.ownerId,
    required this.ownerName,
    required this.itemType,
    required this.status,
    this.price,
    this.category,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final Uint8List? imageBytes;
  final String ownerId;
  final String ownerName;
  final String itemType;
  final String status;
  final double? price;
  final String? category;
  final DateTime createdAt;

  static const String typeFree = 'free';
  static const String typeExchange = 'exchange';
  static const String typeSale = 'sale';

  static const String statusAvailable = 'available';
  static const String statusUnavailable = 'unavailable';
  static const String statusSold = 'sold';

  bool get isFree => itemType == typeFree;
  bool get isAvailable => status == statusAvailable;
  bool get isSold => status == statusSold;

  String get priceLabel {
    if (isFree) return 'Free';
    if (itemType == typeExchange) return 'Exchange';
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
      imageBytes: _parseImageBytes(d['imageData']),
      ownerId: d['ownerId'] as String? ?? '',
      ownerName: d['ownerName'] as String? ?? 'Student',
      itemType: _parseItemType(
        itemType: d['itemType'] as String?,
        legacyIsFree: d['isFree'] as bool?,
      ),
      status: _parseStatus(d['status'] as String?),
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
      if (imageBytes != null) 'imageData': Blob(imageBytes!),
      'ownerId': ownerId,
      'ownerName': ownerName,
      'itemType': itemType,
      'isFree': isFree,
      'status': status,
      'price': itemType == typeSale ? price : null,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static String _parseItemType({String? itemType, bool? legacyIsFree}) {
    if (itemType == typeFree || itemType == typeExchange || itemType == typeSale) {
      return itemType!;
    }
    if (legacyIsFree == true) return typeFree;
    return typeSale;
  }

  static String _parseStatus(String? value) {
    if (value == statusAvailable || value == statusUnavailable || value == statusSold) {
      return value!;
    }
    return statusAvailable;
  }

  static Uint8List? _parseImageBytes(dynamic value) {
    if (value is Blob) return value.bytes;
    if (value is Uint8List) return value;
    if (value is List<dynamic>) {
      return Uint8List.fromList(value.cast<int>());
    }
    return null;
  }
}
