import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  int _ms(Timestamp? t) {
    if (t == null) return 0;
    return t.millisecondsSinceEpoch;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Sign in to see messages.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: context.read<ChatService>().watchMyChatSummaries(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs.toList()
          ..sort(
            (a, b) => _ms(b.data()['updatedAt'] as Timestamp?) -
                _ms(a.data()['updatedAt'] as Timestamp?),
          );
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No conversations yet. Open a listing and tap “Message seller”.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          );
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final d = doc.data();
            final itemTitle = d['itemTitle'] as String? ?? 'Listing';
            final last = d['lastMessage'] as String? ?? '';
            final participants = (d['participants'] as List<dynamic>?)
                    ?.map((e) => e as String)
                    .toList() ??
                [];
            final peerId = participants.firstWhere(
              (p) => p != uid,
              orElse: () => '',
            );
            if (peerId.isEmpty) {
              return ListTile(
                title: Text(itemTitle),
                subtitle: Text(last.isEmpty ? 'Conversation' : last),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatScreen(
                        chatId: doc.id,
                        itemTitle: itemTitle,
                        peerName: 'Student',
                      ),
                    ),
                  );
                },
              );
            }
            return FutureBuilder(
              future: context.read<AuthService>().fetchProfile(peerId),
              builder: (context, userSnap) {
                final name = userSnap.data?.displayName ?? 'Student';
                return ListTile(
                  title: Text(itemTitle),
                  subtitle: Text(
                    last.isEmpty ? 'Tap to start chatting' : last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: CircleAvatar(
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChatScreen(
                          chatId: doc.id,
                          itemTitle: itemTitle,
                          peerName: name,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
