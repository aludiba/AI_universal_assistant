import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../utils/app_localizations_helper.dart';
import '../../widgets/card_widget.dart';
import '../../widgets/empty_widget.dart';
import '../writing_input/writing_input_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DataService _dataService = DataService();
  List<String> _searchHistory = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final history = await _dataService.getSearchHistory();
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // 添加到搜索历史
    await _dataService.addSearchHistory(keyword);
    await _loadSearchHistory();

    // 这里应该实现实际的搜索逻辑
    // 简化处理：搜索所有分类
    setState(() {
      _searchResults = []; // TODO: 实现搜索逻辑
      _isSearching = false;
    });
  }

  void _clearSearchHistory() async {
    await _dataService.clearSearchHistory();
    setState(() {
      _searchHistory = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.l10n.searchPlaceholder,
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                      });
                    },
                  )
                : null,
          ),
          onSubmitted: _performSearch,
          onChanged: (value) {
            setState(() {});
          },
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? _buildSearchHistory()
              : _buildSearchResults(),
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return const EmptyWidget(message: '暂无搜索历史');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.translate('search_history'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: _clearSearchHistory,
              child: Text(context.l10n.translate('delete')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._searchHistory.map(
          (keyword) => ListTile(
            leading: const Icon(Icons.history),
            title: Text(keyword),
            onTap: () {
              _searchController.text = keyword;
              _performSearch(keyword);
            },
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () async {
                _searchHistory.remove(keyword);
                await _dataService.saveSearchHistory(_searchHistory);
                setState(() {});
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return EmptyWidget(
        message: context.l10n.translate('no_related_templates_found'),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: _searchResults.map(
        (item) => CardWidget(
          title: item['title'] ?? '',
          subtitle: item['subtitle'] ?? '',
          iconName: item['icon'] ?? '',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => WritingInputScreen(template: item),
              ),
            );
          },
        ),
      ).toList(),
    );
  }
}

