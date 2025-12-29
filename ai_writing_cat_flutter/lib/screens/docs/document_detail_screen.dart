import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/document_provider.dart';
import '../../constants/app_styles.dart';

/// 文档详情页面
class DocumentDetailScreen extends StatelessWidget {
  final String documentId;
  
  const DocumentDetailScreen({
    super.key,
    required this.documentId,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentProvider>();
    final document = provider.getDocumentById(documentId);
    
    // 初始化详情状态
    if (document != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.initDocumentDetail(documentId);
      });
    }
    
    if (document == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('文档详情'),
        ),
        body: const Center(
          child: Text('文档不存在'),
        ),
      );
    }
    
    final titleController = provider.getDetailController(documentId, 'title');
    final contentController = provider.getDetailController(documentId, 'content');
    final hasChanges = provider.hasDocumentChanges(documentId);
    
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && hasChanges) {
          await provider.saveDocumentDetail(documentId);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('编辑文档'),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _copyContent(context, contentController),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareDocument(context),
            ),
            if (hasChanges)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => _saveDocument(context, provider),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          children: [
            // 标题输入
            TextField(
              controller: titleController,
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
              controller: contentController,
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
                    contentController.text.length.toString(),
                  ),
                  _buildStatItem(
                    '段落',
                    contentController.text.split('\n').length.toString(),
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
  
  Future<void> _saveDocument(BuildContext context, DocumentProvider provider) async {
    await provider.saveDocumentDetail(documentId);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
    }
  }
  
  void _copyContent(BuildContext context, TextEditingController contentController) {
    Clipboard.setData(ClipboardData(text: contentController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }
  
  void _shareDocument(BuildContext context) {
    // TODO: 实现分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中')),
    );
  }
}
