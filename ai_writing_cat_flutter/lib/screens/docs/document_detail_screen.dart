import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/document_provider.dart';
import '../../models/document_model.dart';
import '../../services/data_manager.dart';
import '../../services/deepseek_service.dart';

enum DocumentToolbarAction {
  continueWrite,
  rewrite,
  expand,
  translate,
}

enum DocumentBottomPanel {
  none,
  selection,
  generation,
}

class DocumentDetailUiState {
  final bool isLoading;
  final bool notFound;
  final bool isDirty;
  final bool isSaving;
  final DocumentBottomPanel panel;
  final DocumentToolbarAction? action;
  final String selectedStyle;
  final String selectedLength;
  final String selectedLanguage;
  final bool isGenerating;
  final String generatedContent;

  const DocumentDetailUiState({
    required this.isLoading,
    required this.notFound,
    required this.isDirty,
    required this.isSaving,
    required this.panel,
    required this.action,
    required this.selectedStyle,
    required this.selectedLength,
    required this.selectedLanguage,
    required this.isGenerating,
    required this.generatedContent,
  });

  factory DocumentDetailUiState.initial() {
    return const DocumentDetailUiState(
      isLoading: true,
      notFound: false,
      isDirty: false,
      isSaving: false,
      panel: DocumentBottomPanel.none,
      action: null,
      selectedStyle: 'general',
      selectedLength: 'medium',
      selectedLanguage: 'english',
      isGenerating: false,
      generatedContent: '',
    );
  }

  DocumentDetailUiState copyWith({
    bool? isLoading,
    bool? notFound,
    bool? isDirty,
    bool? isSaving,
    DocumentBottomPanel? panel,
    DocumentToolbarAction? action,
    bool clearAction = false,
    String? selectedStyle,
    String? selectedLength,
    String? selectedLanguage,
    bool? isGenerating,
    String? generatedContent,
  }) {
    return DocumentDetailUiState(
      isLoading: isLoading ?? this.isLoading,
      notFound: notFound ?? this.notFound,
      isDirty: isDirty ?? this.isDirty,
      isSaving: isSaving ?? this.isSaving,
      panel: panel ?? this.panel,
      action: clearAction ? null : (action ?? this.action),
      selectedStyle: selectedStyle ?? this.selectedStyle,
      selectedLength: selectedLength ?? this.selectedLength,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      isGenerating: isGenerating ?? this.isGenerating,
      generatedContent: generatedContent ?? this.generatedContent,
    );
  }
}

class DocumentDetailUiNotifier extends Notifier<DocumentDetailUiState> {
  @override
  DocumentDetailUiState build() {
    return DocumentDetailUiState.initial();
  }

  void finishLoading({required bool notFound}) {
    state = state.copyWith(isLoading: false, notFound: notFound);
  }

  void setDirty(bool value) {
    if (state.isDirty != value) {
      state = state.copyWith(isDirty: value);
    }
  }

  void setSaving(bool value) {
    state = state.copyWith(isSaving: value);
  }

  void openSelection(DocumentToolbarAction action) {
    state = state.copyWith(action: action, panel: DocumentBottomPanel.selection);
  }

  void showGeneration() {
    state = state.copyWith(panel: DocumentBottomPanel.generation);
  }

  void hidePanels() {
    state = state.copyWith(panel: DocumentBottomPanel.none, clearAction: true);
  }

  void selectStyle(String value) {
    state = state.copyWith(selectedStyle: value);
  }

  void selectLength(String value) {
    state = state.copyWith(selectedLength: value);
  }

  void selectLanguage(String value) {
    state = state.copyWith(selectedLanguage: value);
  }

  void startGenerating() {
    state = state.copyWith(
      isGenerating: true,
      panel: DocumentBottomPanel.generation,
      generatedContent: '',
    );
  }

  /// 流式输出时追加内容（对齐 iOS）
  void appendGeneratedContent(String chunk) {
    if (chunk.isEmpty) return;
    state = state.copyWith(
      generatedContent: state.generatedContent + chunk,
    );
  }

  void finishGenerating(String content) {
    state = state.copyWith(
      isGenerating: false,
      panel: DocumentBottomPanel.generation,
      generatedContent: content,
    );
  }

  void stopGenerating() {
    state = state.copyWith(isGenerating: false);
  }
}

