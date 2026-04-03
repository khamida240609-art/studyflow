import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/build_context_x.dart';
import '../../core/utils/form_validators.dart';
import '../../models/app_user.dart';
import '../../models/claim_request.dart';
import '../../models/community.dart';
import '../../models/item_post.dart';
import '../../models/lostly_notification.dart';
import '../../models/pickup_schedule.dart';
import '../../providers/app_providers.dart';
import '../../services/image_service.dart';
import '../../services/location_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/async_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_post_card.dart';
import '../../widgets/lostly_scaffold.dart';
import '../../widgets/status_chip.dart';

class CreateHubScreen extends StatelessWidget {
  const CreateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LostlyScaffold(
      title: context.l10n.create,
      child: ListView(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF102033),
                  Color(0xFF0F8B8D),
                  Color(0xFF6BD6B0),
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(32)),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _itemText(context, 'create_hub_title'),
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  _itemText(context, 'create_hub_subtitle'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _CreateChoiceTile(
            title: context.l10n.reportLostItem,
            subtitle: _itemText(context, 'create_hub_lost_subtitle'),
            icon: Icons.search_off_rounded,
            onTap: () => context.push('/create/lost'),
          ),
          const SizedBox(height: 12),
          _CreateChoiceTile(
            title: context.l10n.reportFoundItem,
            subtitle: _itemText(context, 'create_hub_found_subtitle'),
            icon: Icons.favorite_outline_rounded,
            onTap: () => context.push('/create/found'),
          ),
          const SizedBox(height: 12),
          _CreateChoiceTile(
            title: context.l10n.openQrScanner,
            subtitle: _itemText(context, 'create_hub_scanner_subtitle'),
            icon: Icons.qr_code_scanner_rounded,
            onTap: () => context.push('/scanner'),
          ),
        ],
      ),
    );
  }
}

class CreateLostItemScreen extends StatelessWidget {
  const CreateLostItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PostComposerScreen(
      type: PostType.lost,
      screenTitle: _itemText(context, 'create_lost_post'),
    );
  }
}

class CreateFoundItemScreen extends StatelessWidget {
  const CreateFoundItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _PostComposerScreen(
      type: PostType.found,
      screenTitle: _itemText(context, 'create_found_post'),
    );
  }
}

class EditPostScreen extends StatelessWidget {
  const EditPostScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return _PostComposerScreen(
      postId: postId,
      screenTitle: _itemText(context, 'edit_post'),
    );
  }
}

class ItemDetailsScreen extends ConsumerWidget {
  const ItemDetailsScreen({super.key, required this.postId});

