import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../models/item_listing.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/item_service.dart';
import '../utils/whatsapp.dart';
import 'add_item_screen.dart';
import 'chat_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    final itemService = context.read<ItemService>();
    final authService = context.read<AuthService>();
    final chatService = context.read<ChatService>();
    final me = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Listing')),
      body: StreamBuilder<ItemListing?>(
        stream: itemService.watchItem(itemId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = snap.data;
          if (item == null) {
            return const Center(child: Text('Listing not found.'));
          }
          return FutureBuilder<AppUser?>(
            future: authService.fetchProfile(item.ownerId),
            builder: (context, userSnap) {
              final seller = userSnap.data;
              final sellerPhone = seller?.phone?.trim();
              final hasSellerPhone =
                  sellerPhone != null && sellerPhone.isNotEmpty;
              final isOwner = me?.uid == item.ownerId;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: item.imageBytes != null
                          ? Image.memory(item.imageBytes!, fit: BoxFit.cover)
                          : item.imageUrl.isEmpty
                              ? Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  child: const Icon(Icons.image_not_supported,
                                      size: 64),
                                )
                              : CachedNetworkImage(
                                  imageUrl: item.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  item.isFree
                                      ? 'Free'
                                      : (item.itemType == ItemListing.typeExchange
                                            ? 'Exchange'
                                            : item.priceLabel),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Chip(
                                label: Text(
                                  item.isAvailable
                                      ? 'Available'
                                      : (item.isSold ? 'Sold' : 'Unavailable'),
                                ),
                              ),
                            ],
                          ),
                          if (item.category != null &&
                              item.category!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              item.category!,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Posted ${DateFormat.yMMMd().add_jm().format(item.createdAt)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Seller: ${item.ownerName}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                            ],
                          ),
                          if (!isOwner && me != null) ...[
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () async {
                                final chatId = ChatService.chatIdFor(
                                  uidA: me.uid,
                                  uidB: item.ownerId,
                                  itemId: item.id,
                                );
                                await chatService.ensureChatMeta(
                                  chatId: chatId,
                                  participants: [me.uid, item.ownerId],
                                  itemId: item.id,
                                  itemTitle: item.title,
                                );
                                if (!context.mounted) return;
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ChatScreen(
                                      chatId: chatId,
                                      itemTitle: item.title,
                                      peerName: item.ownerName,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Message seller'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: hasSellerPhone
                                  ? () async {
                                final ok = await openWhatsApp(
                                  phone: sellerPhone,
                                  body:
                                      'Hi! I saw your listing "${item.title}" on SwapShelf.',
                                );
                                if (!context.mounted) return;
                                if (!ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not open WhatsApp on this device.',
                                      ),
                                    ),
                                  );
                                }
                              }
                                  : null,
                              icon: const Icon(Icons.chat),
                              label: const Text('Contact on WhatsApp'),
                            ),
                            if (!hasSellerPhone)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Seller phone is not available yet.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ),
                          ],
                          if (isOwner)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 24),
                                Text(
                                  'This is your listing.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                FilledButton.tonalIcon(
                                  onPressed: () async {
                                    await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => AddItemScreen(
                                          initial: item,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit listing'),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: item.isSold
                                      ? null
                                      : () async {
                                          await itemService.updateStatus(
                                            item.id,
                                            ItemListing.statusSold,
                                          );
                                        },
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Mark as sold'),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: item.isAvailable
                                      ? () async {
                                          await itemService.updateStatus(
                                            item.id,
                                            ItemListing.statusUnavailable,
                                          );
                                        }
                                      : () async {
                                          await itemService.updateStatus(
                                            item.id,
                                            ItemListing.statusAvailable,
                                          );
                                        },
                                  icon: const Icon(Icons.pause_circle_outline),
                                  label: Text(
                                    item.isAvailable
                                        ? 'Mark unavailable'
                                        : 'Mark available',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Delete listing?'),
                                            content: const Text(
                                              'This action cannot be undone.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        ) ??
                                        false;
                                    if (!confirmed) return;
                                    await itemService.deleteItem(item.id);
                                    if (!context.mounted) return;
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Delete listing'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
