import 'package:flutter/material.dart';
import '../models/hot_item_model.dart';
import '../services/hot_service.dart';

/// 热门页面状态管理
class HotProvider with ChangeNotifier {
  final _hotService = HotService();
  
  List<HotCategoryModel> _categories = [];
  int _selectedCategoryIndex = 0;
  List<HotItemModel> _currentItems = [];
  List<HotItemModel> _favoriteItems = [];
  List<HotItemModel> _recentUsedItems = [];
  bool _isLoading = false;
  Locale? _currentLocale;
  
  List<HotCategoryModel> get categories => _categories;
  int get selectedCategoryIndex => _selectedCategoryIndex;
  List<HotItemModel> get currentItems => _currentItems;
  List<HotItemModel> get favoriteItems => _favoriteItems;
  List<HotItemModel> get recentUsedItems => _recentUsedItems;
  bool get isLoading => _isLoading;
  
  HotCategoryModel? get selectedCategory {
    if (_selectedCategoryIndex < _categories.length) {
      return _categories[_selectedCategoryIndex];
    }
    return null;
  }
  
  bool get isFavoriteCategorySelected {
    return selectedCategory?.isFavoriteCategory ?? false;
  }
  
  /// 初始化数据
  Future<void> init({Locale? locale}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentLocale = locale;
      _categories = await _hotService.loadHotCategories(localeOverride: locale);
      await refreshFavorites();
      await refreshRecentUsed();
      await updateContentForSelectedCategory();
    } catch (e) {
      debugPrint('Error initializing hot provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 当系统/应用语言变化时，重新加载本地 JSON（用于让本地模板随语言切换）
  Future<void> ensureLocale(Locale locale) async {
    if (_currentLocale?.languageCode == locale.languageCode) return;
    _currentLocale = locale;
    _categories = await _hotService.loadHotCategories(localeOverride: locale);
    // 语言切换后，保持索引不变，但需要刷新当前内容
    await updateContentForSelectedCategory();
  }
  
  /// 切换分类
  void selectCategory(int index) {
    if (index >= 0 && index < _categories.length) {
      _selectedCategoryIndex = index;
      updateContentForSelectedCategory();
    }
  }
  
  /// 更新当前分类的内容
  Future<void> updateContentForSelectedCategory() async {
    if (selectedCategory == null) return;
    
    if (selectedCategory!.isFavoriteCategory) {
      // 收藏分类 - 不需要加载items
      _currentItems = [];
    } else {
      // 常规分类
      _currentItems = _hotService.getItemsForCategory(selectedCategory!.id);
    }
    
    notifyListeners();
  }
  
  /// 刷新收藏数据
  Future<void> refreshFavorites() async {
    _favoriteItems = await _hotService.getFavorites();
    notifyListeners();
  }
  
  /// 刷新最近使用数据
  Future<void> refreshRecentUsed() async {
    _recentUsedItems = await _hotService.getRecentUsed();
    notifyListeners();
  }
  
  /// 切换收藏状态
  Future<void> toggleFavorite(HotItemModel item) async {
    final isFav = await _hotService.isFavorite(item.id);
    
    if (isFav) {
      await _hotService.removeFavorite(item.id);
    } else {
      await _hotService.addFavorite(item);
    }
    
    await refreshFavorites();
  }
  
  /// 检查是否已收藏
  Future<bool> isFavorite(String itemId) async {
    return await _hotService.isFavorite(itemId);
  }
  
  /// 添加最近使用
  Future<void> addRecentUsed(HotItemModel item) async {
    await _hotService.addRecentUsed(item);
    await refreshRecentUsed();
  }
  
  /// 清空最近使用
  Future<void> clearRecentUsed() async {
    await _hotService.clearRecentUsed();
    await refreshRecentUsed();
  }
}

