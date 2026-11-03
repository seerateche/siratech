import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/l10n.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    final l = L10n(Localizations.localeOf(context).languageCode);
    return Scaffold(
      body: widget.shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: (i) => widget.shell.goBranch(i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.history), label: l.t('history')),
          NavigationDestination(icon: const Icon(Icons.add_circle_outline), label: l.t('newOrder')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l.t('settings')),
        ],
      ),
    );
  }
}
