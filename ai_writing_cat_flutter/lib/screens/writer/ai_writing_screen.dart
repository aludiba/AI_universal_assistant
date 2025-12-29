import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/writing_provider.dart';
import '../../services/deepseek_service.dart';
import '../../constants/app_styles.dart';
import 'writer_screen.dart';
import '../../router/app_router.dart';

/// AI写作页面
class AIWritingScreen extends StatelessWidget {
  final WritingType type;
  final String? initialContent;
  
  const AIWritingScreen({
    super.key,
    required this.type,
    this.initialContent,
  });

  @override
  Widget build(BuildContext context) {
    final writingProvider = context.watch<WritingProvider>();
    
    // 初始化（如果还未初始化或类型变化）
    if (writingProvider.type != type) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        writingProvider.initWriting(type, initialContent: initialContent);
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          if (writingProvider.hasResult)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _copyResult(context, writingProvider),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        children: [
          // 输入区域
          _buildInputSection(context, writingProvider),
          
          const SizedBox(height: AppStyles.paddingLarge),
          
          // 生成按钮
          _buildGenerateButton(context, writingProvider),
          
          const SizedBox(height: AppStyles.paddingLarge),
          
          // 结果区域
          if (writingProvider.hasResult || writingProvider.isGenerating)
            _buildResultSection(context, writingProvider),
        ],
      ),
    );
  }
  
  Widget _buildInputSection(BuildContext context, WritingProvider writingProvider) {
    switch (type) {
      case WritingType.free:
        return _buildFreeWritingInput(context, writingProvider);
      case WritingType.continue_:
        return _buildContinueInput(context, writingProvider);
      case WritingType.rewrite:
        return _buildRewriteInput(context, writingProvider);
      case WritingType.expand:
        return _buildExpandInput(context, writingProvider);
      case WritingType.translate:
        return _buildTranslateInput(context, writingProvider);
    }
  }
  
  Widget _buildFreeWritingInput(BuildContext context, WritingProvider writingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('请输入创作主题', style: AppStyles.titleMedium),
        const SizedBox(height: AppStyles.paddingMedium),
        TextField(
          controller: writingProvider.promptController,
          decoration: const InputDecoration(
            hintText: '例如：写一篇关于春天的散文',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: AppStyles.paddingMedium),
        _buildStyleSelector(context, writingProvider),
      ],
    );
  }
  
  Widget _buildContinueInput(BuildContext context, WritingProvider writingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('请输入需要续写的内容', style: AppStyles.titleMedium),
        const SizedBox(height: AppStyles.paddingMedium),
        TextField(
          controller: writingProvider.contentController,
          decoration: const InputDecoration(
            hintText: '输入您的内容，AI将帮您继续写作...',
          ),
          maxLines: 8,
        ),
        const SizedBox(height: AppStyles.paddingMedium),
        _buildStyleSelector(context, writingProvider),
      ],
    );
  }
  
  Widget _buildRewriteInput(BuildContext context, WritingProvider writingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('请输入需要改写的内容', style: AppStyles.titleMedium),
        const SizedBox(height: AppStyles.paddingMedium),
        TextField(
          controller: writingProvider.contentController,
          decoration: const InputDecoration(
            hintText: '输入需要改写的内容...',
          ),
          maxLines: 8,
        ),
        const SizedBox(height: AppStyles.paddingMedium),
        _buildStyleSelector(context, writingProvider),
      ],
    );
  }
  
  Widget _buildExpandInput(BuildContext context, WritingProvider writingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('请输入需要扩写的内容', style: AppStyles.titleMedium),
        const SizedBox(height: AppStyles.paddingMedium),
        TextField(
          controller: writingProvider.contentController,
          decoration: const InputDecoration(
            hintText: '输入需要扩写的内容...',
          ),
          maxLines: 8,
        ),
        const SizedBox(height: AppStyles.paddingMedium),
        _buildStyleSelector(context, writingProvider),
      ],
    );
  }
  
  Widget _buildTranslateInput(BuildContext context, WritingProvider writingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('请输入需要翻译的内容', style: AppStyles.titleMedium),
        const SizedBox(height: AppStyles.paddingMedium),
        TextField(
          controller: writingProvider.contentController,
          decoration: const InputDecoration(
            hintText: '输入需要翻译的内容...',
          ),
          maxLines: 8,
        ),
        const SizedBox(height: AppStyles.paddingMedium),
        _buildLanguageSelector(context, writingProvider),
      ],
    );
  }
  
  Widget _buildStyleSelector(BuildContext context, WritingProvider writingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('选择风格', style: AppStyles.bodyMedium),
        const SizedBox(height: AppStyles.paddingSmall),
        Wrap(
          spacing: 8,
          children: writingProvider.styles.map((style) {
            return ChoiceChip(
              label: Text(style),
              selected: writingProvider.selectedStyle == style,
              onSelected: (selected) => writingProvider.setStyle(style),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildLanguageSelector(BuildContext context, WritingProvider writingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('目标语言', style: AppStyles.bodyMedium),
        const SizedBox(height: AppStyles.paddingSmall),
        Wrap(
          spacing: 8,
          children: writingProvider.languages.map((language) {
            return ChoiceChip(
              label: Text(language),
              selected: writingProvider.selectedLanguage == language,
              onSelected: (selected) => writingProvider.setLanguage(language),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildGenerateButton(BuildContext context, WritingProvider writingProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: writingProvider.isGenerating ? null : () => _generate(context, writingProvider),
        child: writingProvider.isGenerating
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
  
  Widget _buildResultSection(BuildContext context, WritingProvider writingProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('生成结果', style: AppStyles.titleMedium),
            if (writingProvider.hasResult)
              Text(
                '${writingProvider.resultText.length} 字',
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
            controller: writingProvider.resultController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '生成的内容将显示在这里...',
            ),
            maxLines: null,
            readOnly: writingProvider.isGenerating,
          ),
        ),
      ],
    );
  }
  
  Future<void> _generate(BuildContext context, WritingProvider writingProvider) async {
    final appProvider = context.read<AppProvider>();
    final deepseekService = DeepSeekService();
    
    // 检查VIP状态（可选）
    if (!appProvider.isVip) {
      // 可以显示VIP提示或继续使用
    }
    
    // 检查字数（估算）
    final estimatedWords = 500; // 假设生成500字
    if (!appProvider.hasEnoughWords(estimatedWords)) {
      _showInsufficientWordsDialog(context);
      return;
    }
    
    writingProvider.startGenerating();
    
    try {
      String result;
      
      switch (type) {
        case WritingType.free:
          result = await deepseekService.generateText(
            prompt: writingProvider.promptController.text,
          );
          break;
        case WritingType.continue_:
          result = await deepseekService.continueWriting(
            content: writingProvider.contentController.text,
            style: writingProvider.selectedStyle,
          );
          break;
        case WritingType.rewrite:
          result = await deepseekService.rewriteText(
            content: writingProvider.contentController.text,
            style: writingProvider.selectedStyle,
          );
          break;
        case WritingType.expand:
          result = await deepseekService.expandText(
            content: writingProvider.contentController.text,
            style: writingProvider.selectedStyle,
          );
          break;
        case WritingType.translate:
          result = await deepseekService.translateText(
            content: writingProvider.contentController.text,
            targetLanguage: writingProvider.selectedLanguage,
          );
          break;
      }
      
      writingProvider.setResult(result);
      
      // 消耗字数
      final inputWords = writingProvider.promptController.text.length + writingProvider.contentController.text.length;
      final outputWords = result.length;
      final totalWords = inputWords + outputWords;
      await appProvider.consumeWords(totalWords);
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    } finally {
      writingProvider.finishGenerating();
    }
  }
  
  void _copyResult(BuildContext context, WritingProvider writingProvider) {
    Clipboard.setData(ClipboardData(text: writingProvider.resultText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }
  
  void _showInsufficientWordsDialog(BuildContext context) {
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
              context.pushNamed(AppRoute.wordPack.name);
            },
            child: const Text('购买'),
          ),
        ],
      ),
    );
  }
  
  String _getTitle() {
    switch (type) {
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

