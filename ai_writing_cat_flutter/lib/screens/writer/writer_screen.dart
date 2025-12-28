import 'package:flutter/material.dart';
import '../../constants/app_styles.dart';
import 'ai_writing_screen.dart';

/// 写作页面
class WriterScreen extends StatelessWidget {
  const WriterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI写作'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        children: [
          _buildWritingTypeCard(
            context,
            title: '自由创作',
            description: '根据您的主题和要求，AI帮您创作内容',
            icon: Icons.edit,
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AIWritingScreen(type: WritingType.free),
                ),
              );
            },
          ),
          _buildWritingTypeCard(
            context,
            title: '续写',
            description: '基于您的内容，AI帮您继续写作',
            icon: Icons.navigate_next,
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AIWritingScreen(type: WritingType.continue_),
                ),
              );
            },
          ),
          _buildWritingTypeCard(
            context,
            title: '改写',
            description: 'AI帮您优化表达，改写您的内容',
            icon: Icons.refresh,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AIWritingScreen(type: WritingType.rewrite),
                ),
              );
            },
          ),
          _buildWritingTypeCard(
            context,
            title: '扩写',
            description: 'AI帮您丰富内容，增加细节',
            icon: Icons.expand,
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AIWritingScreen(type: WritingType.expand),
                ),
              );
            },
          ),
          _buildWritingTypeCard(
            context,
            title: '翻译',
            description: 'AI帮您翻译成多种语言',
            icon: Icons.translate,
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AIWritingScreen(type: WritingType.translate),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildWritingTypeCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppStyles.paddingMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.paddingLarge),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: color,
                ),
              ),
              const SizedBox(width: AppStyles.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.titleMedium,
                    ),
                    const SizedBox(height: AppStyles.paddingSmall),
                    Text(
                      description,
                      style: AppStyles.bodyMedium.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 写作类型
enum WritingType {
  free,
  continue_,
  rewrite,
  expand,
  translate,
}

