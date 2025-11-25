import 'package:flutter/material.dart';
import 'hot/hot_screen.dart';
import 'writer/writer_screen.dart';
import 'docs/docs_screen.dart';
import 'settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HotScreen(),
    const WriterScreen(),
    const DocsScreen(),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.whatshot),
            label: '热门',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: '写作',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: '文档',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

