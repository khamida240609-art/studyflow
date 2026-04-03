import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/localization/app_localizations.dart';

class LostlyScaffold extends StatelessWidget {
  const LostlyScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 24),
    this.showBackButton = true,
    this.showHomeShortcut = true,
  });

  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final EdgeInsets padding;
  final bool showBackButton;
  final bool showHomeShortcut;

  @override
  Widget build(BuildContext context) {
    final canPop =
        GoRouter.of(context).canPop() ||
        Navigator.of(context).canPop() ||
        (ModalRoute.of(context)?.canPop ?? false);
    final location = GoRouterState.of(context).matchedLocation;
    final isShellRoot = switch (location) {
      '/home' || '/search' || '/create' || '/chats' || '/profile' => true,
      _ => false,
    };
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shouldShowBackButton = showBackButton && (!isShellRoot || canPop);
    final appBarActions = <Widget>[
      if (showHomeShortcut && !isShellRoot)
        IconButton(
          tooltip: context.l10n.home,
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.home_rounded),
        ),
      ...?actions,
    ];

    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              leading: shouldShowBackButton
                  ? IconButton(
                      tooltip: context.l10n.back,
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).maybePop();
                          return;
                        }
                        if (GoRouter.of(context).canPop()) {
                          context.pop();
                          return;
                        }
                        context.go('/home');
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  : null,
              title: Text(title!),
              actions: appBarActions.isEmpty ? null : appBarActions,
            ),
      floatingActionButton: floatingActionButton,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF071018), Color(0xFF0D1623)]
                : const [Color(0xFFF6F8FC), Color(0xFFFDFEFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: title == null,
          child: Stack(
            children: [
              Positioned(
                top: -120,
                right: -40,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF6BD6B0).withValues(alpha: 0.14),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFF6BD6B0).withValues(alpha: 0.18),
                              Colors.transparent,
                            ],
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}
