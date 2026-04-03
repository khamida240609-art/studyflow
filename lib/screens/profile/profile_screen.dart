import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.bg2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accent2],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        user?.displayName.isNotEmpty == true
                            ? user!.displayName[0].toUpperCase() : 'A',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.displayName ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Badge(label: 'Деңгей ${user?.level ?? 1}', color: AppTheme.accent),
                      const SizedBox(width: 8),
                      _Badge(label: '🔥 ${user?.streakCount ?? 0} серія', color: AppTheme.amber),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats grid
            Row(
              children: [
                Expanded(child: _StatCard(value: '${user?.totalSessions ?? 0}', label: 'Сессия')),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  value: '${((user?.totalFocusMinutes ?? 0) / 60).toStringAsFixed(1)}ч',
                  label: 'Фокус уақыт', color: AppTheme.green)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  value: '${user?.xp ?? 0}', label: 'XP', color: AppTheme.amber)),
              ],
            ),
            const SizedBox(height: 24),

            // Menu
            _MenuItem(icon: '🔔', label: 'Хабарландырулар', onTap: () {}),
            _MenuItem(icon: '⏱', label: 'Таймер баптаулары', onTap: () {}),
            _MenuItem(icon: '📊', label: 'Оқу аналитикасы', onTap: () {}),
            _MenuItem(icon: '🌐', label: 'Тіл', onTap: () {}),
            const SizedBox(height: 8),
            _MenuItem(
              icon: '🚪',
              label: 'Шығу',
              color: AppTheme.red,
              onTap: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard({required this.value, required this.label, this.color = AppTheme.accent2});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bg3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.color = AppTheme.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.bg2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: color == AppTheme.red ? AppTheme.red.withOpacity(0.1) : AppTheme.bg3,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500))),
              Icon(Icons.chevron_right, color: AppTheme.textTertiary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
