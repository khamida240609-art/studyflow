import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/build_context_x.dart';
import '../../core/utils/form_validators.dart';
import '../../models/app_user.dart';
import '../../models/user_preferences.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_post_card.dart';
import '../../widgets/lostly_scaffold.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final authController = ref.watch(authControllerProvider);

    return LostlyScaffold(
      title: l10n.profile,
      actions: [
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      child: user.when(
        data: (profile) {
          if (profile == null) {
            return EmptyState(
              icon: Icons.person_outline_rounded,
              title: _localizedProfileText(context, 'no_profile_loaded'),
              subtitle: _localizedProfileText(
                context,
                'no_profile_loaded_subtitle',
              ),
            );
          }

          final myPosts = ref.watch(userPostsProvider(profile.id));

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileHeader(
                      user: profile,
                      onEdit: () => context.push('/profile/edit'),
                      onNotifications: () => context.push('/notifications'),
                      onSaved: () => context.push('/saved'),
                    ),
                    const SizedBox(height: 20),
                    _MenuTile(
                      icon: Icons.groups_rounded,
                      title: l10n.communityBoard,
                      subtitle: _localizedProfileText(
                        context,
                        'community_board_subtitle',
                      ),
                      onTap: () => context.push('/community'),
                    ),
                    _MenuTile(
                      icon: Icons.map_outlined,
                      title: l10n.mapView,
                      subtitle: _localizedProfileText(
                        context,
                        'map_view_subtitle',
                      ),
                      onTap: () => context.push('/map'),
                    ),
                    if (profile.isAdmin)
                      _MenuTile(
                        icon: Icons.admin_panel_settings_outlined,
                        title: l10n.adminPanel,
                        subtitle: _localizedProfileText(
                          context,
                          'admin_panel_subtitle',
                        ),
                        onTap: () => context.push('/admin'),
                      ),
                    const SizedBox(height: 8),
                    ref
                        .watch(userAnalyticsProvider)
                        .when(
                          data: (analytics) => _AnalyticsGrid(
                            title: 'Моя аналитика',
                            values: <_AnalyticsMetric>[
                              _AnalyticsMetric(
                                label: 'Потеряно',
                                value: '${analytics.lostCount}',
                              ),
                              _AnalyticsMetric(
                                label: 'Найдено',
                                value: '${analytics.foundCount}',
                              ),
                              _AnalyticsMetric(
                                label: 'Возвращено',
                                value: '${analytics.returnedCount}',
                              ),
                              _AnalyticsMetric(
                                label: 'Активные',
                                value: '${analytics.activeCount}',
                              ),
                            ],
                          ),
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, _) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text('$error'),
                          ),
                        ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.myPosts,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              myPosts.when(
                data: (items) {
                  if (items.isEmpty) {
                    return SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.add_photo_alternate_outlined,
                        title: _localizedProfileText(context, 'no_posts_yet'),
                        subtitle: _localizedProfileText(
                          context,
                          'no_posts_yet_subtitle',
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ItemPostCard(
                          post: items[index],
                          onTap: () => context.push('/item/${items[index].id}'),
                        ),
                      );
                    }, childCount: items.length),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('$error')),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 16),
                  child: AppButton(
                    label: l10n.logout,
                    onPressed: authController.isLoading
                        ? null
                        : () async {
                            try {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .signOut();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            } catch (error) {
                              if (context.mounted) {
                                context.showErrorSnackBar('$error');
                              }
                            }
                          },
                    isSecondary: true,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedCommunity;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final communities = ref.watch(communitiesProvider);
    final profileState = ref.watch(profileActionControllerProvider);

    return LostlyScaffold(
      title: l10n.editProfile,
      child: user.when(
        data: (profile) {
          if (profile == null) {
            return EmptyState(
              icon: Icons.person_off_outlined,
              title: _localizedProfileText(context, 'no_profile_available'),
              subtitle: _localizedProfileText(
                context,
                'no_profile_available_subtitle',
              ),
            );
          }

          if (_nameController.text.isEmpty) {
            _nameController.text = profile.displayName;
            _bioController.text = profile.bio ?? '';
            _selectedCommunity = profile.communityIds.firstOrNull ?? 'campus';
          }

          return Form(
            key: _formKey,
            child: ListView(
              children: [
                AppTextField(
                  controller: _nameController,
                  label: l10n.displayName,
                  validator: (value) =>
                      _requiredValidator(context, value, l10n.displayName),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _bioController,
                  label: _localizedProfileText(context, 'bio'),
                  hint: _localizedProfileText(context, 'bio_hint'),
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                communities.when(
                  data: (items) => DropdownButtonFormField<String>(
                    initialValue: _selectedCommunity,
                    decoration: InputDecoration(
                      labelText: _localizedProfileText(
                        context,
                        'primary_community',
                      ),
                    ),
                    items: items
                        .map(
                          (community) => DropdownMenuItem(
                            value: community.id,
                            child: Text(
                              AppConstants.displayCommunity(community.name),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCommunity = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: _localizedProfileText(context, 'save_profile'),
                  isLoading: profileState.isLoading,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    try {
                      await ref
                          .read(profileActionControllerProvider.notifier)
                          .updateProfile(
                            user: profile,
                            displayName: _nameController.text,
                            bio: _bioController.text,
                            communityIds: _selectedCommunity == null
                                ? profile.communityIds
                                : <String>[_selectedCommunity!],
                          );
                      if (context.mounted) {
                        context.pop();
                        context.showAppSnackBar(
                          _localizedProfileText(context, 'profile_updated'),
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        context.showErrorSnackBar('$error');
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _emailController = TextEditingController();
  final _smsController = TextEditingController();
  bool _pushEnabled = true;
  bool _matchAlerts = true;
  bool _claimAlerts = true;
  bool _reminderAlerts = true;
  bool _emailAlerts = false;
  bool _smsAlerts = false;
  bool _initializedPrefs = false;
  String _localeCode = 'ru';

  @override
  void dispose() {
    _emailController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final preferences = ref.watch(userPreferencesProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final actionState = ref.watch(preferencesActionControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return LostlyScaffold(
      title: l10n.settings,
      child: preferences.when(
        data: (prefs) {
          final effective =
              prefs ??
              UserPreferences.defaults(
                userId: currentUser?.id ?? '',
                emailAddress: currentUser?.email,
              );
          if (!_initializedPrefs) {
            _initializedPrefs = true;
            _pushEnabled = effective.pushEnabled;
            _matchAlerts = effective.matchAlertsEnabled;
            _claimAlerts = effective.claimAlertsEnabled;
            _reminderAlerts = effective.reminderAlertsEnabled;
            _emailAlerts = effective.emailAlertsEnabled;
            _smsAlerts = effective.smsAlertsEnabled;
            _localeCode = effective.localeCode;
            _emailController.text = effective.emailAddress ?? '';
            _smsController.text = effective.smsNumber ?? '';
          }

          return ListView(
            children: [
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.notifications,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile.adaptive(
                      value: _pushEnabled,
                      onChanged: (value) =>
                          setState(() => _pushEnabled = value),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Push-уведомления'),
                      subtitle: const Text(
                        'Показывать локальные и FCM-оповещения о совпадениях, чатах и статусах.',
                      ),
                    ),
                    SwitchListTile.adaptive(
                      value: _matchAlerts,
                      onChanged: (value) =>
                          setState(() => _matchAlerts = value),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.matchAlerts),
                      subtitle: Text(
                        _localizedProfileText(context, 'match_alerts_subtitle'),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      value: _claimAlerts,
                      onChanged: (value) =>
                          setState(() => _claimAlerts = value),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Уведомления о заявках'),
                      subtitle: const Text(
                        'Сообщать о новых claim request и решениях по ним.',
                      ),
                    ),
                    SwitchListTile.adaptive(
                      value: _reminderAlerts,
                      onChanged: (value) =>
                          setState(() => _reminderAlerts = value),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Напоминания о встрече'),
                      subtitle: const Text(
                        'Напоминать о назначенной передаче вещи.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email / SMS alerts',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Вы можете дублировать важные alert-уведомления по email и SMS.',
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: _emailAlerts,
                      onChanged: (value) =>
                          setState(() => _emailAlerts = value),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Email alerts'),
                    ),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email для оповещений',
                      hint: 'name@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: _smsAlerts,
                      onChanged: (value) => setState(() => _smsAlerts = value),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('SMS alerts'),
                    ),
                    AppTextField(
                      controller: _smsController,
                      label: 'Номер телефона',
                      hint: '+7 777 000 00 00',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appearance,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _localizedProfileText(context, 'appearance_subtitle'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ThemeChip(
                          label: l10n.systemTheme,
                          selected: themeMode == ThemeMode.system,
                          color: colorScheme.primary,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.system),
                        ),
                        _ThemeChip(
                          label: l10n.lightTheme,
                          selected: themeMode == ThemeMode.light,
                          color: const Color(0xFFFFB347),
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.light),
                        ),
                        _ThemeChip(
                          label: l10n.darkTheme,
                          selected: themeMode == ThemeMode.dark,
                          color: const Color(0xFF203A43),
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(ThemeMode.dark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appLanguage,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _localizedProfileText(context, 'language_subtitle'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _LanguageChip(
                          label: 'Русский',
                          selected: _localeCode == 'ru',
                          onTap: () {
                            setState(() => _localeCode = 'ru');
                            ref
                                .read(appLocaleProvider.notifier)
                                .setLocale(const Locale('ru'));
                          },
                        ),
                        _LanguageChip(
                          label: 'Қазақша',
                          selected: _localeCode == 'kk',
                          onTap: () {
                            setState(() => _localeCode = 'kk');
                            ref
                                .read(appLocaleProvider.notifier)
                                .setLocale(const Locale('kk'));
                          },
                        ),
                        _LanguageChip(
                          label: 'English',
                          selected: _localeCode == 'en',
                          onTap: () {
                            setState(() => _localeCode = 'en');
                            ref
                                .read(appLocaleProvider.notifier)
                                .setLocale(const Locale('en'));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Сохранить настройки уведомлений',
                isLoading: actionState.isLoading,
                onPressed: currentUser == null
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(
                                preferencesActionControllerProvider.notifier,
                              )
                              .savePreferences(
                                preferences: effective.copyWith(
                                  localeCode: _localeCode,
                                  pushEnabled: _pushEnabled,
                                  emailAlertsEnabled: _emailAlerts,
                                  smsAlertsEnabled: _smsAlerts,
                                  matchAlertsEnabled: _matchAlerts,
                                  claimAlertsEnabled: _claimAlerts,
                                  reminderAlertsEnabled: _reminderAlerts,
                                  emailAddress: _emailController.text.trim(),
                                  smsNumber: _smsController.text.trim(),
                                ),
                              );
                          if (context.mounted) {
                            context.showAppSnackBar('Настройки сохранены');
                          }
                        } catch (error) {
                          if (context.mounted) {
                            context.showErrorSnackBar('$error');
                          }
                        }
                      },
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(l10n.aboutLostly),
                  subtitle: Text(
                    _localizedProfileText(context, 'about_lostly_subtitle'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsProvider);
    final allPosts = ref.watch(allPostsProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final l10n = context.l10n;

    if (currentUser?.isAdmin != true) {
      return LostlyScaffold(
        title: l10n.adminPanel,
        child: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: _localizedProfileText(context, 'restricted_area'),
          subtitle: _localizedProfileText(context, 'restricted_area_subtitle'),
        ),
      );
    }

    return LostlyScaffold(
      title: l10n.adminPanel,
      child: ListView(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizedProfileText(context, 'moderation_overview'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  _localizedProfileText(
                    context,
                    'moderation_overview_subtitle',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ref.watch(appAnalyticsProvider).when(
                data: (analytics) => _AnalyticsGrid(
                  title: 'Сводка платформы',
                  values: <_AnalyticsMetric>[
                    _AnalyticsMetric(
                      label: 'Потеряно',
                      value: '${analytics.lostCount}',
                    ),
                    _AnalyticsMetric(
                      label: 'Найдено',
                      value: '${analytics.foundCount}',
                    ),
                    _AnalyticsMetric(
                      label: 'Возвращено',
                      value: '${analytics.returnedCount}',
                    ),
                    _AnalyticsMetric(
                      label: 'Priority docs',
                      value: '${analytics.priorityDocumentCount}',
                    ),
                  ],
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text('$error'),
              ),
          const SizedBox(height: 18),
          Text(
            _localizedProfileText(context, 'reports'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          reports.when(
            data: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.verified_outlined,
                  title: _localizedProfileText(context, 'no_active_reports'),
                  subtitle: _localizedProfileText(
                    context,
                    'no_active_reports_subtitle',
                  ),
                );
              }
              return Column(
                children: items
                    .map(
                      (report) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.reason,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(report.details),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      context.push('/item/${report.postId}'),
                                  child: Text(
                                    _localizedProfileText(context, 'open_post'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FilledButton.tonal(
                                  onPressed: () async {
                                    await ref
                                        .read(
                                          reportActionControllerProvider
                                              .notifier,
                                        )
                                        .resolveReport(report.id);
                                    if (context.mounted) {
                                      context.showAppSnackBar(
                                        _localizedProfileText(
                                          context,
                                          'report_resolved',
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    _localizedProfileText(context, 'resolve'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('$error'),
          ),
          const SizedBox(height: 20),
          Text(
            _localizedProfileText(context, 'recent_posts'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          allPosts.when(
            data: (items) {
              if (items.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: items
                    .take(4)
                    .map(
                      (post) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ItemPostCard(
                          post: post,
                          onTap: () => context.push('/item/${post.id}'),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('$error'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.onEdit,
    required this.onNotifications,
    required this.onSaved,
  });

  final AppUser user;
  final VoidCallback onEdit;
  final VoidCallback onNotifications;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bio = user.bio?.isNotEmpty == true
        ? user.bio!
        : _localizedProfileText(context, 'default_bio');
    final primaryCommunity = user.communityIds.isNotEmpty
        ? AppConstants.displayCommunity(user.communityIds.first)
        : _localizedProfileText(context, 'all_communities');

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 380;
        final statWidth = width < 460 ? width : (width - 12) / 2;
        final actionWidth = width < 460 ? width : (width - 12) / 2;

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4CA7AC), Color(0xFF3B8C91), Color(0xFF2F6F80)],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CA7AC).withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: EdgeInsets.all(isCompact ? 18 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: isCompact ? 30 : 34,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    child: Text(
                      user.displayName.characters.first.toUpperCase(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.groups_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  primaryCommunity,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: onNotifications,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                bio,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: statWidth,
                    child: _StatPill(
                      label: _localizedProfileText(context, 'trust_score'),
                      value: user.trustScore.toStringAsFixed(1),
                    ),
                  ),
                  SizedBox(
                    width: statWidth,
                    child: _StatPill(
                      label: _localizedProfileText(context, 'saved'),
                      value: '${user.savedPostIds.length}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: actionWidth,
                    child: AppButton(
                      label: context.l10n.editProfile,
                      onPressed: onEdit,
                      isSecondary: true,
                    ),
                  ),
                  SizedBox(
                    width: actionWidth,
                    child: AppButton(
                      label: context.l10n.savedPosts,
                      onPressed: onSaved,
                      icon: Icons.bookmark_outline_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AnalyticsMetric {
  const _AnalyticsMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class _AnalyticsGrid extends StatelessWidget {
  const _AnalyticsGrid({
    required this.title,
    required this.values,
  });

  final String title;
  final List<_AnalyticsMetric> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final itemWidth = width < 480 ? width : (width - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: values
                    .map(
                      (metric) => SizedBox(
                        width: itemWidth,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest.withValues(
                                  alpha: 0.35,
                                ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                metric.value,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(metric.label),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      avatar: CircleAvatar(backgroundColor: color, radius: 7),
      onSelected: (_) => onTap(),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onTap == null ? null : (_) => onTap!(),
    );
  }
}

String? _requiredValidator(BuildContext context, String? value, String label) {
  if (value != null && value.trim().isNotEmpty) {
    return null;
  }

  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      return 'Поле "$label" обязательно';
    case 'kk':
      return '"$label" өрісі міндетті';
    default:
      return FormValidators.required(value, label);
  }
}

String _localizedProfileText(BuildContext context, String key) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      switch (key) {
        case 'no_profile_loaded':
          return 'Профиль не загружен';
        case 'no_profile_loaded_subtitle':
          return 'Войдите, чтобы открыть свой персональный дашборд.';
        case 'community_board_subtitle':
          return 'Изучайте разделы кампуса, школы, офиса и торгового центра.';
        case 'map_view_subtitle':
          return 'Смотрите вещи по месту потери или находки.';
        case 'admin_panel_subtitle':
          return 'Модерируйте жалобы и сценарии безопасности сообщества.';
        case 'no_posts_yet':
          return 'Постов пока нет';
        case 'no_posts_yet_subtitle':
          return 'Создайте первое объявление о потере или находке, чтобы начать отслеживание.';
        case 'no_profile_available':
          return 'Профиль недоступен';
        case 'no_profile_available_subtitle':
          return 'Сначала войдите в аккаунт, чтобы редактировать профиль.';
        case 'bio':
          return 'О себе';
        case 'bio_hint':
          return 'Расскажите, какие вещи вы чаще всего помогаете возвращать.';
        case 'primary_community':
          return 'Основное сообщество';
        case 'save_profile':
          return 'Сохранить профиль';
        case 'profile_updated':
          return 'Профиль обновлён';
        case 'match_alerts_subtitle':
          return 'Сообщать мне, когда появляются похожие посты.';
        case 'message_alerts_subtitle':
          return 'Показывать уведомления, когда мне кто-то отвечает.';
        case 'location_hints_subtitle':
          return 'Использовать подсказки карты при создании поста.';
        case 'appearance_subtitle':
          return 'Выберите, как Lostly будет выглядеть на вашем устройстве.';
        case 'language_subtitle':
          return 'Переключайте язык приложения без перезапуска.';
        case 'about_lostly_subtitle':
          return 'Полированное startup-style приложение на Flutter для совместного возврата потерянных вещей.';
        case 'restricted_area':
          return 'Доступ ограничен';
        case 'restricted_area_subtitle':
          return 'Этот раздел доступен только модераторам и администраторам.';
        case 'moderation_overview':
          return 'Обзор модерации';
        case 'moderation_overview_subtitle':
          return 'Проверяйте жалобы, открывайте отмеченные посты и закрывайте очередь модерации в реальном времени.';
        case 'reports':
          return 'Жалобы';
        case 'no_active_reports':
          return 'Активных жалоб нет';
        case 'no_active_reports_subtitle':
          return 'Очередь модерации сейчас чистая.';
        case 'open_post':
          return 'Открыть пост';
        case 'resolve':
          return 'Решить';
        case 'report_resolved':
          return 'Жалоба обработана';
        case 'recent_posts':
          return 'Недавние посты';
        case 'default_bio':
          return 'Помогаю людям вернуть то, что для них действительно важно.';
        case 'all_communities':
          return 'Все сообщества';
        case 'trust_score':
          return 'Уровень доверия';
        case 'saved':
          return 'Сохранено';
      }
      break;
    case 'kk':
      switch (key) {
        case 'no_profile_loaded':
          return 'Профиль жүктелмеді';
        case 'no_profile_loaded_subtitle':
          return 'Жеке дашбордыңызды көру үшін аккаунтқа кіріңіз.';
        case 'community_board_subtitle':
          return 'Кампус, мектеп, офис және сауда орталығы бөлімдерін ашыңыз.';
        case 'map_view_subtitle':
          return 'Заттарды жоғалған не табылған жері бойынша қараңыз.';
        case 'admin_panel_subtitle':
          return 'Шағымдар мен қауымдастық қауіпсіздігі ағындарын басқарыңыз.';
        case 'no_posts_yet':
          return 'Әзірге пост жоқ';
        case 'no_posts_yet_subtitle':
          return 'Бақылауды бастау үшін алғашқы жоғалған не табылған зат постын жасаңыз.';
        case 'no_profile_available':
          return 'Профиль қолжетімсіз';
        case 'no_profile_available_subtitle':
          return 'Профильді өңдеу үшін алдымен жүйеге кіріңіз.';
        case 'bio':
          return 'Өзіңіз туралы';
        case 'bio_hint':
          return 'Қай заттарды қайтаруға жиі көмектесетініңізді жазыңыз.';
        case 'primary_community':
          return 'Негізгі қауымдастық';
        case 'save_profile':
          return 'Профильді сақтау';
        case 'profile_updated':
          return 'Профиль жаңартылды';
        case 'match_alerts_subtitle':
          return 'Ұқсас посттар шыққанда маған хабарлау.';
        case 'message_alerts_subtitle':
          return 'Біреу жауап берсе, хабарлама көрсету.';
        case 'location_hints_subtitle':
          return 'Пост жасау кезінде карта ұсыныстарын пайдалану.';
        case 'appearance_subtitle':
          return 'Lostly қолданбасының құрылғыңызда қалай көрінетінін таңдаңыз.';
        case 'language_subtitle':
          return 'Қолданба тілін қайта қоспай ауыстырыңыз.';
        case 'about_lostly_subtitle':
          return 'Жоғалған заттарды бірге қайтаруға арналған polished startup-style Flutter қолданбасы.';
        case 'restricted_area':
          return 'Кіру шектелген';
        case 'restricted_area_subtitle':
          return 'Бұл бөлім тек модераторлар мен админдерге ашық.';
        case 'moderation_overview':
          return 'Модерация шолуы';
        case 'moderation_overview_subtitle':
          return 'Шағымдарды тексеріп, белгіленген посттарды ашып, модерация кезегін нақты уақытта басқарыңыз.';
        case 'reports':
          return 'Шағымдар';
        case 'no_active_reports':
          return 'Белсенді шағым жоқ';
        case 'no_active_reports_subtitle':
          return 'Қазір модерация кезегі таза.';
        case 'open_post':
          return 'Постты ашу';
        case 'resolve':
          return 'Шешу';
        case 'report_resolved':
          return 'Шағым шешілді';
        case 'recent_posts':
          return 'Соңғы посттар';
        case 'default_bio':
          return 'Адамдарға өздері үшін маңызды заттарын қайта табуға көмектесемін.';
        case 'all_communities':
          return 'Барлық қауымдастық';
        case 'trust_score':
          return 'Сенім ұпайы';
        case 'saved':
          return 'Сақталған';
      }
      break;
  }

  switch (key) {
    case 'no_profile_loaded':
      return 'No profile loaded';
    case 'no_profile_loaded_subtitle':
      return 'Sign in to view your personal dashboard.';
    case 'community_board_subtitle':
      return 'Explore campus, school, office and mall sections.';
    case 'map_view_subtitle':
      return 'Browse items by last seen or found location.';
    case 'admin_panel_subtitle':
      return 'Moderate reports and community safety flows.';
    case 'no_posts_yet':
      return 'No posts yet';
    case 'no_posts_yet_subtitle':
      return 'Create your first lost or found report to start tracking.';
    case 'no_profile_available':
      return 'No profile available';
    case 'no_profile_available_subtitle':
      return 'Sign in first to edit your profile.';
    case 'bio':
      return 'Bio';
    case 'bio_hint':
      return 'Tell people what kind of items you usually help recover.';
    case 'primary_community':
      return 'Primary community';
    case 'save_profile':
      return 'Save profile';
    case 'profile_updated':
      return 'Profile updated';
    case 'match_alerts_subtitle':
      return 'Notify me when similar posts appear.';
    case 'message_alerts_subtitle':
      return 'Show alerts when someone replies to me.';
    case 'location_hints_subtitle':
      return 'Use map hints while creating a post.';
    case 'appearance_subtitle':
      return 'Choose how Lostly should look on your device.';
    case 'language_subtitle':
      return 'Switch the app language without restarting.';
    case 'about_lostly_subtitle':
      return 'A polished startup-style Flutter app for real lost-and-found collaboration.';
    case 'restricted_area':
      return 'Restricted area';
    case 'restricted_area_subtitle':
      return 'Only moderators and admins can access this section.';
    case 'moderation_overview':
      return 'Moderation overview';
    case 'moderation_overview_subtitle':
      return 'Review reports, open flagged posts and resolve moderation queues in real time.';
    case 'reports':
      return 'Reports';
    case 'no_active_reports':
      return 'No active reports';
    case 'no_active_reports_subtitle':
      return 'The moderation queue is currently clean.';
    case 'open_post':
      return 'Open post';
    case 'resolve':
      return 'Resolve';
    case 'report_resolved':
      return 'Report resolved';
    case 'recent_posts':
      return 'Recent posts';
    case 'default_bio':
      return 'Helping people reconnect with what matters most.';
    case 'all_communities':
      return 'All communities';
    case 'trust_score':
      return 'Trust score';
    case 'saved':
      return 'Saved';
    default:
      return '';
  }
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
