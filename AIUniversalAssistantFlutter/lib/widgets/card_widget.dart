import 'package:flutter/material.dart';

/// 卡片组件
class CardWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? iconName;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showFavorite;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const CardWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.iconName,
    this.onTap,
    this.trailing,
    this.showFavorite = false,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  IconData _getIconData(String? iconName) {
    // 映射图标名称到Material图标
    final iconMap = {
      'mic': Icons.mic,
      'heart': Icons.favorite,
      'edit': Icons.edit,
      'graduationcap': Icons.school,
      'square.and.pencil': Icons.article,
      'book': Icons.book,
      'flame': Icons.local_fire_department,
      'newspaper': Icons.newspaper,
      'doc.richtext': Icons.description,
      'questionmark': Icons.help_outline,
      'person.2': Icons.people,
      'play.rectangle': Icons.play_circle_outline,
      'pencil': Icons.edit_note,
      'book.closed': Icons.menu_book,
      'doc.text': Icons.article,
      'a.square': Icons.title,
      'lightbulb': Icons.lightbulb_outline,
      'calendar': Icons.calendar_today,
      'chart.bar': Icons.bar_chart,
      'square.stack': Icons.layers,
      'target': Icons.flag,
      'envelope': Icons.email,
      'quote.bubble': Icons.format_quote,
      'tag': Icons.label,
      'party.popper': Icons.celebration,
      'frying.pan': Icons.restaurant,
      'airplane': Icons.flight,
      'heart.text': Icons.favorite_border,
      'hand.raised': Icons.pan_tool,
      'sparkles': Icons.auto_awesome,
    };
    return iconMap[iconName] ?? Icons.article;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (iconName != null) ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconData(iconName),
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (showFavorite) ...[
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: onFavoriteTap,
                ),
              ],
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

