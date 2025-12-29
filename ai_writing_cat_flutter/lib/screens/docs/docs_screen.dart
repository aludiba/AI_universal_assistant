import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/document_provider.dart';
import '../../models/document_model.dart';
import '../../constants/app_styles.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myDocuments),
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
                    l10n.noDocuments,
                    style: AppStyles.bodyLarge.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppStyles.paddingLarge),
                  ElevatedButton.icon(
                    onPressed: _createNewDocument,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.newDocument),
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
    final l10n = AppLocalizations.of(context)!;
    final docTitle = doc.title.isEmpty ? l10n.untitledDocument : doc.title;
    return Card(
      margin: const EdgeInsets.only(bottom: AppStyles.paddingMedium),
      child: InkWell(
        onTap: () {
          context
              .pushNamed(AppRoute.docDetail.name, pathParameters: {'id': doc.id})
              .then((_) {
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
                      docTitle,
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
                    '${doc.wordCount} ${l10n.words}',
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
    final l10n = AppLocalizations.of(context)!;
    final doc = await provider.createDocument(title: l10n.newDocument);
    
    if (mounted) {
      context
          .pushNamed(AppRoute.docDetail.name, pathParameters: {'id': doc.id})
          .then((_) {
        provider.loadDocuments();
      });
    }
  }
  
  void _deleteDocument(DocumentModel doc, DocumentProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final docTitle = doc.title.isEmpty ? l10n.untitledDocument : doc.title;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConfirm),
        content: Text(l10n.deleteDocumentPrompt(docTitle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              provider.deleteDocument(doc.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.deletedSuccess)),
              );
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final docDate = DateTime(date.year, date.month, date.day);
    
    final timeStr = DateFormat('HH:mm', l10n.localeName).format(date);
    if (docDate == today) {
      return '${l10n.today} $timeStr';
    } else if (docDate == yesterday) {
      return '${l10n.yesterday} $timeStr';
    } else {
      return DateFormat('MM-dd HH:mm', l10n.localeName).format(date);
    }
  }
}

