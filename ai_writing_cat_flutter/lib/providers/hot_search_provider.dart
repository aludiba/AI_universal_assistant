import 'package:flutter/material.dart';
import '../models/hot_item_model.dart';
import '../services/storage_service.dart';
import 'hot_provider.dart';

/// 热门搜索页面状态管理
class HotSearchProvider with ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  final _storageService = StorageService();
  
  List<HotItemModel> _searchResults = [];
  List<String> _historySearches = [];
  bool _isSearching = false;
  bool _hasSearchText = false;
  
  List<HotItemModel> get searchResults => _searchResults;
  List<String> get historySearches => _historySearches;
  bool get isSearching => _isSearching;
  bool get showHistory => !_isSearching && _historySearches.isNotEmpty;
  bool get hasResults => _searchResults.isNotEmpty;
  bool get showEmptyView => _isSearching && _searchResults.isEmpty;
  
  /// 搜索框是否有文本
  bool get hasSearchText => _hasSearchText;
  
  /// 初始化，加载历史搜索
  Future<void> init() async {
    await loadHistorySearches();
  }
  
  /// 加载历史搜索
  Future<void> loadHistorySearches() async {
    _historySearches = _storageService.getSearchHistory();
    notifyListeners();
  }
  
  /// 执行搜索
  void performSearch(String query, HotProvider hotProvider) {
    _hasSearchText = query.isNotEmpty;
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }
    
    _isSearching = true;
    
    final allItems = <HotItemModel>[];
    
    for (var category in hotProvider.categories) {
      if (!category.isFavoriteCategory) {
        allItems.addAll(category.items);
      }
    }
    
    _searchResults = allItems.where((item) {
      return item.title.toLowerCase().contains(query.toLowerCase());
    }).toList();
    
    notifyListeners();
  }
  
  /// 添加到历史搜索
  Future<void> addToHistory(String searchText) async {
    if (searchText.isEmpty) return;
    
    _historySearches.remove(searchText);
    _historySearches.insert(0, searchText);
    
    if (_historySearches.length > 20) {
      _historySearches.removeRange(20, _historySearches.length);
    }
    
    await _storageService.saveSearchHistory(_historySearches);
    notifyListeners();
  }
  
  /// 清空历史搜索
  Future<void> clearHistory() async {
    _historySearches.clear();
    await _storageService.clearSearchHistory();
    notifyListeners();
  }
  
  /// 点击历史搜索项
  void selectHistoryItem(String historyText) {
    searchController.text = historyText;
    _hasSearchText = historyText.isNotEmpty;
    notifyListeners();
  }
  
  /// 清空搜索
  void clearSearch() {
    searchController.clear();
    _searchResults = [];
    _isSearching = false;
    _hasSearchText = false;
    notifyListeners();
  }

  /// 进入搜索页时的“会话重置”
  /// - 仅在确实有残留状态时才 notify，避免不必要的 UI 抖动
  void resetSessionIfNeeded() {
    final needReset =
        searchController.text.isNotEmpty || _searchResults.isNotEmpty || _isSearching || _hasSearchText;
    if (!needReset) return;
    searchController.clear();
    _searchResults = [];
    _isSearching = false;
    _hasSearchText = false;
    notifyListeners();
  }
  
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

