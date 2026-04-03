import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../models/item_post.dart';
import '../theme/app_theme.dart';
import 'status_chip.dart';

class ItemPostCard extends StatelessWidget {
  const ItemPostCard({super.key, required this.post, required this.onTap});

  final ItemPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = post.type.name == 'lost'
        ? AppTheme.lostGradient
        : AppTheme.foundGradient;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                  aspectRatio: 1.18,
                  child: post.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: post.imageUrls.first,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _GradientPlaceholder(
                            gradient: gradient,
                            title: post.title,
                          ),
                        )
                      : _GradientPlaceholder(
                          gradient: gradient,
                          title: post.title,
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  StatusChip(status: post.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (post.isPriorityDocument)
                    const _MetaChip(
                      icon: Icons.priority_high_rounded,
                      label: 'Приоритетный документ',
                    ),
                  if (post.rewardAmount > 0)
                    _MetaChip(
                      icon: Icons.payments_outlined,
                      label:
                          '${post.rewardAmount.toStringAsFixed(0)} ${AppConstants.defaultCurrency}',
                    ),
                  _MetaChip(
                    icon: Icons.sell_outlined,
                    label: AppConstants.displayCategory(post.category),
                  ),
                  _MetaChip(
                    icon: Icons.place_outlined,
                    label: post.locationName,
                  ),
                  if (post.dominantColor != null)
                    _MetaChip(
                      icon: Icons.palette_outlined,
                      label: post.dominantColor!,
                    ),
                  if (post.matchedPostIds.isNotEmpty)
                    _MetaChip(
                      icon: Icons.auto_awesome_outlined,
                      label: '${post.matchedPostIds.length} совпадений',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder({required this.gradient, required this.title});

  final Gradient gradient;
  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
