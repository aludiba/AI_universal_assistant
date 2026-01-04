import 'package:flutter/material.dart';
import '../models/template_model.dart';
import '../services/data_manager.dart';

/// 模板状态管理
class TemplateProvider with ChangeNotifier {
  final _dataManager = DataManager();
  
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
    _searchHistory = _dataManager.loadSearchHistorySearches();
  }
  
  /// 加载所有模板
  Future<void> loadTemplates() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _templates = await _dataManager.getAllTemplates();
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
      _favoriteTemplates = await _dataManager.getFavoriteTemplates();
      notifyListeners();
    } catch (e) {
      // 处理错误
    }
  }
  
  /// 加载最近使用的模板
  Future<void> loadRecentTemplates() async {
    try {
      _recentTemplates = await _dataManager.getRecentlyUsedTemplates(limit: 10);
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
    await _dataManager.updateTemplateFavorite(templateId, !template.isFavorite);
    await loadTemplates();
    await loadFavoriteTemplates();
  }
  
  /// 使用模板（更新最后使用时间）
  Future<void> useTemplate(String templateId) async {
    await _dataManager.updateTemplateLastUsed(templateId);
    await loadTemplates();
    await loadRecentTemplates();
  }
  
  /// 添加搜索历史
  Future<void> addSearchHistory(String keyword) async {
    await _dataManager.addSearchHistory(keyword);
    _searchHistory = _dataManager.loadSearchHistorySearches();
    notifyListeners();
  }
  
  /// 清空搜索历史
  Future<void> clearSearchHistory() async {
    await _dataManager.clearSearchHistory();
    _searchHistory = [];
    notifyListeners();
  }
  
  /// 初始化默认模板
  Future<void> _initDefaultTemplates() async {
    // 检查是否已初始化
    final existing = await _dataManager.getAllTemplates();
    if (existing.isNotEmpty) return;
    
    // 添加默认模板
    final defaultTemplates = _getDefaultTemplates();
    for (var template in defaultTemplates) {
      await _dataManager.upsertTemplate(template);
    }
  }
  
  // 模板详情页状态管理
  final Map<String, Map<String, TextEditingController>> _detailControllers = {};
  final Map<String, bool> _detailIsGenerating = {};
  final Map<String, String?> _detailGeneratedContent = {};
  
  /// 初始化模板详情
  void initTemplateDetail(String templateId, List<TemplateField> fields) {
    if (!_detailControllers.containsKey(templateId)) {
      _detailControllers[templateId] = {};
      for (var field in fields) {
        _detailControllers[templateId]![field.key] = TextEditingController();
      }
      _detailIsGenerating[templateId] = false;
      _detailGeneratedContent[templateId] = null;
    }
  }
  
  /// 获取模板详情字段控制器
  TextEditingController? getTemplateFieldController(String templateId, String fieldKey) {
    return _detailControllers[templateId]?[fieldKey];
  }
  
  /// 检查模板详情是否正在生成
  bool isTemplateGenerating(String templateId) {
    return _detailIsGenerating[templateId] ?? false;
  }
  
  /// 获取模板生成的内容
  String? getTemplateGeneratedContent(String templateId) {
    return _detailGeneratedContent[templateId];
  }
  
  /// 开始生成模板内容
  void startTemplateGenerating(String templateId) {
    _detailIsGenerating[templateId] = true;
    _detailGeneratedContent[templateId] = null;
    notifyListeners();
  }
  
  /// 设置模板生成结果
  void setTemplateGeneratedContent(String templateId, String content) {
    _detailGeneratedContent[templateId] = content;
    notifyListeners();
  }
  
  /// 完成模板生成
  void finishTemplateGenerating(String templateId) {
    _detailIsGenerating[templateId] = false;
    notifyListeners();
  }
  
  /// 清理模板详情状态
  void disposeTemplateDetail(String templateId) {
    final controllers = _detailControllers[templateId];
    if (controllers != null) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
      _detailControllers.remove(templateId);
    }
    _detailIsGenerating.remove(templateId);
    _detailGeneratedContent.remove(templateId);
  }
  
  @override
  void dispose() {
    for (var controllers in _detailControllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    _detailControllers.clear();
    _detailIsGenerating.clear();
    _detailGeneratedContent.clear();
    super.dispose();
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

