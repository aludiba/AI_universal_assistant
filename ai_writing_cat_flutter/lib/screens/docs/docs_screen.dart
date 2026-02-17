import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/document_provider.dart';
import '../../models/document_model.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';
import '../../services/data_manager.dart';

/// 文档页面
class DocsScreen extends StatefulWidget {
  const DocsScreen({super.key});

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> {
  final DataManager _dataManager = DataManager();
  bool _isCreatingDocument = false;

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
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.tabDocs),
      ),
      body: Consumer<DocumentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = provider.documents;

          // iOS: UITableViewStyleGrouped + 自定义 cell/section header
          return Container(
            color: scaffoldBackgroundColor,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Section 0: 新建文档 cell（高度 120，上下 8，左右 16）
                _buildCreateDocumentCell(context, provider),

                // Section 1 Header: “我的文档”（高度 50，底部 8，左右 16）
                _buildMyDocumentsHeader(context, l10n),

                if (docs.isEmpty)
                  // iOS: 中间空文本提示
                  Padding(
                    padding: const EdgeInsets.only(top: 120),
                    child: Center(
                      child: Text(
                        l10n.noDocuments,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ),
                  )
                else
                  ...docs.map((doc) => _buildDocumentRow(context, doc, provider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateDocumentCell(BuildContext context, DocumentProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          onTap: _createNewDocument,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                width: 1,
                color: AppColors.getDivider(context),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  size: 32,
                  color: AppColors.getTextSecondary(context),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.newDocument,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyDocumentsHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      height: 50,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      alignment: Alignment.bottomLeft,
      child: Text(
        l10n.myDocuments,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.getTextPrimary(context),
        ),
      ),
    );
  }

  Widget _buildDocumentRow(BuildContext context, DocumentModel doc, DocumentProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final docTitle = doc.title.isEmpty ? l10n.untitledDocument : doc.title;

    // iOS 有侧滑删除；Flutter 用 Dismissible 近似
    return Dismissible(
      key: ValueKey('doc_${doc.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final shouldDelete = await _confirmDelete(doc);
        return shouldDelete;
      },
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        final deletedMsg = l10n.deletedSuccess;
        await provider.deleteDocument(doc.id);
        messenger.showSnackBar(
          SnackBar(content: Text(deletedMsg)),
        );
      },
      background: Container(
        color: const Color(0xFFEF4444),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Text(
          l10n.delete,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            context.pushNamed(AppRoute.docDetail.name, pathParameters: {'id': doc.id}).then((_) {
              provider.loadDocuments();
            });
          },
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 44,
                        color: AppColors.getTextSecondary(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              docTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.getTextPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  _formatDateForDocs(doc.updatedAt),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.getTextSecondary(context),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '|  ${doc.wordCount} ${l10n.words}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.getTextSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.more_horiz),
                        color: AppColors.getTextSecondary(context),
                        onPressed: () => _showMoreActions(doc, provider),
                      ),
                    ],
                  ),
                ),
                // iOS: 底部分割线，左右 16 inset，高 1
                Container(
                  height: 1,
                  color: AppColors.getDivider(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _createNewDocument() async {
    if (_isCreatingDocument) return;
    _isCreatingDocument = true;
    final provider = context.read<DocumentProvider>();
    try {
      final doc = await provider.createDocument(
        title: '',
        refreshList: false,
      );

      if (!mounted) return;
      await context.pushNamed(
        AppRoute.docDetail.name,
        pathParameters: {'id': doc.id},
      );
      if (mounted) {
        await provider.loadDocuments();
      }
    } finally {
      _isCreatingDocument = false;
    }
  }

  Future<bool> _confirmDelete(DocumentModel doc) async {
    final l10n = AppLocalizations.of(context)!;
    final docTitle = doc.title.isEmpty ? l10n.untitledDocument : doc.title;
    final result = await showDialog<bool>(
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
              Navigator.pop(context, true);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _showMoreActions(DocumentModel doc, DocumentProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    final docTitle = doc.title.isEmpty ? l10n.untitledDocument : doc.title;
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.export),
                onTap: () async {
                  Navigator.pop(context);
                  await _dataManager.exportDocument(docTitle, doc.content);
                },
              ),
              ListTile(
                title: Text(l10n.copy),
                onTap: () async {
                  Navigator.pop(context);
                  final fullText = '$docTitle\n${doc.content.isEmpty ? '' : '\n${doc.content}'}';
                  await Clipboard.setData(ClipboardData(text: fullText));
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.copiedToClipboard)),
                  );
                },
              ),
              ListTile(
                title: Text(
                  l10n.delete,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await _confirmDelete(doc);
                  if (!ok) return;
                  await provider.deleteDocument(doc.id);
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.deletedSuccess)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateForDocs(DateTime date) {
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
      // iOS 更接近原始完整时间：yyyy-MM-dd HH:mm:ss
      return DateFormat('yyyy-MM-dd HH:mm:ss', l10n.localeName).format(date);
    }
  }
}
