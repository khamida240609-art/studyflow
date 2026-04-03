import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/community.dart';
import '../../models/item_post.dart';
import '../../providers/app_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_post_card.dart';
import '../../widgets/lostly_scaffold.dart';

class CommunityBoardScreen extends ConsumerWidget {
  const CommunityBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communities = ref.watch(communitiesProvider);
    final posts = ref.watch(allPostsProvider);

    return LostlyScaffold(
      title: context.l10n.communityBoard,
      child: communities.when(
        data: (communityItems) => posts.when(
          data: (postItems) {
            return ListView(
              children: [
                if (communityItems.isEmpty)
                  const EmptyState(
                    icon: Icons.groups_outlined,
                    title: 'Сообществ пока нет',
                    subtitle:
                        'Создайте или синхронизируйте первый раздел сообщества в Firestore.',
                  )
                else ...[
                  ...communityItems.map(
                    (community) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _CommunitySection(
                        community: community,
                        posts: postItems
                            .where((post) => post.communityId == community.id)
                            .take(6)
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}

class _CommunitySection extends StatelessWidget {
  const _CommunitySection({required this.community, required this.posts});

  final Community community;
  final List<ItemPost> posts;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.displayCommunity(community.name),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(community.description),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(community.locationName),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (community.emergencyNote?.isNotEmpty == true ||
              community.securityEmail?.isNotEmpty == true ||
              community.securityPhone?.isNotEmpty == true) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safety desk',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (community.emergencyNote?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(community.emergencyNote!),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (community.securityPhone?.isNotEmpty == true)
                        FilledButton.tonalIcon(
                          onPressed: () => launchUrl(
                            Uri.parse('tel:${community.securityPhone!}'),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.call_outlined),
                          label: const Text('Позвонить'),
                        ),
                      if (community.securityEmail?.isNotEmpty == true)
                        FilledButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse(
                              'mailto:${community.securityEmail!}?subject=Lostly%20community%20help',
                            ),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.mail_outline_rounded),
                          label: const Text('Написать'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (posts.isEmpty)
            const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Пока тихо',
              subtitle: 'Сейчас в этом сообществе нет активных объявлений.',
            )
          else
            SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) => SizedBox(
                  width: 260,
                  child: ItemPostCard(
                    post: posts[index],
                    onTap: () => context.push('/item/${posts[index].id}'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
