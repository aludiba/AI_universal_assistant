import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/hot_item_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/hot_writing_provider.dart';
import '../../services/deepseek_service.dart';
import '../../constants/app_styles.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';

/// 热门模板写作输入页面
class HotWritingInputScreen extends StatelessWidget {
  final HotItemModel item;
  
  const HotWritingInputScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final writingProvider = context.watch<HotWritingProvider>();
    
    // 初始化（如果还未初始化）
    if (writingProvider.item?.id != item.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        writingProvider.initWriting(item);
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 返回到上一页（通常是搜索页面）
            if (context.canPop()) {
              context.pop();
            } else {
              // 如果无法pop（比如直接打开），则回到热门首页
              context.goNamed(AppRoute.hot.name);
            }
          },
        ),
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
          // 模板说明
          Container(
            padding: const EdgeInsets.all(AppStyles.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
            child: Text(
              item.subtitle,
              style: AppStyles.bodyMedium,
            ),
          ),
          
          const SizedBox(height: AppStyles.paddingLarge),
          
          // 输入区域
          Text(l10n.hotWritingInputTitle, style: AppStyles.titleMedium),
          const SizedBox(height: AppStyles.paddingMedium),
          TextField(
            controller: writingProvider.promptController,
            decoration: InputDecoration(
              hintText: l10n.hotWritingInputHint,
            ),
            maxLines: 5,
          ),
          
          const SizedBox(height: AppStyles.paddingLarge),
          
          // 生成按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: writingProvider.isGenerating ? null : () => _generate(context, writingProvider),
              child: writingProvider.isGenerating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.generatingShort),
                      ],
                    )
                  : Text(l10n.generate),
            ),
          ),
          
          const SizedBox(height: AppStyles.paddingLarge),
          
          // 结果区域
          if (writingProvider.hasResult || writingProvider.isGenerating)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.hotWritingResultTitle, style: AppStyles.titleMedium),
                const SizedBox(height: AppStyles.paddingMedium),
                Container(
                  padding: const EdgeInsets.all(AppStyles.paddingMedium),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                  ),
                  child: TextField(
                    controller: writingProvider.resultController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: l10n.hotWritingResultHint,
                    ),
                    maxLines: null,
                    readOnly: writingProvider.isGenerating,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  Future<void> _generate(BuildContext context, HotWritingProvider writingProvider) async {
    final l10n = AppLocalizations.of(context)!;
    if (writingProvider.promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.hotWritingInputTitle)),
      );
      return;
    }
    
    final appProvider = context.read<AppProvider>();
    final deepseekService = DeepSeekService();
    
    // 检查字数
    if (!appProvider.hasEnoughWords(500)) {
      _showInsufficientWordsDialog(context);
      return;
    }
    
    writingProvider.startGenerating();
    
    try {
      // 构建提示词
      final prompt = '${item.subtitle}\n\n${writingProvider.promptController.text}';
      
      final result = await deepseekService.generateText(
        prompt: prompt,
      );
      
      writingProvider.setResult(result);
      
      // 消耗字数
      final totalWords = writingProvider.promptController.text.length + result.length;
      await appProvider.consumeWords(totalWords);
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.creationFailed}: $e')),
        );
      }
    } finally {
      writingProvider.finishGenerating();
    }
  }
  
  void _copyResult(BuildContext context, HotWritingProvider writingProvider) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: writingProvider.resultText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copiedToClipboard)),
    );
  }
  
  void _showInsufficientWordsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.insufficientWords),
        content: Text(l10n.insufficientWordsDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pushNamed(AppRoute.wordPack.name);
            },
            child: Text(l10n.purchaseWordPack),
          ),
        ],
      ),
    );
  }
}