final documentDetailUiProvider =
    NotifierProvider.autoDispose<DocumentDetailUiNotifier, DocumentDetailUiState>(
  DocumentDetailUiNotifier.new,
);

/// 文档详情页面
class DocumentDetailScreen extends ConsumerStatefulWidget {
  final String documentId;
  
  const DocumentDetailScreen({
    super.key,
    required this.documentId,
  });

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  final DataManager _dataManager = DataManager();
  final DeepSeekService _deepSeekService = DeepSeekService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  final ScrollController _generationScrollController = ScrollController();
  DocumentModel? _currentDocument;
  bool _saveInProgress = false;
  bool _titleExtractedFromGeneration = false;
  /// 删除文档后调用 pop，此时不再保存
  bool _poppingAfterDelete = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeDocument());
  }

  @override
  void dispose() {
    _generationScrollController.dispose();
    _deepSeekService.cancelCurrentRequest();
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    ref.read(documentDetailUiProvider.notifier).setDirty(true);
  }

  Future<void> _initializeDocument() async {
    final uiNotifier = ref.read(documentDetailUiProvider.notifier);
    try {
      final provider = context.read<DocumentProvider>();
      DocumentModel? document = provider.getDocumentById(widget.documentId);
      document ??= await _dataManager.getDocumentById(widget.documentId);

      if (!mounted) return;
      if (document == null) {
        uiNotifier.finishLoading(notFound: true);
        return;
      }

      _currentDocument = document;
      _titleController.text = document.title;
      _contentController.text = document.content;
      uiNotifier.setDirty(false);
      uiNotifier.finishLoading(notFound: false);
    } catch (_) {
      if (!mounted) return;
      uiNotifier.finishLoading(notFound: true);
    }
  }

  Future<void> _saveIfNeeded({bool showMessage = false}) async {
    if (_saveInProgress) return;
    final uiState = ref.read(documentDetailUiProvider);
    if (!uiState.isDirty || _currentDocument == null) return;

    _saveInProgress = true;
    final uiNotifier = ref.read(documentDetailUiProvider.notifier);
    uiNotifier.setSaving(true);
    try {
      if (_isDocumentEmpty()) {
        await context.read<DocumentProvider>().deleteDocument(_currentDocument!.id);
      } else {
        final updated = _currentDocument!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text,
          updatedAt: DateTime.now(),
        );
        await context.read<DocumentProvider>().updateDocument(updated);
        _currentDocument = updated;
        // 若该文档对应创作记录，同步标题与内容回创作记录表（与 iOS 一致）
        final writingRecord = await _dataManager.getWritingRecordById(updated.id);
        if (writingRecord != null) {
          await _dataManager.updateWritingRecord(writingRecord.copyWith(
            templateTitle: updated.title,
            generatedContent: updated.content,
            wordCount: updated.content.length,
          ));
        }
      }
      uiNotifier.setDirty(false);
      if (mounted && showMessage) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.savedSuccess)),
        );
      }
    } catch (_) {
      if (mounted && showMessage) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failure)),
        );
      }
    } finally {
      uiNotifier.setSaving(false);
      _saveInProgress = false;
    }
  }

  bool _isDocumentEmpty() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    return title.isEmpty && content.isEmpty;
  }

  Future<void> _handleExit({bool shouldPersist = true}) async {
    if (_currentDocument == null) return;
    if (!shouldPersist) {
      _deepSeekService.cancelCurrentRequest();
      return;
    }
    if (_isDocumentEmpty()) {
      await context.read<DocumentProvider>().deleteDocument(_currentDocument!.id);
      ref.read(documentDetailUiProvider.notifier).setDirty(false);
      return;
    }
    await _saveIfNeeded();
  }

  Future<void> _showMoreActions() async {
    final doc = _currentDocument;
    if (doc == null) return;
    final l10n = AppLocalizations.of(context)!;

    final fullTitle = _titleController.text.trim();
    final displayTitle = fullTitle.isEmpty ? l10n.untitledDocument : fullTitle;
    final content = _contentController.text;
    final docProvider = context.read<DocumentProvider>();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.export),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _dataManager.exportDocument(displayTitle, content);
                },
              ),
              ListTile(
                title: Text(l10n.copy),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Clipboard.setData(
                    ClipboardData(
                      text: '$displayTitle\n${content.isEmpty ? '' : '\n$content'}',
                    ),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.copiedToClipboard)),
                  );
                },
              ),
              ListTile(
                title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final ok = await _confirmDelete();
                  if (!ok) return;
                  // 与 iOS 一致：删除文档时同时删除同 id 的创作记录
                  await _dataManager.deleteWritingWithID(doc.id);
                  await docProvider.deleteDocument(doc.id);
                  if (!mounted) return;
                  setState(() => _poppingAfterDelete = true);
                  if (context.canPop()) {
                    context.pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConfirm),
        content: Text(l10n.deleteDocumentPrompt(_titleController.text.trim().isEmpty ? l10n.untitledDocument : _titleController.text.trim())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _onToolbarAction(DocumentToolbarAction action) {
    final l10n = AppLocalizations.of(context)!;
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterMainText)),
      );
      return;
    }
    _dismissKeyboard();
    ref.read(documentDetailUiProvider.notifier).openSelection(action);
  }

  Future<void> _startGeneration() async {
    final uiNotifier = ref.read(documentDetailUiProvider.notifier);
    final uiState = ref.read(documentDetailUiProvider);
    final action = uiState.action;
    if (action == null) return;

    _dismissKeyboard();
    _titleExtractedFromGeneration = false;
    uiNotifier.startGenerating();

    Stream<String> stream;
    switch (action) {
      case DocumentToolbarAction.continueWrite:
        stream = _deepSeekService.continueWritingStream(
          content: _contentController.text.trim(),
          style: uiState.selectedStyle,
        );
        break;
      case DocumentToolbarAction.rewrite:
        stream = _deepSeekService.rewriteTextStream(
          content: _contentController.text.trim(),
          style: uiState.selectedStyle,
        );
        break;
      case DocumentToolbarAction.expand:
        stream = _deepSeekService.expandTextStream(
          content: _contentController.text.trim(),
          length: uiState.selectedLength,
          style: uiState.selectedStyle,
        );
        break;
      case DocumentToolbarAction.translate:
        stream = _deepSeekService.translateTextStream(
          content: _contentController.text.trim(),
          targetLanguage: uiState.selectedLanguage,
        );
        break;
    }

    try {
      var accumulated = '';
      await for (final chunk in stream) {
        if (!mounted) return;
        accumulated += chunk;
        uiNotifier.appendGeneratedContent(chunk);
        if (!_titleExtractedFromGeneration &&
            _titleController.text.trim().isEmpty &&
            accumulated.contains('\n')) {
          _titleExtractedFromGeneration = true;
          _tryExtractTitleFromContent(accumulated);
        }
      }
      if (!mounted) return;
      uiNotifier.finishGenerating(accumulated);
      if (!_titleExtractedFromGeneration) {
        _tryExtractTitleFromContent(accumulated);
      }
    } catch (e) {
      if (!mounted) return;
      uiNotifier.stopGenerating();
      final msg = e.toString();
      if (!msg.contains('ClientException')) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.creationFailed}: $msg')),
        );
      }
    }
  }

  void _stopGeneration() {
    _deepSeekService.cancelCurrentRequest();
    ref.read(documentDetailUiProvider.notifier).stopGenerating();
  }

  void _insertGeneratedText() {
    final uiState = ref.read(documentDetailUiProvider);
    if (uiState.generatedContent.isEmpty) return;

    final selectedRange = _contentController.selection;
    if (selectedRange.isValid && !selectedRange.isCollapsed) {
      final newText = _contentController.text.replaceRange(
        selectedRange.start,
        selectedRange.end,
        uiState.generatedContent,
      );
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset: (selectedRange.start + uiState.generatedContent.length).toInt(),
      );
    } else {
      final base = _contentController.text;
      _contentController.text = base.isEmpty
          ? uiState.generatedContent
          : '$base\n${uiState.generatedContent}';
      _contentController.selection = TextSelection.collapsed(
        offset: _contentController.text.length,
      );
    }
    ref.read(documentDetailUiProvider.notifier).setDirty(true);
    _tryExtractTitleFromContent(_contentController.text);
    ref.read(documentDetailUiProvider.notifier).hidePanels();
  }

  void _overwriteWithGeneratedText() {
    final uiState = ref.read(documentDetailUiProvider);
    if (uiState.generatedContent.isEmpty) return;
    _contentController.text = uiState.generatedContent;
    _contentController.selection = TextSelection.collapsed(
      offset: _contentController.text.length,
    );
    ref.read(documentDetailUiProvider.notifier).setDirty(true);
    _tryExtractTitleFromContent(_contentController.text);
    ref.read(documentDetailUiProvider.notifier).hidePanels();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  /// 移除简单 Markdown 符号（对齐 iOS AIUAToolsManager removeMarkdownSymbols）
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

  /// 从内容首行提取标题（对齐 iOS tryExtractTitleFromContent）
  void _tryExtractTitleFromContent(String content) {
    if (_titleController.text.trim().isNotEmpty) return;
    final lines = content.split('\n');
    if (lines.isEmpty) return;
    final firstLine = lines.first.trim();
    if (firstLine.length < 2 || firstLine.length > 100) return;
    final cleanTitle = _removeMarkdownSymbols(firstLine);
    if (cleanTitle.isEmpty) return;
    _titleController.text = cleanTitle;
    ref.read(documentDetailUiProvider.notifier).setDirty(true);
  }

  void _scrollGenerationToBottom() {
    if (!_generationScrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_generationScrollController.hasClients) return;
      final pos = _generationScrollController.position;
      if (pos.maxScrollExtent > pos.pixels) {
        _generationScrollController.animateTo(
          pos.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uiState = ref.watch(documentDetailUiProvider);
    ref.listen(documentDetailUiProvider, (prev, next) {
      if (next.isGenerating &&
          (prev?.generatedContent.length ?? 0) < next.generatedContent.length) {
        _scrollGenerationToBottom();
      }
    });

    if (uiState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (uiState.notFound) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.documentDetails)),
        body: Center(child: Text(l10n.documentNotFound)),
      );
    }

    // 先保存再 pop，避免返回创作记录/文档列表时列表在保存完成前刷新导致内容不更新
    return PopScope(
      canPop: _poppingAfterDelete,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_poppingAfterDelete) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
          return;
        }
        final isGenerating = ref.read(documentDetailUiProvider).isGenerating;
        await _handleExit(shouldPersist: !isGenerating);
        if (!mounted) return;
        setState(() => _poppingAfterDelete = true);
        context.pop();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.white,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(l10n.editDocument),
          actions: [
            if (uiState.isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (uiState.isDirty)
              IconButton(
                icon: const Icon(Icons.save_outlined),
                onPressed: () => _saveIfNeeded(showMessage: true),
              ),
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: _showMoreActions,
            ),
          ],
        ),
        bottomNavigationBar: _buildToolbar(context, uiState),
        body: Stack(
          children: [
            GestureDetector(
              onTap: _dismissKeyboard,
              behavior: HitTestBehavior.translucent,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      maxLines: 2,
                      minLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextPrimary(context),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        hintText: l10n.enterTitle,
                        hintStyle: TextStyle(color: AppColors.getTextSecondary(context)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    color: AppColors.getDivider(context),
                  ),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _contentController,
                              focusNode: _contentFocusNode,
                              maxLines: null,
                              minLines: 4,
                              keyboardType: TextInputType.multiline,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: AppColors.getTextPrimary(context),
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: false,
                                border: InputBorder.none,
                                hintText: l10n.enterMainText,
                                hintStyle: TextStyle(color: AppColors.getTextSecondary(context)),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (uiState.panel == DocumentBottomPanel.selection)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildSelectionPanel(context, uiState),
              ),
            if (uiState.panel == DocumentBottomPanel.generation)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildGenerationPanel(context, uiState),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, DocumentDetailUiState uiState) {
    final l10n = AppLocalizations.of(context)!;
    final items = <({IconData icon, String label, DocumentToolbarAction action})>[
      (icon: Icons.edit_note, label: l10n.continueWriting, action: DocumentToolbarAction.continueWrite),
      (icon: Icons.auto_fix_high, label: l10n.rewrite, action: DocumentToolbarAction.rewrite),
      (icon: Icons.add_chart, label: l10n.expandWriting, action: DocumentToolbarAction.expand),
      (icon: Icons.translate, label: l10n.translate, action: DocumentToolbarAction.translate),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 60,
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF252525)
            : const Color(0xFFF2F2F2),
        child: Row(
          children: items
              .map(
                (item) => Expanded(
                  child: InkWell(
                    onTap: () => _onToolbarAction(item.action),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 18,
                          color: uiState.action == item.action
                              ? AppColors.primary
                              : AppColors.getTextPrimary(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: uiState.action == item.action
                                ? AppColors.primary
                                : AppColors.getTextPrimary(context),
                            fontWeight: uiState.action == item.action
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSelectionPanel(BuildContext context, DocumentDetailUiState uiState) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(documentDetailUiProvider.notifier);
    final action = uiState.action;
    String title = l10n.selectStyle;
    List<String> options = const <String>['general', 'news', 'academic', 'official', 'novel', 'essay'];
    String selected = uiState.selectedStyle;
    void Function(String) onSelect = notifier.selectStyle;

    if (action == DocumentToolbarAction.expand) {
      title = l10n.expansionLength;
      options = const <String>['medium', 'longer'];
      selected = uiState.selectedLength;
      onSelect = notifier.selectLength;
    } else if (action == DocumentToolbarAction.translate) {
      title = l10n.targetLanguage;
      options = const <String>['english', 'chinese', 'japanese'];
      selected = uiState.selectedLanguage;
      onSelect = notifier.selectLanguage;
    }

    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF202020)
          : const Color(0xFFFAFAFA),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: notifier.hidePanels,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options
                  .map(
                    (item) => ChoiceChip(
                      label: Text(_localizedOption(l10n, item)),
                      selected: selected == item,
                      onSelected: (_) => onSelect(item),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _startGeneration,
                child: Text(l10n.generate),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationPanel(BuildContext context, DocumentDetailUiState uiState) {
    final l10n = AppLocalizations.of(context)!;
    final showOverwrite = uiState.action == DocumentToolbarAction.rewrite ||
        uiState.action == DocumentToolbarAction.expand ||
        uiState.action == DocumentToolbarAction.translate;
    final canOperate = uiState.generatedContent.isNotEmpty && !uiState.isGenerating;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF202020) : const Color(0xFFFAFAFA),
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: uiState.isGenerating
                        ? null
                        : () => ref.read(documentDetailUiProvider.notifier).openSelection(uiState.action!),
                    icon: Icon(Icons.chevron_left, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.generatedContentTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const Spacer(),
                  if (uiState.isGenerating)
                    InkWell(
                      onTap: _stopGeneration,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF4B0505) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? const Color(0xFF781414) : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stop_rounded, size: 18, color: Colors.red.shade400),
                            const SizedBox(width: 6),
                            Text(
                              l10n.stopGenerating,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
                decoration: BoxDecoration(
                  color: AppColors.getCardBackground(context),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.getDivider(context)),
                ),
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  controller: _generationScrollController,
                  child: Text(
                    uiState.generatedContent.isEmpty
                        ? (uiState.isGenerating ? l10n.generatingShort : l10n.generatedContentPlaceholder)
                        : uiState.generatedContent,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: uiState.generatedContent.isEmpty
                          ? AppColors.getTextSecondary(context)
                          : AppColors.getTextPrimary(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: uiState.isGenerating ? null : _startGeneration,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.getTextPrimary(context),
                        side: BorderSide(color: AppColors.getDivider(context)),
                        backgroundColor: AppColors.getCardBackground(context),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(l10n.regenerate),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: canOperate ? _insertGeneratedText : null,
                      style: TextButton.styleFrom(
                        foregroundColor: canOperate
                            ? AppColors.primary
                            : AppColors.getTextSecondary(context),
                        backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
                      ),
                      child: Text(l10n.insert),
                    ),
                  ),
                  if (showOverwrite) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextButton(
                        onPressed: canOperate ? _overwriteWithGeneratedText : null,
                        style: TextButton.styleFrom(
                          foregroundColor: canOperate
                              ? AppColors.primary
                              : AppColors.getTextSecondary(context),
                          backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
                        ),
                        child: Text(l10n.overwriteOriginal),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _localizedOption(AppLocalizations l10n, String key) {
    switch (key) {
      case 'general':
        return l10n.general;
      case 'news':
        return l10n.news;
      case 'academic':
        return l10n.academic;
      case 'official':
        return l10n.official;
      case 'novel':
        return l10n.novel;
      case 'essay':
        return l10n.essay;
      case 'medium':
        return l10n.medium;
      case 'longer':
        return l10n.longer;
      case 'english':
        return l10n.english;
      case 'chinese':
        return l10n.chinese;
      case 'japanese':
        return l10n.japanese;
      default:
        return key;
    }
  }
}
