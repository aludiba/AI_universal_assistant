import 'package:flutter/material.dart';
import '../models/hot_item_model.dart';
import 'hot_provider.dart';

/// 热门搜索页面状态管理
class HotSearchProvider with ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  List<HotItemModel> _searchResults = [];
  
  List<HotItemModel> get searchResults => _searchResults;
  bool get hasResults => _searchResults.isNotEmpty;
  
  /// 执行搜索
  void performSearch(String query, HotProvider hotProvider) {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    final allItems = <HotItemModel>[];
    
    for (var category in hotProvider.categories) {
      if (!category.isFavoriteCategory) {
        allItems.addAll(category.items);
      }
    }
    
    _searchResults = allItems.where((item) {
      return item.title.contains(query) ||
          item.subtitle.contains(query) ||
          item.categoryTitle.contains(query);
    }).toList();
    
    notifyListeners();
  }
  
  /// 清空搜索结果
  void clearResults() {
    _searchResults = [];
    searchController.clear();
    notifyListeners();
  }
  
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

