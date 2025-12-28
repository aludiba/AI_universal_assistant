/// 字数包模型
class WordPackModel {
  final String id;
  final int words;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final bool isExpired;
  final WordPackType type;
  
  WordPackModel({
    required this.id,
    required this.words,
    required this.purchaseDate,
    required this.expiryDate,
    required this.type,
  }) : isExpired = DateTime.now().isAfter(expiryDate);
  
  // 从JSON创建
  factory WordPackModel.fromJson(Map<String, dynamic> json) {
    return WordPackModel(
      id: json['id'] as String,
      words: json['words'] as int,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      type: WordPackType.values.firstWhere(
        (e) => e.toString() == 'WordPackType.${json['type']}',
        orElse: () => WordPackType.purchased,
      ),
    );
  }
  
  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'words': words,
      'purchaseDate': purchaseDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'type': type.toString().split('.').last,
    };
  }
  
  // 复制并修改
  WordPackModel copyWith({
    String? id,
    int? words,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    WordPackType? type,
  }) {
    return WordPackModel(
      id: id ?? this.id,
      words: words ?? this.words,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      type: type ?? this.type,
    );
  }
  
  // 获取剩余天数
  int get remainingDays {
    if (isExpired) return 0;
    return expiryDate.difference(DateTime.now()).inDays;
  }
  
  // 是否即将过期（7天内）
  bool get isExpiringSoon {
    return !isExpired && remainingDays <= 7;
  }
}

/// 字数包类型
enum WordPackType {
  vipGift,    // VIP赠送
  purchased,  // 购买的字数包
  reward,     // 激励视频奖励
}

/// 字数包统计
class WordPackStats {
  final int vipGiftWords;      // VIP赠送字数
  final int purchasedWords;    // 购买的字数
  final int rewardWords;       // 奖励字数
  final int totalWords;        // 总字数
  final int consumedWords;     // 已消耗字数
  
  WordPackStats({
    required this.vipGiftWords,
    required this.purchasedWords,
    required this.rewardWords,
    required this.consumedWords,
  }) : totalWords = vipGiftWords + purchasedWords + rewardWords;
  
  // 从JSON创建
  factory WordPackStats.fromJson(Map<String, dynamic> json) {
    return WordPackStats(
      vipGiftWords: json['vipGiftWords'] as int? ?? 0,
      purchasedWords: json['purchasedWords'] as int? ?? 0,
      rewardWords: json['rewardWords'] as int? ?? 0,
      consumedWords: json['consumedWords'] as int? ?? 0,
    );
  }
  
  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'vipGiftWords': vipGiftWords,
      'purchasedWords': purchasedWords,
      'rewardWords': rewardWords,
      'consumedWords': consumedWords,
    };
  }
  
  // 获取剩余字数
  int get remainingWords => totalWords - consumedWords;
  
  // 是否有足够的字数
  bool hasEnoughWords(int required) => remainingWords >= required;
}

