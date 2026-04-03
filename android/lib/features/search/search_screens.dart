import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/community.dart';
import '../../models/item_post.dart';
import '../../providers/app_providers.dart';
import '../../services/location_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_post_card.dart';
import '../../widgets/lostly_scaffold.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedCommunity = 'all';
  PostType? _selectedType;
  PostStatus? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final posts = ref.watch(allPostsProvider);
    final communities = ref.watch(communitiesProvider);

    return LostlyScaffold(
      title: l10n.search,
      actions: [
        IconButton(
          onPressed: () => context.push('/map'),
          icon: const Icon(Icons.map_outlined),
        ),
      ],
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _SearchFilterPanel(
              controller: _searchController,
              selectedCategory: _selectedCategory,
              selectedCommunity: _selectedCommunity,
              selectedType: _selectedType,
              selectedStatus: _selectedStatus,
              communities: communities,
              onCategoryChanged: (value) =>
                  setState(() => _selectedCategory = value),
              onCommunityChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCommunity = value);
                }
              },
              onTypeChanged: (value) => setState(() => _selectedType = value),
              onStatusChanged: (value) =>
                  setState(() => _selectedStatus = value),
              onSearchChanged: () => setState(() {}),
            ),
          ),
          posts.when(
            data: (items) {
              final filtered = _applyFilters(items);
              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: EmptyState(
                        icon: Icons.manage_search_rounded,
                        title: _localizedSearchText(
                          context,
                          'no_matching_items',
                        ),
                        subtitle: _localizedSearchText(
                          context,
                          'no_matching_items_subtitle',
                        ),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(top: 18, bottom: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ItemPostCard(
                        post: filtered[index],
                        onTap: () =>
                            context.push('/item/${filtered[index].id}'),
                      ),
                    );
                  }, childCount: filtered.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('$error')),
            ),
          ),
        ],
      ),
    );
  }

  List<ItemPost> _applyFilters(List<ItemPost> posts) {
    final query = _searchController.text.trim().toLowerCase();
    return posts.where((post) {
      final matchesQuery =
          query.isEmpty ||
          post.title.toLowerCase().contains(query) ||
          post.description.toLowerCase().contains(query) ||
          post.locationName.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == 'All' ||
          AppConstants.displayCategory(post.category) ==
              AppConstants.displayCategory(_selectedCategory);
      final matchesCommunity =
          _selectedCommunity == 'all' || post.communityId == _selectedCommunity;
      final matchesType = _selectedType == null || post.type == _selectedType;
      final matchesStatus =
          _selectedStatus == null || post.status == _selectedStatus;

      return matchesQuery &&
          matchesCategory &&
          matchesCommunity &&
          matchesType &&
          matchesStatus;
    }).toList();
  }
}

class _SearchFilterPanel extends StatelessWidget {
  const _SearchFilterPanel({
    required this.controller,
    required this.selectedCategory,
    required this.selectedCommunity,
    required this.selectedType,
    required this.selectedStatus,
    required this.communities,
    required this.onCategoryChanged,
    required this.onCommunityChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onSearchChanged,
  });

