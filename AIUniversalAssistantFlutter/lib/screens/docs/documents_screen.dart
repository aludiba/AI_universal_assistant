import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../utils/app_localizations_helper.dart';
import '../../models/writing_model.dart';
import 'document_detail_screen.dart';
import '../../widgets/empty_widget.dart';
import 'document_detail_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final DataService _dataService = DataService();
  List<WritingRecord> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 每次返回页面时刷新
    if (!_isLoading) {
      _loadDocuments();
    }
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allDocs = await _dataService.loadAllDocuments();
      setState(() {
        _documents = allDocs;
        _documents.sort((a, b) => b.updateTime.compareTo(a.updateTime));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createNewDocument() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DocumentDetailScreen(isNew: true),
      ),
    ).then((_) => _loadDocuments());
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final docDate = DateTime(date.year, date.month, date.day);

    if (docDate == today) {
      return context.l10n.translate('today');
    } else if (docDate == today.subtract(const Duration(days: 1))) {
      return context.l10n.translate('yesterday');
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  void _showDeleteDialog(WritingRecord document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.translate('confirm_delete_document')),
        content: Text(context.l10n.translate('confirm_delete_document')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await _dataService.deleteDocument(document.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.translate('deleted_success'))),
                );
                _loadDocuments();
              }
            },
            child: Text(
              context.l10n.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tabDocs),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 新建文档按钮
                InkWell(
                  onTap: _createNewDocument,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.translate('new_document'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 文档列表
                if (_documents.isEmpty)
                  Expanded(
                    child: EmptyWidget(
                      message: context.l10n.translate('no_documents'),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.l10n.translate('my_documents'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        final doc = _documents[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              doc.title.isEmpty
                                  ? context.l10n.translate('untitled_document')
                                  : doc.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  doc.content.isEmpty
                                      ? context.l10n.translate('empty_document')
                                      : doc.content.length > 50
                                          ? '${doc.content.substring(0, 50)}...'
                                          : doc.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(doc.updateTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: Text(context.l10n.translate('delete')),
                                  onTap: () => Future.delayed(
                                    Duration.zero,
                                    () => _showDeleteDialog(doc),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => DocumentDetailScreen(
                                    document: doc,
                                    isNew: false,
                                  ),
                                ),
                              ).then((_) => _loadDocuments());
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

