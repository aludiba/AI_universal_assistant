/// 写作记录模型
class WritingRecordModel {
  final String id;
  final String templateId;
  final String templateTitle;
  final String prompt;
  final String? generatedContent;
  final int? wordCount;
  final DateTime createdAt;
  final bool isCompleted;
  
  WritingRecordModel({
    required this.id,
    required this.templateId,
    required this.templateTitle,
    required this.prompt,
    this.generatedContent,
    this.wordCount,
    required this.createdAt,
    this.isCompleted = false,
  });
  
  // 从JSON创建
  factory WritingRecordModel.fromJson(Map<String, dynamic> json) {
    return WritingRecordModel(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      templateTitle: json['templateTitle'] as String,
      prompt: json['prompt'] as String,
      generatedContent: json['generatedContent'] as String?,
      wordCount: json['wordCount'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
  
  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateId': templateId,
      'templateTitle': templateTitle,
      'prompt': prompt,
      'generatedContent': generatedContent,
      'wordCount': wordCount,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
  
  // 复制并修改
  WritingRecordModel copyWith({
    String? id,
    String? templateId,
    String? templateTitle,
    String? prompt,
    String? generatedContent,
    int? wordCount,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return WritingRecordModel(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      templateTitle: templateTitle ?? this.templateTitle,
      prompt: prompt ?? this.prompt,
      generatedContent: generatedContent ?? this.generatedContent,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

