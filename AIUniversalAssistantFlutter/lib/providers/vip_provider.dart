import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../services/storage_service.dart';

class VIPProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  Subscription _subscription = Subscription(
    type: SubscriptionType.none,
    isActive: false,
  );

  Subscription get subscription => _subscription;
  bool get isVIP => _subscription.isActive && _subscription.type.isVIP;

  /// 加载订阅信息
  Future<void> loadSubscription() async {
    final json = await _storageService.getSubscription();
    if (json != null) {
      try {
        _subscription = Subscription.fromJson(jsonDecode(json));
      } catch (e) {
        _subscription = Subscription(
          type: SubscriptionType.none,
          isActive: false,
        );
      }
    }
    notifyListeners();
  }

  /// 订阅会员
  Future<void> subscribe(SubscriptionType type) async {
    DateTime? expiryDate;
    
    switch (type) {
      case SubscriptionType.weekly:
        expiryDate = DateTime.now().add(const Duration(days: 7));
        break;
      case SubscriptionType.monthly:
        expiryDate = DateTime.now().add(const Duration(days: 30));
        break;
      case SubscriptionType.yearly:
        expiryDate = DateTime.now().add(const Duration(days: 365));
        break;
      case SubscriptionType.lifetime:
        expiryDate = null;
        break;
      case SubscriptionType.none:
        expiryDate = null;
        break;
    }

    _subscription = Subscription(
      type: type,
      expiryDate: expiryDate,
      isActive: true,
    );

    await _storageService.saveSubscription(jsonEncode(_subscription.toJson()));
    notifyListeners();
  }

  /// 取消订阅
  Future<void> cancelSubscription() async {
    _subscription = Subscription(
      type: SubscriptionType.none,
      isActive: false,
    );
    await _storageService.saveSubscription(jsonEncode(_subscription.toJson()));
    notifyListeners();
  }

  /// 检查订阅是否过期
  bool checkSubscriptionExpiry() {
    if (!_subscription.isActive) return false;

    final expiryDate = _subscription.expiryDate;
    if (expiryDate == null) return true; // 永久会员

    final isExpired = DateTime.now().isAfter(expiryDate);
    if (isExpired) {
      cancelSubscription();
    }
    return !isExpired;
  }
}

