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
  String _query = '';
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Textbooks',
    'Notes & summaries',
    'Lab gear & scrubs',
    'Electronics',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final service = context.read<ItemService>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            children: [
              TextField(
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by title or description',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCategory = v ?? 'All'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Free'),
                    selected: _freeOnly,
                    onSelected: (v) => setState(() => _freeOnly = v),
                  ),
                ],
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
              var items = snapshot.data!;
              if (_selectedCategory != 'All') {
                items = items
                    .where((e) => (e.category ?? '').trim() == _selectedCategory)
                    .toList();
              }
              if (_query.isNotEmpty) {
                items = items
                    .where(
                      (e) =>
                          e.title.toLowerCase().contains(_query) ||
                          e.description.toLowerCase().contains(_query),
                    )
                    .toList();
              }
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    _query.isNotEmpty || _selectedCategory != 'All' || _freeOnly
                        ? 'No listings match your filters.'
                        : 'No listings yet. Be the first to post!',
                  ),
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
