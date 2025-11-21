import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ai_service.dart';
import '../../services/word_pack_service.dart';
import '../../services/data_service.dart';
import '../../utils/app_localizations_helper.dart';
import '../../utils/word_counter.dart';
import '../../models/writing_model.dart';

class WritingDetailScreen extends StatefulWidget {
  final WritingRecord record;
  final bool isNew;

  const WritingDetailScreen({
    super.key,
    required this.record,
    this.isNew = false,
  });

  @override
  State<WritingDetailScreen> createState() => _WritingDetailScreenState();
}

class _WritingDetailScreenState extends State<WritingDetailScreen> {
  final TextEditingController _contentController = TextEditingController();
  final AIService _aiService = AIService();
  final WordPackService _wordPackService = WordPackService();
  final DataService _dataService = DataService();
  bool _isGenerating = false;
  bool _isCompleted = false;
  StreamSubscription<String>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.record.content;
    if (widget.isNew && widget.record.content.isEmpty) {
      _startGeneration();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _streamSubscription?.cancel();
    _aiService.cancel();
    super.dispose();
  }

  Future<void> _startGeneration() async {
    if (widget.record.prompt == null || widget.record.prompt!.isEmpty) {
      return;
    }

    setState(() {
      _isGenerating = true;
      _isCompleted = false;
      _contentController.clear();
    });

    try {
      final wordCount = widget.record.wordCount ?? 0;
      final stream = _aiService.generateStream(
        prompt: widget.record.prompt!,
        wordCount: wordCount > 0 ? wordCount : null,
      );

      _streamSubscription = stream.listen(
        (chunk) {
          setState(() {
            _contentController.text += chunk;
          });
        },
        onDone: () {
          _onGenerationComplete();
        },
        onError: (error) {
          setState(() {
            _isGenerating = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('生成失败: $error')),
            );
          }
        },
      );
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    }
  }

  void _onGenerationComplete() {
    setState(() {
      _isGenerating = false;
      _isCompleted = true;
    });

    // 消耗字数
    final finalText = _contentController.text;
    if (finalText.isNotEmpty) {
      // 输入字数以prompt为准
      final inputWords = WordCounter.countWords(widget.record.prompt ?? '');
      final outputWords = WordCounter.countWords(finalText);
      final totalWords = inputWords + outputWords;

      _wordPackService.consumeWords(totalWords).then((result) {
        if (result.success) {
          print('消耗字数成功: $totalWords 字，剩余: ${result.remainingWords} 字');
        }
      });
    }

    // 保存记录
    _saveRecord();
  }

  Future<void> _saveRecord() async {
    final record = WritingRecord(
      id: widget.record.id,
      title: widget.record.title,
      content: _contentController.text,
      prompt: widget.record.prompt,
      theme: widget.record.theme,
      requirement: widget.record.requirement,
      wordCount: widget.record.wordCount,
      style: widget.record.style,
      createTime: widget.record.createTime,
      updateTime: DateTime.now(),
      type: widget.record.type,
    );

    await _dataService.saveWritingRecord(record);
  }

  void _stopGenerating() {
    _streamSubscription?.cancel();
    _aiService.cancel();
    setState(() {
      _isGenerating = false;
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _contentController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.translate('copied_to_clipboard'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record.title.isEmpty 
            ? context.l10n.translate('creation_details')
            : widget.record.title),
        actions: [
          if (_isGenerating)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopGenerating,
              tooltip: context.l10n.translate('stop_generating'),
            )
          else if (_contentController.text.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyToClipboard,
              tooltip: context.l10n.translate('copy'),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startGeneration,
              tooltip: context.l10n.translate('regenerate'),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_isGenerating)
            LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                readOnly: _isGenerating,
                decoration: InputDecoration(
                  hintText: _isGenerating 
                      ? context.l10n.translate('creating_in_progress')
                      : context.l10n.translate('generated_content'),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

