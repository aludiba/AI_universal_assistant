import 'package:flutter/foundation.dart';
import '../models/hot_category.dart';
import '../models/writing_category.dart';
import '../services/data_service.dart';
import '../services/storage_service.dart';

class DataProvider with ChangeNotifier {
  final DataService _dataService = DataService();
  final StorageService _storageService = StorageService();

  List<HotCategory> _hotCategories = [];
  List<WritingCategory> _writingCategories = [];
  List<String> _favorites = [];
  List<String> _recentUsed = [];
  List<String> _searchHistory = [];

  List<HotCategory> get hotCategories => _hotCategories;
  List<WritingCategory> get writingCategories => _writingCategories;
  List<String> get favorites => _favorites;
  List<String> get recentUsed => _recentUsed;
  List<String> get searchHistory => _searchHistory;

  /// 加载热门分类
  Future<void> loadHotCategories() async {
    _hotCategories = await _dataService.loadHotCategories();
    notifyListeners();
  }

  /// 加载写作分类
  Future<void> loadWritingCategories() async {
    _writingCategories = await _dataService.loadWritingCategories();
    notifyListeners();
  }

  /// 加载收藏
  Future<void> loadFavorites() async {
    _favorites = await _storageService.getFavorites();
    notifyListeners();
  }

  /// 添加收藏
  Future<void> addFavorite(String itemId) async {
    await _storageService.addFavorite(itemId);
    await loadFavorites();
  }

  /// 移除收藏
  Future<void> removeFavorite(String itemId) async {
    await _storageService.removeFavorite(itemId);
    await loadFavorites();
  }

  /// 是否收藏
  bool isFavorite(String itemId) {
    return _favorites.contains(itemId);
  }

  /// 加载最近使用
  Future<void> loadRecentUsed() async {
    _recentUsed = await _storageService.getRecentUsed();
    notifyListeners();
  }

  /// 添加最近使用
  Future<void> addRecentUsed(String itemId) async {
    await _storageService.addRecentUsed(itemId);
    await loadRecentUsed();
  }

  /// 清除最近使用
  Future<void> clearRecentUsed() async {
    await _storageService.clearRecentUsed();
    await loadRecentUsed();
  }

  /// 加载搜索历史
  Future<void> loadSearchHistory() async {
    _searchHistory = await _storageService.getSearchHistory();
    notifyListeners();
  }

  /// 添加搜索历史
  Future<void> addSearchHistory(String keyword) async {
    await _storageService.addSearchHistory(keyword);
    await loadSearchHistory();
  }

  /// 清除搜索历史
  Future<void> clearSearchHistory() async {
    await _storageService.clearSearchHistory();
    await loadSearchHistory();
  }

  /// 计算缓存大小
  Future<int> calculateCacheSize() async {
    return await _storageService.calculateCacheSize();
  }

  /// 清理缓存
  Future<void> clearCache() async {
    await _storageService.clearCache();
    await loadRecentUsed();
    await loadSearchHistory();
  }
}

