import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    DateTime created;
    if (ts is Timestamp) {
      created = ts.toDate();
    } else {
      created = DateTime.now();
    }
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] as String? ?? '',
      text: d['text'] as String? ?? '',
      createdAt: created,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
