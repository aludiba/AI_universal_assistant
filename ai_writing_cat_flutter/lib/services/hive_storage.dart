import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive 存储服务（纯 Dart 实现，支持所有平台包括鸿蒙）
class HiveStorage {
  static final HiveStorage _instance = HiveStorage._internal();
  factory HiveStorage() => _instance;
  HiveStorage._internal();

  Box? _box;
  bool _initialized = false;

  /// 初始化 Hive
  Future<void> init() async {
    if (_initialized) return;
    
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox('app_storage');
      _initialized = true;
      debugPrint('✅ Hive 初始化成功');
    } catch (e, stackTrace) {
      debugPrint('❌ Hive 初始化失败: $e');
      debugPrint('Stack: $stackTrace');
      rethrow;
    }
  }

  /// 获取字符串
  String? getString(String key) {
    try {
      return _box?.get(key) as String?;
    } catch (e) {
      debugPrint('Hive getString error for key $key: $e');
      return null;
    }
  }

  /// 设置字符串
  Future<bool> setString(String key, String value) async {
    try {
      await _box?.put(key, value);
      return true;
    } catch (e) {
      debugPrint('Hive setString error for key $key: $e');
      return false;
    }
  }

  /// 获取字符串列表
  List<String>? getStringList(String key) {
    try {
      final value = _box?.get(key);
      if (value is List) {
        return List<String>.from(value);
      }
      return null;
    } catch (e) {
      debugPrint('Hive getStringList error for key $key: $e');
      return null;
    }
  }

  /// 设置字符串列表
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      await _box?.put(key, value);
      return true;
    } catch (e) {
      debugPrint('Hive setStringList error for key $key: $e');
      return false;
    }
  }

  /// 获取整数
  int? getInt(String key) {
    try {
      return _box?.get(key) as int?;
    } catch (e) {
      debugPrint('Hive getInt error for key $key: $e');
      return null;
    }
  }

  /// 设置整数
  Future<bool> setInt(String key, int value) async {
    try {
      await _box?.put(key, value);
      return true;
    } catch (e) {
      debugPrint('Hive setInt error for key $key: $e');
      return false;
    }
  }

  /// 获取布尔值
  bool? getBool(String key) {
    try {
      return _box?.get(key) as bool?;
    } catch (e) {
      debugPrint('Hive getBool error for key $key: $e');
      return null;
    }
  }

  /// 设置布尔值
  Future<bool> setBool(String key, bool value) async {
    try {
      await _box?.put(key, value);
      return true;
    } catch (e) {
      debugPrint('Hive setBool error for key $key: $e');
      return false;
    }
  }

  /// 移除键
  Future<bool> remove(String key) async {
    try {
      await _box?.delete(key);
      return true;
    } catch (e) {
      debugPrint('Hive remove error for key $key: $e');
      return false;
    }
  }

  /// 清空所有数据
  Future<bool> clear() async {
    try {
      await _box?.clear();
      return true;
    } catch (e) {
      debugPrint('Hive clear error: $e');
      return false;
    }
  }

  /// 检查键是否存在
  bool containsKey(String key) {
    return _box?.containsKey(key) ?? false;
  }

  /// 获取所有键
  Iterable<String> getKeys() {
    return _box?.keys.cast<String>() ?? [];
  }
}
