import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/template_model.dart';
import '../../providers/template_provider.dart';
import '../../providers/app_provider.dart';
import '../../services/deepseek_service.dart';
import '../../constants/app_styles.dart';

/// 模板详情页面
class TemplateDetailScreen extends StatefulWidget {
  final TemplateModel template;
  
  const TemplateDetailScreen({
    super.key,
    required this.template,
  });

  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final _deepseekService = DeepSeekService();
  
  bool _isGenerating = false;
  String? _generatedContent;
  
  @override
  void initState() {
    super.initState();
    // 为每个字段创建控制器
    for (var field in widget.template.fields) {
      _controllers[field.key] = TextEditingController();
    }
  }
  
  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.title),
        actions: [
          Consumer<TemplateProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  widget.template.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: widget.template.isFavorite ? Colors.red : null,
                ),
                onPressed: () {
                  provider.toggleFavorite(widget.template.id);
                },
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          children: [
            // 模板描述
            Text(
              widget.template.description,
              style: AppStyles.bodyLarge.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: AppStyles.paddingLarge),
            
            // 输入字段
            ...widget.template.fields.map((field) => _buildField(field)),
            
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
                    : const Text('开始创作'),
              ),
            ),
            
            // 生成结果
            if (_generatedContent != null) ...[
              const SizedBox(height: AppStyles.paddingLarge),
              _buildResultSection(),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildField(TemplateField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppStyles.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppStyles.paddingSmall),
          TextFormField(
            controller: _controllers[field.key],
            decoration: InputDecoration(
              hintText: field.placeholder,
            ),
            maxLines: field.type == TemplateFieldType.textarea ? 5 : 1,
            keyboardType: field.type == TemplateFieldType.number
                ? TextInputType.number
                : TextInputType.text,
            validator: field.required
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入${field.label}';
                    }
                    return null;
                  }
                : null,
          ),
        ],
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
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    // TODO: 复制内容
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    // TODO: 保存到文档
                  },
                ),
              ],
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
          child: Text(_generatedContent!),
        ),
      ],
    );
  }
  
  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) {
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
      _generatedContent = null;
    });
    
    try {
      // 构建提示词
      final prompt = _buildPrompt();
      
      // 调用AI生成
      final result = await _deepseekService.generateText(prompt: prompt);
      
      setState(() {
        _generatedContent = result;
      });
      
      // 消耗字数
      await appProvider.consumeWords(prompt.length + result.length);
      
      // 记录使用
      final templateProvider = context.read<TemplateProvider>();
      await templateProvider.useTemplate(widget.template.id);
      
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
  
  String _buildPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('请根据以下信息帮我${widget.template.title}：');
    buffer.writeln();
    
    for (var field in widget.template.fields) {
      final value = _controllers[field.key]!.text;
      if (value.isNotEmpty) {
        buffer.writeln('${field.label}：$value');
      }
    }
    
    return buffer.toString();
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

