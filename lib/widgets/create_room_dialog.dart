import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';
import '../utils/theme.dart';

class CreateRoomDialog extends StatefulWidget {
  final String userId;
  const CreateRoomDialog({super.key, required this.userId});
  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  final _nameCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  RoomMode _mode = RoomMode.deep;
  int _focus = 50;
  int _brk = 10;
  bool _loading = false;

  final _modes = [
    {'mode': RoomMode.deep, 'label': 'Deep Work', 'emoji': '🧠', 'desc': '50+10'},
    {'mode': RoomMode.light, 'label': 'Light', 'emoji': '☀️', 'desc': '25+5'},
    {'mode': RoomMode.exam, 'label': 'Exam', 'emoji': '🔥', 'desc': '90+15'},
  ];

  @override
  void dispose() { _nameCtrl.dispose(); _subjectCtrl.dispose(); super.dispose(); }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final roomId = await context.read<RoomService>().createRoom(
      name: _nameCtrl.text.trim(),
      subject: _subjectCtrl.text.trim().isEmpty ? 'Жалпы' : _subjectCtrl.text.trim(),
      mode: _mode,
      focusMinutes: _focus,
      breakMinutes: _brk,
      createdBy: widget.userId,
    );
    if (mounted) { Navigator.pop(context); context.push('/room/$roomId'); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Бөлме жасау', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: AppTheme.textSecondary)),
          ]),
          const SizedBox(height: 20),
          TextField(controller: _nameCtrl, style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'Бөлме атауы'), autofocus: true),
          const SizedBox(height: 12),
          TextField(controller: _subjectCtrl, style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'Пән (міндетті емес)')),
          const SizedBox(height: 20),
          const Text('Режим', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: _modes.map((m) {
              final selected = _mode == m['mode'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _mode = m['mode'] as RoomMode;
                    if (_mode == RoomMode.deep) { _focus = 50; _brk = 10; }
                    if (_mode == RoomMode.light) { _focus = 25; _brk = 5; }
                    if (_mode == RoomMode.exam) { _focus = 90; _brk = 15; }
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.accent.withOpacity(0.15) : AppTheme.bg3,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? AppTheme.accent : AppTheme.border),
                    ),
                    child: Column(children: [
                      Text(m['emoji'] as String, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(m['label'] as String, style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: selected ? AppTheme.accent2 : AppTheme.textSecondary)),
                      Text(m['desc'] as String,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _create,
            child: _loading
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Бөлме жасау'),
          ),
        ],
      ),
    );
  }
}
