import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/hot_item_model.dart';
import '../../providers/app_provider.dart';
import '../../services/deepseek_service.dart';
import '../../constants/app_styles.dart';
import '../../l10n/app_localizations.dart';

/// 热门模板写作输入页面
class HotWritingInputScreen extends StatefulWidget {
  final HotItemModel item;
  
  const HotWritingInputScreen({
    super.key,
    required this.item,
  });

  @override
  State<HotWritingInputScreen> createState() => _HotWritingInputScreenState();
}

class _HotWritingInputScreenState extends State<HotWritingInputScreen> {
  final _deepseekService = DeepSeekService();
  final _promptController = TextEditingController();
  final _resultController = TextEditingController();
  
  bool _isGenerating = false;
  
  @override
  void dispose() {
    _promptController.dispose();
    _resultController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.title),
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
          // 模板说明
          Container(
            padding: const EdgeInsets.all(AppStyles.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
            child: Text(
              widget.item.subtitle,
              style: AppStyles.bodyMedium,
            ),
          ),
          
          const SizedBox(height: AppStyles.paddingLarge),
          
          // 输入区域
          Text(l10n.hotWritingInputTitle, style: AppStyles.titleMedium),
          const SizedBox(height: AppStyles.paddingMedium),
          TextField(
            controller: _promptController,
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
              onPressed: _isGenerating ? null : _generate,
              child: _isGenerating
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
          if (_resultController.text.isNotEmpty || _isGenerating)
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
                    controller: _resultController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: l10n.hotWritingResultHint,
                    ),
                    maxLines: null,
                    readOnly: _isGenerating,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context)!;
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.hotWritingInputTitle)),
      );
      return;
    }
    
    final appProvider = context.read<AppProvider>();
    
    // 检查字数
    if (!appProvider.hasEnoughWords(500)) {
      _showInsufficientWordsDialog();
      return;
    }
    
    setState(() {
      _isGenerating = true;
      _resultController.clear();
    });
    
    try {
      // 构建提示词
      final prompt = '${widget.item.subtitle}\n\n${_promptController.text}';
      
      final result = await _deepseekService.generateText(
        prompt: prompt,
      );
      
      setState(() {
        _resultController.text = result;
      });
      
      // 消耗字数
      final totalWords = _promptController.text.length + result.length;
      await appProvider.consumeWords(totalWords);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.creationFailed}: $e')),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
  
  void _copyResult() {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: _resultController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copiedToClipboard)),
    );
  }
  
  void _showInsufficientWordsDialog() {
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
              // TODO: 跳转到字数包购买页面
            },
            child: Text(l10n.purchaseWordPack),
          ),
        ],
      ),
    );
  }
}

