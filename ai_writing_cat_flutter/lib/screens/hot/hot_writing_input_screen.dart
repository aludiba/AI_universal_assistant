import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/hot_item_model.dart';
import '../../providers/app_provider.dart';
import '../../services/deepseek_service.dart';
import '../../constants/app_styles.dart';

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
          const Text('请输入创作内容', style: AppStyles.titleMedium),
          const SizedBox(height: AppStyles.paddingMedium),
          TextField(
            controller: _promptController,
            decoration: const InputDecoration(
              hintText: '输入您的创作主题或要求...',
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
          ),
          
          const SizedBox(height: AppStyles.paddingLarge),
          
          // 结果区域
          if (_resultController.text.isNotEmpty || _isGenerating)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('生成结果', style: AppStyles.titleMedium),
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
            ),
        ],
      ),
    );
  }
  
  Future<void> _generate() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入创作内容')),
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
}

