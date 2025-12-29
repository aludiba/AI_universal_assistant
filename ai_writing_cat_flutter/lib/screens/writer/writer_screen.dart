import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_styles.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';

/// 写作页面
class WriterScreen extends StatelessWidget {
  const WriterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.writerTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        children: [
          _buildWritingTypeCard(
            context,
            title: l10n.writingFreeTitle,
            description: l10n.writingFreeDesc,
            icon: Icons.edit,
            color: Colors.blue,
            onTap: () {
              context.pushNamed(
                AppRoute.aiWriting.name,
                queryParameters: {'type': WritingType.free.name},
              );
            },
          ),
          _buildWritingTypeCard(
            context,
            title: l10n.continueWriting,
            description: l10n.writingContinueDesc,
            icon: Icons.navigate_next,
            color: Colors.green,
            onTap: () {
              context.pushNamed(
                AppRoute.aiWriting.name,
                queryParameters: {'type': WritingType.continue_.name},
              );
            },
          ),
          _buildWritingTypeCard(
            context,
            title: l10n.rewrite,
            description: l10n.writingRewriteDesc,
            icon: Icons.refresh,
            color: Colors.orange,
            onTap: () {
              context.pushNamed(
                AppRoute.aiWriting.name,
                queryParameters: {'type': WritingType.rewrite.name},
              );
            },
          ),
          _buildWritingTypeCard(
            context,
            title: l10n.expandWriting,
            description: l10n.writingExpandDesc,
            icon: Icons.expand,
            color: Colors.purple,
            onTap: () {
              context.pushNamed(
                AppRoute.aiWriting.name,
                queryParameters: {'type': WritingType.expand.name},
              );
            },
          ),
          _buildWritingTypeCard(
            context,
            title: l10n.translate,
            description: l10n.writingTranslateDesc,
            icon: Icons.translate,
            color: Colors.teal,
            onTap: () {
              context.pushNamed(
                AppRoute.aiWriting.name,
                queryParameters: {'type': WritingType.translate.name},
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

