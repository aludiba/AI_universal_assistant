import 'dart:convert';
import 'package:flutter/services.dart';

/// 数据加载服务
class DataLoaderService {
  static final DataLoaderService _instance = DataLoaderService._internal();
  factory DataLoaderService() => _instance;
  DataLoaderService._internal();

  List<Map<String, dynamic>>? _hotCategories;
  List<Map<String, dynamic>>? _writingCategories;

  /// 加载热门分类数据
  Future<List<Map<String, dynamic>>> loadHotCategories() async {
    if (_hotCategories != null) {
      return _hotCategories!;
    }

    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/hot_categories.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _hotCategories = jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
      return _hotCategories!;
    } catch (e) {
      print('加载热门分类数据失败: $e');
      return [];
    }
  }

  /// 加载写作分类数据
  Future<List<Map<String, dynamic>>> loadWritingCategories() async {
    if (_writingCategories != null) {
      return _writingCategories!;
    }

    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/writing_categories.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _writingCategories = jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
      return _writingCategories!;
    } catch (e) {
      print('加载写作分类数据失败: $e');
      return [];
    }
  }

  /// 根据分类ID获取项目列表
  Future<List<Map<String, dynamic>>> getItemsForCategory(String categoryId) async {
    final categories = await loadHotCategories();
    for (var category in categories) {
      if (category['id'] == categoryId) {
        final items = category['items'] as List<dynamic>?;
        return items?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
      }
    }
    return [];
  }

  /// 清除缓存
  void clearCache() {
    _hotCategories = null;
    _writingCategories = null;
  }
}

