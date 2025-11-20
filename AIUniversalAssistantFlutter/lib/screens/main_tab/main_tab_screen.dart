import 'package:flutter/material.dart';
import '../hot/hot_screen.dart';
import '../writer/writer_screen.dart';
import '../docs/documents_screen.dart';
import '../settings/settings_screen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HotScreen(),
    const WriterScreen(),
    const DocumentsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department),
            activeIcon: Icon(Icons.local_fire_department),
            label: '热门',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            activeIcon: Icon(Icons.edit),
            label: '写作',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            activeIcon: Icon(Icons.description),
            label: '文档',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            activeIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

