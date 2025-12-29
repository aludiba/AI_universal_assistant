import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/hot_provider.dart';
import '../../providers/hot_search_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';

/// 热门搜索页面
class HotSearchScreen extends StatelessWidget {
  const HotSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchProvider = context.watch<HotSearchProvider>();
    final hotProvider = context.read<HotProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchProvider.searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.searchPlaceholder,
            border: InputBorder.none,
          ),
          onChanged: (query) => searchProvider.performSearch(query, hotProvider),
        ),
      ),
      body: searchProvider.hasResults
          ? ListView.builder(
              itemCount: searchProvider.searchResults.length,
              itemBuilder: (context, index) {
                final item = searchProvider.searchResults[index];
                return ListTile(
                  title: Text(item.title),
                  subtitle: Text(item.subtitle),
                  onTap: () {
                    context.goNamed(AppRoute.hotWrite.name, extra: item);
                  },
                );
              },
            )
          : Center(
              child: Text(l10n.searchEnterKeyword),
            ),
    );
  }
}
