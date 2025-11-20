/// 写作记录模型
class WritingRecord {
  final String id;
  final String title;
  final String content;
  final String? prompt;
  final String? theme;
  final String? requirement;
  final int? wordCount;
  final String? style;
  final DateTime createTime;
  final DateTime updateTime;
  final String type; // 创作类型：continue, rewrite, expand, translate, create

  WritingRecord({
    required this.id,
    required this.title,
    required this.content,
    this.prompt,
    this.theme,
    this.requirement,
    this.wordCount,
    this.style,
    required this.createTime,
    required this.updateTime,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'prompt': prompt,
      'theme': theme,
      'requirement': requirement,
      'wordCount': wordCount,
      'style': style,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
      'type': type,
    };
  }

  factory WritingRecord.fromJson(Map<String, dynamic> json) {
    return WritingRecord(
      id: json['id'],
      title: json['title'] ?? '无标题',
      content: json['content'] ?? '',
      prompt: json['prompt'],
      theme: json['theme'],
      requirement: json['requirement'],
      wordCount: json['wordCount'],
      style: json['style'],
      createTime: DateTime.parse(json['createTime']),
      updateTime: DateTime.parse(json['updateTime']),
      type: json['type'] ?? 'create',
    );
  }
}

/// 文档模型
class Document {
  final String id;
  final String title;
  final String content;
  final DateTime createTime;
  final DateTime updateTime;

  Document({
    required this.id,
    required this.title,
    required this.content,
    required this.createTime,
    required this.updateTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createTime': createTime.toIso8601String(),
      'updateTime': updateTime.toIso8601String(),
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      title: json['title'] ?? '未命名文档',
      content: json['content'] ?? '',
      createTime: DateTime.parse(json['createTime']),
      updateTime: DateTime.parse(json['updateTime']),
    );
  }
}

/// 模板模型
class Template {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String? prompt;
  final String? example;

  Template({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.prompt,
    this.example,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'prompt': prompt,
      'example': example,
    };
  }

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      prompt: json['prompt'],
      example: json['example'],
    );
  }
}

