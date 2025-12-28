import 'package:flutter/material.dart';
import '../models/template_model.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

/// 模板状态管理
class TemplateProvider with ChangeNotifier {
  final _databaseService = DatabaseService();
  final _storageService = StorageService();
  
  List<TemplateModel> _templates = [];
  List<TemplateModel> _favoriteTemplates = [];
  List<TemplateModel> _recentTemplates = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  
  List<TemplateModel> get templates => _templates;
  List<TemplateModel> get favoriteTemplates => _favoriteTemplates;
  List<TemplateModel> get recentTemplates => _recentTemplates;
  List<String> get searchHistory => _searchHistory;
  bool get isLoading => _isLoading;
  
  /// 初始化模板数据
  Future<void> init() async {
    await _initDefaultTemplates();
    await loadTemplates();
    await loadFavoriteTemplates();
    await loadRecentTemplates();
    _searchHistory = _storageService.getSearchHistory();
  }
  
  /// 加载所有模板
  Future<void> loadTemplates() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _templates = await _databaseService.getAllTemplates();
    } catch (e) {
      // 处理错误
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 加载收藏的模板
  Future<void> loadFavoriteTemplates() async {
    try {
      _favoriteTemplates = await _databaseService.getFavoriteTemplates();
      notifyListeners();
    } catch (e) {
      // 处理错误
    }
  }
  
  /// 加载最近使用的模板
  Future<void> loadRecentTemplates() async {
    try {
      _recentTemplates = await _databaseService.getRecentlyUsedTemplates(limit: 10);
      notifyListeners();
    } catch (e) {
      // 处理错误
    }
  }
  
  /// 根据分类获取模板
  List<TemplateModel> getTemplatesByCategory(String category) {
    return _templates.where((t) => t.category == category).toList();
  }
  
  /// 搜索模板
  List<TemplateModel> searchTemplates(String keyword) {
    if (keyword.isEmpty) return [];
    
    return _templates.where((t) {
      return t.title.contains(keyword) || t.description.contains(keyword);
    }).toList();
  }
  
  /// 切换收藏状态
  Future<void> toggleFavorite(String templateId) async {
    final template = _templates.firstWhere((t) => t.id == templateId);
    await _databaseService.updateTemplateFavorite(templateId, !template.isFavorite);
    await loadTemplates();
    await loadFavoriteTemplates();
  }
  
  /// 使用模板（更新最后使用时间）
  Future<void> useTemplate(String templateId) async {
    await _databaseService.updateTemplateLastUsed(templateId);
    await loadTemplates();
    await loadRecentTemplates();
  }
  
  /// 添加搜索历史
  Future<void> addSearchHistory(String keyword) async {
    await _storageService.addSearchHistory(keyword);
    _searchHistory = _storageService.getSearchHistory();
    notifyListeners();
  }
  
  /// 清空搜索历史
  Future<void> clearSearchHistory() async {
    await _storageService.clearSearchHistory();
    _searchHistory = [];
    notifyListeners();
  }
  
  /// 初始化默认模板
  Future<void> _initDefaultTemplates() async {
    // 检查是否已初始化
    final existing = await _databaseService.getAllTemplates();
    if (existing.isNotEmpty) return;
    
    // 添加默认模板
    final defaultTemplates = _getDefaultTemplates();
    for (var template in defaultTemplates) {
      await _databaseService.upsertTemplate(template);
    }
  }
  
  /// 获取默认模板列表
  List<TemplateModel> _getDefaultTemplates() {
    return [
      TemplateModel(
        id: 'social_post_1',
        title: '朋友圈文案',
        description: '生成吸引人的朋友圈文案',
        category: TemplateCategory.socialMedia,
        fields: [
          TemplateField(
            key: 'topic',
            label: '主题',
            placeholder: '例如：美食、旅行、心情等',
          ),
          TemplateField(
            key: 'mood',
            label: '情绪风格',
            placeholder: '例如：轻松、励志、感性等',
            required: false,
          ),
        ],
      ),
      TemplateModel(
        id: 'work_report_1',
        title: '工作总结',
        description: '生成专业的工作总结报告',
        category: TemplateCategory.workplace,
        fields: [
          TemplateField(
            key: 'period',
            label: '时间周期',
            placeholder: '例如：本周、本月、本季度',
          ),
          TemplateField(
            key: 'content',
            label: '主要工作内容',
            placeholder: '简要描述本周期的主要工作',
            type: TemplateFieldType.textarea,
          ),
        ],
      ),
      TemplateModel(
        id: 'essay_1',
        title: '作文写作',
        description: '生成高质量的作文',
        category: TemplateCategory.school,
        fields: [
          TemplateField(
            key: 'topic',
            label: '作文题目',
            placeholder: '输入作文题目',
          ),
          TemplateField(
            key: 'wordCount',
            label: '字数要求',
            placeholder: '例如：800字',
            type: TemplateFieldType.number,
          ),
        ],
      ),
    ];
  }
}

