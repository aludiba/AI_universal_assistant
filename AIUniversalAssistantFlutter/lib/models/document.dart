import 'package:uuid/uuid.dart';

class Document {
  final String id;
  final String title;
  final String content;
  final DateTime createTime;
  final DateTime updateTime;

  Document({
    String? id,
    required this.title,
    required this.content,
    DateTime? createTime,
    DateTime? updateTime,
  })  : id = id ?? const Uuid().v4(),
        createTime = createTime ?? DateTime.now(),
        updateTime = updateTime ?? DateTime.now();

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createTime: DateTime.fromMillisecondsSinceEpoch(json['createTime'] ?? 0),
      updateTime: DateTime.fromMillisecondsSinceEpoch(json['updateTime'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createTime': createTime.millisecondsSinceEpoch,
      'updateTime': updateTime.millisecondsSinceEpoch,
    };
  }

  Document copyWith({
    String? title,
    String? content,
    DateTime? updateTime,
  }) {
    return Document(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createTime: createTime,
      updateTime: updateTime ?? DateTime.now(),
    );
  }
}

