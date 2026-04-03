import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/item_post.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/async_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_post_card.dart';
import '../../widgets/lostly_scaffold.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final allPosts = ref.watch(allPostsProvider);
    final lostPosts = ref.watch(lostPostsProvider);
    final foundPosts = ref.watch(foundPostsProvider);

    return LostlyScaffold(
      padding: EdgeInsets.zero,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  user.when(
                    data: (profile) => _HeroHeader(
                      title: l10n.greeting(
                        _firstName(profile?.displayName, context),
                      ),
                      subtitle: _localizedHomeText(context, 'hero_subtitle'),
                      onNotificationsTap: () => context.push('/notifications'),
                      onScannerTap: () => context.push('/scanner'),
                    ),
                    loading: () => const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => _HeroHeader(
                      title: 'Lostly',
                      subtitle: '$error',
                      onNotificationsTap: () => context.push('/notifications'),
                      onScannerTap: () => context.push('/scanner'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _QuickActionsGrid(
                    onCreateLost: () => context.push('/create/lost'),
                    onCreateFound: () => context.push('/create/found'),
                    onOpenMap: () => context.push('/map'),
                    onOpenCommunity: () => context.push('/community'),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Живая карта района',
                    actionLabel: 'Открыть карту',
                    onAction: () => context.push('/map'),
                  ),
                  const SizedBox(height: 12),
                  allPosts.when(
                    data: (items) => _LiveMapPreviewCard(
                      posts: items,
                      onOpenMap: () => context.push('/map'),
                    ),
                    loading: () => const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Container(
                      height: 220,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Text('$error'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: _localizedHomeText(context, 'fresh_lost_reports'),
                    actionLabel: _localizedHomeText(context, 'see_all'),
                    onAction: () => context.push('/lost'),
                  ),
                ],
              ),
            ),
          ),
          lostPosts.when(
            data: (items) => _PostsStrip(
              posts: items,
              emptyLabel: _localizedHomeText(context, 'lost_empty_subtitle'),
            ),
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('$error'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SectionHeader(
                title: _localizedHomeText(context, 'fresh_found_reports'),
                actionLabel: _localizedHomeText(context, 'see_all'),
                onAction: () => context.push('/found'),
              ),
            ),
          ),
          foundPosts.when(
            data: (items) => _PostsStrip(
              posts: items,
              emptyLabel: _localizedHomeText(context, 'found_empty_subtitle'),
            ),
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('$error'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.foundGradient,
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizedHomeText(context, 'need_fast_handoff'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _localizedHomeText(context, 'qr_card_subtitle'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: l10n.openQrScanner,
                      onPressed: () => context.push('/scanner'),
                      icon: Icons.qr_code_scanner_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LostItemsFeedScreen extends ConsumerWidget {
  const LostItemsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final posts = ref.watch(lostPostsProvider);
    return LostlyScaffold(
      title: l10n.lostItemsFeed,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create/lost'),
        label: Text(l10n.reportLostItem),
        icon: const Icon(Icons.add_rounded),
      ),
      child: AsyncValueWidget(
        value: posts,
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              title: _localizedHomeText(context, 'no_lost_items_yet'),
              subtitle: _localizedHomeText(context, 'lost_feed_empty_subtitle'),
              actionLabel: l10n.create,
              onAction: () => context.push('/create/lost'),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) => ItemPostCard(
              post: items[index],
              onTap: () => context.push('/item/${items[index].id}'),
            ),
          );
        },
      ),
    );
  }
}

class FoundItemsFeedScreen extends ConsumerWidget {
  const FoundItemsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final posts = ref.watch(foundPostsProvider);
    return LostlyScaffold(
      title: l10n.foundItemsFeed,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create/found'),
        label: Text(l10n.reportFoundItem),
        icon: const Icon(Icons.add_rounded),
      ),
      child: AsyncValueWidget(
        value: posts,
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: _localizedHomeText(context, 'no_found_items_yet'),
              subtitle: _localizedHomeText(
                context,
                'found_feed_empty_subtitle',
              ),
              actionLabel: l10n.create,
              onAction: () => context.push('/create/found'),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) => ItemPostCard(
              post: items[index],
              onTap: () => context.push('/item/${items[index].id}'),
            ),
          );
        },
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.onNotificationsTap,
    required this.onScannerTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onNotificationsTap;
  final VoidCallback onScannerTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(36),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
              ),
              IconButton.filledTonal(
                onPressed: onNotificationsTap,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 22),
          AppButton(
            label: _localizedHomeText(context, 'scan_item_qr_now'),
            onPressed: onScannerTap,
            icon: Icons.qr_code_scanner_rounded,
            isSecondary: true,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onCreateLost,
    required this.onCreateFound,
    required this.onOpenMap,
    required this.onOpenCommunity,
  });

  final VoidCallback onCreateLost;
  final VoidCallback onCreateFound;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenCommunity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.2,
      children: [
        _ActionTile(
          label: l10n.lostSomething,
          icon: Icons.search_off_rounded,
          gradient: AppTheme.lostGradient,
          onTap: onCreateLost,
        ),
        _ActionTile(
          label: l10n.foundSomething,
          icon: Icons.favorite_outline_rounded,
          gradient: AppTheme.foundGradient,
          onTap: onCreateFound,
        ),
        _ActionTile(
          label: l10n.mapView,
          icon: Icons.map_outlined,
          gradient: const LinearGradient(
            colors: [Color(0xFFE5F1FF), Color(0xFFB4D7FF)],
          ),
          onTap: onOpenMap,
        ),
        _ActionTile(
          label: l10n.communities,
          icon: Icons.apartment_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF3D6), Color(0xFFFFD5A5)],
          ),
          onTap: onOpenCommunity,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon),
            ),
            const Spacer(),
            Text(label, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _PostsStrip extends StatelessWidget {
  const _PostsStrip({required this.posts, required this.emptyLabel});

  final List<ItemPost> posts;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: EmptyState(
            icon: Icons.inbox_outlined,
            title: _localizedHomeText(context, 'still_quiet_here'),
            subtitle: emptyLabel,
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 310,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: posts.take(8).length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, index) => SizedBox(
            width: 262,
            child: ItemPostCard(
              post: posts[index],
              onTap: () => context.push('/item/${posts[index].id}'),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveMapPreviewCard extends StatelessWidget {
  const _LiveMapPreviewCard({required this.posts, required this.onOpenMap});

  final List<ItemPost> posts;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final mappedPosts = posts
        .where((post) => post.latitude != 0 && post.longitude != 0)
        .take(8)
        .toList();

    if (mappedPosts.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF0F7FF), Color(0xFFDDF1FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Карта уже готова',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Как только у объявлений появятся координаты, они отобразятся здесь прямо на главном экране.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            AppButton(
              label: 'Открыть полную карту',
              onPressed: onOpenMap,
              icon: Icons.map_rounded,
            ),
          ],
        ),
      );
    }

    final initial = mappedPosts.first;
    final markers = mappedPosts
        .map(
          (post) => Marker(
            markerId: MarkerId(post.id),
            position: LatLng(post.latitude, post.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              post.type.name == 'lost'
                  ? BitmapDescriptor.hueRose
                  : BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: post.title,
              snippet: post.locationName,
            ),
          ),
        )
        .toSet();

    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: GoogleMap(
                liteModeEnabled: true,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                initialCameraPosition: CameraPosition(
                  target: LatLng(initial.latitude, initial.longitude),
                  zoom: 12,
                ),
                markers: markers,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.58),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Карта в реальном времени',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Смотрите точки найденных и потерянных вещей прямо с главного экрана.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: onOpenMap,
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: const Text('Открыть'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _firstName(String? value, BuildContext context) {
  if (value == null || value.trim().isEmpty) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return 'Друг';
      case 'kk':
        return 'Дос';
      default:
        return 'Explorer';
    }
  }
  return value.trim().split(' ').first;
}

