import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatService {
  ChatService(this._firestore);

  final FirebaseFirestore _firestore;

  static String chatIdFor({
    required String uidA,
    required String uidB,
    required String itemId,
  }) {
    final pair = [uidA, uidB]..sort();
    return '${pair[0]}_${pair[1]}_$itemId';
  }

  CollectionReference<Map<String, dynamic>> _messagesCol(String chatId) {
    return _firestore.collection('chats').doc(chatId).collection('messages');
  }

  Future<void> ensureChatMeta({
    required String chatId,
    required List<String> participants,
    required String itemId,
    required String itemTitle,
  }) async {
    final ref = _firestore.collection('chats').doc(chatId);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'participants': participants,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _messagesCol(chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(ChatMessage.fromFirestore).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    final batch = _firestore.batch();
    final msgRef = _messagesCol(chatId).doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _firestore.collection('chats').doc(chatId),
      {
        'lastMessage': text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyChatSummaries(
    String myUid,
  ) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .snapshots();
  }
}
