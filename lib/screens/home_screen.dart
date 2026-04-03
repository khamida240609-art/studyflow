import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/group_provider.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _studyMinutes = 25;
  int _breakMinutes = 5;
  int _bellMinutes = 1;

  Timer? _timer;
  bool _isStudy = true;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start(SessionProvider sessions) {
    if (_timer != null) return;
    if (_isStudy) {
      if (_secondsLeft == 0) {
        _secondsLeft = _studyMinutes * 60;
      }
      sessions.start(category: 'General');
      context.read<GroupProvider>().setStatus(
            context.read<AuthService>().userId ?? 'local-user',
            'Studying',
          );
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final elapsed = (_studyMinutes * 60) - _secondsLeft;
      if (_isStudy && _bellMinutes > 0 && elapsed >= _bellMinutes * 60) {
        await _finishPhase(sessions);
        return;
      }
      if (_secondsLeft <= 1) {
        await _finishPhase(sessions);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
    setState(() {});
  }

  Future<void> _finishPhase(SessionProvider sessions) async {
    _timer?.cancel();
    _timer = null;
    if (_isStudy) {
      await sessions.stop();
      if (!mounted) return;
      context.read<GoalProvider>().onSessionCompleted();
      context.read<GroupProvider>().addStudyMinutes(
            context.read<AuthService>().userId ?? 'local-user',
            _studyMinutes,
          );
      context.read<GroupProvider>().setStatus(
            context.read<AuthService>().userId ?? 'local-user',
            'Break',
          );
      _isStudy = false;
      _secondsLeft = _breakMinutes * 60;
    } else {
      _isStudy = true;
      context.read<GroupProvider>().setStatus(
            context.read<AuthService>().userId ?? 'local-user',
            'Studying',
          );
      _secondsLeft = _studyMinutes * 60;
    }
    if (mounted) setState(() {});
  }

  Future<void> _stop(SessionProvider sessions) async {
    _timer?.cancel();
    _timer = null;
    if (_isStudy && sessions.isRunning) {
      await sessions.stop();
    }
    context.read<GroupProvider>().setStatus(
          context.read<AuthService>().userId ?? 'local-user',
          'Offline',
        );
    _isStudy = true;
    _secondsLeft = 0;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionProvider>();
    final goal = context.watch<GoalProvider>();
    final badges = context.watch<BadgeProvider>();
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text('StudyFlow',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(_isStudy ? 'Mode: Study' : 'Mode: Break',
                    style: TextStyle(color: AppTheme.secondary(context))),
                const Spacer(),
                IconButton(
                  onPressed: () => context.push('/profile'),
                  icon: const Icon(Icons.person),
                ),
              ],
            ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.bg2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Text('$minutes:$seconds',
                        style: const TextStyle(
                            fontSize: 48, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      children: [
                        SizedBox(
                          width: 120,
                          child: ElevatedButton(
                            onPressed: () => _start(sessions),
                            child: const Text('Start'),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: OutlinedButton(
                            onPressed: () => _stop(sessions),
                            child: const Text('Stop'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ConfigCard(
                studyMinutes: _studyMinutes,
                breakMinutes: _breakMinutes,
                targetSessions: goal.targetSessions,
                bellMinutes: _bellMinutes,
                onChanged: (s, b, target, bell) {
                  setState(() {
                    _studyMinutes = s;
                    _breakMinutes = b;
                    _bellMinutes = bell;
                    if (_isStudy && _timer == null) {
                      _secondsLeft = _studyMinutes * 60;
                    }
                  });
                  goal.setTarget(target);
                },
              ),
              const SizedBox(height: 20),
              if (badges.selectedBadge != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.bg2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Text(badges.selectedBadge!.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pinned badge: ${badges.selectedBadge!.title}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              if (badges.selectedBadge != null) const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bg2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Daily Progress',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                  Text('${goal.completedSessions}/${goal.targetSessions} sessions',
                      style: TextStyle(color: AppTheme.secondary(context))),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: goal.targetSessions == 0
                            ? 0
                            : (goal.completedSessions / goal.targetSessions).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppTheme.bg4,
                        color: AppTheme.accent2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final int studyMinutes;
  final int breakMinutes;
  final int targetSessions;
  final int bellMinutes;
  final void Function(int study, int brk, int target, int bell) onChanged;

  const _ConfigCard({
    required this.studyMinutes,
    required this.breakMinutes,
    required this.targetSessions,
    required this.bellMinutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Custom Settings', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _NumberField(
            label: 'Study minutes',
            initial: studyMinutes,
            onSaved: (v) => onChanged(v, breakMinutes, targetSessions, bellMinutes),
          ),
          _NumberField(
            label: 'Break minutes',
            initial: breakMinutes,
            onSaved: (v) => onChanged(studyMinutes, v, targetSessions, bellMinutes),
          ),
          _NumberField(
            label: 'Daily target (sessions)',
            initial: targetSessions,
            onSaved: (v) => onChanged(studyMinutes, breakMinutes, v, bellMinutes),
          ),
          _NumberField(
            label: 'Bell reminder (minutes)',
            initial: bellMinutes,
            onSaved: (v) => onChanged(studyMinutes, breakMinutes, targetSessions, v),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  final String label;
  final int initial;
  final void Function(int value) onSaved;
  const _NumberField({
    required this.label,
    required this.initial,
    required this.onSaved,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(widget.label)),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(isDense: true),
              onSubmitted: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed > 0) {
                  widget.onSaved(parsed);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              final parsed = int.tryParse(_ctrl.text);
              if (parsed != null && parsed > 0) {
                widget.onSaved(parsed);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
