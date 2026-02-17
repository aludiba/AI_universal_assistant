import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/document_model.dart';
import '../../models/hot_item_model.dart';
import '../../models/writing_record_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/document_provider.dart';
import '../../router/app_router.dart';
import '../../services/data_manager.dart';
import '../../services/deepseek_service.dart';

const Color _kDetailCardBorder = Color(0xFFE5E7EB);
const Color _kDetailStopBg = Color(0xFFFEF2F2);
const Color _kDetailStopText = Color(0xFFEF4444);
const Color _kDetailStopBorder = Color(0xFFFECACA);

class HotWritingDetailArgs {
  const HotWritingDetailArgs({
    required this.item,
    required this.prompt,
    required this.wordCount,
  });

  final HotItemModel item;
  final String prompt;
  final int wordCount;
}

/// 对齐 iOS `AIUAWritingDetailViewController` 的文章生成详情页。
class HotWritingDetailScreen extends StatefulWidget {
  const HotWritingDetailScreen({
    super.key,
    required this.args,
  });

  final HotWritingDetailArgs args;

  @override
  State<HotWritingDetailScreen> createState() => _HotWritingDetailScreenState();
}

class _HotWritingDetailScreenState extends State<HotWritingDetailScreen> {
  final DataManager _dataManager = DataManager();
  final DeepSeekService _writer = DeepSeekService();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<String>? _streamSub;
  String _rawText = '';
  String _titleText = '';
  String _contentText = '';
  String? _currentWritingId;
  DocumentModel? _editingDocument;
  bool _isGenerating = true;
  bool _userStoppedCreation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startWriting());
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _writer.cancelCurrentRequest();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startWriting() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final appProvider = context.read<AppProvider>();

    final estimatedOutputWords = widget.args.wordCount > 0 ? widget.args.wordCount : 1000;
    if (!appProvider.hasEnoughWords(estimatedOutputWords)) {
      _showInsufficientWordsDialog(estimatedOutputWords, appProvider.remainingWords);
      setState(() {
        _isGenerating = false;
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _userStoppedCreation = false;
      _rawText = '';
      _titleText = '';
      _contentText = '';
    });

    final prompt = '${widget.args.prompt}\n${l10n.format}:1、${l10n.firstLine}；2、${l10n.bodyBelow}。';
    _streamSub = _writer
        .generateFullStreamWritingWithPrompt(
          prompt: prompt,
          wordCount: widget.args.wordCount,
        )
        .listen(
      (chunk) {
        if (!mounted || !_isGenerating) return;
        _handleStreamChunk(chunk);
      },
      onError: (Object error) {
        if (!mounted) return;
        _finishWithError(error.toString());
      },
      onDone: () {
        if (!mounted) return;
        _finalizeWriting();
      },
      cancelOnError: false,
    );
  }

  void _handleStreamChunk(String chunk) {
    _rawText += chunk;
    final processed = _removeMarkdownSymbols(_rawText);
    final parsed = _parseTitleAndBody(processed, isFinal: false);
    setState(() {
      _titleText = parsed.$1;
      _contentText = parsed.$2;
    });
    _scrollToBottom();
  }

  Future<void> _finalizeWriting() async {
    if (!_isGenerating) return;

    final l10n = AppLocalizations.of(context)!;
    final processed = _removeMarkdownSymbols(_rawText).trim();
    final parsed = _parseTitleAndBody(processed, isFinal: true);

    setState(() {
      _isGenerating = false;
      _titleText = parsed.$1.isEmpty ? l10n.creationContent : parsed.$1;
      _contentText = parsed.$2;
    });

    final outputText = _buildFullText();
    if (outputText.isNotEmpty) {
      await _consumeWords(outputText.length);
      await _saveWritingRecord(outputText.length);
    }
    _scrollToBottom();
  }

  void _finishWithError(String message) {
    if (!mounted) return;
    setState(() {
      _isGenerating = false;
    });
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.creationFailed}: $message')),
    );
  }

  Future<void> _consumeWords(int outputWords) async {
    if (outputWords <= 0) return;
    final appProvider = context.read<AppProvider>();
    await appProvider.consumeWords(outputWords);
  }

  Future<void> _saveWritingRecord(int outputWords) async {
    final fullText = _buildFullText();
    if (fullText.isEmpty) return;

    if (_currentWritingId != null) {
      await _dataManager.deleteWritingWithID(_currentWritingId!);
      _currentWritingId = null;
    }

    final newId = _dataManager.generateUniqueID();
    _currentWritingId = newId;

    final record = WritingRecordModel(
      id: newId,
      templateId: widget.args.item.id,
      templateTitle: _titleText.isEmpty ? widget.args.item.title : _titleText,
      prompt: widget.args.prompt,
      generatedContent: fullText,
      wordCount: outputWords,
      createdAt: DateTime.now(),
      isCompleted: true,
    );
    await _dataManager.saveWritingToPlist(record);
  }

  Future<void> _stopGenerating() async {
    if (!_isGenerating) return;
    _userStoppedCreation = true;
    _writer.cancelCurrentRequest();
    await _streamSub?.cancel();
    await _finalizeWriting();
  }

  Future<void> _rewrite() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recreate),
        content: Text(l10n.confirmRegenerateContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    _writer.cancelCurrentRequest();
    await _streamSub?.cancel();
    if (_currentWritingId != null) {
      await _dataManager.deleteWritingWithID(_currentWritingId!);
      _currentWritingId = null;
    }

    setState(() {
      _rawText = '';
      _titleText = '';
      _contentText = '';
      _isGenerating = true;
    });
    await _startWriting();
  }

  Future<void> _copyAll() async {
    final fullText = _buildFullText();
    if (fullText.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: fullText));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copiedToClipboard)),
    );
  }

  Future<void> _export() async {
    if (_titleText.isEmpty && _contentText.isEmpty) return;
    await _dataManager.exportDocument(
      _titleText.isEmpty ? widget.args.item.title : _titleText,
      _contentText,
    );
  }

  Future<void> _edit() async {
    final fullText = _buildFullText();
    if (fullText.isEmpty) return;

    final provider = context.read<DocumentProvider>();
    final title = _titleText.isEmpty ? widget.args.item.title : _titleText;
    final content = _contentText;

    if (_editingDocument == null) {
      _editingDocument = await provider.createDocument(
        title: title,
        content: content,
        refreshList: false,
      );
    } else {
      final updated = _editingDocument!.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
      );
      await provider.updateDocument(updated);
      _editingDocument = updated;
    }

    if (!mounted || _editingDocument == null) return;
    context.pushNamed(
      AppRoute.docDetail.name,
      pathParameters: {'id': _editingDocument!.id},
    );
  }

  String _buildFullText() {
    if (_titleText.isEmpty && _contentText.isEmpty) return '';
    if (_titleText.isEmpty) return _contentText.trim();
    if (_contentText.isEmpty) return _titleText.trim();
    return '${_titleText.trim()}\n${_contentText.trim()}';
  }

  (String, String) _parseTitleAndBody(String text, {required bool isFinal}) {
    final l10n = AppLocalizations.of(context)!;
    final lines = text.split('\n').map((e) => e.trim()).toList();
    while (lines.isNotEmpty && lines.first.isEmpty) {
      lines.removeAt(0);
    }
    if (lines.isEmpty) {
      return (isFinal ? l10n.creationContent : l10n.creatingInProgress, '');
    }

    final first = lines.first;
    if (first.length > 2 && first.length < 100) {
      final body = lines.skip(1).where((line) => line.isNotEmpty).join('\n');
      return (first, body);
    }

    return (isFinal ? l10n.creationContent : l10n.creatingInProgress, lines.join('\n'));
  }

  /// 移除 Markdown 符号（对齐 iOS AIUAToolsManager removeMarkdownSymbols）
  /// 使用 replaceAllMapped 避免将 r'$1' 当作字面量输出导致内容出现 "$1"
  String _removeMarkdownSymbols(String text) {
    var value = text;
    value = value.replaceAll(RegExp(r'`{1,3}'), '');
    value = value.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '');
    value = value.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => m.group(1)!);
    value = value.replaceAllMapped(RegExp(r'\*(.*?)\*'), (m) => m.group(1)!);
    value = value.replaceAllMapped(RegExp(r'_(.*?)_'), (m) => m.group(1)!);
    value = value.replaceAllMapped(RegExp(r'~~(.*?)~~'), (m) => m.group(1)!);
    value = value.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
    value = value.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
    value = value.replaceAll(RegExp(r'^\s*\$\d+\s*', multiLine: true), '');
    return value.trim();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _showInsufficientWordsDialog(int need, int available) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.insufficientWords),
        content: Text(l10n.insufficientWordsMessage(need, available)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pushNamed(AppRoute.wordPack.name);
            },
            child: Text(l10n.purchaseWordPack),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark ? Theme.of(context).dividerColor : _kDetailCardBorder;
    final displayTitle =
        _titleText.isEmpty ? (_isGenerating ? l10n.creatingInProgress : l10n.untitledDocument) : _titleText;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _saveIfHasContentAndPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.creationDetails),
        ),
        body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      displayTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (_contentText.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Divider(height: 1, color: borderColor),
                      const SizedBox(height: 20),
                    ],
                    SelectableText(
                      _contentText,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isGenerating)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: _stopGenerating,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kDetailStopText,
                    backgroundColor: _kDetailStopBg,
                    side: const BorderSide(color: _kDetailStopBorder),
                    minimumSize: const Size(120, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.stop, size: 16),
                  label: Text(l10n.stopGenerating),
                ),
              ),
            ),
          if (!_isGenerating)
            SafeArea(
              top: false,
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                      offset: const Offset(0, -2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: Icons.autorenew,
                      label: l10n.rewrite,
                      onTap: _rewrite,
                    ),
                    _ActionButton(
                      icon: Icons.copy_all_outlined,
                      label: l10n.copy,
                      onTap: _copyAll,
                    ),
                    _ActionButton(
                      icon: Icons.ios_share_outlined,
                      label: l10n.export,
                      onTap: _export,
                    ),
                    _ActionButton(
                      icon: Icons.edit_outlined,
                      label: l10n.edit,
                      onTap: _edit,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  /// 返回时若有内容则自动保存为文档再 pop；若用户点击过停止则只返回不保存
  Future<void> _saveIfHasContentAndPop() async {
    if (_userStoppedCreation) {
      if (mounted) context.pop();
      return;
    }
    final fullText = _buildFullText();
    if (fullText.isEmpty) {
      if (mounted) context.pop();
      return;
    }
    final provider = context.read<DocumentProvider>();
    final title = _titleText.isEmpty ? widget.args.item.title : _titleText;
    final content = _contentText;
    if (_editingDocument == null) {
      _editingDocument = await provider.createDocument(
        title: title,
        content: content,
        refreshList: true,
      );
    } else {
      final updated = _editingDocument!.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
      );
      await provider.updateDocument(updated);
      _editingDocument = updated;
    }
    if (!mounted) return;
    context.pop();
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
