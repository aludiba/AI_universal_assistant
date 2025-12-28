import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/document_provider.dart';
import '../../models/document_model.dart';
import '../../constants/app_styles.dart';
import 'document_detail_screen.dart';

/// 文档页面
class DocsScreen extends StatefulWidget {
  const DocsScreen({super.key});

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> {
  @override
  void initState() {
    super.initState();
    // 加载文档列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().loadDocuments();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的文档'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewDocument,
          ),
        ],
      ),
      body: Consumer<DocumentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (provider.documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: AppStyles.paddingMedium),
                  Text(
                    '暂无文档',
                    style: AppStyles.bodyLarge.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppStyles.paddingLarge),
                  ElevatedButton.icon(
                    onPressed: _createNewDocument,
                    icon: const Icon(Icons.add),
                    label: const Text('创建新文档'),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(AppStyles.paddingMedium),
            itemCount: provider.documents.length,
            itemBuilder: (context, index) {
              final doc = provider.documents[index];
              return _buildDocumentCard(doc, provider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewDocument,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildDocumentCard(DocumentModel doc, DocumentProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppStyles.paddingMedium),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DocumentDetailScreen(documentId: doc.id),
            ),
          ).then((_) {
            // 返回时刷新列表
            provider.loadDocuments();
          });
        },
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      doc.title.isEmpty ? '未命名文档' : doc.title,
                      style: AppStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: () => _deleteDocument(doc, provider),
                  ),
                ],
              ),
              const SizedBox(height: AppStyles.paddingSmall),
              if (doc.content.isNotEmpty)
                Text(
                  doc.content,
                  style: AppStyles.bodyMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: AppStyles.paddingSmall),
              Row(
                children: [
                  Text(
                    '${doc.wordCount} 字',
                    style: AppStyles.bodySmall.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: AppStyles.paddingMedium),
                  Text(
                    _formatDate(doc.updatedAt),
                    style: AppStyles.bodySmall.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _createNewDocument() async {
    final provider = context.read<DocumentProvider>();
    final doc = await provider.createDocument(title: '新文档');
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentDetailScreen(documentId: doc.id),
        ),
      ).then((_) {
        provider.loadDocuments();
      });
    }
  }
  
  void _deleteDocument(DocumentModel doc, DocumentProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${doc.title.isEmpty ? "未命名文档" : doc.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteDocument(doc.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('删除成功')),
              );
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final docDate = DateTime(date.year, date.month, date.day);
    
    if (docDate == today) {
      return '今天 ${DateFormat('HH:mm').format(date)}';
    } else if (docDate == yesterday) {
      return '昨天 ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('MM-dd HH:mm').format(date);
    }
  }
}

