import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/writing_record_model.dart';
import '../../providers/document_provider.dart';
import '../../router/app_router.dart';
import '../../services/data_manager.dart';

/// 创作记录列表页（模仿 iOS AIUAWritingRecordsViewController）
/// [templateId] 非空时仅展示该模板的创作记录（从模板详情进入）；为空时展示全部（从设置/热门进入）
class WritingRecordsScreen extends StatefulWidget {
  final String? templateId;

  const WritingRecordsScreen({super.key, this.templateId});

  @override
  State<WritingRecordsScreen> createState() => _WritingRecordsScreenState();
}

class _WritingRecordsScreenState extends State<WritingRecordsScreen> {
  final DataManager _dataManager = DataManager();
  List<WritingRecordModel> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    try {
      final list = widget.templateId != null && widget.templateId!.isNotEmpty
          ? await _dataManager.loadWritingsByTemplateId(widget.templateId)
          : await _dataManager.loadAllWritings();
      if (mounted) setState(() {
        _records = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
    }
    return DateFormat('yyyy-MM-dd HH:mm', l10n.localeName).format(date);
  }

  Future<bool> _confirmDelete(WritingRecordModel record) async {
    final l10n = AppLocalizations.of(context)!;
    final title = record.templateTitle.isEmpty ? l10n.noWritingRecords : record.templateTitle;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirm),
        content: Text(l10n.deleteDocumentPrompt(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _onRecordTap(WritingRecordModel record) async {
    try {
      await _dataManager.ensureDocumentFromWritingRecord(record);
      if (!mounted) return;
      await context.read<DocumentProvider>().loadDocuments();
      if (!mounted) return;
      context.pushNamed(AppRoute.docDetail.name, pathParameters: {'id': record.id}).then((_) {
        _loadRecords();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.documentNotFound)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(l10n.writingRecords),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Text(
                    l10n.noWritingRecords,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    return _buildRecordRow(context, record, l10n);
                  },
                ),
    );
  }

  Widget _buildRecordRow(
    BuildContext context,
    WritingRecordModel record,
    AppLocalizations l10n,
  ) {
    final title = record.templateTitle.isEmpty ? l10n.untitledDocument : record.templateTitle;
    final promptPreview = record.prompt.length > 60
        ? '${record.prompt.substring(0, 60)}...'
        : record.prompt;
    final content = record.generatedContent ?? '';
    final contentPreview = content.length > 100 ? '${content.substring(0, 100)}...' : content;
    final wordCount = record.wordCount ?? content.length;

    return Dismissible(
      key: ValueKey('writing_record_${record.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(record),
      onDismissed: (_) async {
        await _dataManager.deleteWritingWithID(record.id);
        if (mounted) {
          setState(() => _records.removeWhere((r) => r.id == record.id));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deletedSuccess)),
          );
        }
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
          onTap: () => _onRecordTap(record),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                if (promptPreview.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    promptPreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
                if (contentPreview.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    contentPreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _formatDate(record.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$wordCount ${l10n.words}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
}
