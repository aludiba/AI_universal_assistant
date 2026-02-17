import 'package:flutter/material.dart';

/// 应用颜色常量
class AppColors {
  // 主题色
  static const Color primary = Color(0xFF3366CC);
  static const Color primaryLight = Color(0xFF5588EE);
  static const Color primaryDark = Color(0xFF1144AA);
  
  // 背景色（支持暗黑模式）
  static const Color background = Colors.white;
  static const Color backgroundDark = Colors.black;
  static const Color secondaryBackground = Color(0xFFF5F5F5);
  static const Color secondaryBackgroundDark = Color(0xFF1E1E1E);
  
  // 文本颜色
  static const Color textPrimary = Color(0xFF333333);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF999999);
  
  // 分隔线颜色
  static const Color divider = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF303030);
  
  // 功能色
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // 卡片背景
  static const Color cardBackground = Colors.white;
  static const Color cardBackgroundDark = Color(0xFF1E1E1E);
  
  // 获取适配暗黑模式的颜色
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? backgroundDark
        : background;
  }
  
  static Color getSecondaryBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? secondaryBackgroundDark
        : secondaryBackground;
  }
  
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimaryDark
        : textPrimary;
  }
  
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textSecondaryDark
        : textSecondary;
  }
  
  static Color getDivider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? dividerDark
        : divider;
  }
  
  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardBackgroundDark
        : cardBackground;
  }
}