  final TextEditingController controller;
  final String selectedCategory;
  final String selectedCommunity;
  final PostType? selectedType;
  final PostStatus? selectedStatus;
  final AsyncValue<List<Community>> communities;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String?> onCommunityChanged;
  final ValueChanged<PostType?> onTypeChanged;
  final ValueChanged<PostStatus?> onStatusChanged;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: (_) => onSearchChanged(),
            decoration: InputDecoration(
              labelText: _localizedSearchText(context, 'search_field_label'),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Категории',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChoiceChip(
                label: _localizedSearchText(context, 'all'),
                selected: selectedCategory == 'All',
                onSelected: () => onCategoryChanged('All'),
              ),
              ...AppConstants.itemCategories.map(
                (category) => _FilterChoiceChip(
                  label: category,
                  selected: selectedCategory == category,
                  onSelected: () => onCategoryChanged(category),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final fieldWidth = width >= 560 ? (width - 12) / 2 : width;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: communities.when(
                      data: (items) => _CommunityDropdown(
                        communities: items,
                        value: selectedCommunity,
                        onChanged: onCommunityChanged,
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<PostType?>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: _localizedSearchText(context, 'type'),
                      ),
                      items: [
                        DropdownMenuItem<PostType?>(
                          value: null,
                          child: Text(_localizedSearchText(context, 'all')),
                        ),
                        DropdownMenuItem<PostType?>(
                          value: PostType.lost,
                          child: Text(
                            _localizedTypeLabel(context, PostType.lost),
                          ),
                        ),
                        DropdownMenuItem<PostType?>(
                          value: PostType.found,
                          child: Text(
                            _localizedTypeLabel(context, PostType.found),
                          ),
                        ),
                      ],
                      onChanged: onTypeChanged,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<PostStatus?>(
                      initialValue: selectedStatus,
                      decoration: InputDecoration(
                        labelText: _localizedSearchText(context, 'status'),
                      ),
                      items: [
                        DropdownMenuItem<PostStatus?>(
                          value: null,
                          child: Text(_localizedSearchText(context, 'all')),
                        ),
                        DropdownMenuItem<PostStatus?>(
                          value: PostStatus.lost,
                          child: Text(
                            _localizedStatusLabel(context, PostStatus.lost),
                          ),
                        ),
                        DropdownMenuItem<PostStatus?>(
                          value: PostStatus.found,
                          child: Text(
                            _localizedStatusLabel(context, PostStatus.found),
                          ),
                        ),
                        DropdownMenuItem<PostStatus?>(
                          value: PostStatus.matched,
                          child: Text(
                            _localizedStatusLabel(context, PostStatus.matched),
                          ),
                        ),
                        DropdownMenuItem<PostStatus?>(
                          value: PostStatus.returned,
                          child: Text(
                            _localizedStatusLabel(context, PostStatus.returned),
                          ),
                        ),
                      ],
                      onChanged: onStatusChanged,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class SavedPostsScreen extends ConsumerWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final saved = ref.watch(savedPostsProvider);
    return LostlyScaffold(
      title: l10n.savedPosts,
      child: saved.when(
        data: (posts) {
          if (posts.isEmpty) {
            return EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: l10n.savedPostsEmptyTitle,
              subtitle: l10n.savedPostsEmptySubtitle,
            );
          }
          return ListView.separated(
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) => ItemPostCard(
              post: posts[index],
              onTap: () => context.push('/item/${posts[index].id}'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(48.0196, 66.9237),
    zoom: 4.7,
  );

  GoogleMapController? _controller;
  bool _locating = false;

  Set<Marker> _buildCityMarkers() {
    return _kazakhstanCities
        .map(
          (city) => Marker(
            markerId: MarkerId(city.name),
            position: LatLng(city.latitude, city.longitude),
            infoWindow: InfoWindow(title: city.name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        )
        .toSet();
  }

  Set<Marker> _buildPostMarkers(List<ItemPost> posts) {
    return posts
        .where((post) => post.latitude != 0 || post.longitude != 0)
        .map(
          (post) => Marker(
            markerId: MarkerId('post-${post.id}'),
            position: LatLng(post.latitude, post.longitude),
            infoWindow: InfoWindow(
              title: post.title,
              snippet:
                  '${AppConstants.displayCategory(post.category)} • ${post.status.label}',
              onTap: () => context.push('/item/${post.id}'),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _statusMarkerHue(post.status),
            ),
          ),
        )
        .toSet();
  }

  double _statusMarkerHue(PostStatus status) {
    switch (status) {
      case PostStatus.lost:
        return BitmapDescriptor.hueRose;
      case PostStatus.found:
        return BitmapDescriptor.hueGreen;
      case PostStatus.matched:
        return BitmapDescriptor.hueCyan;
      case PostStatus.returned:
        return BitmapDescriptor.hueViolet;
    }
  }

  Future<void> _focusCurrentLocation() async {
    if (_locating) {
      return;
    }
    setState(() => _locating = true);
    try {
      final result = await ref
          .read(locationServiceProvider)
          .determinePosition();
      if (_controller == null) {
        return;
      }

      final latitude =
          result.position?.latitude ?? LocationService.fallbackLatitude;
      final longitude =
          result.position?.longitude ?? LocationService.fallbackLongitude;

      await _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(latitude, longitude),
            zoom: result.hasPosition ? 12.6 : 5.1,
          ),
        ),
      );

      if (mounted && result.message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message!)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Не удалось определить локацию. Показан центр Казахстана.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(allPostsProvider).valueOrNull ?? const <ItemPost>[];
    final markers = <Marker>{
      ..._buildCityMarkers(),
      ..._buildPostMarkers(posts),
    };

    return LostlyScaffold(
      title: 'Карта',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.location_city_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Карта объявлений и городов Казахстана',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Маркер города показывает населённый пункт, а маркер поста открывает карточку объявления.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: _focusCurrentLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: GoogleMap(
                initialCameraPosition: _initialCameraPosition,
                onMapCreated: (controller) => _controller = controller,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                markers: markers,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _CommunityDropdown extends StatelessWidget {
  const _CommunityDropdown({
    required this.communities,
    required this.value,
    required this.onChanged,
  });

  final List<Community> communities;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: _localizedSearchText(context, 'community'),
      ),
      items: [
        DropdownMenuItem<String>(
          value: 'all',
          child: Text(_localizedSearchText(context, 'all')),
        ),
        ...communities.map(
          (community) => DropdownMenuItem<String>(
            value: community.id,
            child: Text(AppConstants.displayCommunity(community.name)),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _KazakhstanCity {
  const _KazakhstanCity({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}

const List<_KazakhstanCity> _kazakhstanCities = [
  _KazakhstanCity(name: 'Астана', latitude: 51.1694, longitude: 71.4491),
  _KazakhstanCity(name: 'Алматы', latitude: 43.2389, longitude: 76.8897),
  _KazakhstanCity(name: 'Шымкент', latitude: 42.3417, longitude: 69.5901),
  _KazakhstanCity(name: 'Тараз', latitude: 42.9004, longitude: 71.3655),
  _KazakhstanCity(name: 'Қарағанды', latitude: 49.8047, longitude: 73.1094),
  _KazakhstanCity(name: 'Ақтөбе', latitude: 50.2839, longitude: 57.1660),
  _KazakhstanCity(name: 'Атырау', latitude: 47.0945, longitude: 51.9238),
  _KazakhstanCity(name: 'Ақтау', latitude: 43.6532, longitude: 51.1975),
  _KazakhstanCity(name: 'Павлодар', latitude: 52.2873, longitude: 76.9674),
  _KazakhstanCity(name: 'Өскемен', latitude: 49.9483, longitude: 82.6275),
  _KazakhstanCity(name: 'Түркістан', latitude: 43.2973, longitude: 68.2518),
  _KazakhstanCity(name: 'Қостанай', latitude: 53.2144, longitude: 63.6246),
  _KazakhstanCity(name: 'Қызылорда', latitude: 44.8488, longitude: 65.4823),
  _KazakhstanCity(name: 'Орал', latitude: 51.2278, longitude: 51.3865),
  _KazakhstanCity(name: 'Петропавл', latitude: 54.8728, longitude: 69.1430),
];

String _localizedSearchText(BuildContext context, String key) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      switch (key) {
        case 'search_field_label':
          return 'Поиск по названию, описанию или локации';
        case 'all':
          return 'Все';
        case 'type':
          return 'Тип';
        case 'status':
          return 'Статус';
        case 'community':
          return 'Сообщество';
        case 'no_matching_items':
          return 'Ничего не найдено';
        case 'no_matching_items_subtitle':
          return 'Попробуйте изменить категорию, сообщество или статус.';
        case 'no_mapped_posts_yet':
          return 'Постов на карте пока нет';
        case 'no_mapped_posts_subtitle':
          return 'Посты с координатами появятся здесь как интерактивные маркеры.';
      }
      break;
    case 'kk':
      switch (key) {
        case 'search_field_label':
          return 'Атауы, сипаттамасы немесе локациясы бойынша іздеу';
        case 'all':
          return 'Барлығы';
        case 'type':
          return 'Түрі';
        case 'status':
          return 'Статус';
        case 'community':
          return 'Қауымдастық';
        case 'no_matching_items':
          return 'Сәйкес зат табылмады';
        case 'no_matching_items_subtitle':
          return 'Категорияны, қауымдастықты не статусты өзгертіп көріңіз.';
        case 'no_mapped_posts_yet':
          return 'Картада посттар әлі жоқ';
        case 'no_mapped_posts_subtitle':
          return 'Координаттары бар посттар осы жерде белгі ретінде көрінеді.';
      }
      break;
  }

  switch (key) {
    case 'search_field_label':
      return 'Search by name, description or location';
    case 'all':
      return 'All';
    case 'type':
      return 'Type';
    case 'status':
      return 'Status';
    case 'community':
      return 'Community';
    case 'no_matching_items':
      return 'No matching items';
    case 'no_matching_items_subtitle':
      return 'Try changing the category, community or status filters.';
    case 'no_mapped_posts_yet':
      return 'No mapped posts yet';
    case 'no_mapped_posts_subtitle':
      return 'Posts with coordinates will appear here as tappable markers.';
    default:
      return '';
  }
}

String _localizedTypeLabel(BuildContext context, PostType type) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      return type == PostType.lost ? 'Потеряно' : 'Найдено';
    case 'kk':
      return type == PostType.lost ? 'Жоғалған' : 'Табылған';
    default:
      return type == PostType.lost ? 'Lost' : 'Found';
  }
}

String _localizedStatusLabel(BuildContext context, PostStatus status) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      switch (status) {
        case PostStatus.lost:
          return 'Потеряно';
        case PostStatus.found:
          return 'Найдено';
        case PostStatus.matched:
          return 'Совпадение';
        case PostStatus.returned:
          return 'Возвращено';
      }
    case 'kk':
      switch (status) {
        case PostStatus.lost:
          return 'Жоғалған';
        case PostStatus.found:
          return 'Табылған';
        case PostStatus.matched:
          return 'Сәйкестенді';
        case PostStatus.returned:
          return 'Қайтарылды';
      }
    default:
      switch (status) {
        case PostStatus.lost:
          return 'Lost';
        case PostStatus.found:
          return 'Found';
        case PostStatus.matched:
          return 'Matched';
        case PostStatus.returned:
          return 'Returned';
      }
  }
}
