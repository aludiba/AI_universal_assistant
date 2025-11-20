import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../services/vip_service.dart';
import '../../services/ai_service.dart';
import '../../services/word_pack_service.dart';
import '../../utils/app_localizations_helper.dart';
import '../../utils/app_localizations_helper.dart';
import '../../models/writing_model.dart';

enum EditAction { continueWriting, rewrite, expand, translate }

class DocumentDetailScreen extends StatefulWidget {
  final WritingRecord? document;
  final bool isNew;

  const DocumentDetailScreen({
    super.key,
    this.document,
    this.isNew = false,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final DataService _dataService = DataService();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isNew && widget.document != null) {
      _titleController.text = widget.document!.title;
      _contentController.text = widget.document!.content;
    } else {
      _isEditing = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveDocument() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.translate('enter_title'))),
      );
      return;
    }

    final doc = Document(
      id: widget.document?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      createTime: widget.document?.createTime ?? DateTime.now(),
      updateTime: DateTime.now(),
    );

    await _dataService.saveDocument(doc);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showEditActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text(context.l10n.translate('continue_writing')),
              onTap: () {
                Navigator.pop(context);
                _performEdit(EditAction.continueWriting);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(context.l10n.translate('rewrite')),
              onTap: () {
                Navigator.pop(context);
                _performEdit(EditAction.rewrite);
              },
            ),
            ListTile(
              leading: const Icon(Icons.expand_circle_down),
              title: Text(context.l10n.translate('expand_writing')),
              onTap: () {
                Navigator.pop(context);
                _performEdit(EditAction.expand);
              },
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: Text(context.l10n.translate('translate')),
              onTap: () {
                Navigator.pop(context);
                _performEdit(EditAction.translate);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performEdit(EditAction action) async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.translate('please_enter_main_content_first'))),
      );
      return;
    }

    // 检查VIP权限
    final vipService = VIPService();
    final isVIP = await vipService.isVIP();
    if (!isVIP) {
      _showVIPDialog();
      return;
    }

    // 检查字数
    final wordCount = _estimateWordCount(action);
    final wordPackService = WordPackService();
    final hasEnough = await wordPackService.hasEnoughWords(wordCount);
    if (!hasEnough) {
      final available = await wordPackService.totalAvailableWords();
      _showInsufficientWordsDialog(wordCount, available);
      return;
    }

    // 直接调用AI服务生成
    final aiService = AIService();
    final prompt = _buildPrompt(action);
    
    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await aiService.generate(
        prompt: prompt,
        wordCount: wordCount,
      );

      if (mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        
        // 更新文档内容
        if (action == EditAction.rewrite || action == EditAction.expand || action == EditAction.translate) {
          _contentController.text = result;
        } else if (action == EditAction.continueWriting) {
          _contentController.text += '\n\n$result';
        }
        
        // 消耗字数
        final inputWords = _contentController.text.length;
        final outputWords = result.length;
        await wordPackService.consumeWords(inputWords + outputWords);
        
        _saveDocument();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    }
  }

  int _estimateWordCount(EditAction action) {
    final baseWords = _contentController.text.length;
    switch (action) {
      case EditAction.continueWriting:
        return baseWords > 500 ? baseWords : 500;
      case EditAction.rewrite:
        return baseWords > 300 ? baseWords : 300;
      case EditAction.expand:
        return (baseWords * 2).clamp(500, 2000);
      case EditAction.translate:
        return baseWords > 500 ? baseWords : 500;
    }
  }

  String _buildPrompt(EditAction action) {
    final content = _contentController.text.trim();
    switch (action) {
      case EditAction.continueWriting:
        return '${context.l10n.translate('please_continue_based_on_the_following')}\n\n$content';
      case EditAction.rewrite:
        return '${context.l10n.translate('please_rewrite_the_following')}\n\n$content';
      case EditAction.expand:
        return '${context.l10n.translate('please_expand_the_following')}\n\n$content';
      case EditAction.translate:
        return '${context.l10n.translate('please_translate_the_following_to')} 英文\n\n$content';
    }
  }

  void _showVIPDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.translate('vip_unlock_required')),
        content: Text(context.l10n.translate('vip_general_locked_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 导航到会员页面
            },
            child: Text(context.l10n.translate('unlock_vip_features')),
          ),
        ],
      ),
    );
  }

  void _showInsufficientWordsDialog(int needed, int available) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.translate('insufficient_words')),
        content: Text(
          context.l10n.translate('insufficient_words_message', [needed, available]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.translate('cancel')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing || widget.isNew
            ? context.l10n.translate('document_details')
            : _titleController.text),
        actions: [
          if (!widget.isNew && !_isEditing)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showEditActionSheet,
            ),
          if (_isEditing || widget.isNew)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveDocument,
            ),
          if (!widget.isNew && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isEditing || widget.isNew)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: context.l10n.translate('enter_title'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          Expanded(
            child: TextField(
              controller: _contentController,
              readOnly: !_isEditing && !widget.isNew,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: context.l10n.translate('enter_main_text'),
                border: _isEditing || widget.isNew
                    ? const OutlineInputBorder()
                    : InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }
}

