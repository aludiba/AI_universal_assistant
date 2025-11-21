import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_model.dart';
import 'iap_service.dart';
import 'package:flutter/foundation.dart';

/// VIP服务
class VIPService extends ChangeNotifier {
  static final VIPService _instance = VIPService._internal();
  factory VIPService() => _instance;
  VIPService._internal();

  final IAPService _iapService = IAPService();
  static const String _keySubscription = 'subscription';

  /// 检查是否是VIP
  Future<bool> isVIP() async {
    final subscription = await getSubscription();
    if (subscription.type == SubscriptionType.lifetime) {
      return true;
    }

    if (subscription.isActive && subscription.expiryDate != null) {
      return subscription.expiryDate!.isAfter(DateTime.now());
    }

    return false;
  }

  /// 获取订阅信息
  Future<SubscriptionModel> getSubscription() async {
    // 先从IAP服务检查
    await _iapService.checkSubscriptionStatus();

    final prefs = await SharedPreferences.getInstance();
    final subscriptionJson = prefs.getString(_keySubscription);

    if (subscriptionJson != null) {
      try {
        // 解析订阅JSON（如果需要从本地存储恢复）
        // 实际应该从IAP服务获取，这里暂时不使用本地存储的json
        jsonDecode(subscriptionJson);
      } catch (e) {
        // 解析失败，返回默认值
      }
    }

    // 从IAP服务获取最新状态
    final isVIP = _iapService.isVIPMember;
    final subscriptionType = await _iapService.getCurrentSubscriptionType();
    final expiryDate = await _iapService.getSubscriptionExpiryDate();

    final subscription = SubscriptionModel(
      type: subscriptionType,
      expiryDate: expiryDate,
      isActive: isVIP,
    );

    // 保存到本地
    await _saveSubscription(subscription);

    return subscription;
  }

  /// 检查VIP权限
  Future<bool> checkVIPPermission({String? featureName}) async {
    return await isVIP();
  }

  Future<void> _saveSubscription(SubscriptionModel subscription) async {
    final prefs = await SharedPreferences.getInstance();
    // 简化存储，实际应该序列化完整对象
    await prefs.setBool('is_vip', subscription.isActive);
    await prefs.setInt('subscription_type', subscription.type.index);
    if (subscription.expiryDate != null) {
      await prefs.setString(
        'expiry_date',
        subscription.expiryDate!.toIso8601String(),
      );
    }
  }
}

