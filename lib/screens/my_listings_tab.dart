import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item_listing.dart';
import '../services/item_service.dart';
import '../widgets/item_card.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

class MyListingsTab extends StatelessWidget {
  const MyListingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Sign in required.'));
    }

    return Stack(
      children: [
        StreamBuilder<List<ItemListing>>(
          stream: context.read<ItemService>().watchMyItems(uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data!;
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'You have no listings yet. Tap + to post a book or item.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return ItemCard(
                  item: item,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ItemDetailScreen(itemId: item.id),
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const AddItemScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('New listing'),
          ),
        ),
      ],
    );
  }
}
