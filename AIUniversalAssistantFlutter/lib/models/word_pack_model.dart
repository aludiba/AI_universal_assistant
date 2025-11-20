/// 字数包类型
enum WordPackType {
  pack500K,
  pack2M,
  pack6M,
}

/// 字数包记录
class WordPackRecord {
  final String id;
  final WordPackType type;
  final int words;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final int remainingWords;
  final bool isExpired;

  WordPackRecord({
    required this.id,
    required this.type,
    required this.words,
    required this.purchaseDate,
    required this.expiryDate,
    required this.remainingWords,
    required this.isExpired,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'words': words,
      'purchaseDate': purchaseDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'remainingWords': remainingWords,
      'isExpired': isExpired,
    };
  }

  factory WordPackRecord.fromJson(Map<String, dynamic> json) {
    return WordPackRecord(
      id: json['id'],
      type: WordPackType.values[json['type'] ?? 0],
      words: json['words'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
      expiryDate: DateTime.parse(json['expiryDate']),
      remainingWords: json['remainingWords'],
      isExpired: json['isExpired'] ?? false,
    );
  }
}

/// VIP赠送字数记录
class VIPGiftRecord {
  final DateTime date;
  final int words;
  final int remainingWords;

  VIPGiftRecord({
    required this.date,
    required this.words,
    required this.remainingWords,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'words': words,
      'remainingWords': remainingWords,
    };
  }

  factory VIPGiftRecord.fromJson(Map<String, dynamic> json) {
    return VIPGiftRecord(
      date: DateTime.parse(json['date']),
      words: json['words'],
      remainingWords: json['remainingWords'],
    );
  }
}

/// 字数统计信息
class WordPackStats {
  final int vipGiftedWords;
  final int purchasedWords;
  final int totalAvailableWords;
  final int consumedWords;

  WordPackStats({
    required this.vipGiftedWords,
    required this.purchasedWords,
    required this.totalAvailableWords,
    required this.consumedWords,
  });
}

