import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import '../../models/room_model.dart';
import '../../utils/theme.dart';
import '../../widgets/room_card.dart';
import '../../widgets/create_room_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.userModel;
    final firstName = user?.displayName.split(' ').first ?? 'Student';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Сәлем, $firstName 👋',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        const Text('Спринтке дайынсыз ба?',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.accent, AppTheme.accent2],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          (user?.displayName.isNotEmpty == true)
                              ? user!.displayName[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Streak bar
            if (user != null && user.streakCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _StreakBar(streak: user.streakCount),
              ),

            const SizedBox(height: 20),

            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Text('🟢 Тікелей бөлмелер',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showCreateRoom(context, auth),
                    icon: const Icon(Icons.add, size: 16, color: AppTheme.accent2),
                    label: const Text('Жасау',
                      style: TextStyle(color: AppTheme.accent2, fontSize: 13)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      backgroundColor: AppTheme.accent.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Rooms list (real-time)
            Expanded(
              child: StreamBuilder<List<RoomModel>>(
                stream: context.read<RoomService>().activeRoomsStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Қате: ${snap.error}',
                      style: const TextStyle(color: AppTheme.textSecondary)));
                  }
                  final rooms = snap.data ?? [];
                  if (rooms.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('📚', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('Бөлме жоқ', style: TextStyle(color: AppTheme.textSecondary)),
                          SizedBox(height: 4),
                          Text('Бірінші болып жасаңыз!',
                            style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => RoomCard(
                      room: rooms[i],
                      onTap: () => context.push('/room/${rooms[i].id}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateRoom(BuildContext context, AuthService auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateRoomDialog(userId: auth.userId!),
    );
  }
}

class _StreakBar extends StatelessWidget {
  final int streak;
  const _StreakBar({required this.streak});

  @override
  Widget build(BuildContext context) {
    final days = ['Д','С','Ш','Б','Ж','С','Жк'];
    final today = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bg3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('$streak', style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.amber)),
                    const SizedBox(width: 4),
                    const Text('күндік серія',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                const Text('Жалғастырыңыз!',
                  style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
              ],
            ),
          ),
          Row(
            children: List.generate(7, (i) {
              final done = i < streak && i <= today;
              final isToday = i == today;
              return Container(
                width: 26, height: 26,
                margin: const EdgeInsets.only(left: 3),
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.amber
                      : done ? AppTheme.amber.withOpacity(0.3)
                      : AppTheme.bg4,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(days[i],
                    style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w500,
                      color: isToday ? Colors.black
                          : done ? AppTheme.amber
                          : AppTheme.textTertiary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
