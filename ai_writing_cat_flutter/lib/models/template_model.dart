/// 写作模板模型
class TemplateModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<TemplateField> fields;
  final bool isFavorite;
  final DateTime? lastUsedAt;
  
  TemplateModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.fields,
    this.isFavorite = false,
    this.lastUsedAt,
  });
  
  // 从JSON创建
  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    return TemplateModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      fields: (json['fields'] as List)
          .map((e) => TemplateField.fromJson(e as Map<String, dynamic>))
          .toList(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
    );
  }
  
  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'fields': fields.map((e) => e.toJson()).toList(),
      'isFavorite': isFavorite,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }
  
  // 复制并修改
  TemplateModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    List<TemplateField>? fields,
    bool? isFavorite,
    DateTime? lastUsedAt,
  }) {
    return TemplateModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      fields: fields ?? this.fields,
      isFavorite: isFavorite ?? this.isFavorite,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}

/// 模板字段
class TemplateField {
  final String key;
  final String label;
  final String placeholder;
  final TemplateFieldType type;
  final bool required;
  final List<String>? options;
  
  TemplateField({
    required this.key,
    required this.label,
    required this.placeholder,
    this.type = TemplateFieldType.text,
    this.required = true,
    this.options,
  });
  
  // 从JSON创建
  factory TemplateField.fromJson(Map<String, dynamic> json) {
    return TemplateField(
      key: json['key'] as String,
      label: json['label'] as String,
      placeholder: json['placeholder'] as String,
      type: TemplateFieldType.values.firstWhere(
        (e) => e.toString() == 'TemplateFieldType.${json['type']}',
        orElse: () => TemplateFieldType.text,
      ),
      required: json['required'] as bool? ?? true,
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : null,
    );
  }
  
  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'placeholder': placeholder,
      'type': type.toString().split('.').last,
      'required': required,
      'options': options,
    };
  }
}

/// 模板字段类型
enum TemplateFieldType {
  text,      // 单行文本
  textarea,  // 多行文本
  number,    // 数字
  select,    // 下拉选择
}

/// 模板分类
class TemplateCategory {
  static const String socialMedia = 'socialMedia';
  static const String school = 'school';
  static const String workplace = 'workplace';
  static const String life = 'life';
  static const String marketing = 'marketing';
  
  static List<String> get all => [
    socialMedia,
    school,
    workplace,
    life,
    marketing,
  ];
}

