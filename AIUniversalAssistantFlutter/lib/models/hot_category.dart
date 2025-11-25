class HotCategory {
  final String id;
  final String title;
  final bool isFavoriteCategory;
  final List<HotItem> items;

  HotCategory({
    required this.id,
    required this.title,
    this.isFavoriteCategory = false,
    this.items = const [],
  });

  factory HotCategory.fromJson(Map<String, dynamic> json) {
    return HotCategory(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      isFavoriteCategory: json['isFavoriteCategory'] ?? false,
      items: (json['items'] as List?)
              ?.map((item) => HotItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isFavoriteCategory': isFavoriteCategory,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class HotItem {
  final String title;
  final String subtitle;
  final String icon;
  final String type;
  final String categoryId;
  final String categoryTitle;

  HotItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.categoryId,
    required this.categoryTitle,
  });

  String get uniqueId => '${categoryId}_${type}_$title';

  factory HotItem.fromJson(Map<String, dynamic> json) {
    return HotItem(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      icon: json['icon'] ?? '',
      type: json['type'] ?? '',
      categoryId: json['categoryId'] ?? '',
      categoryTitle: json['categoryTitle'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'type': type,
      'categoryId': categoryId,
      'categoryTitle': categoryTitle,
    };
  }
}

