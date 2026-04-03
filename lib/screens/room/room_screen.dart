import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/room_model.dart';
import '../../models/message_model.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import '../../services/session_service.dart';
import '../../utils/theme.dart';
import '../../widgets/timer_widget.dart';

class RoomScreen extends StatefulWidget {
  final String roomId;
  const RoomScreen({super.key, required this.roomId});
  @override State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  RoomModel? _room;
  bool _joined = false;
  bool _showComplete = false;
  int _sprintsCompleted = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthService>();
    final roomSvc = context.read<RoomService>();
    final sessSvc = context.read<SessionService>();

    _room = await roomSvc.getRoom(widget.roomId);
    if (_room == null) return;

    setState(() {});

    // Join room
    await roomSvc.joinRoom(widget.roomId, auth.userId!, auth.displayName);
    await sessSvc.startSession(auth.userId!, widget.roomId);
    setState(() => _joined = true);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _leaveRoom({bool early = false}) async {
    final auth = context.read<AuthService>();
    final roomSvc = context.read<RoomService>();
    final sessSvc = context.read<SessionService>();

    if (early && _joined) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.bg2,
          title: const Text('Ерте кету?'),
          content: const Text('Сессиядан ерте шықсаңыз, XP есептелмейді.',
            style: TextStyle(color: AppTheme.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Қалу', style: TextStyle(color: AppTheme.accent2))),
            TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Шығу', style: TextStyle(color: AppTheme.red))),
          ],
        ),
      );
      if (confirm != true) return;
    }

    if (_joined) {
      await roomSvc.leaveRoom(widget.roomId, auth.userId!, early: early);
      await sessSvc.completeSession(
        uid: auth.userId!,
        roomId: widget.roomId,
        sprintsCompleted: _sprintsCompleted,
        focusMinutesPerSprint: _room?.focusMinutes ?? 50,
        leftEarly: early,
      );
      await auth.refreshUserModel();
    }
    if (mounted) context.go('/home');
  }

  void _onSprintComplete() {
    setState(() { _sprintsCompleted++; });
  }

  void _onSessionComplete() async {
    final auth = context.read<AuthService>();
    final roomSvc = context.read<RoomService>();
    final sessSvc = context.read<SessionService>();

    await roomSvc.leaveRoom(widget.roomId, auth.userId!, early: false);
    await sessSvc.completeSession(
      uid: auth.userId!,
      roomId: widget.roomId,
      sprintsCompleted: 4,
      focusMinutesPerSprint: _room?.focusMinutes ?? 50,
    );
    await auth.refreshUserModel();
    setState(() { _showComplete = true; _joined = false; });
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final auth = context.read<AuthService>();
    context.read<RoomService>().sendMessage(
      widget.roomId,
      auth.userId!,
      auth.displayName,
      text,
    );
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_room == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.accent)));
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _leaveRoom(early: true),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _leaveRoom(early: true),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_room!.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('${_room!.focusMinutes} мин фокус · ${_room!.breakMinutes} мин үзіліс',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.green.withOpacity(0.3)),
              ),
              child: const Text('LIVE', style: TextStyle(color: AppTheme.green, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Timer widget
                PomodoroTimerWidget(
                  focusMinutes: _room!.focusMinutes,
                  breakMinutes: _room!.breakMinutes,
                  onSprintComplete: _onSprintComplete,
                  onSessionComplete: _onSessionComplete,
                ),
                const Divider(color: AppTheme.border, height: 1),

                // Participants
                _ParticipantsSection(roomId: widget.roomId),
                const Divider(color: AppTheme.border, height: 1),

                // Chat
                Expanded(
                  child: _ChatSection(
                    roomId: widget.roomId,
                    scrollCtrl: _scrollCtrl,
                    msgCtrl: _msgCtrl,
                    onSend: _sendMessage,
                  ),
                ),
              ],
            ),

            // Complete overlay
            if (_showComplete)
              _CompleteOverlay(
                sprintsCompleted: 4,
                onContinue: () => context.go('/home'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantsSection extends StatelessWidget {
  final String roomId;
  const _ParticipantsSection({required this.roomId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: context.read<RoomService>().participantsStream(roomId),
      builder: (context, snap) {
        final parts = snap.data ?? [];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Text('Қатысушылар',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('● ${parts.length}',
                  style: const TextStyle(color: AppTheme.green, fontSize: 11)),
              ),
              const Spacer(),
              // Avatar row
              SizedBox(
                height: 28,
                child: Stack(
                  children: [
                    ...parts.take(5).toList().asMap().entries.map((e) {
                      final colors = [AppTheme.accent, AppTheme.green, AppTheme.amber,
                        AppTheme.red, AppTheme.accent2];
                      final name = e.value['displayName'] as String? ?? '?';
                      return Positioned(
                        right: e.key * 20.0,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: colors[e.key % colors.length],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.bg, width: 1.5),
                          ),
                          child: Center(
                            child: Text(name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatSection extends StatelessWidget {
  final String roomId;
  final ScrollController scrollCtrl;
  final TextEditingController msgCtrl;
  final VoidCallback onSend;

  const _ChatSection({
    required this.roomId, required this.scrollCtrl,
    required this.msgCtrl, required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<AuthService>().currentUser?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text('Чат', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: context.read<RoomService>().messagesStream(roomId),
            builder: (context, snap) {
              final msgs = snap.data ?? [];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (scrollCtrl.hasClients && msgs.isNotEmpty) {
                  scrollCtrl.animateTo(scrollCtrl.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
                }
              });
              return ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final m = msgs[i];
                  final isMe = m.senderUid == myUid;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            Text(isMe ? 'Сіз' : m.senderName,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                                color: isMe ? AppTheme.green : AppTheme.accent2)),
                            const SizedBox(width: 6),
                            Text(
                              '${m.createdAt.hour}:${m.createdAt.minute.toString().padLeft(2,'0')}',
                              style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppTheme.accent.withOpacity(0.2)
                                : AppTheme.bg3,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isMe ? 12 : 2),
                              bottomRight: Radius.circular(isMe ? 2 : 12),
                            ),
                            border: isMe
                                ? Border.all(color: AppTheme.accent.withOpacity(0.3))
                                : null,
                          ),
                          child: Text(m.text, style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Input row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: msgCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Хабарлама жазыңыз...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onSend,
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompleteOverlay extends StatelessWidget {
  final int sprintsCompleted;
  final VoidCallback onContinue;
  const _CompleteOverlay({required this.sprintsCompleted, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bg.withOpacity(0.95),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text('Спринт аяқталды!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Толық Pomodoro сессиясын аяқтадыңыз. Тамаша!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                decoration: BoxDecoration(
                  color: AppTheme.bg3,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border2),
                ),
                child: Column(
                  children: [
                    Text('+${sprintsCompleted * 50} XP',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700,
                        color: AppTheme.amber)),
                    const Text('тәжірибе жиналды',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onContinue,
                child: const Text('Бөлмелерге қайту'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
