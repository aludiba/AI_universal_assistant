import 'dart:convert';
import 'dart:ui' show Locale, PlatformDispatcher;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/hot_item_model.dart';
import 'storage_service.dart';

/// 热门数据服务
class HotService {
  static final HotService _instance = HotService._internal();
  factory HotService() => _instance;
  HotService._internal();
  
  final _storageService = StorageService();
  
  List<HotCategoryModel>? _categories;
  String? _loadedLanguageCode;
  
  /// 加载热门分类数据
  Future<List<HotCategoryModel>> loadHotCategories({Locale? localeOverride}) async {
    final locale = localeOverride ?? PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode.toLowerCase();
    if (_categories != null && _loadedLanguageCode == languageCode) {
      return _categories!;
    }
    
    try {
      final assetPath = _assetPathForLanguage(languageCode);
      final String jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> jsonList = jsonDecode(jsonString) as List;
      _categories = jsonList
          .map((json) => HotCategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
      _loadedLanguageCode = languageCode;
      return _categories!;
    } catch (e) {
      debugPrint('Error loading hot categories: $e');
      return [];
    }
  }

  String _assetPathForLanguage(String languageCode) {
    switch (languageCode) {
      case 'ja':
        return 'assets/hot_categories_ja.json';
      case 'en':
        return 'assets/hot_categories_en.json';
      case 'zh':
      case 'zh_hans':
      case 'zh_hant':
      default:
        return 'assets/hot_categories.json';
    }
  }
  
  /// 获取分类的所有项目
  List<HotItemModel> getItemsForCategory(String categoryId) {
    if (_categories == null) return [];
    
    try {
      final category = _categories!.firstWhere((c) => c.id == categoryId);
      return category.items;
    } catch (e) {
      return [];
    }
  }
  
  /// 判断是否为收藏分类
  bool isFavoriteCategory(HotCategoryModel category) {
    return category.isFavoriteCategory;
  }
  
  /// 添加收藏
  Future<void> addFavorite(HotItemModel item) async {
    final favorites = await getFavorites();
    final itemId = item.id;
    
    // 如果已经收藏，不重复添加
    if (favorites.any((f) => f.id == itemId)) {
      return;
    }
    
    favorites.insert(0, item);
    await _saveFavorites(favorites);
  }
  
  /// 移除收藏
  Future<void> removeFavorite(String itemId) async {
    final favorites = await getFavorites();
    favorites.removeWhere((item) => item.id == itemId);
    await _saveFavorites(favorites);
  }
  
  /// 是否已收藏
  Future<bool> isFavorite(String itemId) async {
    final favorites = await getFavorites();
    return favorites.any((item) => item.id == itemId);
  }
  
  /// 获取所有收藏
  Future<List<HotItemModel>> getFavorites() async {
    final data = _storageService.prefs.getString('hot_favorites');
    if (data == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(data) as List;
      return jsonList
          .map((json) => HotItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// 保存收藏列表
  Future<void> _saveFavorites(List<HotItemModel> favorites) async {
    final jsonString = jsonEncode(favorites.map((e) => e.toJson()).toList());
    await _storageService.prefs.setString('hot_favorites', jsonString);
  }
  
  /// 添加最近使用
  Future<void> addRecentUsed(HotItemModel item) async {
    final recentUsed = await getRecentUsed();
    final itemId = item.id;
    
    // 移除已存在的相同项
    recentUsed.removeWhere((r) => r.id == itemId);
    
    // 添加到最前面
    recentUsed.insert(0, item);
    
    // 最多保留20条
    if (recentUsed.length > 20) {
      recentUsed.removeRange(20, recentUsed.length);
    }
    
    await _saveRecentUsed(recentUsed);
  }
  
  /// 获取最近使用
  Future<List<HotItemModel>> getRecentUsed() async {
    final data = _storageService.prefs.getString('hot_recent_used');
    if (data == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(data) as List;
      return jsonList
          .map((json) => HotItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// 保存最近使用列表
  Future<void> _saveRecentUsed(List<HotItemModel> recentUsed) async {
    final jsonString = jsonEncode(recentUsed.map((e) => e.toJson()).toList());
    await _storageService.prefs.setString('hot_recent_used', jsonString);
  }
  
  /// 清空最近使用
  Future<void> clearRecentUsed() async {
    await _storageService.prefs.remove('hot_recent_used');
  }
}

