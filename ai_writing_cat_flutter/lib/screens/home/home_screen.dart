import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

/// 主界面 - TabBar导航
class HomeScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_fire_department_outlined),
            activeIcon: const Icon(Icons.local_fire_department),
            label: l10n.tabHot,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.edit_outlined),
            activeIcon: const Icon(Icons.edit),
            label: l10n.tabWriter,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.description_outlined),
            activeIcon: const Icon(Icons.description),
            label: l10n.tabDocs,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: l10n.tabSettings,
          ),
        ],
      ),
    );
  }
}

