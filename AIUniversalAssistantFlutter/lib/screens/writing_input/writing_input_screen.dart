import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../services/vip_service.dart';
import '../../services/ai_service.dart';
import '../../services/word_pack_service.dart';
import '../../utils/app_localizations_helper.dart';
import '../../utils/word_counter.dart';
import '../../models/writing_model.dart';
import 'writing_detail_screen.dart';

class WritingInputScreen extends StatefulWidget {
  final Map<String, dynamic>? template;

  const WritingInputScreen({super.key, this.template});

  @override
  State<WritingInputScreen> createState() => _WritingInputScreenState();
}

class _WritingInputScreenState extends State<WritingInputScreen> {
  final TextEditingController _themeController = TextEditingController();
  final TextEditingController _requirementController = TextEditingController();
  final TextEditingController _wordCountController = TextEditingController();
  final DataService _dataService = DataService();
  final AIService _aiService = AIService();
  final WordPackService _wordPackService = WordPackService();
  bool _unlimitedWords = false;
  String? _selectedStyle;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _requirementController.text = widget.template!['content'] ?? '';
    }
  }

  @override
  void dispose() {
    _themeController.dispose();
    _requirementController.dispose();
    _wordCountController.dispose();
    _aiService.cancel();
    super.dispose();
  }

  Future<void> _startWriting() async {
    if (_requirementController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.translate('please_enter_main_content_first'))),
      );
      return;
    }

    // 检查字数
    final wordCount = _unlimitedWords 
        ? 0 
        : (int.tryParse(_wordCountController.text) ?? 1000);
    
    if (wordCount > 0) {
      final hasEnough = await _wordPackService.hasEnoughWords(wordCount);
      if (!hasEnough) {
        final available = await _wordPackService.totalAvailableWords();
        _showInsufficientWordsDialog(wordCount, available);
        return;
      }
    }

    setState(() {
      _isGenerating = true;
    });

    // 构建prompt
    final prompt = _buildPrompt();
    final record = WritingRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _themeController.text.trim().isEmpty 
          ? '无标题' 
          : _themeController.text.trim(),
      content: '',
      prompt: prompt,
      theme: _themeController.text.trim().isEmpty ? null : _themeController.text.trim(),
      requirement: _requirementController.text.trim(),
      wordCount: wordCount > 0 ? wordCount : null,
      style: _selectedStyle,
      createTime: DateTime.now(),
      updateTime: DateTime.now(),
      type: 'create',
    );

    // 导航到生成页面
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WritingDetailScreen(
            record: record,
            isNew: true,
          ),
        ),
      );
      setState(() {
        _isGenerating = false;
      });
    }
  }

  String _buildPrompt() {
    String prompt = _requirementController.text.trim();
    if (_selectedStyle != null) {
      prompt += '\n\n请使用$_selectedStyle风格进行写作。';
    }
    return prompt;
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 导航到字数包页面
              // Navigator.of(context).push(...);
            },
            child: Text(context.l10n.translate('purchase_word_pack')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('creation_details')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主题输入
            TextField(
              controller: _themeController,
              decoration: InputDecoration(
                labelText: context.l10n.translate('theme'),
                hintText: context.l10n.translate('enter_creation_theme'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // 要求输入
            TextField(
              controller: _requirementController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: context.l10n.translate('require'),
                hintText: context.l10n.translate('enter_specific_requirements'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // 字数设置
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wordCountController,
                    enabled: !_unlimitedWords,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.l10n.translate('maximum_word_count'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Checkbox(
                  value: _unlimitedWords,
                  onChanged: (value) {
                    setState(() {
                      _unlimitedWords = value ?? false;
                    });
                  },
                ),
                Text(context.l10n.translate('unlimited')),
              ],
            ),
            const SizedBox(height: 16),
            // 风格选择
            DropdownButtonFormField<String>(
              value: _selectedStyle,
              decoration: InputDecoration(
                labelText: context.l10n.translate('select_style'),
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '通用', child: Text('通用')),
                DropdownMenuItem(value: '新闻', child: Text('新闻')),
                DropdownMenuItem(value: '学术', child: Text('学术')),
                DropdownMenuItem(value: '公务', child: Text('公务')),
                DropdownMenuItem(value: '小说', child: Text('小说')),
                DropdownMenuItem(value: '作文', child: Text('作文')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStyle = value;
                });
              },
            ),
            const SizedBox(height: 32),
            // 生成按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _startWriting,
                child: _isGenerating
                    ? const CircularProgressIndicator()
                    : Text(context.l10n.translate('start_creating')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

