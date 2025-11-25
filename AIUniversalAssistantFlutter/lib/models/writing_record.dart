import 'package:uuid/uuid.dart';

class WritingRecord {
  final String id;
  final String title;
  final String content;
  final String? prompt;
  final String? theme;
  final String? requirement;
  final int? wordCount;
  final String? style;
  final String type;
  final DateTime createTime;
  final DateTime updateTime;

  WritingRecord({
    String? id,
    required this.title,
    required this.content,
    this.prompt,
    this.theme,
    this.requirement,
    this.wordCount,
    this.style,
    required this.type,
    DateTime? createTime,
    DateTime? updateTime,
  })  : id = id ?? const Uuid().v4(),
        createTime = createTime ?? DateTime.now(),
        updateTime = updateTime ?? DateTime.now();

  factory WritingRecord.fromJson(Map<String, dynamic> json) {
    return WritingRecord(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      prompt: json['prompt'],
      theme: json['theme'],
      requirement: json['requirement'],
      wordCount: json['wordCount'],
      style: json['style'],
      type: json['type'] ?? '',
      createTime: DateTime.fromMillisecondsSinceEpoch(json['createTime'] ?? 0),
      updateTime: DateTime.fromMillisecondsSinceEpoch(json['updateTime'] ?? 0),
    );
  }

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
      'type': type,
      'createTime': createTime.millisecondsSinceEpoch,
      'updateTime': updateTime.millisecondsSinceEpoch,
    };
  }

  WritingRecord copyWith({
    String? title,
    String? content,
    String? prompt,
    String? theme,
    String? requirement,
    int? wordCount,
    String? style,
    String? type,
    DateTime? updateTime,
  }) {
    return WritingRecord(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      prompt: prompt ?? this.prompt,
      theme: theme ?? this.theme,
      requirement: requirement ?? this.requirement,
      wordCount: wordCount ?? this.wordCount,
      style: style ?? this.style,
      type: type ?? this.type,
      createTime: createTime,
      updateTime: updateTime ?? DateTime.now(),
    );
  }
}