String _localizedHomeText(BuildContext context, String key) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      switch (key) {
        case 'hero_subtitle':
          return 'Ваша сеть lost-and-found работает в реальном времени.';
        case 'fresh_lost_reports':
          return 'Свежие объявления о потерях';
        case 'fresh_found_reports':
          return 'Свежие объявления о находках';
        case 'see_all':
          return 'Смотреть всё';
        case 'lost_empty_subtitle':
          return 'Пока нет потерянных вещей. Начните ленту своим первым объявлением.';
        case 'found_empty_subtitle':
          return 'Пока нет найденных вещей. Здесь появятся возвраты от сообщества.';
        case 'need_fast_handoff':
          return 'Нужна быстрая передача?';
        case 'qr_card_subtitle':
          return 'Создавайте QR-ID для ценных вещей и позже сканируйте их для мгновенного поиска владельца.';
        case 'no_lost_items_yet':
          return 'Пока нет потерянных вещей';
        case 'lost_feed_empty_subtitle':
          return 'Новые объявления сообщества будут появляться здесь в реальном времени.';
        case 'no_found_items_yet':
          return 'Пока нет найденных вещей';
        case 'found_feed_empty_subtitle':
          return 'Здесь будут появляться вещи, найденные сообществом.';
        case 'scan_item_qr_now':
          return 'Сканировать QR вещи';
        case 'still_quiet_here':
          return 'Пока тихо';
      }
      break;
    case 'kk':
      switch (key) {
        case 'hero_subtitle':
          return 'Сіздің жоғалған және табылған заттар желіңіз нақты уақытта жұмыс істеп тұр.';
        case 'fresh_lost_reports':
          return 'Жаңа жоғалған заттар';
        case 'fresh_found_reports':
          return 'Жаңа табылған заттар';
        case 'see_all':
          return 'Барлығын көру';
        case 'lost_empty_subtitle':
          return 'Әзірге жоғалған зат жоқ. Алғашқы хабарламаңызды жариялап бастаңыз.';
        case 'found_empty_subtitle':
          return 'Әзірге табылған зат жоқ. Қауымдастық қайтарған заттар осы жерде көрінеді.';
        case 'need_fast_handoff':
          return 'Жылдам табыстау керек пе?';
        case 'qr_card_subtitle':
          return 'Бағалы затыңызға QR-ID жасап, кейін иесін бірден табу үшін сканерлеңіз.';
        case 'no_lost_items_yet':
          return 'Әзірге жоғалған заттар жоқ';
        case 'lost_feed_empty_subtitle':
          return 'Қауымдастықтың жаңа хабарламалары осы жерде нақты уақытта шығады.';
        case 'no_found_items_yet':
          return 'Әзірге табылған заттар жоқ';
        case 'found_feed_empty_subtitle':
          return 'Қауымдастық тапқан заттар осы жерде көрсетіледі.';
        case 'scan_item_qr_now':
          return 'Заттың QR кодын сканерлеу';
        case 'still_quiet_here':
          return 'Әзірге тыныш';
      }
      break;
  }

  switch (key) {
    case 'hero_subtitle':
      return 'Your real-time lost-and-found network is live.';
    case 'fresh_lost_reports':
      return 'Fresh lost reports';
    case 'fresh_found_reports':
      return 'Fresh found reports';
    case 'see_all':
      return 'See all';
    case 'lost_empty_subtitle':
      return 'No lost items yet. Start the board with your first report.';
    case 'found_empty_subtitle':
      return 'No found items yet. Community returns will appear here.';
    case 'need_fast_handoff':
      return 'Need a fast handoff?';
    case 'qr_card_subtitle':
      return 'Generate QR IDs for your valuables and scan them later for instant owner lookup.';
    case 'no_lost_items_yet':
      return 'No lost items yet';
    case 'lost_feed_empty_subtitle':
      return 'New community reports will appear here in real time.';
    case 'no_found_items_yet':
      return 'No found items yet';
    case 'found_feed_empty_subtitle':
      return 'Recovered items posted by the community will appear here.';
    case 'scan_item_qr_now':
      return 'Scan item QR now';
    case 'still_quiet_here':
      return 'Still quiet here';
    default:
      return '';
  }
}
