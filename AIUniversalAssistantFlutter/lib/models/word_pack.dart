enum WordPackType {
  pack500K('50万字', 500000, 6.0),
  pack1M('100万字', 1000000, 12.0),
  pack3M('300万字', 3000000, 30.0),
  pack5M('500万字', 5000000, 50.0);

  final String displayName;
  final int words;
  final double price;

  const WordPackType(this.displayName, this.words, this.price);
}

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

  factory WordPackRecord.fromJson(Map<String, dynamic> json) {
    return WordPackRecord(
      id: json['id'],
      type: WordPackType.values[json['type']],
      words: json['words'],
      purchaseDate: DateTime.fromMillisecondsSinceEpoch(json['purchaseDate']),
      expiryDate: DateTime.fromMillisecondsSinceEpoch(json['expiryDate']),
      remainingWords: json['remainingWords'],
      isExpired: json['isExpired'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'words': words,
      'purchaseDate': purchaseDate.millisecondsSinceEpoch,
      'expiryDate': expiryDate.millisecondsSinceEpoch,
      'remainingWords': remainingWords,
      'isExpired': isExpired,
    };
  }

  WordPackRecord copyWith({
    int? remainingWords,
    bool? isExpired,
  }) {
    return WordPackRecord(
      id: id,
      type: type,
      words: words,
      purchaseDate: purchaseDate,
      expiryDate: expiryDate,
      remainingWords: remainingWords ?? this.remainingWords,
      isExpired: isExpired ?? this.isExpired,
    );
  }
}

class VIPGiftRecord {
  final DateTime date;
  final int words;
  final int remainingWords;

  VIPGiftRecord({
    required this.date,
    required this.words,
    required this.remainingWords,
  });

  factory VIPGiftRecord.fromJson(Map<String, dynamic> json) {
    return VIPGiftRecord(
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      words: json['words'],
      remainingWords: json['remainingWords'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.millisecondsSinceEpoch,
      'words': words,
      'remainingWords': remainingWords,
    };
  }
}

class WordConsumeResult {
  final bool success;
  final int remainingWords;

  WordConsumeResult({
    required this.success,
    required this.remainingWords,
  });
}

