import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  int _indexFromLocation(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/group')) return 1;
    if (location.startsWith('/teacher')) return 2;
    if (location.startsWith('/analytics')) return 3;
    if (location.startsWith('/badges')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.bg2,
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/home'); break;
            case 1: context.go('/group'); break;
            case 2: context.go('/teacher'); break;
            case 3: context.go('/analytics'); break;
            case 4: context.go('/badges'); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.timer), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.group), label: 'Group'),
          NavigationDestination(icon: Icon(Icons.school), label: 'Teacher'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'AI'),
          NavigationDestination(icon: Icon(Icons.emoji_events), label: 'Badges'),
        ],
      ),
    );
  }
}
