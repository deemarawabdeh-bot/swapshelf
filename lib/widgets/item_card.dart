import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/item_listing.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, this.onTap});

  final ItemListing item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: item.imageUrl.isEmpty
                  ? Container(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(Icons.image_not_supported_outlined,
                          size: 48, color: scheme.outline),
                    )
                  : CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: scheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.isFree
                          ? scheme.primaryContainer
                          : scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.isFree ? 'Free' : item.priceLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: item.isFree
                                ? scheme.onPrimaryContainer
                                : scheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.ownerName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
