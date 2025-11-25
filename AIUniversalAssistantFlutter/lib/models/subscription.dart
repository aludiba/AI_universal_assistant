enum SubscriptionType {
  none('未订阅', 0.0, ''),
  weekly('周度会员', 6.0, '体验AI写作'),
  monthly('月度会员', 18.0, '短期创作首选'),
  yearly('年度会员', 68.0, '约0.5毛/天'),
  lifetime('永久会员', 198.0, '一次购买，永久使用');

  final String displayName;
  final double price;
  final String description;

  const SubscriptionType(this.displayName, this.price, this.description);

  bool get isVIP => this != SubscriptionType.none;
}

class Subscription {
  final SubscriptionType type;
  final DateTime? expiryDate;
  final bool isActive;

  Subscription({
    required this.type,
    this.expiryDate,
    required this.isActive,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      type: SubscriptionType.values[json['type']],
      expiryDate: json['expiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expiryDate'])
          : null,
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }
}

