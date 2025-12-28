import 'package:flutter/material.dart';
import '../hot/hot_screen.dart';
import '../writer/writer_screen.dart';
import '../docs/docs_screen.dart';
import '../settings/settings_screen.dart';
import '../../l10n/app_localizations.dart';

/// 主界面 - TabBar导航
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HotScreen(),
    const WriterScreen(),
    const DocsScreen(),
    const SettingsScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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

