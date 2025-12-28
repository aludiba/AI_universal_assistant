import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/document_model.dart';
import '../services/database_service.dart';

/// 文档状态管理
class DocumentProvider with ChangeNotifier {
  final _databaseService = DatabaseService();
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
      _documents = await _databaseService.getAllDocuments();
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
    
    await _databaseService.insertDocument(document);
    await loadDocuments();
    
    return document;
  }
  
  /// 更新文档
  Future<void> updateDocument(DocumentModel document) async {
    final updatedDocument = document.copyWith(
      updatedAt: DateTime.now(),
    );
    
    await _databaseService.updateDocument(updatedDocument);
    await loadDocuments();
  }
  
  /// 删除文档
  Future<void> deleteDocument(String id) async {
    await _databaseService.deleteDocument(id);
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
}

