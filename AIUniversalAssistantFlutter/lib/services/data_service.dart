import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/writing_model.dart';

/// 数据管理服务
class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // 收藏
  static const String _keyFavorites = 'favorites';
  // 最近使用
  static const String _keyRecentUsed = 'recent_used';
  // 搜索历史
  static const String _keySearchHistory = 'search_history';

  /// 获取收藏列表
  Future<List<Map<String, dynamic>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_keyFavorites);
    if (favoritesJson == null) {
      return [];
    }
    return List<Map<String, dynamic>>.from(jsonDecode(favoritesJson));
  }

  /// 添加收藏
  Future<void> addFavorite(Map<String, dynamic> item) async {
    final favorites = await getFavorites();
    if (!favorites.any((f) => f['id'] == item['id'])) {
      favorites.add(item);
      await _saveFavorites(favorites);
    }
  }

  /// 移除收藏
  Future<void> removeFavorite(String itemId) async {
    final favorites = await getFavorites();
    favorites.removeWhere((f) => f['id'] == itemId);
    await _saveFavorites(favorites);
  }

  /// 检查是否收藏
  Future<bool> isFavorite(String itemId) async {
    final favorites = await getFavorites();
    return favorites.any((f) => f['id'] == itemId);
  }

  /// 获取最近使用
  Future<List<Map<String, dynamic>>> getRecentUsed() async {
    final prefs = await SharedPreferences.getInstance();
    final recentJson = prefs.getString(_keyRecentUsed);
    if (recentJson == null) {
      return [];
    }
    return List<Map<String, dynamic>>.from(jsonDecode(recentJson));
  }

  /// 添加最近使用
  Future<void> addRecentUsed(Map<String, dynamic> item) async {
    final recent = await getRecentUsed();
    // 移除重复项
    recent.removeWhere((r) => r['id'] == item['id']);
    // 添加到开头
    recent.insert(0, item);
    // 限制数量
    if (recent.length > 50) {
      recent.removeRange(50, recent.length);
    }
    await _saveRecentUsed(recent);
  }

  /// 清空最近使用
  Future<void> clearRecentUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRecentUsed);
  }

  /// 获取搜索历史
  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_keySearchHistory);
    if (historyJson == null) {
      return [];
    }
    return List<String>.from(jsonDecode(historyJson));
  }

  /// 保存搜索历史
  Future<void> saveSearchHistory(List<String> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySearchHistory, jsonEncode(history));
  }

  /// 添加搜索记录
  Future<void> addSearchHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;
    
    final history = await getSearchHistory();
    history.remove(keyword);
    history.insert(0, keyword);
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    await saveSearchHistory(history);
  }

  /// 清空搜索历史
  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySearchHistory);
  }

  /// 保存写作记录
  Future<void> saveWritingRecord(WritingRecord record) async {
    final file = await _getWritingsFile();
    final records = await loadAllWritings();
    
    // 更新或添加
    final index = records.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    
    final json = jsonEncode(records.map((r) => r.toJson()).toList());
    await file.writeAsString(json);
  }

  /// 加载所有写作记录
  Future<List<WritingRecord>> loadAllWritings() async {
    final file = await _getWritingsFile();
    if (!await file.exists()) {
      return [];
    }
    
    try {
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((json) => WritingRecord.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 根据类型加载写作记录
  Future<List<WritingRecord>> loadWritingsByType(String type) async {
    final all = await loadAllWritings();
    return all.where((w) => w.type == type).toList();
  }

  /// 删除写作记录
  Future<bool> deleteWriting(String writingId) async {
    final records = await loadAllWritings();
    final originalLength = records.length;
    records.removeWhere((r) => r.id == writingId);
    
    if (records.length < originalLength) {
      final file = await _getWritingsFile();
      final json = jsonEncode(records.map((r) => r.toJson()).toList());
      await file.writeAsString(json);
      return true;
    }
    return false;
  }

  /// 保存文档
  Future<void> saveDocument(Document document) async {
    final file = await _getDocumentsFile();
    final documents = await loadAllDocuments();
    
    final index = documents.indexWhere((d) => d.id == document.id);
    if (index >= 0) {
      documents[index] = document;
    } else {
      documents.add(document);
    }
    
    final json = jsonEncode(documents.map((d) => d.toJson()).toList());
    await file.writeAsString(json);
  }

  /// 加载所有文档
  Future<List<Document>> loadAllDocuments() async {
    final file = await _getDocumentsFile();
    if (!await file.exists()) {
      return [];
    }
    
    try {
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((json) => Document.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 删除文档
  Future<bool> deleteDocument(String documentId) async {
    final documents = await loadAllDocuments();
    final originalLength = documents.length;
    documents.removeWhere((d) => d.id == documentId);
    
    if (documents.length < originalLength) {
      final file = await _getDocumentsFile();
      final json = jsonEncode(documents.map((d) => d.toJson()).toList());
      await file.writeAsString(json);
      return true;
    }
    return false;
  }

  /// 清理缓存
  Future<void> clearCache() async {
    await clearRecentUsed();
    await clearSearchHistory();
    // 不删除收藏和写作记录
  }

  Future<void> _saveFavorites(List<Map<String, dynamic>> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFavorites, jsonEncode(favorites));
  }

  Future<void> _saveRecentUsed(List<Map<String, dynamic>> recent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRecentUsed, jsonEncode(recent));
  }

  Future<File> _getWritingsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/writings.json');
  }

  Future<File> _getDocumentsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/documents.json');
  }
}

