import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/template_model.dart';
import '../../providers/template_provider.dart';
import '../../providers/app_provider.dart';
import '../../services/deepseek_service.dart';
import '../../constants/app_styles.dart';

/// 模板详情页面
class TemplateDetailScreen extends StatelessWidget {
  final TemplateModel template;
  
  const TemplateDetailScreen({
    super.key,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    final templateProvider = context.watch<TemplateProvider>();
    final formKey = GlobalKey<FormState>();
    
    // 初始化详情状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      templateProvider.initTemplateDetail(template.id, template.fields);
    });
    
    final isGenerating = templateProvider.isTemplateGenerating(template.id);
    final generatedContent = templateProvider.getTemplateGeneratedContent(template.id);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(template.title),
        actions: [
          Consumer<TemplateProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  template.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: template.isFavorite ? Colors.red : null,
                ),
                onPressed: () {
                  provider.toggleFavorite(template.id);
                },
              );
            },
          ),
        ],
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          children: [
            // 模板描述
            Text(
              template.description,
              style: AppStyles.bodyLarge.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: AppStyles.paddingLarge),
            
            // 输入字段
            ...template.fields.map((field) => _buildField(context, templateProvider, template.id, field)),
            
            const SizedBox(height: AppStyles.paddingLarge),
            
            // 生成按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isGenerating ? null : () => _generate(context, templateProvider, formKey),
                child: isGenerating
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
            if (generatedContent != null) ...[
              const SizedBox(height: AppStyles.paddingLarge),
              _buildResultSection(context, generatedContent),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildField(BuildContext context, TemplateProvider templateProvider, String templateId, TemplateField field) {
    final controller = templateProvider.getTemplateFieldController(templateId, field.key);
    
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
            controller: controller,
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
  
  Widget _buildResultSection(BuildContext context, String generatedContent) {
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
          child: Text(generatedContent),
        ),
      ],
    );
  }
  
  Future<void> _generate(BuildContext context, TemplateProvider templateProvider, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    
    final appProvider = context.read<AppProvider>();
    final deepseekService = DeepSeekService();
    
    // 检查字数
    if (!appProvider.hasEnoughWords(500)) {
      _showInsufficientWordsDialog(context);
      return;
    }
    
    templateProvider.startTemplateGenerating(template.id);
    
    try {
      // 构建提示词
      final prompt = _buildPrompt(templateProvider);
      
      // 调用AI生成
      final result = await deepseekService.generateText(prompt: prompt);
      
      templateProvider.setTemplateGeneratedContent(template.id, result);
      
      // 消耗字数
      await appProvider.consumeWords(prompt.length + result.length);
      
      // 记录使用
      await templateProvider.useTemplate(template.id);
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    } finally {
      templateProvider.finishTemplateGenerating(template.id);
    }
  }
  
  String _buildPrompt(TemplateProvider templateProvider) {
    final buffer = StringBuffer();
    buffer.writeln('请根据以下信息帮我${template.title}：');
    buffer.writeln();
    
    for (var field in template.fields) {
      final controller = templateProvider.getTemplateFieldController(template.id, field.key);
      final value = controller?.text ?? '';
      if (value.isNotEmpty) {
        buffer.writeln('${field.label}：$value');
      }
    }
    
    return buffer.toString();
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
              // TODO: 跳转到字数包购买页面
            },
            child: const Text('购买'),
          ),
        ],
      ),
    );
  }
}
