import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale, PlatformDispatcher;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'hive_storage.dart';
import '../models/hot_item_model.dart';
import '../models/writing_record_model.dart';
import '../models/document_model.dart';
import '../models/template_model.dart';
import '../models/subscription_model.dart';
import '../models/word_pack_model.dart';
import '../models/writing_category_model.dart';

/// 数据管理器 - 统一处理数据相关操作
/// 模仿 iOS 项目的 AIUADataManager 类
class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  final HiveStorage _storage = HiveStorage();
  Database? _database;
  List<HotCategoryModel>? _categories;
  String? _loadedLanguageCode;
  List<WritingCategory>? _writingCategories;
  String? _loadedWritingLanguageCode;
  String? _sandboxDirPath;
  File? _favoritesFile;
  File? _recentUsedFile;

  /// 初始化（使用 Hive 纯 Dart 存储）
  Future<void> init() async {
    await _storage.init();
  }

  /// 获取字符串
  String? _getString(String key) => _storage.getString(key);

  /// 设置字符串
  Future<bool> _setString(String key, String value) => _storage.setString(key, value);

  /// 获取字符串列表
  List<String>? _getStringList(String key) => _storage.getStringList(key);

  /// 设置字符串列表
  Future<bool> _setStringList(String key, List<String> value) => _storage.setStringList(key, value);

  /// 获取整数
  int? _getInt(String key) => _storage.getInt(key);

  /// 设置整数
  Future<bool> _setInt(String key, int value) => _storage.setInt(key, value);

  /// 获取布尔值
  bool? _getBool(String key) => _storage.getBool(key);

  /// 设置布尔值
  Future<bool> _setBool(String key, bool value) => _storage.setBool(key, value);

  /// 移除键
  Future<bool> _remove(String key) => _storage.remove(key);

  /// 清空所有数据
  Future<bool> _clear() => _storage.clear();

  // ==================== 数据库相关 ====================

  /// 获取数据库实例
  /// 注意：在鸿蒙等不支持的平台上，如果 sqflite 不可用，会抛出异常
  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      debugPrint('获取数据库实例失败: $e');
      rethrow;
    }
  }

  /// 初始化数据库（在鸿蒙等不支持的平台上会抛出异常，需要调用方处理）
  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = p.join(databasesPath, 'ai_writing_cat.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e, stackTrace) {
      debugPrint('数据库初始化失败（平台可能不支持 sqflite）: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow; // 重新抛出，让调用方处理
    }
  }

  /// 创建表
  Future<void> _onCreate(Database db, int version) async {
    // 文档表
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // 写作记录表
    await db.execute('''
      CREATE TABLE writing_records (
        id TEXT PRIMARY KEY,
        templateId TEXT NOT NULL,
        templateTitle TEXT NOT NULL,
        prompt TEXT NOT NULL,
        generatedContent TEXT,
        wordCount INTEGER,
        createdAt TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 模板表
    await db.execute('''
      CREATE TABLE templates (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        fields TEXT NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        lastUsedAt TEXT
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_documents_updatedAt ON documents(updatedAt)');
    await db.execute('CREATE INDEX idx_writing_records_createdAt ON writing_records(createdAt)');
    await db.execute('CREATE INDEX idx_templates_category ON templates(category)');
  }

  /// 关闭数据库
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // ==================== 热门 ====================

  /// 获取"热门"数据
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

  /// 加载收藏列表
  Future<List<HotItemModel>> loadFavorites() async {
    return _readListFromSandbox(
      file: await _favoritesJsonFile(),
      legacyPrefsKey: 'hot_favorites',
    );
  }

  /// 添加收藏
  Future<void> addFavorite(HotItemModel item) async {
    final favorites = await loadFavorites();
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
    final favorites = await loadFavorites();
    favorites.removeWhere((item) => item.id == itemId);
    await _saveFavorites(favorites);
  }

  /// 是否已收藏
  Future<bool> isFavorite(String itemId) async {
    final favorites = await loadFavorites();
    return favorites.any((item) => item.id == itemId);
  }

  /// 加载最近使用列表
  Future<List<HotItemModel>> loadRecentUsed() async {
    return _readListFromSandbox(
      file: await _recentUsedJsonFile(),
      legacyPrefsKey: 'hot_recent_used',
    );
  }

  /// 添加最近使用
  Future<void> addRecentUsed(HotItemModel item) async {
    final recentUsed = await loadRecentUsed();
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

  /// 清空最近使用
  Future<void> clearRecentUsed() async {
    final file = await _recentUsedJsonFile();
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (e) {
        debugPrint('Error deleting recent used file: $e');
      }
    }
    // 兼容旧版本 prefs
    try {
      await _remove('hot_recent_used');
    } catch (_) {}
  }

  Future<String> _getSandboxDirPath() async {
    if (_sandboxDirPath != null) return _sandboxDirPath!;
    final dir = await getApplicationDocumentsDirectory();
    _sandboxDirPath = dir.path;
    return _sandboxDirPath!;
  }

  Future<File> _favoritesJsonFile() async {
    if (_favoritesFile != null) return _favoritesFile!;
    final dir = await _getSandboxDirPath();
    _favoritesFile = File(p.join(dir, 'hot_favorites.json'));
    return _favoritesFile!;
  }

  Future<File> _recentUsedJsonFile() async {
    if (_recentUsedFile != null) return _recentUsedFile!;
    final dir = await _getSandboxDirPath();
    _recentUsedFile = File(p.join(dir, 'hot_recent_used.json'));
    return _recentUsedFile!;
  }

  Future<List<HotItemModel>> _readListFromSandbox({
    required File file,
    required String legacyPrefsKey,
  }) async {
    // 1) 优先读沙盒文件
    try {
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isEmpty) return [];
        final list = jsonDecode(content);
        if (list is! List) return [];
        return list
            .whereType<Map<String, dynamic>>()
            .map((json) => HotItemModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Error reading ${file.path}: $e');
    }

    // 2) 兼容旧版本：从 SharedPreferences 迁移一次
    try {
      final legacy = _getString(legacyPrefsKey);
      if (legacy == null || legacy.trim().isEmpty) return [];
      final list = jsonDecode(legacy);
      if (list is! List) return [];
      final items = list
          .whereType<Map<String, dynamic>>()
          .map((json) => HotItemModel.fromJson(json))
          .toList();
      await _writeListToSandbox(file: file, legacyPrefsKey: legacyPrefsKey, items: items);
      await _remove(legacyPrefsKey);
      return items;
    } catch (e) {
      debugPrint('Error migrating legacy $legacyPrefsKey: $e');
      return [];
    }
  }

  Future<void> _writeListToSandbox({
    required File file,
    required String legacyPrefsKey,
    required List<HotItemModel> items,
  }) async {
    try {
      final jsonString = jsonEncode(items.map((e) => e.toJson()).toList());
      // 原子写：写 tmp 后 replace
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonString, flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await tmp.rename(file.path);
    } catch (e) {
      debugPrint('Error writing ${file.path}: $e');
      rethrow;
    }
  }

  Future<void> _saveFavorites(List<HotItemModel> favorites) async {
    await _writeListToSandbox(
      file: await _favoritesJsonFile(),
      legacyPrefsKey: 'hot_favorites',
      items: favorites,
    );
  }

  Future<void> _saveRecentUsed(List<HotItemModel> recentUsed) async {
    await _writeListToSandbox(
      file: await _recentUsedJsonFile(),
      legacyPrefsKey: 'hot_recent_used',
      items: recentUsed,
    );
  }

  // ==================== 搜索 ====================

  /// 搜索模块加载所有类别数据（扁平化所有 items）
  Future<List<HotItemModel>> loadSearchCategoriesData() async {
    final categories = await loadHotCategories();
    final List<HotItemModel> allItems = [];
    for (final category in categories) {
      allItems.addAll(category.items);
    }
    return allItems;
  }

  /// 搜索模块加载历史搜索数据
  List<String> loadSearchHistorySearches() {
    return _getStringList('search_history') ?? [];
  }

  /// 搜索模块保存搜索记录
  Future<void> saveHistorySearches(List<String> history) async {
    await _setStringList('search_history', history);
  }

  /// 添加搜索记录
  Future<void> addSearchHistory(String keyword) async {
    final history = loadSearchHistorySearches();
    history.remove(keyword); // 移除重复项
    history.insert(0, keyword); // 插入到最前面
    if (history.length > 20) {
      history.removeRange(20, history.length); // 最多保留20条
    }
    await saveHistorySearches(history);
  }

  /// 清空搜索历史
  Future<void> clearSearchHistory() async {
    await _remove('search_history');
  }

  // ==================== 写作 ====================

  /// 获取"写作"数据
  Future<List<WritingCategory>> loadWritingCategories({Locale? localeOverride}) async {
    final locale = localeOverride ?? PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode.toLowerCase();
    if (_writingCategories != null && _loadedWritingLanguageCode == languageCode) {
      return _writingCategories!;
    }

    try {
      final assetPath = _writingAssetPathForLanguage(languageCode);
      final String jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> jsonList = jsonDecode(jsonString) as List;
      _writingCategories = jsonList
          .map((json) => WritingCategory.fromJson(json as Map<String, dynamic>))
          .toList();
      _loadedWritingLanguageCode = languageCode;
      return _writingCategories!;
    } catch (e) {
      debugPrint('Error loading writing categories: $e');
      return [];
    }
  }

  String _writingAssetPathForLanguage(String languageCode) {
    switch (languageCode) {
      case 'ja':
        return 'assets/writing_categories_ja.json';
      case 'en':
        return 'assets/writing_categories_en.json';
      case 'zh':
      case 'zh_hans':
      case 'zh_hant':
      default:
        return 'assets/writing_categories.json';
    }
  }

  // ==================== 写作详情 ====================

  /// 保存写作详情
  Future<void> saveWritingToPlist(WritingRecordModel writingRecord) async {
    final db = await database;
    final data = writingRecord.toJson();
    data['isCompleted'] = writingRecord.isCompleted ? 1 : 0;
    await db.insert(
      'writing_records',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 加载所有写作记录
  Future<List<WritingRecordModel>> loadAllWritings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'writing_records',
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) {
      final data = Map<String, dynamic>.from(map);
      data['isCompleted'] = map['isCompleted'] == 1;
      return WritingRecordModel.fromJson(data);
    }).toList();
  }

  /// 根据ID获取单条写作记录（用于文档详情保存时同步回创作记录）
  Future<WritingRecordModel?> getWritingRecordById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'writing_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    final data = Map<String, dynamic>.from(maps.first);
    data['isCompleted'] = maps.first['isCompleted'] == 1;
    return WritingRecordModel.fromJson(data);
  }

  /// 根据类型加载写作记录
  Future<List<WritingRecordModel>> loadWritingsByType(String? type) async {
    final allWritings = await loadAllWritings();
    if (type == null || type.isEmpty) {
      return allWritings;
    } else {
      return allWritings;
    }
  }

  /// 根据模板ID加载写作记录（仅展示当前模板的创作记录，与 iOS 一致）
  Future<List<WritingRecordModel>> loadWritingsByTemplateId(String? templateId) async {
    if (templateId == null || templateId.isEmpty) {
      return loadAllWritings();
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'writing_records',
      where: 'templateId = ?',
      whereArgs: [templateId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) {
      final data = Map<String, dynamic>.from(map);
      data['isCompleted'] = map['isCompleted'] == 1;
      return WritingRecordModel.fromJson(data);
    }).toList();
  }

  /// 根据ID删除写作记录
  Future<bool> deleteWritingWithID(String writingID) async {
    try {
      final db = await database;
      await db.delete(
        'writing_records',
        where: 'id = ?',
        whereArgs: [writingID],
      );
      return true;
    } catch (e) {
      debugPrint('删除写作记录失败: $e');
      return false;
    }
  }

  /// 更新写作记录
  Future<void> updateWritingRecord(WritingRecordModel record) async {
    final db = await database;
    final data = record.toJson();
    data['isCompleted'] = record.isCompleted ? 1 : 0;
    await db.update(
      'writing_records',
      data,
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  // ==================== 文档操作 ====================

  /// 插入文档
  Future<void> insertDocument(DocumentModel document) async {
    final db = await database;
    await db.insert(
      'documents',
      document.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新文档
  Future<void> updateDocument(DocumentModel document) async {
    final db = await database;
    // 兼容保留：更新 documents 表
    await db.update(
      'documents',
      document.toJson(),
      where: 'id = ?',
      whereArgs: [document.id],
    );

    // iOS 对齐：文档与创作记录同源，更新文档时同步回写 writing_records
    final existing = await getWritingRecordById(document.id);
    final record = WritingRecordModel(
      id: document.id,
      templateId: existing?.templateId ?? '',
      templateTitle: document.title,
      prompt: existing?.prompt ?? '',
      generatedContent: document.content,
      wordCount: document.content.length,
      // writing_records 无 updatedAt 字段，使用 createdAt 作为列表排序时间
      createdAt: document.updatedAt,
      isCompleted: existing?.isCompleted ?? true,
    );
    await saveWritingToPlist(record);
  }

  /// 删除文档
  Future<void> deleteDocument(String id) async {
    final db = await database;
    // iOS 对齐：文档与创作记录同源，删除文档时删除同 id 创作记录
    await db.delete(
      'writing_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取所有文档
  Future<List<DocumentModel>> getAllDocuments() async {
    // iOS 对齐：文档列表直接来自创作记录同一份数据
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'writing_records',
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) {
      final createdAt = DateTime.tryParse((map['createdAt'] as String?) ?? '') ?? DateTime.now();
      return DocumentModel(
        id: (map['id'] as String?) ?? '',
        title: (map['templateTitle'] as String?) ?? '',
        content: (map['generatedContent'] as String?) ?? '',
        createdAt: createdAt,
        updatedAt: createdAt,
      );
    }).toList();
  }

  /// 根据ID获取文档
  Future<DocumentModel?> getDocumentById(String id) async {
    // iOS 对齐：文档详情读取与创作记录同一份数据
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'writing_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    final map = maps.first;
    final createdAt = DateTime.tryParse((map['createdAt'] as String?) ?? '') ?? DateTime.now();
    return DocumentModel(
      id: (map['id'] as String?) ?? '',
      title: (map['templateTitle'] as String?) ?? '',
      content: (map['generatedContent'] as String?) ?? '',
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  /// 从创作记录确保对应文档存在（用于打开编辑），有则返回，无则创建后返回
  Future<DocumentModel> ensureDocumentFromWritingRecord(WritingRecordModel record) async {
    final existing = await getDocumentById(record.id);
    if (existing != null) return existing;
    final doc = DocumentModel(
      id: record.id,
      title: record.templateTitle,
      content: record.generatedContent ?? '',
      createdAt: record.createdAt,
      updatedAt: record.createdAt,
    );
    await insertDocument(doc);
    return doc;
  }

  /// 从文档确保对应创作记录存在（与 iOS 一致：文档列表与创作记录列表同源）
  /// 文档首页新建文档时调用，使该文档同时出现在创作记录列表
  Future<void> ensureWritingRecordFromDocument(DocumentModel doc) async {
    final existing = await getWritingRecordById(doc.id);
    if (existing != null) return;
    final record = WritingRecordModel(
      id: doc.id,
      templateId: '',
      templateTitle: doc.title,
      prompt: '',
      generatedContent: doc.content,
      wordCount: doc.content.length,
      createdAt: doc.createdAt,
      isCompleted: true,
    );
    await saveWritingToPlist(record);
  }

  // ==================== 模板操作 ====================

  /// 插入或更新模板
  Future<void> upsertTemplate(TemplateModel template) async {
    final db = await database;
    final data = template.toJson();
    data['fields'] = jsonEncode(template.fields.map((e) => e.toJson()).toList());
    data['isFavorite'] = template.isFavorite ? 1 : 0;
    await db.insert(
      'templates',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新模板收藏状态
  Future<void> updateTemplateFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'templates',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 更新模板最后使用时间
  Future<void> updateTemplateLastUsed(String id) async {
    final db = await database;
    await db.update(
      'templates',
      {'lastUsedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取所有模板
  Future<List<TemplateModel>> getAllTemplates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('templates');
    return maps.map((map) {
      final data = Map<String, dynamic>.from(map);
      // 解析 fields JSON 字符串
      if (data['fields'] is String) {
        final fieldsList = jsonDecode(data['fields'] as String) as List;
        data['fields'] = fieldsList;
      }
      return TemplateModel.fromJson(data);
    }).toList();
  }

  /// 根据分类获取模板
  Future<List<TemplateModel>> getTemplatesByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'templates',
      where: 'category = ?',
      whereArgs: [category],
    );
    return maps.map((map) {
      final data = Map<String, dynamic>.from(map);
      if (data['fields'] is String) {
        final fieldsList = jsonDecode(data['fields'] as String) as List;
        data['fields'] = fieldsList;
      }
      return TemplateModel.fromJson(data);
    }).toList();
  }

  /// 获取收藏的模板
  Future<List<TemplateModel>> getFavoriteTemplates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'templates',
      where: 'isFavorite = ?',
      whereArgs: [1],
    );
    return maps.map((map) {
      final data = Map<String, dynamic>.from(map);
      if (data['fields'] is String) {
        final fieldsList = jsonDecode(data['fields'] as String) as List;
        data['fields'] = fieldsList;
      }
      return TemplateModel.fromJson(data);
    }).toList();
  }

  /// 获取最近使用的模板
  Future<List<TemplateModel>> getRecentlyUsedTemplates({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'templates',
      where: 'lastUsedAt IS NOT NULL',
      orderBy: 'lastUsedAt DESC',
      limit: limit,
    );
    return maps.map((map) {
      final data = Map<String, dynamic>.from(map);
      if (data['fields'] is String) {
        final fieldsList = jsonDecode(data['fields'] as String) as List;
        data['fields'] = fieldsList;
      }
      return TemplateModel.fromJson(data);
    }).toList();
  }

  // ==================== 订阅相关 ====================

  /// 保存订阅信息
  Future<void> saveSubscription(SubscriptionModel subscription) async {
    await _setString('subscription', jsonEncode(subscription.toJson()));
  }

  /// 获取订阅信息
  SubscriptionModel? getSubscription() {
    final data = _getString('subscription');
    if (data == null) return null;
    return SubscriptionModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  /// 清除订阅信息
  Future<void> clearSubscription() async {
    await _remove('subscription');
  }

  /// 是否是VIP
  bool get isVip {
    final subscription = getSubscription();
    return subscription?.isVip ?? false;
  }

  // ==================== 字数包相关 ====================

  /// 保存字数包统计
  Future<void> saveWordPackStats(WordPackStats stats) async {
    await _setString('word_pack_stats', jsonEncode(stats.toJson()));
  }

  /// 获取字数包统计
  WordPackStats getWordPackStats() {
    final data = _getString('word_pack_stats');
    if (data == null) {
      return WordPackStats(
        vipGiftWords: 0,
        purchasedWords: 0,
        rewardWords: 0,
        consumedWords: 0,
      );
    }
    return WordPackStats.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  /// 保存字数包列表
  Future<void> saveWordPacks(List<WordPackModel> packs) async {
    final data = packs.map((p) => p.toJson()).toList();
    await _setString('word_packs', jsonEncode(data));
  }

  /// 获取字数包列表
  List<WordPackModel> getWordPacks() {
    final data = _getString('word_packs');
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data) as List;
    return list.map((e) => WordPackModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 消耗字数
  Future<bool> consumeWords(int words) async {
    final stats = getWordPackStats();
    if (!stats.hasEnoughWords(words)) {
      return false;
    }

    final newStats = WordPackStats(
      vipGiftWords: stats.vipGiftWords,
      purchasedWords: stats.purchasedWords,
      rewardWords: stats.rewardWords,
      consumedWords: stats.consumedWords + words,
    );

    await saveWordPackStats(newStats);
    return true;
  }

  /// 添加字数（购买或赠送）
  Future<void> addWords({
    int vipGift = 0,
    int purchased = 0,
    int reward = 0,
  }) async {
    final stats = getWordPackStats();
    final newStats = WordPackStats(
      vipGiftWords: stats.vipGiftWords + vipGift,
      purchasedWords: stats.purchasedWords + purchased,
      rewardWords: stats.rewardWords + reward,
      consumedWords: stats.consumedWords,
    );
    await saveWordPackStats(newStats);
  }

  // ==================== 试用相关 ====================

  /// 获取试用次数
  int getTrialCount() {
    return _getInt('trial_count') ?? 0;
  }

  /// 增加试用次数
  Future<void> incrementTrialCount() async {
    final count = getTrialCount();
    await _setInt('trial_count', count + 1);
  }

  /// 是否还有试用次数
  bool hasTrialRemaining() {
    return getTrialCount() < 3; // 最多3次试用
  }

  // ==================== 激励视频相关 ====================

  /// 获取今日观看次数
  int getTodayRewardCount() {
    final lastDate = _getString('reward_last_date');
    final today = DateTime.now().toString().substring(0, 10);

    if (lastDate != today) {
      return 0;
    }

    return _getInt('reward_count') ?? 0;
  }

  /// 增加观看次数
  Future<void> incrementRewardCount() async {
    final today = DateTime.now().toString().substring(0, 10);
    await _setString('reward_last_date', today);

    final count = getTodayRewardCount();
    await _setInt('reward_count', count + 1);
  }

  /// 是否可以观看激励视频
  bool canWatchRewardAd() {
    return getTodayRewardCount() < 4; // 每天最多4次
  }

  // ==================== 应用设置 ====================

  /// 获取启动次数
  int getLaunchCount() {
    return _getInt('launch_count') ?? 0;
  }

  /// 增加启动次数
  Future<void> incrementLaunchCount() async {
    final count = getLaunchCount();
    await _setInt('launch_count', count + 1);
  }

  /// 是否显示过引导
  bool hasShownGuide() {
    return _getBool('has_shown_guide') ?? false;
  }

  /// 设置已显示引导
  Future<void> setShownGuide() async {
    await _setBool('has_shown_guide', true);
  }

  /// 获取主题模式
  String getThemeMode() {
    return _getString('theme_mode') ?? 'system';
  }

  /// 设置主题模式
  Future<void> setThemeMode(String mode) async {
    await _setString('theme_mode', mode);
  }

  /// 获取语言
  String? getLanguage() {
    return _getString('language');
  }

  /// 设置语言
  Future<void> setLanguage(String language) async {
    await _setString('language', language);
  }

  /// 清空所有数据
  Future<void> clearAll() async {
    await _clear();
  }

  // ==================== 提示词处理 ====================

  /// 从提示词中提取要求
  String extractRequirementFromPrompt(String prompt) {
    if (prompt.isEmpty) {
      return '';
    }

    final cleanedPrompt = prompt.trim();

    // 模式1: 提取"要求："后面的内容
    final requirementPrefixes = ['要求：', '要求:', '要求'];

    for (final prefix in requirementPrefixes) {
      final prefixIndex = cleanedPrompt.indexOf(prefix);
      if (prefixIndex != -1) {
        final requirement = cleanedPrompt
            .substring(prefixIndex + prefix.length)
            .trim();
        if (requirement.isNotEmpty) {
          return truncateRequirementIfNeeded(requirement);
        }
      }
    }

    // 模式2: 使用正则表达式匹配"要求：XXX"格式
    final regex = RegExp(r'要求[:：]\s*([^，。！？]+)');
    final match = regex.firstMatch(cleanedPrompt);
    if (match != null && match.groupCount >= 1) {
      final requirement = match.group(1)?.trim() ?? '';
      if (requirement.isNotEmpty) {
        return truncateRequirementIfNeeded(requirement);
      }
    }

    // 模式3: 如果没有明确的要求，提取主题后的合理部分
    return extractReasonablePartFromPrompt(cleanedPrompt);
  }

  /// 提取提示词的合理部分
  String extractReasonablePartFromPrompt(String prompt) {
    if (prompt.isEmpty) {
      return '';
    }

    // 移除主题部分（如果存在）
    final theme = extractThemeFromPrompt(prompt);
    if (theme.isNotEmpty) {
      final themeIndex = prompt.indexOf(theme);
      if (themeIndex != -1) {
        var contentAfterTheme = prompt
            .substring(themeIndex + theme.length)
            .trim();
        // 移除可能的分隔符
        contentAfterTheme = contentAfterTheme
            .replaceAll(RegExp(r'^[，：:；;]+'), '')
            .trim();
        if (contentAfterTheme.isNotEmpty) {
          return truncateRequirementIfNeeded(contentAfterTheme);
        }
      }
    }

    // 模式4: 如果prompt本身不长，直接使用
    if (prompt.length <= 50) {
      return truncateRequirementIfNeeded(prompt);
    }

    // 模式5: 截取前50个字符作为预览
    return truncateRequirementIfNeeded(prompt);
  }

  /// 截断要求文本（如果过长）
  String truncateRequirementIfNeeded(String requirement) {
    if (requirement.length <= 60) {
      return requirement;
    }

    // 截取前60个字符并在末尾添加省略号
    final truncated = requirement.substring(0, 60).trim();
    return '$truncated...';
  }

  /// 从提示词中提取主题
  String extractThemeFromPrompt(String prompt) {
    if (prompt.isEmpty) {
      return '';
    }

    final cleanedPrompt = prompt.trim();

    // 模式1: "主题：XXX，要求：XXX"
    final regex1 = RegExp(r'主题[:：]\s*([^，要求]+?)(?:，|$|要求)');
    final match1 = regex1.firstMatch(cleanedPrompt);
    if (match1 != null && match1.groupCount >= 1) {
      final theme = match1.group(1)?.trim() ?? '';
      if (theme.isNotEmpty) {
        return theme;
      }
    }

    // 模式2: "XXX:XXX" 格式
    final regex2 = RegExp(r'^([^:：]+?)[:：]\s*([^，]+)');
    final match2 = regex2.firstMatch(cleanedPrompt);
    if (match2 != null && match2.groupCount >= 2) {
      final firstPart = match2.group(1)?.trim() ?? '';
      if (firstPart.contains('主题') || firstPart.length <= 10) {
        var theme = match2.group(2)?.trim() ?? '';
        // 移除可能的要求部分
        final requirementIndex = theme.indexOf('要求');
        if (requirementIndex != -1) {
          theme = theme.substring(0, requirementIndex);
        }
        theme = theme.replaceAll(RegExp(r'^[，]+'), '').trim();
        if (theme.isNotEmpty) {
          return theme;
        }
      }
    }

    // 模式3: 直接返回第一个逗号前的内容（如果内容较短）
    final commaIndex = cleanedPrompt.indexOf('，');
    if (commaIndex != -1 && commaIndex < 20) {
      final possibleTheme = cleanedPrompt.substring(0, commaIndex).trim();
      if (possibleTheme.isNotEmpty) {
        return possibleTheme;
      }
    }

    // 模式4: 如果整个prompt很短，直接返回
    if (cleanedPrompt.length <= 25) {
      return cleanedPrompt;
    }

    return '';
  }

  // ==================== 辅助方法 ====================

  /// 获取项目ID（使用 type + title 作为唯一标识）
  String getItemId(Map<String, dynamic> item) {
    final type = item['type'] ?? '';
    final title = item['title'] ?? '';
    return '${type}_$title';
  }

  /// 生成唯一ID
  String generateUniqueID() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return timestamp.toString();
  }

  /// 获取当前时间字符串（yyyy-MM-dd HH:mm:ss）
  String currentTimeString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  /// 获取当前日期字符串（yyyyMMdd_HHmmss）
  String currentDateString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }

  /// 获取文件路径（Documents目录）
  Future<String> getPlistFilePath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, fileName);
  }

  /// 导出文档
  Future<void> exportDocument(String title, String content) async {
    try {
      final fullText = '$title\n\n$content';

      // 创建临时文件
      final tempDir = await getTemporaryDirectory();
      final fileName = 'creation_content_${currentDateString()}.txt';
      final filePath = p.join(tempDir.path, fileName);
      final file = File(filePath);

      await file.writeAsString(fullText, encoding: utf8);

      if (await file.exists()) {
        final xFile = XFile(filePath);
        await Share.shareXFiles([xFile], text: title);
      }
    } catch (e) {
      debugPrint('导出文档失败: $e');
      rethrow;
    }
  }

  // ==================== 缓存管理 ====================

  /// 计算缓存总大小（字节）
  /// 包括：最近使用、搜索历史、文档、写作记录
  /// 注意：这里统计的是业务数据本身大小，不统计整个 sqlite 文件体积，
  /// 避免出现“数据已清空但数据库文件仍占空间”的误差。
  Future<int> calculateCacheSize() async {
    int totalSize = 0;
    final documentsDir = await getApplicationDocumentsDirectory();

    // 需要计算大小的文件列表
    final cacheFiles = [
      'hot_recent_used.json',
    ];

    for (final fileName in cacheFiles) {
      final filePath = p.join(documentsDir.path, fileName);
      final file = File(filePath);
      if (await file.exists()) {
        try {
          totalSize += await file.length();
        } catch (e) {
          debugPrint('计算文件大小失败: $filePath, $e');
        }
      }
    }

    // 兼容旧版本：若最近使用仍在本地存储字符串中，也计入缓存
    final legacyRecentUsed = _getString('hot_recent_used');
    if (legacyRecentUsed != null && legacyRecentUsed.isNotEmpty) {
      totalSize += utf8.encode(legacyRecentUsed).length;
    }

    // 计算搜索历史大小
    final history = loadSearchHistorySearches();
    if (history.isNotEmpty) {
      final jsonString = jsonEncode(history);
      totalSize += utf8.encode(jsonString).length;
    }

    // 计算文档、写作记录（按实际业务字段字节估算）
    try {
      final db = await database;

      final docs = await db.query(
        'documents',
        columns: ['id', 'title', 'content', 'createdAt', 'updatedAt'],
      );
      for (final row in docs) {
        totalSize += utf8.encode((row['id'] as String?) ?? '').length;
        totalSize += utf8.encode((row['title'] as String?) ?? '').length;
        totalSize += utf8.encode((row['content'] as String?) ?? '').length;
        totalSize += utf8.encode((row['createdAt'] as String?) ?? '').length;
        totalSize += utf8.encode((row['updatedAt'] as String?) ?? '').length;
      }

      final records = await db.query(
        'writing_records',
        columns: [
          'id',
          'templateId',
          'templateTitle',
          'prompt',
          'generatedContent',
          'wordCount',
          'createdAt',
          'isCompleted',
        ],
      );
      for (final row in records) {
        totalSize += utf8.encode((row['id'] as String?) ?? '').length;
        totalSize += utf8.encode((row['templateId'] as String?) ?? '').length;
        totalSize += utf8.encode((row['templateTitle'] as String?) ?? '').length;
        totalSize += utf8.encode((row['prompt'] as String?) ?? '').length;
        totalSize += utf8.encode((row['generatedContent'] as String?) ?? '').length;
        totalSize += utf8.encode('${row['wordCount'] ?? ''}').length;
        totalSize += utf8.encode((row['createdAt'] as String?) ?? '').length;
        totalSize += utf8.encode('${row['isCompleted'] ?? ''}').length;
      }
    } catch (e) {
      debugPrint('计算文档/写作记录大小失败: $e');
    }

    return totalSize;
  }

  /// 格式化缓存大小为可读字符串
  String formatCacheSize(int size) {
    if (size == 0) {
      return '0 B';
    }

    final sizeInKB = size / 1024.0;
    if (sizeInKB < 1024) {
      return '${sizeInKB.toStringAsFixed(1)} KB';
    }

    final sizeInMB = sizeInKB / 1024.0;
    if (sizeInMB < 1024) {
      return '${sizeInMB.toStringAsFixed(2)} MB';
    }

    final sizeInGB = sizeInMB / 1024.0;
    return '${sizeInGB.toStringAsFixed(2)} GB';
  }

  /// 清理缓存（与 iOS 对齐）
  /// 清除：文档、最近使用、搜索历史、写作记录
  /// 保留：收藏（我的关注）
  Future<Map<String, dynamic>> clearCache() async {
    final errors = <String>[];
    final documentsDir = await getApplicationDocumentsDirectory();

    // 1. 清除最近使用（与 iOS AIUARecentUsed.plist 对应）
    final cacheFiles = ['hot_recent_used.json'];
    for (final fileName in cacheFiles) {
      final filePath = p.join(documentsDir.path, fileName);
      final file = File(filePath);
      if (await file.exists()) {
        try {
          await file.delete();
          debugPrint('[DataManager] 成功删除缓存文件: $fileName');
        } catch (e) {
          final errorMsg = '删除 $fileName 失败: $e';
          errors.add(errorMsg);
          debugPrint('[DataManager] $errorMsg');
        }
      }
    }
    // 兼容旧版本 prefs
    try {
      await _remove('hot_recent_used');
    } catch (_) {}

    // 2. 清除搜索历史（与 iOS SearchHistory.plist 对应）
    try {
      await clearSearchHistory();
      debugPrint('[DataManager] 成功清除搜索历史');
    } catch (e) {
      final errorMsg = '清除搜索历史失败: $e';
      errors.add(errorMsg);
      debugPrint('[DataManager] $errorMsg');
    }

    // 3. 清除文档表、写作记录表（与 iOS AIUAWritings 等对应；文档一并清理）
    try {
      final db = await database;
      await db.delete('documents');
      debugPrint('[DataManager] 成功清除文档');
      await db.delete('writing_records');
      debugPrint('[DataManager] 成功清除写作记录');
    } catch (e) {
      final errorMsg = '清除数据库表失败: $e';
      errors.add(errorMsg);
      debugPrint('[DataManager] $errorMsg');
    }

    if (errors.isNotEmpty) {
      return {
        'success': false,
        'errorMessage': errors.join('\n'),
      };
    } else {
      debugPrint('[DataManager] 缓存清理完成');
      return {
        'success': true,
        'errorMessage': null,
      };
    }
  }
}
