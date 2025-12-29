import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/hot_item_model.dart';
import '../models/template_model.dart';
import '../screens/docs/docs_screen.dart';
import '../screens/docs/document_detail_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/hot/hot_screen.dart';
import '../screens/hot/hot_search_screen.dart';
import '../screens/hot/hot_writing_input_screen.dart';
import '../screens/settings/membership_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/word_pack_screen.dart';
import '../screens/writer/ai_writing_screen.dart';
import '../screens/writer/template_detail_screen.dart';
import '../screens/writer/writer_screen.dart';

enum AppRoute {
  hot,
  hotSearch,
  hotWrite,
  writer,
  aiWriting,
  templateDetail,
  docs,
  docDetail,
  settings,
  membership,
  wordPack,
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/hot',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/hot',
                name: AppRoute.hot.name,
                pageBuilder: (context, state) => const NoTransitionPage(child: HotScreen()),
                routes: [
                  GoRoute(
                    path: 'search',
                    name: AppRoute.hotSearch.name,
                    builder: (context, state) => const HotSearchScreen(),
                  ),
                  GoRoute(
                    path: 'write',
                    name: AppRoute.hotWrite.name,
                    builder: (context, state) {
                      final item = state.extra as HotItemModel;
                      return HotWritingInputScreen(item: item);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/writer',
                name: AppRoute.writer.name,
                pageBuilder: (context, state) => const NoTransitionPage(child: WriterScreen()),
                routes: [
                  GoRoute(
                    path: 'ai',
                    name: AppRoute.aiWriting.name,
                    builder: (context, state) {
                      final typeStr = state.uri.queryParameters['type'];
                      final initialContent = state.uri.queryParameters['initialContent'];
                      final type = _parseWritingType(typeStr) ?? WritingType.free;
                      return AIWritingScreen(type: type, initialContent: initialContent);
                    },
                  ),
                  GoRoute(
                    path: 'template',
                    name: AppRoute.templateDetail.name,
                    builder: (context, state) {
                      final template = state.extra as TemplateModel;
                      return TemplateDetailScreen(template: template);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/docs',
                name: AppRoute.docs.name,
                pageBuilder: (context, state) => const NoTransitionPage(child: DocsScreen()),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: AppRoute.docDetail.name,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return DocumentDetailScreen(documentId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: AppRoute.settings.name,
                pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
                routes: [
                  GoRoute(
                    path: 'membership',
                    name: AppRoute.membership.name,
                    builder: (context, state) => const MembershipScreen(),
                  ),
                  GoRoute(
                    path: 'word-pack',
                    name: AppRoute.wordPack.name,
                    builder: (context, state) => const WordPackScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('页面不存在')),
        body: Center(child: Text(state.error?.toString() ?? '页面不存在')),
      );
    },
  );
}

WritingType? _parseWritingType(String? raw) {
  if (raw == null) return null;
  for (final v in WritingType.values) {
    if (v.name == raw) return v;
  }
  return null;
}


