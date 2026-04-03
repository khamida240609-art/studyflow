import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/utils/build_context_x.dart';
import '../../models/chat_message.dart';
import '../../models/chat_room.dart';
import '../../providers/app_providers.dart';
import '../../widgets/async_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/lostly_scaffold.dart';

const _conciergeChatId = 'lostly-concierge';
const _conciergeUserId = 'lostly-concierge-user';
const _conciergeName = 'Куратор Lostly';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(chatsProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return LostlyScaffold(
      title: context.l10n.chats,
      child: AsyncValueWidget(
        value: chats,
        data: (rooms) {
          return ListView(
            children: [
              _SupportChatTile(
                onTap: () => context.push(
                  '/chat/$_conciergeChatId?otherUserId=$_conciergeUserId&otherUserName=${Uri.encodeComponent(_conciergeName)}',
                ),
              ),
              const SizedBox(height: 14),
              if (rooms.isEmpty)
                const EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Чатов пока нет',
                  subtitle:
                      'Откройте любой предмет и нажмите "Написать владельцу", чтобы начать чат в реальном времени.',
                )
              else
                ...rooms.map((room) {
                  final otherId = room.participantIds.firstWhere(
                    (id) => id != currentUserId,
                    orElse: () => room.participantIds.first,
                  );
                  final otherName =
                      room.participantNames[otherId] ?? 'Пользователь Lostly';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ChatTile(
                      room: room,
                      otherName: otherName,
                      unreadCount: room.unreadCounts[currentUserId] ?? 0,
                      onTap: () => context.push(
                        '/chat/${room.id}?otherUserId=$otherId&otherUserName=${Uri.encodeComponent(otherName)}',
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  final String chatId;
  final String otherUserId;
  final String otherUserName;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref
          .read(chatActionControllerProvider.notifier)
          .markRead(chatId: widget.chatId),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }
    final text = _messageController.text;
    _messageController.clear();
    try {
      await ref
          .read(chatActionControllerProvider.notifier)
          .sendMessage(
            chatId: widget.chatId,
            receiverId: widget.otherUserId,
            text: text,
          );
    } catch (error) {
      if (mounted) {
        context.showErrorSnackBar('$error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chatId == _conciergeChatId) {
      return const _ConciergeChatScreen(otherUserName: _conciergeName);
    }

    final messages = ref.watch(messagesProvider(widget.chatId));
    final currentUserId = ref.watch(currentUserIdProvider);
    final isSending = ref.watch(chatActionControllerProvider).isLoading;

    return LostlyScaffold(
      title: widget.otherUserName,
      child: Column(
        children: [
          Expanded(
            child: AsyncValueWidget(
              value: messages,
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.waving_hand_outlined,
                    title: 'Напишите первым',
                    subtitle: 'Этот диалог пуст. Начните с первого сообщения.',
                    actionLabel: 'Отправить первое сообщение',
                    onAction: () => _messageController.text =
                        'Здравствуйте! Меня заинтересовал ваш пост.',
                  );
                }

                return ListView.builder(
                  reverse: false,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final message = items[index];
                    final isMine = message.senderId == currentUserId;
                    final next = index < items.length - 1
                        ? items[index + 1]
                        : null;
                    final showDate =
                        next == null ||
                        next.sentAt.day != message.sentAt.day ||
                        next.sentAt.month != message.sentAt.month;

                    return Column(
                      children: [
                        if (showDate) ...[
                          const SizedBox(height: 12),
                          Text(
                            DateFormat('d MMM', 'ru').format(message.sentAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _MessageBubble(message: message, isMine: isMine),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Напишите сообщение...',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: isSending ? null : _send,
                icon: isSending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupportChatTile extends StatelessWidget {
  const _SupportChatTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF102033), Color(0xFF1D4ED8), Color(0xFF6BD6B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _conciergeName,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Онлайн сейчас. Поможет с картой, QR, публикацией и возвратом вещей.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ConciergeChatScreen extends StatefulWidget {
  const _ConciergeChatScreen({required this.otherUserName});

  final String otherUserName;

  @override
  State<_ConciergeChatScreen> createState() => _ConciergeChatScreenState();
}

class _ConciergeChatScreenState extends State<_ConciergeChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = <ChatMessage>[
    ChatMessage(
      id: 'concierge-1',
      chatId: _conciergeChatId,
      senderId: _conciergeUserId,
      receiverId: 'me',
      text:
          'Здравствуйте! Я на связи и могу помочь с картой, QR-кодами, публикацией постов и возвратом вещей.',
      sentAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    ChatMessage(
      id: 'concierge-2',
      chatId: _conciergeChatId,
      senderId: _conciergeUserId,
      receiverId: 'me',
      text:
          'Например, напишите "карта", "QR" или "как вернуть вещь", и я подскажу следующий шаг.',
      sentAt: DateTime.now().subtract(const Duration(minutes: 7)),
    ),
  ];

  bool _isReplying = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          id: 'me-${DateTime.now().microsecondsSinceEpoch}',
          chatId: _conciergeChatId,
          senderId: 'me',
          receiverId: _conciergeUserId,
          text: text,
          sentAt: DateTime.now(),
        ),
      );
      _controller.clear();
      _isReplying = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) {
      return;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          id: 'support-${DateTime.now().microsecondsSinceEpoch}',
          chatId: _conciergeChatId,
          senderId: _conciergeUserId,
          receiverId: 'me',
          text: _buildConciergeReply(text),
          sentAt: DateTime.now(),
        ),
      );
      _isReplying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LostlyScaffold(
      title: widget.otherUserName,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  child: Icon(Icons.support_agent_rounded, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Живой demo-чат для презентации. Ответы приходят сразу, чтобы можно было полноценно прокликать сценарий общения.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length + (_isReplying ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isReplying && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                final message = _messages[index];
                return Column(
                  children: [
                    if (index == 0 ||
                        _messages[index - 1].sentAt.day != message.sentAt.day)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          DateFormat('d MMM', 'ru').format(message.sentAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    _MessageBubble(
                      message: message,
                      isMine: message.senderId == 'me',
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Спросите про карту, QR или возврат...',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _isReplying ? null : _send,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildConciergeReply(String query) {
    final text = query.toLowerCase();
    if (text.contains('карт')) {
      return 'Карта уже встроена в приложение: на главном экране есть preview, а полный экран открывается через кнопку "Карта". Для работы на Android нужно только вставить Google Maps API key в AndroidManifest.';
    }
    if (text.contains('qr')) {
      return 'Откройте карточку предмета и нажмите QR-код. Для сканирования используйте встроенный QR Scanner, после распознавания откроется нужный предмет.';
    }
    if (text.contains('вернут') || text.contains('вернуть')) {
      return 'Лучший сценарий такой: откройте найденную вещь, отправьте заявку "Это моя вещь", пройдите верификацию и после одобрения переведите статус в "Возвращено".';
    }
    if (text.contains('пост') || text.contains('объяв')) {
      return 'Чтобы создать сильный пост, добавьте фото, точную категорию, локацию и описание отличительных деталей. Тогда совпадения и карта работают заметно лучше.';
    }
    return 'Я помогу. Попробуйте спросить про карту, QR, публикацию поста, верификацию владельца или возврат вещи.';
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.room,
    required this.otherName,
    required this.unreadCount,
    required this.onTap,
  });

  final ChatRoom room;
  final String otherName;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timestamp = room.lastMessageAt ?? room.createdAt;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              child: Text(otherName.characters.first.toUpperCase()),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    room.lastMessage ?? 'Чат создан по объявлению Lostly',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 12,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  '$unreadCount',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final color = isMine
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final textColor = isMine ? Colors.white : null;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.72,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(22).copyWith(
                bottomLeft: Radius.circular(isMine ? 22 : 8),
                bottomRight: Radius.circular(isMine ? 8 : 22),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.sentAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.7)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
