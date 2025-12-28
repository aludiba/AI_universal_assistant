import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hot_provider.dart';
import '../../models/hot_item_model.dart';
import '../../l10n/app_localizations.dart';
import 'hot_writing_input_screen.dart';

/// 热门搜索页面
class HotSearchScreen extends StatefulWidget {
  const HotSearchScreen({super.key});

  @override
  State<HotSearchScreen> createState() => _HotSearchScreenState();
}

class _HotSearchScreenState extends State<HotSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<HotItemModel> _searchResults = [];
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.searchPlaceholder,
            border: InputBorder.none,
          ),
          onChanged: _performSearch,
        ),
      ),
      body: _searchResults.isEmpty
          ? Center(
              child: Text(l10n.searchEnterKeyword),
            )
          : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                return ListTile(
                  title: Text(item.title),
                  subtitle: Text(item.subtitle),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HotWritingInputScreen(item: item),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
  
  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    
    final provider = context.read<HotProvider>();
    final allItems = <HotItemModel>[];
    
    for (var category in provider.categories) {
      if (!category.isFavoriteCategory) {
        allItems.addAll(category.items);
      }
    }
    
    setState(() {
      _searchResults = allItems.where((item) {
        return item.title.contains(query) ||
            item.subtitle.contains(query) ||
            item.categoryTitle.contains(query);
      }).toList();
    });
  }
}

