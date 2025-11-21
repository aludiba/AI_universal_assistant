import 'package:flutter/material.dart';

/// 空状态组件
class EmptyWidget extends StatelessWidget {
  final String message;
  final String? icon;
  final Widget? customIcon;
  final VoidCallback? onTap;

  const EmptyWidget({
    super.key,
    required this.message,
    this.icon,
    this.customIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (customIcon != null)
                customIcon!
              else if (icon != null)
                Icon(
                  _getIconData(icon!),
                  size: 64,
                  color: Colors.grey[400],
                )
              else
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'search':
        return Icons.search_outlined;
      case 'document':
        return Icons.description_outlined;
      case 'writing':
        return Icons.edit_outlined;
      case 'favorite':
        return Icons.favorite_outline;
      default:
        return Icons.inbox_outlined;
    }
  }
}

