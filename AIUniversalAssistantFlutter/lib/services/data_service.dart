import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/hot_category.dart';
import '../models/writing_category.dart';

class DataService {
  /// 加载热门分类
  Future<List<HotCategory>> loadHotCategories() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/hot_categories.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => HotCategory.fromJson(json)).toList();
    } catch (e) {
      print('加载热门分类失败: $e');
      return [];
    }
  }

  /// 加载写作分类
  Future<List<WritingCategory>> loadWritingCategories() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/writing_categories.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => WritingCategory.fromJson(json)).toList();
    } catch (e) {
      print('加载写作分类失败: $e');
      return [];
    }
  }
}

