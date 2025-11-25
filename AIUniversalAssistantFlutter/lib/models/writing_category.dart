class WritingCategory {
  final String title;
  final List<WritingTemplate> items;

  WritingCategory({
    required this.title,
    required this.items,
  });

  factory WritingCategory.fromJson(Map<String, dynamic> json) {
    return WritingCategory(
      title: json['title'] ?? '',
      items: (json['items'] as List?)
              ?.map((item) => WritingTemplate.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class WritingTemplate {
  final String title;
  final String content;

  WritingTemplate({
    required this.title,
    required this.content,
  });

  factory WritingTemplate.fromJson(Map<String, dynamic> json) {
    return WritingTemplate(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }
}

