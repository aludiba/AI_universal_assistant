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

  /// 判断是否应该显示底部导航栏
  bool _shouldShowBottomNavBar(BuildContext context) {
    try {
      final routerState = GoRouterState.of(context);
      final location = routerState.uri.path;
      
      // 以下路径需要隐藏底部导航栏（子路由页面）
      final hiddenPaths = [
        '/hot/search',
        '/hot/write',
        '/writer/ai',
        '/writer/template',
        '/docs/', // 文档详情页
        '/settings/membership',
        '/settings/word-pack',
      ];
      
      // 检查当前路径是否匹配需要隐藏导航栏的路径
      for (final path in hiddenPaths) {
        if (location.startsWith(path)) {
          return false;
        }
      }
    } catch (e) {
      // 如果获取路由状态失败，默认显示导航栏
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showBottomNavBar = _shouldShowBottomNavBar(context);
    
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: showBottomNavBar
          ? BottomNavigationBar(
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
            )
          : null,
    );
  }
}

