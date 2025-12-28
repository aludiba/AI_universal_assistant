/// 订阅模型
class SubscriptionModel {
  final String productId;
  final SubscriptionType type;
  final DateTime? purchaseDate;
  final DateTime? expiryDate;
  final bool isActive;
  final bool isLifetime;
  
  SubscriptionModel({
    required this.productId,
    required this.type,
    this.purchaseDate,
    this.expiryDate,
    this.isActive = false,
    this.isLifetime = false,
  });
  
  // 从JSON创建
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      productId: json['productId'] as String,
      type: SubscriptionType.values.firstWhere(
        (e) => e.toString() == 'SubscriptionType.${json['type']}',
        orElse: () => SubscriptionType.none,
      ),
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? false,
      isLifetime: json['isLifetime'] as bool? ?? false,
    );
  }
  
  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'type': type.toString().split('.').last,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'isActive': isActive,
      'isLifetime': isLifetime,
    };
  }
  
  // 复制并修改
  SubscriptionModel copyWith({
    String? productId,
    SubscriptionType? type,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    bool? isActive,
    bool? isLifetime,
  }) {
    return SubscriptionModel(
      productId: productId ?? this.productId,
      type: type ?? this.type,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      isLifetime: isLifetime ?? this.isLifetime,
    );
  }
  
  // 是否为VIP
  bool get isVip => isActive || isLifetime;
  
  // 获取剩余天数
  int get remainingDays {
    if (isLifetime || expiryDate == null) return -1;
    if (!isActive) return 0;
    return expiryDate!.difference(DateTime.now()).inDays;
  }
}

/// 订阅类型
enum SubscriptionType {
  none,
  weekly,
  monthly,
  yearly,
  lifetime,
}

/// 订阅产品信息
class SubscriptionProduct {
  final String productId;
  final SubscriptionType type;
  final String title;
  final String description;
  final String price;
  final bool isRecommended;
  
  SubscriptionProduct({
    required this.productId,
    required this.type,
    required this.title,
    required this.description,
    required this.price,
    this.isRecommended = false,
  });
}

