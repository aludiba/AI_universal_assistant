import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/deepseek_service.dart';
import '../../constants/app_styles.dart';
import 'writer_screen.dart';

/// AI写作页面
class AIWritingScreen extends StatefulWidget {
  final WritingType type;
  final String? initialContent;
  
  const AIWritingScreen({
    super.key,
    required this.type,
    this.initialContent,
  });

  @override
  State<AIWritingScreen> createState() => _AIWritingScreenState();
}

class _AIWritingScreenState extends State<AIWritingScreen> {
  final _deepseekService = DeepSeekService();
  final _promptController = TextEditingController();
  final _contentController = TextEditingController();
  final _resultController = TextEditingController();
  
  bool _isGenerating = false;
  String _selectedStyle = '通用';
  String _selectedLanguage = '中文';
  
  final List<String> _styles = ['通用', '新闻', '学术', '公务', '小说', '作文'];
  final List<String> _languages = ['中文', '英文', '日文'];
  
  @override
  void initState() {
    super.initState();
    if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }
  }
  
  @override
  void dispose() {
    _promptController.dispose();
    _contentController.dispose();
    _resultController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          if (_resultController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyResult,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        children: [
          // 输入区域
          _buildInputSection(),
          
          const SizedBox(height: AppStyles.paddingLarge),
          
          // 生成按钮
          _buildGenerateButton(),
          
          const SizedBox(height: AppStyles.paddingLarge),
          
          // 结果区域
          if (_resultController.text.isNotEmpty || _isGenerating)
            _buildResultSection(),
        ],
      ),
    );
  }
  
  Widget _buildInputSection() {
    switch (widget.type) {
      case WritingType.free:
        return _buildFreeWritingInput();
      case WritingType.continue_:
        return _buildContinueInput();
      case WritingType.rewrite:
        return _buildRewriteInput();
      case WritingType.expand:
        return _buildExpandInput();
      case WritingType.translate:
        return _buildTranslateInput();
    }
  }
  
  Widget _buildFreeWritingInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('请输入创作主题', style: AppStyles.titleMedium),
        const SizedBox(height: AppStyles.paddingMedium),
        TextField(
          controller: _promptController,
          decoration: const InputDecoration(
            hintText: '例如：写一篇关于春天的散文',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: AppStyles.paddingMedium),
        _buildStyleSelector(),
      ],
    );
  }
  
  Widget _buildContinueInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('请输入需要续写的内容', style: AppStyles.titleMedium),
        const SizedBox(height: AppStyles.paddingMedium),
        TextField(
          controller: _contentController,
          decoration: const InputDecoration(
            hintText: '输入您的内容，AI将帮您继续写作...',
          ),
          maxLines: 8,
        ),
        const SizedBox(height: AppStyles.paddingMedium),
        _buildStyleSelector(),
      ],
    );
  }
  
  Widget _buildRewriteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('请输入需要改写的内容', style: AppStyles.titleMedium),
        const SizedBox(height: AppStyles.paddingMedium),
        TextField(
          controller: _contentController,
          decoration: const InputDecoration(
            hintText: '输入需要改写的内容...',
          ),
          maxLines: 8,
        ),
        const SizedBox(height: AppStyles.paddingMedium),
        _buildStyleSelector(),
      ],
    );
  }
  
  Widget _buildExpandInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('请输入需要扩写的内容', style: AppStyles.titleMedium),
        const SizedBox(height: AppStyles.paddingMedium),
        TextField(
          controller: _contentController,
          decoration: const InputDecoration(
            hintText: '输入需要扩写的内容...',
          ),
          maxLines: 8,
        ),
        const SizedBox(height: AppStyles.paddingMedium),
        _buildStyleSelector(),
      ],
    );
  }
  
  Widget _buildTranslateInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('请输入需要翻译的内容', style: AppStyles.titleMedium),
        const SizedBox(height: AppStyles.paddingMedium),
        TextField(
          controller: _contentController,
          decoration: const InputDecoration(
            hintText: '输入需要翻译的内容...',
          ),
          maxLines: 8,
        ),
        const SizedBox(height: AppStyles.paddingMedium),
        _buildLanguageSelector(),
      ],
    );
  }
  
  Widget _buildStyleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('选择风格', style: AppStyles.bodyMedium),
        const SizedBox(height: AppStyles.paddingSmall),
        Wrap(
          spacing: 8,
          children: _styles.map((style) {
            return ChoiceChip(
              label: Text(style),
              selected: _selectedStyle == style,
              onSelected: (selected) {
                setState(() {
                  _selectedStyle = style;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('目标语言', style: AppStyles.bodyMedium),
        const SizedBox(height: AppStyles.paddingSmall),
        Wrap(
          spacing: 8,
          children: _languages.map((language) {
            return ChoiceChip(
              label: Text(language),
              selected: _selectedLanguage == language,
              onSelected: (selected) {
                setState(() {
                  _selectedLanguage = language;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _generate,
        child: _isGenerating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('生成中...'),
                ],
              )
            : const Text('开始生成'),
      ),
    );
  }
  
  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('生成结果', style: AppStyles.titleMedium),
            if (_resultController.text.isNotEmpty)
              Text(
                '${_resultController.text.length} 字',
                style: AppStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppStyles.paddingMedium),
        Container(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          ),
          child: TextField(
            controller: _resultController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '生成的内容将显示在这里...',
            ),
            maxLines: null,
            readOnly: _isGenerating,
          ),
        ),
      ],
    );
  }
  
  Future<void> _generate() async {
    final appProvider = context.read<AppProvider>();
    
    // 检查VIP状态（可选）
    if (!appProvider.isVip) {
      // 可以显示VIP提示或继续使用
    }
    
    // 检查字数（估算）
    final estimatedWords = 500; // 假设生成500字
    if (!appProvider.hasEnoughWords(estimatedWords)) {
      _showInsufficientWordsDialog();
      return;
    }
    
    setState(() {
      _isGenerating = true;
      _resultController.clear();
    });
    
    try {
      String result;
      
      switch (widget.type) {
        case WritingType.free:
          result = await _deepseekService.generateText(
            prompt: _promptController.text,
          );
          break;
        case WritingType.continue_:
          result = await _deepseekService.continueWriting(
            content: _contentController.text,
            style: _selectedStyle,
          );
          break;
        case WritingType.rewrite:
          result = await _deepseekService.rewriteText(
            content: _contentController.text,
            style: _selectedStyle,
          );
          break;
        case WritingType.expand:
          result = await _deepseekService.expandText(
            content: _contentController.text,
            style: _selectedStyle,
          );
          break;
        case WritingType.translate:
          result = await _deepseekService.translateText(
            content: _contentController.text,
            targetLanguage: _selectedLanguage,
          );
          break;
      }
      
      setState(() {
        _resultController.text = result;
      });
      
      // 消耗字数
      final inputWords = _promptController.text.length + _contentController.text.length;
      final outputWords = result.length;
      final totalWords = inputWords + outputWords;
      await appProvider.consumeWords(totalWords);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
  
  void _copyResult() {
    Clipboard.setData(ClipboardData(text: _resultController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }
  
  void _showInsufficientWordsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('字数不足'),
        content: const Text('您的剩余字数不足，请购买字数包或开通会员。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 跳转到字数包购买页面
            },
            child: const Text('购买'),
          ),
        ],
      ),
    );
  }
  
  String _getTitle() {
    switch (widget.type) {
      case WritingType.free:
        return '自由创作';
      case WritingType.continue_:
        return '续写';
      case WritingType.rewrite:
        return '改写';
      case WritingType.expand:
        return '扩写';
      case WritingType.translate:
        return '翻译';
    }
  }
}

