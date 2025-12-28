import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/app_styles.dart';
import '../constants/app_colors.dart';

/// 热门卡片组件
class HotCardWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isFavorite;
  final bool showFavoriteButton;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  
  const HotCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isFavorite = false,
    this.showFavoriteButton = true,
    this.onTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColor = _getRandomGradientColor();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 图标容器
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: gradientColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 标题
                      Expanded(
                        child: Text(
                          title,
                          style: AppStyles.titleMedium.copyWith(
                            color: AppColors.getTextPrimary(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 副标题 - 不使用Expanded，固定最大行数
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Text(
                      subtitle,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.getTextSecondary(context),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // 收藏按钮
            if (showFavoriteButton)
              Positioned(
                left: 16,
                bottom: 16,
                child: GestureDetector(
                  onTap: onFavoriteTap,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.getCardBackground(context),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 14,
                      color: isFavorite ? Colors.red : Colors.grey[600],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  /// 获取随机渐变色
  Color _getRandomGradientColor() {
    final colors = [
      AppColors.primary,
      const Color.fromRGBO(204, 102, 51, 1.0),   // 橙色
      const Color.fromRGBO(102, 153, 51, 1.0),   // 绿色
      const Color.fromRGBO(204, 51, 102, 1.0),   // 粉色
      const Color.fromRGBO(153, 51, 204, 1.0),   // 紫色
      const Color.fromRGBO(51, 153, 153, 1.0),   // 青色
    ];
    final random = math.Random(title.hashCode);
    return colors[random.nextInt(colors.length)];
  }
}

/// 空状态卡片
class EmptyStateCard extends StatelessWidget {
  final String message;
  
  const EmptyStateCard({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: AppStyles.bodyMedium.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

