import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/hot_item_model.dart';
import '../../providers/hot_provider.dart';
import '../../providers/hot_search_provider.dart';
import '../../router/app_router.dart';

/// 热门搜索页面
class HotSearchScreen extends StatefulWidget {
  const HotSearchScreen({super.key});

  @override
  State<HotSearchScreen> createState() => _HotSearchScreenState();
}

class _HotSearchScreenState extends State<HotSearchScreen> {
  @override
  void initState() {
    super.initState();
    // 延迟到首帧之后再初始化 Provider，避免在 build 期间触发 notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<HotSearchProvider>();
      p.resetSessionIfNeeded();
      p.init();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchProvider = context.watch<HotSearchProvider>();
    final hotProvider = context.read<HotProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            searchProvider.clearSearch();
            context.pop();
          },
        ),
        title: _buildSearchBar(context, l10n, searchProvider, hotProvider),
        titleSpacing: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: _buildBody(context, l10n, searchProvider),
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    AppLocalizations l10n,
    HotSearchProvider searchProvider,
    HotProvider hotProvider,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    // iOS 版本：width = screenWidth - 68，iOS 26.0+ 为 screenWidth - 88
    final width = screenWidth - 88;

    return Container(
      width: width,
      height: 36,
      margin: const EdgeInsets.only(left: 8, right: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: searchProvider.searchController,
        autofocus: true,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: l10n.enterKeywordsToSearchTemplates,
          hintStyle: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 16,
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]?.withValues(alpha: 0.3)
              : Colors.grey[200]?.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).hintColor,
            size: 20,
          ),
          // 使用 Provider 的响应式属性来控制清除按钮显示
          suffixIcon: searchProvider.hasSearchText
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  color: Theme.of(context).hintColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () {
                    searchProvider.clearSearch();
                  },
                )
              : null,
        ),
        onChanged: (query) {
          searchProvider.performSearch(query, hotProvider);
        },
        onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    HotSearchProvider searchProvider,
  ) {
    // 如果显示空视图，直接返回
    if (searchProvider.showEmptyView) {
      return _buildEmptyView(context, l10n);
    }

    // 构建列表内容
    final children = <Widget>[];

    // 显示历史搜索
    if (searchProvider.showHistory &&
        searchProvider.historySearches.isNotEmpty) {
      children.add(_buildHistoryHeader(context, l10n, searchProvider));
      children.addAll(
        searchProvider.historySearches.asMap().entries.map((entry) {
          final index = entry.key;
          final historyText = entry.value;
          return _buildHistoryCell(
            context,
            historyText,
            index == searchProvider.historySearches.length - 1,
            searchProvider,
          );
        }),
      );
    }

    // 显示搜索结果
    if (searchProvider.isSearching && searchProvider.searchResults.isNotEmpty) {
      children.addAll(
        searchProvider.searchResults.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildSearchResultCell(
            context,
            item,
            index == searchProvider.searchResults.length - 1,
          );
        }),
      );
    }

    // 如果没有内容，返回空widget
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    // 有内容时返回ListView
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: children,
    );
  }

  Widget _buildHistoryHeader(
    BuildContext context,
    AppLocalizations l10n,
    HotSearchProvider searchProvider,
  ) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            l10n.searchHistory,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 24),
            color: Theme.of(context).hintColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () => searchProvider.clearHistory(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCell(
    BuildContext context,
    HotItemModel item,
    bool isLast,
  ) {
    return InkWell(
      onTap: () async {
        await context.read<HotSearchProvider>().addToHistory(item.title);
        if (context.mounted) {
          // 使用 pushNamed 而不是 goNamed，以维护路由栈，返回时会回到搜索页
          context.pushNamed(AppRoute.hotWrite.name, extra: item);
        }
      },
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Theme.of(context).cardColor,
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  _getIconData(item.icon),
                  size: 24,
                  color: const Color(0xFF3366CC), // AIUA_BLUE_COLOR
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).textTheme.titleLarge?.color,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (!isLast)
              Positioned(
                left: 16,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 0.5,
                  color: Theme.of(context).dividerColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCell(
    BuildContext context,
    String historyText,
    bool isLast,
    HotSearchProvider searchProvider,
  ) {
    return InkWell(
      onTap: () {
        searchProvider.selectHistoryItem(historyText);
        searchProvider.performSearch(historyText, context.read<HotProvider>());
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Colors.white,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: Theme.of(context).hintColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      historyText,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Container(
                height: 0.5,
                margin: const EdgeInsets.only(left: 16),
                color: Theme.of(context).dividerColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.noRelatedTemplatesFound,
            style: TextStyle(fontSize: 16, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              // 直接切换到 writer 分支（go 会替换当前 location，搜索页不会残留在栈里）
              context.goNamed(AppRoute.writer.name);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.goToWritingModule,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF3366CC), // AIUA_BLUE_COLOR
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: const Color(0xFF3366CC), // AIUA_BLUE_COLOR
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // 将 iOS SF Symbols 名称映射到 Flutter Material Icons
    final iconMap = {
      'doc.text': Icons.description,
      'doc.text.fill': Icons.description,
      'text.bubble': Icons.chat_bubble_outline,
      'text.bubble.fill': Icons.chat_bubble,
      'envelope': Icons.mail_outline,
      'envelope.fill': Icons.mail,
      'pencil': Icons.edit,
      'pencil.circle': Icons.edit,
      'book': Icons.book,
      'book.fill': Icons.book,
      'note.text': Icons.note,
      'note.text.fill': Icons.note,
    };
    return iconMap[iconName] ?? Icons.description;
  }
}
