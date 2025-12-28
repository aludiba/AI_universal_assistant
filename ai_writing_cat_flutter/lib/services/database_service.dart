import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/document_model.dart';
import '../models/writing_record_model.dart';
import '../models/template_model.dart';

/// 本地数据库服务
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  Database? _database;
  
  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'ai_writing_cat.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
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
    await db.update(
      'documents',
      document.toJson(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }
  
  /// 删除文档
  Future<void> deleteDocument(String id) async {
    final db = await database;
    await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// 获取所有文档
  Future<List<DocumentModel>> getAllDocuments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => DocumentModel.fromJson(map)).toList();
  }
  
  /// 根据ID获取文档
  Future<DocumentModel?> getDocumentById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return DocumentModel.fromJson(maps.first);
  }
  
  // ==================== 写作记录操作 ====================
  
  /// 插入写作记录
  Future<void> insertWritingRecord(WritingRecordModel record) async {
    final db = await database;
    final data = record.toJson();
    data['isCompleted'] = record.isCompleted ? 1 : 0;
    await db.insert(
      'writing_records',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
  
  /// 删除写作记录
  Future<void> deleteWritingRecord(String id) async {
    final db = await database;
    await db.delete(
      'writing_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// 获取所有写作记录
  Future<List<WritingRecordModel>> getAllWritingRecords() async {
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
  
  // ==================== 模板操作 ====================
  
  /// 插入或更新模板
  Future<void> upsertTemplate(TemplateModel template) async {
    final db = await database;
    final data = template.toJson();
    data['fields'] = template.toJson()['fields'].toString();
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
    return maps.map((map) => TemplateModel.fromJson(map)).toList();
  }
  
  /// 根据分类获取模板
  Future<List<TemplateModel>> getTemplatesByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'templates',
      where: 'category = ?',
      whereArgs: [category],
    );
    return maps.map((map) => TemplateModel.fromJson(map)).toList();
  }
  
  /// 获取收藏的模板
  Future<List<TemplateModel>> getFavoriteTemplates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'templates',
      where: 'isFavorite = ?',
      whereArgs: [1],
    );
    return maps.map((map) => TemplateModel.fromJson(map)).toList();
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
    return maps.map((map) => TemplateModel.fromJson(map)).toList();
  }
  
  /// 清空所有数据
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('writing_records');
    // 注意：不删除文档和模板收藏
  }
  
  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

