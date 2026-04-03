import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final _groupNameCtrl = TextEditingController();
  final _groupPassCtrl = TextEditingController();
  final _joinCodeCtrl = TextEditingController();
  final _joinNameCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    _groupPassCtrl.dispose();
    _joinCodeCtrl.dispose();
    _joinNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<GroupProvider>();
    final auth = context.read<AuthService>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Group Study',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Stay accountable with friends.',
                style: TextStyle(color: AppTheme.secondary(context))),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppTheme.red)),
              const SizedBox(height: 8),
            ],
            if (!group.inGroup) ...[
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create group',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _groupNameCtrl,
                      decoration: const InputDecoration(hintText: 'Group name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _groupPassCtrl,
                      decoration: const InputDecoration(hintText: 'Group password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        final name = _groupNameCtrl.text.trim();
                        final pass = _groupPassCtrl.text.trim();
                        if (name.isEmpty || pass.isEmpty) {
                          setState(() => _error = 'Fill name and password');
                          return;
                        }
                        group
                            .createGroup(
                              name: name,
                              password: pass,
                              uid: auth.userId ?? 'local-user',
                              userName: auth.displayName,
                            )
                            .then((_) => setState(() => _error = null));
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Join group',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _joinCodeCtrl,
                      decoration: const InputDecoration(hintText: 'Enter code'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _joinNameCtrl,
                      decoration: const InputDecoration(hintText: 'Group name'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        final code = _joinCodeCtrl.text.trim();
                        final name = _joinNameCtrl.text.trim();
                        if (code.isEmpty || name.isEmpty) {
                          setState(() => _error = 'Enter code and group name');
                          return;
                        }
                        group
                            .joinGroup(code, name, auth.userId ?? 'local-user')
                            .then((ok) => setState(() => _error = ok ? null : 'Wrong code or name'));
                      },
                      child: const Text('Join'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.groupName ?? 'Study Group',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('Code: ${group.groupCode}',
                        style: TextStyle(color: AppTheme.secondary(context))),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Start Group Session'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: group.leaveGroup,
                      child: const Text('Leave group'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('Participants',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: group.participants.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final p = group.participants[i];
                          return _ParticipantTile(
                            name: p['name'] ?? 'User',
                            status: p['status'] ?? 'Offline',
                            minutes: (p['totalMinutes'] ?? 0).toString(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ChatBox(group: group, uid: auth.userId ?? 'local-user', name: auth.displayName),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final String name;
  final String status;
  final String minutes;
  const _ParticipantTile({required this.name, required this.status, required this.minutes});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Studying':
        color = AppTheme.green;
        break;
      case 'Break':
        color = AppTheme.amber;
        break;
      default:
        color = AppTheme.textTertiary;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.bg4,
            child: Text(name[0]),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('$name • $minutes min')),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ChatBox extends StatefulWidget {
  final GroupProvider group;
  final String uid;
  final String name;
  const _ChatBox({required this.group, required this.uid, required this.name});

  @override
  State<_ChatBox> createState() => _ChatBoxState();
}

class _ChatBoxState extends State<_ChatBox> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.group.messagesStream(),
              builder: (context, snap) {
                final items = snap.data ?? [];
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final m = items[i];
                    return Text('${m['name']}: ${m['text']}',
                        style: const TextStyle(fontSize: 12));
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Message...',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final text = _ctrl.text.trim();
                  if (text.isEmpty) return;
                  widget.group.sendMessage(widget.uid, widget.name, text);
                  _ctrl.clear();
                },
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
