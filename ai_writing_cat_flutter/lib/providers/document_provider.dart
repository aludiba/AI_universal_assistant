import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/document_model.dart';
import '../services/data_manager.dart';

/// 文档状态管理
class DocumentProvider with ChangeNotifier {
  final _dataManager = DataManager();
  final _uuid = const Uuid();
  
  List<DocumentModel> _documents = [];
  bool _isLoading = false;
  
  List<DocumentModel> get documents => _documents;
  bool get isLoading => _isLoading;
  
  /// 加载所有文档
  Future<void> loadDocuments() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _documents = await _dataManager.getAllDocuments();
    } catch (e) {
      // 处理错误
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 创建新文档
  Future<DocumentModel> createDocument({
    String title = '',
    String content = '',
  }) async {
    final now = DateTime.now();
    final document = DocumentModel(
      id: _uuid.v4(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    
    await _dataManager.insertDocument(document);
    await loadDocuments();
    
    return document;
  }
  
  /// 更新文档
  Future<void> updateDocument(DocumentModel document) async {
    final updatedDocument = document.copyWith(
      updatedAt: DateTime.now(),
    );
    
    await _dataManager.updateDocument(updatedDocument);
    await loadDocuments();
  }
  
  /// 删除文档
  Future<void> deleteDocument(String id) async {
    await _dataManager.deleteDocument(id);
    await loadDocuments();
  }
  
  /// 根据ID获取文档
  DocumentModel? getDocumentById(String id) {
    try {
      return _documents.firstWhere((doc) => doc.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // 文档详情页状态管理
  final Map<String, TextEditingController> _detailControllers = {};
  final Map<String, bool> _detailHasChanges = {};
  
  /// 获取文档详情控制器
  TextEditingController getDetailController(String documentId, String field) {
    final key = '${documentId}_$field';
    if (!_detailControllers.containsKey(key)) {
      _detailControllers[key] = TextEditingController();
    }
    return _detailControllers[key]!;
  }
  
  /// 初始化文档详情
  void initDocumentDetail(String documentId) {
    final doc = getDocumentById(documentId);
    if (doc != null) {
      getDetailController(documentId, 'title').text = doc.title;
      getDetailController(documentId, 'content').text = doc.content;
      _detailHasChanges[documentId] = false;
      
      // 监听变化
      getDetailController(documentId, 'title').addListener(() {
        _detailHasChanges[documentId] = true;
        notifyListeners();
      });
      getDetailController(documentId, 'content').addListener(() {
        _detailHasChanges[documentId] = true;
        notifyListeners();
      });
    }
  }
  
  /// 检查文档是否有未保存的更改
  bool hasDocumentChanges(String documentId) {
    return _detailHasChanges[documentId] ?? false;
  }
  
  /// 保存文档详情
  Future<void> saveDocumentDetail(String documentId) async {
    final titleController = getDetailController(documentId, 'title');
    final contentController = getDetailController(documentId, 'content');
    
    final doc = getDocumentById(documentId);
    if (doc != null) {
      final updatedDoc = doc.copyWith(
        title: titleController.text,
        content: contentController.text,
        updatedAt: DateTime.now(),
      );
      await updateDocument(updatedDoc);
      _detailHasChanges[documentId] = false;
      notifyListeners();
    }
  }
  
  /// 清理文档详情状态
  void disposeDocumentDetail(String documentId) {
    final titleKey = '${documentId}_title';
    final contentKey = '${documentId}_content';
    
    _detailControllers[titleKey]?.dispose();
    _detailControllers[contentKey]?.dispose();
    _detailControllers.remove(titleKey);
    _detailControllers.remove(contentKey);
    _detailHasChanges.remove(documentId);
  }
  
  @override
  void dispose() {
    for (var controller in _detailControllers.values) {
      controller.dispose();
    }
    _detailControllers.clear();
    _detailHasChanges.clear();
    super.dispose();
  }
}

