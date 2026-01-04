/// 写作分类项模型
class WritingCategoryItem {
  final String title;
  final String content;

  WritingCategoryItem({
    required this.title,
    required this.content,
  });

  factory WritingCategoryItem.fromJson(Map<String, dynamic> json) {
    return WritingCategoryItem(
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }
}

/// 写作分类模型
class WritingCategory {
  final String title;
  final List<WritingCategoryItem> items;

  WritingCategory({
    required this.title,
    required this.items,
  });

  factory WritingCategory.fromJson(Map<String, dynamic> json) {
    return WritingCategory(
      title: json['title'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => WritingCategoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

