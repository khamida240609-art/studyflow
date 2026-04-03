import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/badge_provider.dart';
import '../utils/theme.dart';
import '../widgets/badge_card.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final badgeProv = context.watch<BadgeProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Achievements',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Unlock badges by staying consistent.',
                style: TextStyle(color: AppTheme.secondary(context), fontSize: 13)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: badgeProv.badges.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.05,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (_, i) {
                  final b = badgeProv.badges[i];
                  return BadgeCard(
                    badge: b,
                    selected: badgeProv.selectedBadgeId == b.id,
                    onTap: () => badgeProv.selectBadge(b.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
