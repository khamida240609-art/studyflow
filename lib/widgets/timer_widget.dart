import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class PomodoroTimerWidget extends StatefulWidget {
  final int focusMinutes;
  final int breakMinutes;
  final VoidCallback onSprintComplete;
  final VoidCallback onSessionComplete;
  static const int totalSprints = 4;

  const PomodoroTimerWidget({
    super.key,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.onSprintComplete,
    required this.onSessionComplete,
  });

  @override
  State<PomodoroTimerWidget> createState() => _PomodoroTimerWidgetState();
}

class _PomodoroTimerWidgetState extends State<PomodoroTimerWidget>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _running = false;
  bool _isFocus = true;
  int _sprint = 1;
  late int _remaining;
  late int _total;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _total = widget.focusMinutes * 60;
    _remaining = _total;
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _toggle() => _running ? _pause() : _start();

  void _start() {
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0) {
        setState(() => _remaining--);
      } else {
        _handlePhaseEnd();
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = _total;
    });
  }

  void _handlePhaseEnd() {
    _timer?.cancel();
    setState(() => _running = false);

    if (_isFocus) {
      widget.onSprintComplete();
      if (_sprint >= PomodoroTimerWidget.totalSprints) {
        widget.onSessionComplete();
        return;
      }
      // Switch to break
      setState(() {
        _isFocus = false;
        _total = widget.breakMinutes * 60;
        _remaining = _total;
      });
    } else {
      // Switch to focus, next sprint
      setState(() {
        _sprint++;
        _isFocus = true;
        _total = widget.focusMinutes * 60;
        _remaining = _total;
      });
    }
  }

  String get _timeStr {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress => 1 - (_remaining / _total);

  @override
  Widget build(BuildContext context) {
    final phaseColor = _isFocus ? AppTheme.accent : AppTheme.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Column(
        children: [
          // Circular timer
          SizedBox(
            width: 180, height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(180, 180),
                  painter: _TimerPainter(
                    progress: _progress,
                    color: phaseColor,
                    bgColor: AppTheme.bg3,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_timeStr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1,
                      )),
                    const SizedBox(height: 4),
                    Text(_isFocus ? 'ФОКУС' : 'ҮЗІЛІС',
                      style: TextStyle(
                        fontSize: 11, letterSpacing: 1.5,
                        color: phaseColor, fontWeight: FontWeight.w500,
                      )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _reset,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.bg3,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border2),
                  ),
                  child: const Text('↺ Қайта',
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _toggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  decoration: BoxDecoration(
                    color: phaseColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _running ? '⏸ Тоқтату' : '▶ Бастау',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sprint dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(PomodoroTimerWidget.totalSprints, (i) {
              final done = i < _sprint - 1;
              final active = i == _sprint - 1;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: done ? AppTheme.bg4
                      : active ? AppTheme.accent
                      : AppTheme.bg4,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: done ? AppTheme.border2
                        : active ? AppTheme.accent
                        : AppTheme.border,
                    width: done ? 1 : 0,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text('Спринт $_sprint / ${PomodoroTimerWidget.totalSprints}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
        ],
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  _TimerPainter({required this.progress, required this.color, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = (size.width - 12) / 2;
    final paint = Paint()
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Background ring
    paint.color = bgColor;
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Progress arc
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_TimerPainter old) =>
      old.progress != progress || old.color != color;
}