  final String postId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ItemPost item,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Удалить пост?'),
          content: const Text(
            'Пост будет удалён из Firestore и сразу исчезнет из общих списков у всех пользователей.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(postActionControllerProvider.notifier).deletePost(item);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Пост удалён')));
      context.go('/home');
    } catch (error) {
      if (context.mounted) {
        context.showErrorSnackBar('$error');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(postProvider(postId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return post.when(
      data: (item) {
        if (item == null) {
          return LostlyScaffold(
            title: 'Детали предмета',
            child: EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Предмет не найден',
              subtitle:
                  'Пост мог быть удалён или QR оказался недействительным.',
            ),
          );
        }

        final isOwner = currentUser?.id == item.userId;
        final isAdmin = currentUser?.isAdmin ?? false;
        final isSaved = currentUser?.savedPostIds.contains(item.id) ?? false;
        final claims = ref.watch(claimsForPostProvider(item.id));
        final matchViews = ref.watch(postMatchViewsProvider(item.id));
        final community = ref.watch(communityByIdProvider(item.communityId));

        return LostlyScaffold(
          title: 'Детали предмета',
          actions: [
            if (isOwner)
              IconButton(
                onPressed: () => _confirmDelete(context, ref, item),
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Удалить пост',
              ),
            IconButton(
              onPressed: () async {
                try {
                  await ref
                      .read(postActionControllerProvider.notifier)
                      .toggleSave(item.id, isSaved);
                  if (context.mounted) {
                    context.showAppSnackBar(
                      isSaved
                          ? 'Удалено из сохранённых'
                          : 'Добавлено в сохранённые',
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    context.showErrorSnackBar('$error');
                  }
                }
              },
              icon: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
            ),
          ],
          child: ListView(
            children: [
              _ItemGallery(item: item),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  StatusChip(status: item.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoPill(
                    icon: Icons.sell_outlined,
                    label: AppConstants.displayCategory(item.category),
                  ),
                  _InfoPill(
                    icon: Icons.place_outlined,
                    label: item.locationName,
                  ),
                  _InfoPill(
                    icon: Icons.groups_outlined,
                    label: AppConstants.displayCommunity(item.communityId),
                  ),
                  _InfoPill(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat(
                      'd MMM, HH:mm',
                      'ru',
                    ).format(item.createdAt),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _OwnerCard(item: item, isOwner: isOwner, isAdmin: isAdmin),
              const SizedBox(height: 14),
              _IdentityCard(
                item: item,
                canOpenQr: isOwner,
                onOpenQr: isOwner
                    ? () => context.push('/item/${item.id}/qr')
                    : null,
              ),
              if (community != null) ...[
                const SizedBox(height: 14),
                _SecurityContactCard(community: community),
              ],
              const SizedBox(height: 18),
              if (isOwner)
                _OwnerActions(
                  item: item,
                  onEdit: () => context.push('/item/${item.id}/edit'),
                  onQr: () => context.push('/item/${item.id}/qr'),
                  onStatusChanged: (status) async {
                    await ref
                        .read(postActionControllerProvider.notifier)
                        .updateStatus(postId: item.id, status: status);
                    if (context.mounted) {
                      context.showAppSnackBar(
                        'Статус обновлён: ${status.label}',
                      );
                    }
                  },
                )
              else
                _GuestActions(
                  item: item,
                  onMessage: () async {
                    try {
                      final chatId = await ref
                          .read(chatActionControllerProvider.notifier)
                          .openChat(
                            postId: item.id,
                            otherUserId: item.userId,
                            otherUserName: item.authorName,
                          );
                      if (context.mounted) {
                        context.push(
                          '/chat/$chatId?otherUserId=${item.userId}&otherUserName=${Uri.encodeComponent(item.authorName)}',
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        context.showErrorSnackBar('$error');
                      }
                    }
                  },
                  onClaim: item.type == PostType.found
                      ? () => context.push(
                          '/claim/${item.id}?ownerId=${item.userId}',
                        )
                      : null,
                  onReport: () => context.push('/report/${item.id}'),
                ),
              const SizedBox(height: 22),
              if (isOwner) ...[
                Text(
                  'Заявки на подтверждение',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                claims.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const EmptyState(
                        icon: Icons.fact_check_outlined,
                        title: 'Заявок пока нет',
                        subtitle:
                            'Здесь будут появляться запросы на подтверждение от других пользователей.',
                      );
                    }

                    return Column(
                      children: items
                          .map(
                            (claim) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ClaimCard(
                                claim: claim,
                                postId: item.id,
                                onApprove: () async {
                                  await ref
                                      .read(
                                        claimActionControllerProvider.notifier,
                                      )
                                      .updateClaimStatus(
                                        claim: claim,
                                        status: ClaimStatus.approved,
                                      );
                                  await ref
                                      .read(
                                        postActionControllerProvider.notifier,
                                      )
                                      .updateStatus(
                                        postId: item.id,
                                        status: PostStatus.matched,
                                        notifyUserId: claim.claimantId,
                                      );
                                  if (context.mounted) {
                                    context.showAppSnackBar('Заявка одобрена');
                                  }
                                },
                                onReject: () async {
                                  await ref
                                      .read(
                                        claimActionControllerProvider.notifier,
                                      )
                                      .updateClaimStatus(
                                        claim: claim,
                                        status: ClaimStatus.rejected,
                                      );
                                  if (context.mounted) {
                                    context.showAppSnackBar('Заявка отклонена');
                                  }
                                },
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text('$error'),
                ),
                const SizedBox(height: 22),
              ],
              Text(
                'Похожие совпадения',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              matchViews.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Пока нет совпадений',
                      subtitle:
                          'Lostly покажет здесь похожие объявления противоположного типа.',
                    );
                  }
                  return Column(
                    children: items
                        .map(
                          (match) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MatchSuggestionCard(
                              match: match,
                              onTap: () =>
                                  context.push('/item/${match.post.id}'),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('$error'),
              ),
            ],
          ),
        );
      },
      loading: () => const LostlyScaffold(
        title: 'Детали предмета',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => LostlyScaffold(
        title: 'Детали предмета',
        child: Center(child: Text('$error')),
      ),
    );
  }
}

class CameraCaptureScreen extends ConsumerStatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  ConsumerState<CameraCaptureScreen> createState() =>
      _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends ConsumerState<CameraCaptureScreen> {
  CameraController? _controller;
  XFile? _capturedFile;
  bool _isReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await ref
          .read(cameraServiceProvider)
          .loadAvailableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'На этом устройстве камера недоступна.');
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (mounted) {
        setState(() {
          _controller = controller;
          _isReady = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    try {
      final file = await _controller?.takePicture();
      if (mounted) {
        setState(() => _capturedFile = file);
      }
    } catch (error) {
      if (mounted) {
        context.showErrorSnackBar('$error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return LostlyScaffold(
        title: _itemText(context, 'camera'),
        child: EmptyState(
          icon: Icons.camera_alt_outlined,
          title: _itemText(context, 'camera_unavailable'),
          subtitle: _error!,
        ),
      );
    }

    if (!_isReady || _controller == null) {
      return LostlyScaffold(
        title: _itemText(context, 'camera'),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_capturedFile != null) {
      return LostlyScaffold(
        title: _itemText(context, 'preview'),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.file(
                  File(_capturedFile!.path),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: _itemText(context, 'retake'),
                    onPressed: () => setState(() => _capturedFile = null),
                    isSecondary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: _itemText(context, 'use_photo'),
                    onPressed: () => context.pop(_capturedFile!.path),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: CameraPreview(_controller!)),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton.filledTonal(
                onPressed: () => context.pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.44),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _handled = false;

  Future<void> _handleDetection(String code) async {
    if (_handled) {
      return;
    }
    setState(() => _handled = true);
    final post = await ref.read(postsRepositoryProvider).findByQrValue(code);
    if (!mounted) {
      return;
    }

    if (post == null) {
      context.showErrorSnackBar(_itemText(context, 'qr_invalid'));
      await Future<void>.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _handled = false);
      }
      return;
    }

    context.pushReplacement('/item/${post.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              onDetect: (capture) {
                final rawValue = capture.barcodes.first.rawValue;
                if (rawValue != null) {
                  _handleDetection(rawValue);
                }
              },
            ),
          ),
          Positioned(
            top: 54,
            left: 18,
            right: 18,
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => context.pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.45),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      _itemText(context, 'scanner_hint'),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QrGeneratorScreen extends ConsumerWidget {
  const QrGeneratorScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(postProvider(postId));
    return LostlyScaffold(
      title: _itemText(context, 'item_qr'),
      child: AsyncValueWidget(
        value: post,
        data: (item) {
          if (item == null) {
            return EmptyState(
              icon: Icons.error_outline_rounded,
              title: _itemText(context, 'item_not_found'),
              subtitle: _itemText(context, 'item_qr_missing_subtitle'),
            );
          }

          return ListView(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    QrImageView(
                      data: item.qrCodeValue,
                      size: 260,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(color: Colors.black),
                      dataModuleStyle: const QrDataModuleStyle(
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Item ID: ${item.itemCode}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _itemText(context, 'item_qr_subtitle'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ClaimRequestScreen extends ConsumerStatefulWidget {
  const ClaimRequestScreen({
    super.key,
    required this.postId,
    required this.ownerId,
  });

  final String postId;
  final String ownerId;

  @override
  ConsumerState<ClaimRequestScreen> createState() => _ClaimRequestScreenState();
}

class _ClaimRequestScreenState extends ConsumerState<ClaimRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _evidenceController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LostlyScaffold(
      title: _itemText(context, 'this_is_mine'),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            AppTextField(
              controller: _messageController,
              label: _itemText(context, 'claim_message'),
              hint: _itemText(context, 'claim_message_hint'),
              maxLines: 5,
              validator: (value) => _requiredField(
                context,
                value,
                _itemText(context, 'claim_message'),
              ),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _evidenceController,
              label: _itemText(context, 'proof_details'),
              hint: _itemText(context, 'proof_details_hint'),
              maxLines: 4,
              validator: (value) => _requiredField(
                context,
                value,
                _itemText(context, 'proof_details'),
              ),
            ),
            const SizedBox(height: 22),
            AppButton(
              label: _itemText(context, 'continue_to_verification'),
              onPressed: () {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                context.push(
                  '/verification/${widget.postId}?ownerId=${widget.ownerId}',
                  extra: <String, String>{
                    'message': _messageController.text,
                    'evidence': _evidenceController.text,
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OwnershipVerificationScreen extends ConsumerStatefulWidget {
  const OwnershipVerificationScreen({
    super.key,
    required this.postId,
    required this.ownerId,
    required this.claimMessage,
    required this.evidence,
  });

  final String postId;
  final String ownerId;
  final String claimMessage;
  final String evidence;

  @override
  ConsumerState<OwnershipVerificationScreen> createState() =>
      _OwnershipVerificationScreenState();
}

class _OwnershipVerificationScreenState
    extends ConsumerState<OwnershipVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers = AppConstants
      .verificationQuestions
      .map((_) => TextEditingController())
      .toList();

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final answers = <String, String>{};
    for (
      var index = 0;
      index < AppConstants.verificationQuestions.length;
      index++
    ) {
      answers[AppConstants.verificationQuestions[index]] = _controllers[index]
          .text
          .trim();
    }

    try {
      await ref
          .read(claimActionControllerProvider.notifier)
          .submitClaim(
            postId: widget.postId,
            ownerId: widget.ownerId,
            message: widget.claimMessage,
            evidence: widget.evidence,
            answers: answers,
          );
      if (context.mounted) {
        context.pushReplacement('/item/${widget.postId}');
        context.showAppSnackBar(_itemText(context, 'claim_request_sent'));
      }
    } catch (error) {
      if (context.mounted) {
        context.showErrorSnackBar('$error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(claimActionControllerProvider);
    return LostlyScaffold(
      title: _itemText(context, 'ownership_verification'),
      child: Form(
        key: _formKey,
        child: ListView.separated(
          itemCount: AppConstants.verificationQuestions.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            if (index == AppConstants.verificationQuestions.length) {
              return AppButton(
                label: _itemText(context, 'submit_claim'),
                onPressed: _submit,
                isLoading: state.isLoading,
              );
            }
            return AppTextField(
              controller: _controllers[index],
              label: '${_itemText(context, 'question')} ${index + 1}',
              hint: AppConstants.verificationQuestions[index],
              maxLines: 4,
              validator: (value) =>
                  _requiredField(context, value, _itemText(context, 'answer')),
            );
          },
        ),
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return LostlyScaffold(
      title: context.l10n.notifications,
      child: AsyncValueWidget(
        value: notifications,
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_off_outlined,
              title: _itemText(context, 'all_quiet'),
              subtitle: _itemText(context, 'notifications_empty_subtitle'),
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = items[index];
              return _NotificationCard(
                notification: notification,
                onTap: () async {
                  await ref
                      .read(notificationsRepositoryProvider)
                      .markAsRead(notification.id);
                  if (notification.data.containsKey('chatId')) {
                    final chatId = notification.data['chatId'];
                    if (chatId != null && chatId.isNotEmpty) {
                      final query = <String, String>{
                        if ((notification.data['otherUserId'] ?? '').isNotEmpty)
                          'otherUserId': notification.data['otherUserId']!,
                        if ((notification.data['otherUserName'] ?? '')
                            .isNotEmpty)
                          'otherUserName': notification.data['otherUserName']!,
                      };
                      context.push(
                        Uri(
                          path: '/chat/$chatId',
                          queryParameters: query,
                        ).toString(),
                      );
                      return;
                    }
                  }
                  if (notification.data.containsKey('scheduleId')) {
                    context.showAppSnackBar(
                      'Напоминание о встрече сохранено в карточке предмета.',
                    );
                  }
                  if (notification.referenceId != null) {
                    context.push('/item/${notification.referenceId!}');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class PickupScheduleScreen extends ConsumerStatefulWidget {
  const PickupScheduleScreen({
    super.key,
    required this.claimId,
    required this.postId,
    required this.ownerId,
    required this.claimantId,
  });

  final String claimId;
  final String postId;
  final String ownerId;
  final String claimantId;

  @override
  ConsumerState<PickupScheduleScreen> createState() =>
      _PickupScheduleScreenState();
}

class _PickupScheduleScreenState extends ConsumerState<PickupScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _scheduledAt;
  PickupScheduleStatus _status = PickupScheduleStatus.proposed;
  bool _initialized = false;

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      locale: const Locale('ru'),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledAt ?? now.add(const Duration(hours: 2)),
      ),
    );
    if (time == null || !mounted) {
      return;
    }

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _dateController.text = DateFormat(
        'd MMM yyyy, HH:mm',
        'ru',
      ).format(_scheduledAt!);
    });
  }

  Future<void> _submit(PickupSchedule? existing) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_scheduledAt == null) {
      context.showErrorSnackBar('Выберите дату и время передачи.');
      return;
    }

    final now = DateTime.now();
    final schedule = PickupSchedule(
      id: existing?.id ?? '',
      claimId: widget.claimId,
      postId: widget.postId,
      ownerId: widget.ownerId,
      claimantId: widget.claimantId,
      locationName: _locationController.text.trim(),
      scheduledAt: _scheduledAt!,
      status: _status,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      await ref
          .read(pickupScheduleActionControllerProvider.notifier)
          .createOrUpdateSchedule(schedule: schedule);
      if (mounted) {
        context.pop();
        context.showAppSnackBar('Расписание передачи сохранено.');
      }
    } catch (error) {
      if (mounted) {
        context.showErrorSnackBar('$error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(pickupScheduleForClaimProvider(widget.claimId));
    final state = ref.watch(pickupScheduleActionControllerProvider);

    return LostlyScaffold(
      title: 'Передача вещи',
      child: schedule.when(
        data: (existing) {
          if (!_initialized) {
            _initialized = true;
            _locationController.text = existing?.locationName ?? '';
            _notesController.text = existing?.notes ?? '';
            _scheduledAt = existing?.scheduledAt;
            _dateController.text = existing == null
                ? ''
                : DateFormat(
                    'd MMM yyyy, HH:mm',
                    'ru',
                  ).format(existing.scheduledAt);
            _status = existing?.status ?? PickupScheduleStatus.proposed;
          }

          return Form(
            key: _formKey,
            child: ListView(
              children: [
                AppTextField(
                  controller: _locationController,
                  label: 'Место передачи',
                  hint: 'Например, ресепшен кампуса или центральный вход',
                  validator: (value) =>
                      _requiredField(context, value, 'Место передачи'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _dateController,
                  label: 'Дата и время',
                  hint: 'Выберите дату и время',
                  readOnly: true,
                  onTap: _pickDateTime,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<PickupScheduleStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Статус встречи',
                  ),
                  items: PickupScheduleStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _notesController,
                  label: 'Комментарий',
                  hint: 'Добавьте ориентир, условия передачи или удобный слот.',
                  maxLines: 4,
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: existing == null
                      ? 'Создать расписание'
                      : 'Обновить расписание',
                  onPressed: () => _submit(existing),
                  isLoading: state.isLoading,
                  icon: Icons.event_available_outlined,
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

class ReportFakePostScreen extends ConsumerStatefulWidget {
  const ReportFakePostScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<ReportFakePostScreen> createState() =>
      _ReportFakePostScreenState();
}

class _ReportFakePostScreenState extends ConsumerState<ReportFakePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportActionControllerProvider);

    return LostlyScaffold(
      title: _itemText(context, 'report_post'),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            AppTextField(
              controller: _reasonController,
              label: _itemText(context, 'reason'),
              hint: _itemText(context, 'reason_hint'),
              validator: (value) =>
                  _requiredField(context, value, _itemText(context, 'reason')),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _detailsController,
              label: _itemText(context, 'details'),
              hint: _itemText(context, 'details_hint'),
              maxLines: 5,
              validator: (value) =>
                  _requiredField(context, value, _itemText(context, 'details')),
            ),
            const SizedBox(height: 22),
            AppButton(
              label: _itemText(context, 'submit_report'),
              onPressed: () async {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                try {
                  await ref
                      .read(reportActionControllerProvider.notifier)
                      .createReport(
                        postId: widget.postId,
                        reason: _reasonController.text,
                        details: _detailsController.text,
                      );
                  if (context.mounted) {
                    context.pop();
                    context.showAppSnackBar(
                      _itemText(context, 'report_sent_to_moderators'),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    context.showErrorSnackBar('$error');
                  }
                }
              },
              isLoading: state.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _PostComposerScreen extends ConsumerStatefulWidget {
  const _PostComposerScreen({
    this.postId,
    this.type,
    required this.screenTitle,
  });

  final String? postId;
  final PostType? type;
  final String screenTitle;

  @override
  ConsumerState<_PostComposerScreen> createState() =>
      _PostComposerScreenState();
}

class _PostComposerScreenState extends ConsumerState<_PostComposerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _rewardController = TextEditingController();
  String _category = AppConstants.itemCategories.first;
  String? _communityId = 'campus';
  String? _documentType;
  final List<String> _imagePaths = <String>[];
  double _latitude = 0;
  double _longitude = 0;
  bool _isAnonymous = false;
  bool _rewardEnabled = false;
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  Future<void> _pickGalleryImages(ImageService imageService) async {
    final images = await imageService.pickMultipleFromGallery();
    if (images.isEmpty) {
      return;
    }
    setState(() => _imagePaths.addAll(images.map((file) => file.path)));
  }

  Future<void> _openCamera() async {
    final imagePath = await context.push<String>('/camera');
    if (imagePath != null && mounted) {
      setState(() => _imagePaths.add(imagePath));
    }
  }

  Future<void> _useCurrentLocation(LocationService locationService) async {
    try {
      final result = await locationService.determinePosition();
      setState(() {
        _latitude =
            result.position?.latitude ?? LocationService.fallbackLatitude;
        _longitude =
            result.position?.longitude ?? LocationService.fallbackLongitude;
        if (_locationController.text.trim().isEmpty) {
          _locationController.text = result.hasPosition
              ? _itemText(context, 'current_location_pin')
              : LocationService.fallbackLocationLabel;
        }
      });
      if (mounted) {
        context.showAppSnackBar(
          result.message ?? _itemText(context, 'location_updated'),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _latitude = LocationService.fallbackLatitude;
          _longitude = LocationService.fallbackLongitude;
          if (_locationController.text.trim().isEmpty) {
            _locationController.text = LocationService.fallbackLocationLabel;
          }
        });
        context.showErrorSnackBar(
          'Локация недоступна. Использован центр Казахстана.',
        );
      }
    }
  }

  Future<void> _submit(ItemPost? existing, AppUser? user) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (user == null) {
      context.showErrorSnackBar(_itemText(context, 'please_log_in_first'));
      return;
    }
    if (_rewardEnabled &&
        (double.tryParse(_rewardController.text.trim()) ?? 0) <= 0) {
      context.showErrorSnackBar('Укажите корректную сумму вознаграждения.');
      return;
    }

    try {
      final rewardAmount = _rewardEnabled
          ? double.tryParse(_rewardController.text.trim()) ?? 0
          : 0.0;
      if (existing == null) {
        final result = await ref
            .read(postActionControllerProvider.notifier)
            .createPost(
              type: widget.type!,
              title: _titleController.text,
              description: _descriptionController.text,
              category: _category,
              locationName: _locationController.text,
              latitude: _latitude,
              longitude: _longitude,
              communityId: _communityId ?? 'campus',
              imagePaths: _imagePaths,
              rewardAmount: rewardAmount,
              isAnonymous: _isAnonymous,
              documentType: _category == 'Документы' ? _documentType : null,
            );
        if (mounted) {
          context.pushReplacement('/item/${result.postId}');
          context.showAppSnackBar(
            result.hasUploadIssues
                ? 'Пост опубликован, но ${result.failedUploadCount} фото не загрузилось в Firebase Storage. Сейчас сохранён только текст и успешно загруженные изображения.'
                : _itemText(context, 'post_published'),
          );
        }
      } else {
        final result = await ref
            .read(postActionControllerProvider.notifier)
            .updatePost(
              existing: existing,
              title: _titleController.text,
              description: _descriptionController.text,
              category: _category,
              locationName: _locationController.text,
              latitude: _latitude,
              longitude: _longitude,
              communityId: _communityId ?? existing.communityId,
              imagePaths: _imagePaths,
              rewardAmount: rewardAmount,
              isAnonymous: _isAnonymous,
              documentType: _category == 'Документы' ? _documentType : null,
            );
        if (mounted) {
          context.pushReplacement('/item/${existing.id}');
          context.showAppSnackBar(
            result.hasUploadIssues
                ? 'Пост обновлён, но ${result.failedUploadCount} фото не загрузилось в Firebase Storage. Пост сохранён без этих изображений.'
                : _itemText(context, 'post_updated'),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        context.showErrorSnackBar('$error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageService = ref.watch(imageServiceProvider);
    final locationService = ref.watch(locationServiceProvider);
    final communities = ref.watch(communitiesProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final actionState = ref.watch(postActionControllerProvider);
    final existingPostAsync = widget.postId == null
        ? const AsyncValue<ItemPost?>.data(null)
        : ref.watch(postProvider(widget.postId!));

    return LostlyScaffold(
      title: widget.screenTitle,
      child: existingPostAsync.when(
        data: (existing) {
          final canEditExisting =
              existing == null ||
              currentUser == null ||
              currentUser.id == existing.userId ||
              currentUser.isAdmin;

          if (!canEditExisting) {
            return const EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Нет доступа',
              subtitle: 'Редактировать можно только собственные посты.',
            );
          }

          if (!_initialized && existing != null) {
            _initialized = true;
            _titleController.text = existing.title;
            _descriptionController.text = existing.description;
            _locationController.text = existing.locationName;
            _rewardController.text = existing.rewardAmount > 0
                ? existing.rewardAmount.toStringAsFixed(0)
                : '';
            _category = existing.category;
            _communityId = existing.communityId;
            _documentType = existing.documentType;
            _latitude = existing.latitude;
            _longitude = existing.longitude;
            _isAnonymous = existing.isAnonymous;
            _rewardEnabled = existing.rewardAmount > 0;
            _imagePaths
              ..clear()
              ..addAll(existing.imageUrls);
          } else if (!_initialized && existing == null) {
            _initialized = true;
            _communityId = currentUser?.communityIds.firstOrNull ?? 'campus';
          }

          final composerType = existing?.type ?? widget.type!;

          return Form(
            key: _formKey,
            child: ListView(
              children: [
                _ComposerHero(type: composerType),
                const SizedBox(height: 18),
                AppTextField(
                  controller: _titleController,
                  label: _itemText(context, 'title'),
                  hint: composerType == PostType.lost
                      ? _itemText(context, 'lost_title_hint')
                      : _itemText(context, 'found_title_hint'),
                  validator: (value) => _requiredField(
                    context,
                    value,
                    _itemText(context, 'title'),
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _descriptionController,
                  label: _itemText(context, 'description'),
                  hint: _itemText(context, 'description_hint'),
                  maxLines: 5,
                  validator: (value) => _requiredField(
                    context,
                    value,
                    _itemText(context, 'description'),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: _itemText(context, 'category'),
                  ),
                  items: AppConstants.itemCategories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _category = value!;
                    if (_category != 'Документы') {
                      _documentType = null;
                    }
                  }),
                ),
                if (_category == 'Документы') ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _documentType,
                    decoration: const InputDecoration(
                      labelText: 'Тип документа',
                    ),
                    items: AppConstants.documentTypes
                        .map(
                          (documentType) => DropdownMenuItem(
                            value: documentType,
                            child: Text(documentType),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _documentType = value),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.priority_high_rounded),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Документы получают приоритет в matching и уведомлениях.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                communities.when(
                  data: (items) => DropdownButtonFormField<String>(
                    initialValue: _communityId,
                    decoration: InputDecoration(
                      labelText: _itemText(context, 'community'),
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
                    onChanged: (value) => setState(() => _communityId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _locationController,
                  label: _itemText(context, 'location_name'),
                  hint: _itemText(context, 'location_name_hint'),
                  validator: (value) => _requiredField(
                    context,
                    value,
                    _itemText(context, 'location_name'),
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  value: _isAnonymous,
                  onChanged: (value) => setState(() => _isAnonymous = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Анонимная публикация'),
                  subtitle: const Text(
                    'Имя автора будет скрыто в публичной карточке, но останется доступно системе и администратору.',
                  ),
                ),
                if (composerType == PostType.lost) ...[
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    value: _rewardEnabled,
                    onChanged: (value) => setState(() {
                      _rewardEnabled = value;
                      if (!value) {
                        _rewardController.clear();
                      }
                    }),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Указать вознаграждение'),
                    subtitle: const Text(
                      'Добавьте сумму, если хотите мотивировать быстрый возврат вещи.',
                    ),
                  ),
                  if (_rewardEnabled) ...[
                    const SizedBox(height: 10),
                    AppTextField(
                      controller: _rewardController,
                      label: 'Сумма вознаграждения',
                      hint: 'Например, 5000',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: _itemText(context, 'use_current_location'),
                        onPressed: () => _useCurrentLocation(locationService),
                        icon: Icons.my_location_rounded,
                        isSecondary: true,
                      ),
                    ),
                  ],
                ),
                if (_latitude != 0 || _longitude != 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${_itemText(context, 'pinned_at')} ${_latitude.toStringAsFixed(5)}, ${_longitude.toStringAsFixed(5)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  _itemText(context, 'photos'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: _itemText(context, 'gallery'),
                        onPressed: () => _pickGalleryImages(imageService),
                        icon: Icons.photo_library_outlined,
                        isSecondary: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: _itemText(context, 'camera'),
                        onPressed: _openCamera,
                        icon: Icons.camera_alt_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_imagePaths.isEmpty)
                  EmptyState(
                    icon: Icons.photo_camera_back_outlined,
                    title: _itemText(context, 'no_photos_added'),
                    subtitle: _itemText(context, 'no_photos_added_subtitle'),
                  )
                else
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagePaths.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final path = _imagePaths[index];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: SizedBox(
                                width: 110,
                                height: 110,
                                child: path.startsWith('http')
                                    ? Image.network(path, fit: BoxFit.cover)
                                    : Image.file(File(path), fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _imagePaths.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 22),
                AppButton(
                  label: existing == null
                      ? _itemText(context, 'publish_post')
                      : _itemText(context, 'save_changes'),
                  onPressed: () => _submit(existing, currentUser),
                  isLoading: actionState.isLoading,
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

class _ComposerHero extends StatelessWidget {
  const _ComposerHero({required this.type});

  final PostType type;

  @override
  Widget build(BuildContext context) {
    final gradient = type == PostType.lost
        ? const LinearGradient(colors: [Color(0xFFFFD5D1), Color(0xFFFF7A6B)])
        : const LinearGradient(colors: [Color(0xFFD0FFF1), Color(0xFF6BD6B0)]);

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            type == PostType.lost
                ? Icons.search_off_rounded
                : Icons.favorite_outline_rounded,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            type == PostType.lost
                ? _itemText(context, 'lost_report')
                : _itemText(context, 'found_report'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            type == PostType.lost
                ? _itemText(context, 'lost_report_subtitle')
                : _itemText(context, 'found_report_subtitle'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _CreateChoiceTile extends StatelessWidget {
  const _CreateChoiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 24, child: Icon(icon)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(subtitle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _ItemGallery extends StatefulWidget {
  const _ItemGallery({required this.item});

  final ItemPost item;

  @override
  State<_ItemGallery> createState() => _ItemGalleryState();
}

class _ItemGalleryState extends State<_ItemGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: AspectRatio(
            aspectRatio: 1.05,
            child: widget.item.imageUrls.isEmpty
                ? Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: Icon(Icons.image_outlined, size: 48),
                    ),
                  )
                : PageView.builder(
                    itemCount: widget.item.imageUrls.length,
                    onPageChanged: (value) => setState(() => _page = value),
                    itemBuilder: (context, index) {
                      return Image.network(
                        widget.item.imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        if (widget.item.imageUrls.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.item.imageUrls.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: _page == index ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _page == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({
    required this.item,
    required this.isOwner,
    required this.isAdmin,
  });

  final ItemPost item;
  final bool isOwner;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final displayName = item.isAnonymous && !isOwner && !isAdmin
        ? 'Анонимный автор'
        : item.authorName;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            child: Text(displayName.characters.first.toUpperCase()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_itemText(context, 'trust_score')} ${item.trustScore.toStringAsFixed(1)}',
                ),
              ],
            ),
          ),
          if (item.isVerified)
            const Icon(Icons.verified_rounded, color: Colors.green),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.item,
    required this.canOpenQr,
    required this.onOpenQr,
  });

  final ItemPost item;
  final bool canOpenQr;
  final VoidCallback? onOpenQr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Item ID', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(item.itemCode, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (item.isPriorityDocument)
                const _InfoPill(
                  icon: Icons.priority_high_rounded,
                  label: 'Приоритетный документ',
                ),
              if (item.rewardAmount > 0)
                _InfoPill(
                  icon: Icons.payments_outlined,
                  label:
                      'Вознаграждение ${item.rewardAmount.toStringAsFixed(0)} ${AppConstants.defaultCurrency}',
                ),
              if (item.documentType?.isNotEmpty == true)
                _InfoPill(
                  icon: Icons.badge_outlined,
                  label: AppConstants.displayDocumentType(item.documentType!),
                ),
              if (item.dominantColor?.isNotEmpty == true)
                _InfoPill(
                  icon: Icons.palette_outlined,
                  label: item.dominantColor!,
                ),
            ],
          ),
          if (canOpenQr && onOpenQr != null) ...[
            const SizedBox(height: 14),
            AppButton(
              label: 'Открыть QR и item card',
              onPressed: onOpenQr,
              icon: Icons.qr_code_rounded,
              isSecondary: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _SecurityContactCard extends StatelessWidget {
  const _SecurityContactCard({required this.community});

  final Community community;

  Future<void> _launchExternal(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if ((community.securityEmail?.isEmpty ?? true) &&
        (community.securityPhone?.isEmpty ?? true) &&
        (community.emergencyNote?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Помощь и безопасность',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            community.emergencyNote ??
                'Если предмет важный или чувствительный, можно быстро связаться со службой безопасности сообщества.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (community.securityPhone?.isNotEmpty == true)
                AppButton(
                  label: 'Позвонить',
                  onPressed: () =>
                      _launchExternal('tel:${community.securityPhone!}'),
                  icon: Icons.call_outlined,
                  isSecondary: true,
                ),
              if (community.securityEmail?.isNotEmpty == true)
                AppButton(
                  label: 'Написать security',
                  onPressed: () => _launchExternal(
                    'mailto:${community.securityEmail!}?subject=Lostly%20security%20help',
                  ),
                  icon: Icons.mail_outline_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerActions extends StatelessWidget {
  const _OwnerActions({
    required this.item,
    required this.onEdit,
    required this.onQr,
    required this.onStatusChanged,
  });

  final ItemPost item;
  final VoidCallback onEdit;
  final VoidCallback onQr;
  final ValueChanged<PostStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: _itemText(context, 'edit_post'),
                onPressed: onEdit,
                icon: Icons.edit_outlined,
                isSecondary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: _itemText(context, 'qr_code'),
                onPressed: onQr,
                icon: Icons.qr_code_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<PostStatus>(
          initialValue: item.status,
          decoration: InputDecoration(
            labelText: _itemText(context, 'post_status'),
          ),
          items: PostStatus.values
              .map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onStatusChanged(value);
            }
          },
        ),
      ],
    );
  }
}

class _GuestActions extends StatelessWidget {
  const _GuestActions({
    required this.item,
    required this.onMessage,
    required this.onClaim,
    required this.onReport,
  });

  final ItemPost item;
  final VoidCallback onMessage;
  final VoidCallback? onClaim;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: _itemText(context, 'message_owner'),
                onPressed: onMessage,
                icon: Icons.chat_bubble_outline_rounded,
              ),
            ),
            if (onClaim != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: _itemText(context, 'this_is_mine'),
                  onPressed: onClaim,
                  icon: Icons.verified_user_outlined,
                  isSecondary: true,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onReport,
            icon: const Icon(Icons.flag_outlined),
            label: Text(_itemText(context, 'report_fake_post')),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
      ),
    );
  }
}

class _ClaimCard extends ConsumerWidget {
  const _ClaimCard({
    required this.claim,
    required this.postId,
    required this.onApprove,
    required this.onReject,
  });

  final ClaimRequest claim;
  final String postId;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(pickupScheduleForClaimProvider(claim.id));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  claim.claimantName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(claim.status.label),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(claim.message),
          const SizedBox(height: 8),
          Text(
            '${_itemText(context, 'proof')}: ${claim.evidence}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Verification checklist',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...claim.verificationChecklist.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    entry.value
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: entry.value ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.key)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...claim.answers.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${entry.key}\n${entry.value}'),
            ),
          ),
          if (claim.status == ClaimStatus.pending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: _itemText(context, 'reject'),
                    onPressed: onReject,
                    isSecondary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: _itemText(context, 'approve'),
                    onPressed: onApprove,
                  ),
                ),
              ],
            ),
          ],
          if (claim.status == ClaimStatus.approved) ...[
            const SizedBox(height: 12),
            schedule.when(
              data: (value) {
                if (value == null) {
                  return AppButton(
                    label: 'Назначить передачу',
                    onPressed: () => context.push(
                      '/pickup/${claim.id}?postId=$postId&ownerId=${claim.ownerId}&claimantId=${claim.claimantId}',
                    ),
                    icon: Icons.event_available_outlined,
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Передача назначена',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${DateFormat('d MMM yyyy, HH:mm', 'ru').format(value.scheduledAt)} • ${value.locationName}',
                      ),
                      if (value.notes?.isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(value.notes!),
                      ],
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'Изменить расписание',
                        onPressed: () => context.push(
                          '/pickup/${claim.id}?postId=$postId&ownerId=${claim.ownerId}&claimantId=${claim.claimantId}',
                        ),
                        isSecondary: true,
                        icon: Icons.edit_calendar_outlined,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('$error'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchSuggestionCard extends StatelessWidget {
  const _MatchSuggestionCard({required this.match, required this.onTap});

  final PostMatchView match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ItemPostCard(post: match.post, onTap: onTap),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  icon: Icons.auto_awesome_outlined,
                  label: 'AI score ${match.score.toStringAsFixed(0)}',
                ),
                ...match.reasons
                    .take(3)
                    .map(
                      (reason) => _InfoPill(
                        icon: Icons.tips_and_updates_outlined,
                        label: reason,
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final LostlyNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (notification.type) {
      NotificationType.message => Icons.chat_bubble_outline_rounded,
      NotificationType.claim => Icons.verified_user_outlined,
      NotificationType.match => Icons.auto_awesome_outlined,
      NotificationType.status => Icons.sync_alt_rounded,
      NotificationType.report => Icons.flag_outlined,
      NotificationType.moderation => Icons.admin_panel_settings_outlined,
      NotificationType.reminder => Icons.event_note_outlined,
      NotificationType.security => Icons.shield_outlined,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(notification.body),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat(
                      'd MMM, HH:mm',
                      'ru',
                    ).format(notification.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
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

String? _requiredField(BuildContext context, String? value, String label) {
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

String _itemText(BuildContext context, String key) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      switch (key) {
        case 'create_hub_title':
          return 'Создайте пост, который сработает быстро';
        case 'create_hub_subtitle':
          return 'Начните с объявления о потере или находке, либо сразу откройте QR-сканирование.';
        case 'create_hub_lost_subtitle':
          return 'Опишите, что пропало, и укажите локацию. Фото можно добавить позже.';
        case 'create_hub_found_subtitle':
          return 'Помогите вернуть вещь, опубликовав где и как вы её нашли.';
        case 'create_hub_scanner_subtitle':
          return 'Отсканируйте QR Lostly, чтобы сразу открыть связанную страницу вещи.';
        case 'create_lost_post':
          return 'Создать пост о потере';
        case 'create_found_post':
          return 'Создать пост о находке';
        case 'edit_post':
          return 'Редактировать пост';
        case 'camera':
          return 'Камера';
        case 'camera_unavailable':
          return 'Камера недоступна';
        case 'preview':
          return 'Предпросмотр';
        case 'retake':
          return 'Переснять';
        case 'use_photo':
          return 'Использовать фото';
        case 'qr_invalid':
          return 'QR недействителен или вещь не найдена.';
        case 'scanner_hint':
          return 'Сканируйте QR Lostly, чтобы открыть связанный пост.';
        case 'item_qr':
          return 'QR вещи';
        case 'item_not_found':
          return 'Вещь не найдена';
        case 'item_qr_missing_subtitle':
          return 'QR больше нельзя сгенерировать, потому что пост отсутствует.';
        case 'item_qr_subtitle':
          return 'Сканируйте этот код в Lostly, чтобы сразу перейти к странице вещи.';
        case 'this_is_mine':
          return 'Это моя вещь';
        case 'claim_message':
          return 'Сообщение для заявки';
        case 'claim_message_hint':
          return 'Объясните, почему вы считаете, что эта вещь принадлежит вам.';
        case 'proof_details':
          return 'Детали подтверждения';
        case 'proof_details_hint':
          return 'Укажите гравировку, наклейки, серийные подсказки или уникальные отметки.';
        case 'continue_to_verification':
          return 'Перейти к проверке';
        case 'ownership_verification':
          return 'Проверка владельца';
        case 'submit_claim':
          return 'Отправить заявку';
        case 'question':
          return 'Вопрос';
        case 'answer':
          return 'Ответ';
        case 'all_quiet':
          return 'Пока тихо';
        case 'notifications_empty_subtitle':
          return 'Новые чаты, заявки и совпадения появятся здесь.';
        case 'open_chat_from_chats_tab':
          return 'Откройте связанный чат из вкладки Чаты.';
        case 'report_post':
          return 'Пожаловаться на пост';
        case 'reason':
          return 'Причина';
        case 'reason_hint':
          return 'Спам, фейковое владение, неподходящий контент...';
        case 'details':
          return 'Подробности';
        case 'details_hint':
          return 'Добавьте дополнительный контекст для модераторов.';
        case 'submit_report':
          return 'Отправить жалобу';
        case 'report_sent_to_moderators':
          return 'Жалоба отправлена модераторам';
        case 'title':
          return 'Название';
        case 'lost_title_hint':
          return 'Потерян чёрный рюкзак';
        case 'found_title_hint':
          return 'Найден серебристый MacBook';
        case 'description':
          return 'Описание';
        case 'description_hint':
          return 'Добавьте цвета, особые приметы, что произошло и любые полезные детали.';
        case 'category':
          return 'Категория';
        case 'community':
          return 'Сообщество';
        case 'location_name':
          return 'Название локации';
        case 'location_name_hint':
          return '2 этаж библиотеки, фудкорт, парковка...';
        case 'use_current_location':
          return 'Использовать текущую локацию';
        case 'pinned_at':
          return 'Отмечено:';
        case 'photos':
          return 'Фото';
        case 'gallery':
          return 'Галерея';
        case 'no_photos_added':
          return 'Фото не добавлены';
        case 'no_photos_added_subtitle':
          return 'Фото можно не добавлять. Если оно есть, загрузите его из галереи или камеры для более точного поиска.';
        case 'publish_post':
          return 'Опубликовать пост';
        case 'save_changes':
          return 'Сохранить изменения';
        case 'current_location_pin':
          return 'Текущая геолокация';
        case 'location_updated':
          return 'Локация обновлена';
        case 'please_log_in_first':
          return 'Сначала войдите в аккаунт.';
        case 'add_at_least_one_photo':
          return 'Фото необязательно.';
        case 'post_published':
          return 'Пост опубликован';
        case 'post_updated':
          return 'Пост обновлён';
        case 'claim_request_sent':
          return 'Заявка отправлена';
        case 'lost_report':
          return 'Отчёт о потере';
        case 'found_report':
          return 'Отчёт о находке';
        case 'lost_report_subtitle':
          return 'Добавьте точные детали и последнее известное место. Фото поможет, но сейчас оно необязательно.';
        case 'found_report_subtitle':
          return 'Опишите обстоятельства находки и при желании добавьте фото, чтобы владельцу было проще узнать вещь.';
        case 'qr_code':
          return 'QR код';
        case 'post_status':
          return 'Статус поста';
        case 'message_owner':
          return 'Написать владельцу';
        case 'report_fake_post':
          return 'Пожаловаться на фейковый пост';
        case 'proof':
          return 'Подтверждение';
        case 'reject':
          return 'Отклонить';
        case 'approve':
          return 'Одобрить';
        case 'trust_score':
          return 'Рейтинг';
      }
      break;
    case 'kk':
      switch (key) {
        case 'create_hub_title':
          return 'Жылдам нәтиже беретін пост жасаңыз';
        case 'create_hub_subtitle':
          return 'Жоғалған не табылған заттан бастаңыз немесе бірден QR сканерлеуге өтіңіз.';
        case 'create_hub_lost_subtitle':
          return 'Не жоғалғанын сипаттап, орнын көрсетіңіз. Фотоны кейін де қосуға болады.';
        case 'create_hub_found_subtitle':
          return 'Затты қайтаруға көмектесіңіз: қайдан және қалай тапқаныңызды жариялаңыз.';
        case 'create_hub_scanner_subtitle':
          return 'Lostly QR-ын сканерлеп, зат бетіне бірден өтіңіз.';
        case 'create_lost_post':
          return 'Жоғалған зат постын жасау';
        case 'create_found_post':
          return 'Табылған зат постын жасау';
        case 'edit_post':
          return 'Постты өңдеу';
        case 'camera':
          return 'Камера';
        case 'camera_unavailable':
          return 'Камера қолжетімсіз';
        case 'preview':
          return 'Алдын ала қарау';
        case 'retake':
          return 'Қайта түсіру';
        case 'use_photo':
          return 'Фотоны қолдану';
        case 'qr_invalid':
          return 'QR жарамсыз немесе зат табылмады.';
        case 'scanner_hint':
          return 'Байланысты постты ашу үшін Lostly QR-ын сканерлеңіз.';
        case 'item_qr':
          return 'Заттың QR-ы';
        case 'item_not_found':
          return 'Зат табылмады';
        case 'item_qr_missing_subtitle':
          return 'Пост жоқ болғандықтан бұл QR енді жасалмайды.';
        case 'item_qr_subtitle':
          return 'Зат бетіне бірден өту үшін осы кодты Lostly ішінде сканерлеңіз.';
        case 'this_is_mine':
          return 'Бұл менің затым';
        case 'claim_message':
          return 'Өтініш хабарламасы';
        case 'claim_message_hint':
          return 'Неге бұл зат сіздікі деп ойлайтыныңызды түсіндіріңіз.';
        case 'proof_details':
          return 'Дәлел деректері';
        case 'proof_details_hint':
          return 'Ою, стикер, сериялық белгі не ерекше таңбаларды жазыңыз.';
        case 'continue_to_verification':
          return 'Тексеруге өту';
        case 'ownership_verification':
          return 'Иесін растау';
        case 'submit_claim':
          return 'Өтініш жіберу';
        case 'question':
          return 'Сұрақ';
        case 'answer':
          return 'Жауап';
        case 'all_quiet':
          return 'Әзірге тыныш';
        case 'notifications_empty_subtitle':
          return 'Жаңа чат, өтініш және сәйкестік хабарламалары осы жерде шығады.';
        case 'open_chat_from_chats_tab':
          return 'Қатысты чатты Чаттар бөлімінен ашыңыз.';
        case 'report_post':
          return 'Постқа шағым беру';
        case 'reason':
          return 'Себеп';
        case 'reason_hint':
          return 'Спам, жалған иелік, орынсыз контент...';
        case 'details':
          return 'Толығырақ';
        case 'details_hint':
          return 'Модераторларға қосымша мәлімет беріңіз.';
        case 'submit_report':
          return 'Шағым жіберу';
        case 'report_sent_to_moderators':
          return 'Шағым модераторларға жіберілді';
        case 'title':
          return 'Атауы';
        case 'lost_title_hint':
          return 'Қара рюкзак жоғалды';
        case 'found_title_hint':
          return 'Күміс түсті MacBook табылды';
        case 'description':
          return 'Сипаттама';
        case 'description_hint':
          return 'Түсін, ерекше белгілерін, не болғанын және пайдалы мәліметтерді жазыңыз.';
        case 'category':
          return 'Санат';
        case 'community':
          return 'Қауымдастық';
        case 'location_name':
          return 'Орнының атауы';
        case 'location_name_hint':
          return 'Кітапхананың 2-қабаты, фудкорт, автотұрақ...';
        case 'use_current_location':
          return 'Қазіргі орынды қолдану';
        case 'pinned_at':
          return 'Белгіленген орын:';
        case 'photos':
          return 'Фотолар';
        case 'gallery':
          return 'Галерея';
        case 'no_photos_added':
          return 'Фото қосылмаған';
        case 'no_photos_added_subtitle':
          return 'Фото қоспауға болады. Егер бар болса, іздеуді нақтылау үшін галереядан не камерадан жүктеңіз.';
        case 'publish_post':
          return 'Пост жариялау';
        case 'save_changes':
          return 'Өзгерістерді сақтау';
        case 'current_location_pin':
          return 'Ағымдағы локация';
        case 'location_updated':
          return 'Локация жаңартылды';
        case 'please_log_in_first':
          return 'Алдымен жүйеге кіріңіз.';
        case 'add_at_least_one_photo':
          return 'Фото міндетті емес.';
        case 'post_published':
          return 'Пост жарияланды';
        case 'post_updated':
          return 'Пост жаңартылды';
        case 'claim_request_sent':
          return 'Өтініш жіберілді';
        case 'lost_report':
          return 'Жоғалған зат есебі';
        case 'found_report':
          return 'Табылған зат есебі';
        case 'lost_report_subtitle':
          return 'Нақты мәлімет пен соңғы белгілі орынды қосыңыз. Фото болса жақсы, бірақ міндетті емес.';
        case 'found_report_subtitle':
          return 'Табылған жағдайды сипаттап, қаласаңыз фото қосыңыз, сонда иесіне тану оңайырақ болады.';
        case 'qr_code':
          return 'QR код';
        case 'post_status':
          return 'Пост статусы';
        case 'message_owner':
          return 'Иесіне жазу';
        case 'report_fake_post':
          return 'Жалған постқа шағым беру';
        case 'proof':
          return 'Дәлел';
        case 'reject':
          return 'Қабылдамау';
        case 'approve':
          return 'Мақұлдау';
        case 'trust_score':
          return 'Сенім ұпайы';
      }
      break;
  }

  switch (key) {
    case 'create_hub_title':
      return 'Create a post that moves fast';
    case 'create_hub_subtitle':
      return 'Start with a lost or found report, or jump straight into the QR scan flow.';
    case 'create_hub_lost_subtitle':
      return 'Describe what went missing and set the location. Photos can be added later.';
    case 'create_hub_found_subtitle':
      return 'Help return something by publishing where and how you found it.';
    case 'create_hub_scanner_subtitle':
      return 'Scan a Lostly QR to instantly open the linked item page.';
    case 'create_lost_post':
      return 'Create lost post';
    case 'create_found_post':
      return 'Create found post';
    case 'edit_post':
      return 'Edit post';
    case 'camera':
      return 'Camera';
    case 'camera_unavailable':
      return 'Camera unavailable';
    case 'preview':
      return 'Preview';
    case 'retake':
      return 'Retake';
    case 'use_photo':
      return 'Use photo';
    case 'qr_invalid':
      return 'QR is invalid or item was not found.';
    case 'scanner_hint':
      return 'Scan a Lostly item QR to open the linked post.';
    case 'item_qr':
      return 'Item QR';
    case 'item_not_found':
      return 'Item not found';
    case 'item_qr_missing_subtitle':
      return 'This QR can no longer be generated because the post is missing.';
    case 'item_qr_subtitle':
      return 'Scan this code in Lostly to jump directly to the item page.';
    case 'this_is_mine':
      return 'This is mine';
    case 'claim_message':
      return 'Claim message';
    case 'claim_message_hint':
      return 'Explain why you believe this item belongs to you.';
    case 'proof_details':
      return 'Proof details';
    case 'proof_details_hint':
      return 'Mention engraving, stickers, serial hints or unique marks.';
    case 'continue_to_verification':
      return 'Continue to verification';
    case 'ownership_verification':
      return 'Ownership verification';
    case 'submit_claim':
      return 'Submit claim';
    case 'question':
      return 'Question';
    case 'answer':
      return 'Answer';
    case 'all_quiet':
      return 'All quiet';
    case 'notifications_empty_subtitle':
      return 'New chat, claim and match alerts will appear here.';
    case 'open_chat_from_chats_tab':
      return 'Open the related chat from Chats tab.';
    case 'report_post':
      return 'Report post';
    case 'reason':
      return 'Reason';
    case 'reason_hint':
      return 'Spam, fake ownership, inappropriate content...';
    case 'details':
      return 'Details';
    case 'details_hint':
      return 'Share extra context for moderators.';
    case 'submit_report':
      return 'Submit report';
    case 'report_sent_to_moderators':
      return 'Report sent to moderators';
    case 'title':
      return 'Title';
    case 'lost_title_hint':
      return 'Lost black backpack';
    case 'found_title_hint':
      return 'Found silver MacBook';
    case 'description':
      return 'Description';
    case 'description_hint':
      return 'Add colors, unique marks, what happened and any useful clues.';
    case 'category':
      return 'Category';
    case 'community':
      return 'Community';
    case 'location_name':
      return 'Location name';
    case 'location_name_hint':
      return 'Library floor 2, food court, parking lot...';
    case 'use_current_location':
      return 'Use current location';
    case 'pinned_at':
      return 'Pinned at';
    case 'photos':
      return 'Photos';
    case 'gallery':
      return 'Gallery';
    case 'no_photos_added':
      return 'No photos added';
    case 'no_photos_added_subtitle':
      return 'Photos are optional. If you have one, add it from the gallery or camera to improve matching.';
    case 'publish_post':
      return 'Publish post';
    case 'save_changes':
      return 'Save changes';
    case 'current_location_pin':
      return 'Current location pin';
    case 'location_updated':
      return 'Location updated';
    case 'please_log_in_first':
      return 'Please log in first.';
    case 'add_at_least_one_photo':
      return 'Photos are optional.';
    case 'post_published':
      return 'Post published';
    case 'post_updated':
      return 'Post updated';
    case 'claim_request_sent':
      return 'Claim request sent';
    case 'lost_report':
      return 'Lost report';
    case 'found_report':
      return 'Found report';
    case 'lost_report_subtitle':
      return 'Add strong details and the last known location. Photos help, but they are optional.';
    case 'found_report_subtitle':
      return 'Describe the found item clearly and optionally add photos to help the owner verify faster.';
    case 'qr_code':
      return 'QR code';
    case 'post_status':
      return 'Post status';
    case 'message_owner':
      return 'Message owner';
    case 'report_fake_post':
      return 'Report fake post';
    case 'proof':
      return 'Proof';
    case 'reject':
      return 'Reject';
    case 'approve':
      return 'Approve';
    case 'trust_score':
      return 'Trust score';
    default:
      return '';
  }
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
