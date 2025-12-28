import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/document_provider.dart';
import '../../models/document_model.dart';
import '../../constants/app_styles.dart';

/// 文档详情页面
class DocumentDetailScreen extends StatefulWidget {
  final String documentId;
  
  const DocumentDetailScreen({
    super.key,
    required this.documentId,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  DocumentModel? _document;
  bool _hasChanges = false;
  
  @override
  void initState() {
    super.initState();
    _loadDocument();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  void _loadDocument() {
    final provider = context.read<DocumentProvider>();
    _document = provider.getDocumentById(widget.documentId);
    
    if (_document != null) {
      _titleController.text = _document!.title;
      _contentController.text = _document!.content;
      
      // 监听文本变化
      _titleController.addListener(_onTextChanged);
      _contentController.addListener(_onTextChanged);
    }
  }
  
  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_document == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('文档详情'),
        ),
        body: const Center(
          child: Text('文档不存在'),
        ),
      );
    }
    
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          await _saveDocument();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('编辑文档'),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyContent,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareDocument,
            ),
            if (_hasChanges)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveDocument,
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          children: [
            // 标题输入
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '请输入标题',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const Divider(),
            
            // 内容输入
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: '请输入内容',
                border: InputBorder.none,
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            
            const SizedBox(height: AppStyles.paddingLarge),
            
            // 统计信息
            Container(
              padding: const EdgeInsets.all(AppStyles.paddingMedium),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    '字数',
                    _contentController.text.length.toString(),
                  ),
                  _buildStatItem(
                    '段落',
                    _contentController.text.split('\n').length.toString(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Future<void> _saveDocument() async {
    if (_document == null) return;
    
    final updatedDocument = _document!.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      updatedAt: DateTime.now(),
    );
    
    final provider = context.read<DocumentProvider>();
    await provider.updateDocument(updatedDocument);
    
    setState(() {
      _hasChanges = false;
      _document = updatedDocument;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
    }
  }
  
  void _copyContent() {
    Clipboard.setData(ClipboardData(text: _contentController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }
  
  void _shareDocument() {
    // TODO: 实现分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中')),
    );
  }
}

