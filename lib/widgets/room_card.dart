import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../utils/theme.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;

  const RoomCard({super.key, required this.room, required this.onTap});

  Color get _modeColor {
    switch (room.mode) {
      case RoomMode.deep: return AppTheme.accent;
      case RoomMode.light: return AppTheme.green;
      case RoomMode.exam: return AppTheme.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bg2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            // Top color stripe
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: _modeColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(room.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _modeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(room.modeLabel,
                          style: TextStyle(color: _modeColor, fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(room.subject,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Live indicator
                      Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.green, shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text('${room.participantCount} оқып жатыр',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.bg4,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('⏱ ${room.focusMinutes}+${room.breakMinutes} мин',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      ),
                    ],
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
