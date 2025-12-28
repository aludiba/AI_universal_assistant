/// 热门项目模型
class HotItemModel {
  final String title;
  final String subtitle;
  final String icon;
  final String type;
  final String categoryId;
  final String categoryTitle;
  
  HotItemModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.categoryId,
    required this.categoryTitle,
  });
  
  factory HotItemModel.fromJson(Map<String, dynamic> json) {
    return HotItemModel(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      icon: json['icon'] as String,
      type: json['type'] as String,
      categoryId: json['categoryId'] as String,
      categoryTitle: json['categoryTitle'] as String,
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
  
  // 生成唯一ID
  String get id => '${categoryId}_$type';
}

/// 热门分类模型
class HotCategoryModel {
  final String id;
  final String title;
  final bool isFavoriteCategory;
  final List<HotItemModel> items;
  
  HotCategoryModel({
    required this.id,
    required this.title,
    this.isFavoriteCategory = false,
    required this.items,
  });
  
  factory HotCategoryModel.fromJson(Map<String, dynamic> json) {
    return HotCategoryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      isFavoriteCategory: json['isFavoriteCategory'] as bool? ?? false,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => HotItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isFavoriteCategory': isFavoriteCategory,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

