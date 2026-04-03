import 'package:flutter/material.dart';
import '../models/badge.dart' as model;
import '../utils/theme.dart';

class BadgeCard extends StatelessWidget {
  final model.Badge badge;
  final bool selected;
  final VoidCallback onTap;
  const BadgeCard({
    super.key,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !badge.unlocked;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: locked ? AppTheme.bg3 : AppTheme.bg2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.accent2 : (locked ? AppTheme.border2 : AppTheme.accent),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(badge.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
          Text(badge.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: locked ? AppTheme.secondary(context) : AppTheme.textPrimary,
              )),
          const SizedBox(height: 6),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.tertiary(context)),
          ),
            if (selected) ...[
              const SizedBox(height: 6),
              const Text('Pinned', style: TextStyle(color: AppTheme.accent2, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}
