import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item_listing.dart';
import '../services/item_service.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

class BrowseTab extends StatefulWidget {
  const BrowseTab({super.key});

  @override
  State<BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<BrowseTab> {
  bool _freeOnly = false;

  @override
  Widget build(BuildContext context) {
    final service = context.read<ItemService>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Find textbooks, notes, lab gear, and more.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              FilterChip(
                label: const Text('Free only'),
                selected: _freeOnly,
                onSelected: (v) => setState(() => _freeOnly = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ItemListing>>(
            stream: service.watchItems(freeOnly: _freeOnly ? true : null),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const Center(
                  child: Text('No listings yet. Be the first to post!'),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
        ),
      ],
    );
  }
}
