import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../providers/session_provider.dart';
import '../utils/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<int> _usageDays() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('first_open_date');
    DateTime first;
    if (stored == null) {
      first = DateTime.now();
      await prefs.setString('first_open_date', first.toIso8601String());
    } else {
      first = DateTime.parse(stored);
    }
    final now = DateTime.now();
    return now.difference(first).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final theme = context.watch<ThemeProvider>();
    final sessions = context.watch<SessionProvider>().sessions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.bg3,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(auth.displayName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(auth.email.isNotEmpty ? auth.email : 'email not set',
                style: TextStyle(color: AppTheme.secondary(context))),
            const SizedBox(height: 20),
            FutureBuilder<int>(
              future: _usageDays(),
              builder: (context, snap) {
                final days = snap.data ?? 1;
                return _InfoTile(
                  title: 'Usage days',
                  value: '$days days',
                );
              },
            ),
            _InfoTile(title: 'Total sessions', value: '${sessions.length}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.bg2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dark_mode),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Dark mode')),
                  Switch(
                    value: theme.mode == ThemeMode.dark,
                    onChanged: (v) => theme.toggle(v),
                  ),
                ],
              ),
            ),
            ListTile(
              tileColor: AppTheme.bg2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text('Sign out'),
              trailing: const Icon(Icons.logout),
              onTap: () async {
                await auth.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
