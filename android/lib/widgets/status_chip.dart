import 'package:flutter/material.dart';

import '../core/enums/app_enums.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final PostStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PostStatus.lost => const Color(0xFFFF7A6B),
      PostStatus.found => const Color(0xFF1BA97F),
      PostStatus.matched => const Color(0xFF0F8B8D),
      PostStatus.returned => const Color(0xFF4452B8),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}
