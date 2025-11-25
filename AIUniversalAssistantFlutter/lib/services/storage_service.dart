import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFavorites = 'favorites';
  static const String _keyRecentUsed = 'recent_used';
  static const String _keySearchHistory = 'search_history';
  static const String _keyVIPGift = 'vip_gift';
  static const String _keyWordPacks = 'word_packs';
  static const String _keyConsumedWords = 'consumed_words';
  static const String _keyLastRefreshDate = 'last_refresh_date';
  static const String _keySubscription = 'subscription';

  // 收藏
  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyFavorites);
    if (json == null) return [];
    return List<String>.from(jsonDecode(json));
  }

  Future<void> saveFavorites(List<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFavorites, jsonEncode(favorites));
  }

  Future<bool> isFavorite(String itemId) async {
    final favorites = await getFavorites();
    return favorites.contains(itemId);
  }

  Future<void> addFavorite(String itemId) async {
    final favorites = await getFavorites();
    if (!favorites.contains(itemId)) {
      favorites.add(itemId);
      await saveFavorites(favorites);
    }
  }

  Future<void> removeFavorite(String itemId) async {
    final favorites = await getFavorites();
    favorites.remove(itemId);
    await saveFavorites(favorites);
  }

  // 最近使用
  Future<List<String>> getRecentUsed() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyRecentUsed);
    if (json == null) return [];
    return List<String>.from(jsonDecode(json));
  }

  Future<void> saveRecentUsed(List<String> recentUsed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRecentUsed, jsonEncode(recentUsed));
  }

  Future<void> addRecentUsed(String itemId) async {
    final recentUsed = await getRecentUsed();
    recentUsed.remove(itemId);
    recentUsed.insert(0, itemId);
    if (recentUsed.length > 20) {
      recentUsed.removeLast();
    }
    await saveRecentUsed(recentUsed);
  }

  Future<void> clearRecentUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRecentUsed);
  }

  // 搜索历史
  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keySearchHistory);
    if (json == null) return [];
    return List<String>.from(jsonDecode(json));
  }

  Future<void> saveSearchHistory(List<String> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySearchHistory, jsonEncode(history));
  }

  Future<void> addSearchHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;
    final history = await getSearchHistory();
    history.remove(keyword);
    history.insert(0, keyword);
    if (history.length > 20) {
      history.removeLast();
    }
    await saveSearchHistory(history);
  }

  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySearchHistory);
  }

  // 字数包相关
  Future<void> saveWordPacks(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWordPacks, json);
  }

  Future<String?> getWordPacks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyWordPacks);
  }

  Future<void> saveVIPGift(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVIPGift, json);
  }

  Future<String?> getVIPGift() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyVIPGift);
  }

  Future<void> saveConsumedWords(int words) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyConsumedWords, words);
  }

  Future<int> getConsumedWords() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyConsumedWords) ?? 0;
  }

  Future<void> saveLastRefreshDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastRefreshDate, date);
  }

  Future<String?> getLastRefreshDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastRefreshDate);
  }

  // 订阅信息
  Future<void> saveSubscription(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySubscription, json);
  }

  Future<String?> getSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySubscription);
  }

  // 计算缓存大小
  Future<int> calculateCacheSize() async {
    int size = 0;
    final prefs = await SharedPreferences.getInstance();
    
    final recentUsed = prefs.getString(_keyRecentUsed);
    if (recentUsed != null) {
      size += recentUsed.length;
    }
    
    final searchHistory = prefs.getString(_keySearchHistory);
    if (searchHistory != null) {
      size += searchHistory.length;
    }
    
    return size;
  }

  // 清理缓存
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRecentUsed);
    await prefs.remove(_keySearchHistory);
  }
}

