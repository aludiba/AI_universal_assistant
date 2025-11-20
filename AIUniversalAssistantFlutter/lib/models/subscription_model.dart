/// 订阅类型
enum SubscriptionType {
  lifetime,
  yearly,
  monthly,
  weekly,
  none,
}

/// 订阅模型
class SubscriptionModel {
  final SubscriptionType type;
  final DateTime? expiryDate;
  final bool isActive;

  SubscriptionModel({
    required this.type,
    this.expiryDate,
    required this.isActive,
  });

  bool get isVIP => isActive && type != SubscriptionType.none;

  String get displayName {
    switch (type) {
      case SubscriptionType.lifetime:
        return '永久会员';
      case SubscriptionType.yearly:
        return '年度会员';
      case SubscriptionType.monthly:
        return '月度会员';
      case SubscriptionType.weekly:
        return '周度会员';
      case SubscriptionType.none:
        return '未开通会员';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'expiryDate': expiryDate?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      type: SubscriptionType.values[json['type'] ?? 4],
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      isActive: json['isActive'] ?? false,
    );
  }
}

