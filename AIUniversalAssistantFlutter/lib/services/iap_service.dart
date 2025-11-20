import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../config/app_config.dart';
import '../models/subscription_model.dart';

/// IAP内购服务
class IAPService extends ChangeNotifier {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  SubscriptionModel? _currentSubscription;
  bool _isVIPMember = false;
  SubscriptionType _currentSubscriptionType = SubscriptionType.none;
  DateTime? _subscriptionExpiryDate;

  bool get isVIPMember => _isVIPMember;
  SubscriptionType get currentSubscriptionType => _currentSubscriptionType;
  DateTime? get subscriptionExpiryDate => _subscriptionExpiryDate;

  /// 初始化
  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      return;
    }

    // 监听购买更新
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('IAP Error: $error'),
    );

    // 检查订阅状态
    await checkSubscriptionStatus();
  }

  /// 获取产品信息
  Future<List<ProductDetails>> fetchProducts() async {
    if (!_isAvailable) {
      return [];
    }

    final productIds = {
      AppConfig.iapLifetimeProductId,
      AppConfig.iapYearlyProductId,
      AppConfig.iapMonthlyProductId,
      AppConfig.iapWeeklyProductId,
      AppConfig.wordPack500KProductId,
      AppConfig.wordPack2MProductId,
      AppConfig.wordPack6MProductId,
    };

    final response = await _iap.queryProductDetails(productIds);
    _products = response.productDetails;
    return _products;
  }

  /// 购买订阅
  Future<IAPPurchaseResult> purchaseSubscription(
    SubscriptionType type,
  ) async {
    if (!_isAvailable) {
      return IAPPurchaseResult(
        success: false,
        errorMessage: '设备不支持应用内购买',
      );
    }

    final productId = _getProductIdForSubscriptionType(type);
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('产品未找到'),
    );

    final purchaseParam = PurchaseParam(productDetails: product);
    final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);

    if (success) {
      return IAPPurchaseResult(success: true);
    } else {
      return IAPPurchaseResult(
        success: false,
        errorMessage: '购买失败',
      );
    }
  }

  /// 购买消耗型产品（字数包）
  Future<IAPPurchaseResult> purchaseConsumableProduct(String productId) async {
    if (!_isAvailable) {
      return IAPPurchaseResult(
        success: false,
        errorMessage: '设备不支持应用内购买',
      );
    }

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('产品未找到'),
    );

    final purchaseParam = PurchaseParam(productDetails: product);
    final success = await _iap.buyConsumable(purchaseParam: purchaseParam);

    if (success) {
      return IAPPurchaseResult(success: true);
    } else {
      return IAPPurchaseResult(
        success: false,
        errorMessage: '购买失败',
      );
    }
  }

  /// 恢复购买
  Future<IAPRestoreResult> restorePurchases() async {
    if (!_isAvailable) {
      return IAPRestoreResult(
        success: false,
        restoredCount: 0,
        errorMessage: '设备不支持应用内购买',
      );
    }

    try {
      await _iap.restorePurchases();
      // 恢复购买会触发购买更新流
      return IAPRestoreResult(success: true, restoredCount: 1);
    } catch (e) {
      return IAPRestoreResult(
        success: false,
        restoredCount: 0,
        errorMessage: e.toString(),
      );
    }
  }

  /// 检查订阅状态
  Future<void> checkSubscriptionStatus() async {
    if (!_isAvailable) {
      return;
    }

    // 从收据验证订阅状态
    // 这里简化处理，实际应该验证收据
    final pastPurchases = await _iap.restorePurchases();
    
    // 解析收据获取订阅信息
    // 实际实现需要调用服务器验证或本地验证
    _updateSubscriptionStatus();
  }

  void _updateSubscriptionStatus() {
    // 从本地存储或收据中解析订阅信息
    // 这里简化处理
    _isVIPMember = false;
    _currentSubscriptionType = SubscriptionType.none;
    _subscriptionExpiryDate = null;
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (var purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        // 购买进行中
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // 购买成功或恢复成功
        _handleSuccessfulPurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        // 购买失败
        print('Purchase error: ${purchase.error}');
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  void _handleSuccessfulPurchase(PurchaseDetails purchase) {
    final productId = purchase.productID;
    
    // 判断是订阅还是消耗型产品
    if (_isSubscriptionProduct(productId)) {
      _updateSubscriptionFromPurchase(productId);
    } else if (_isWordPackProduct(productId)) {
      // 字数包购买成功，由WordPackService处理
    }
  }

  bool _isSubscriptionProduct(String productId) {
    return productId == AppConfig.iapLifetimeProductId ||
        productId == AppConfig.iapYearlyProductId ||
        productId == AppConfig.iapMonthlyProductId ||
        productId == AppConfig.iapWeeklyProductId;
  }

  bool _isWordPackProduct(String productId) {
    return productId == AppConfig.wordPack500KProductId ||
        productId == AppConfig.wordPack2MProductId ||
        productId == AppConfig.wordPack6MProductId;
  }

  void _updateSubscriptionFromPurchase(String productId) {
    if (productId == AppConfig.iapLifetimeProductId) {
      _isVIPMember = true;
      _currentSubscriptionType = SubscriptionType.lifetime;
      _subscriptionExpiryDate = null;
    } else {
      // 其他订阅类型需要从收据中解析到期时间
      // 这里简化处理
      _isVIPMember = true;
      _currentSubscriptionType = _getSubscriptionTypeFromProductId(productId);
      // 实际应该从收据中获取到期时间
    }
  }

  SubscriptionType _getSubscriptionTypeFromProductId(String productId) {
    switch (productId) {
      case AppConfig.iapYearlyProductId:
        return SubscriptionType.yearly;
      case AppConfig.iapMonthlyProductId:
        return SubscriptionType.monthly;
      case AppConfig.iapWeeklyProductId:
        return SubscriptionType.weekly;
      default:
        return SubscriptionType.none;
    }
  }

  String _getProductIdForSubscriptionType(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.lifetime:
        return AppConfig.iapLifetimeProductId;
      case SubscriptionType.yearly:
        return AppConfig.iapYearlyProductId;
      case SubscriptionType.monthly:
        return AppConfig.iapMonthlyProductId;
      case SubscriptionType.weekly:
        return AppConfig.iapWeeklyProductId;
      default:
        return '';
    }
  }

  /// 清理资源
  void dispose() {
    _subscription?.cancel();
  }
}

/// IAP购买结果
class IAPPurchaseResult {
  final bool success;
  final String? errorMessage;

  IAPPurchaseResult({
    required this.success,
    this.errorMessage,
  });
}

/// IAP恢复结果
class IAPRestoreResult {
  final bool success;
  final int restoredCount;
  final String? errorMessage;

  IAPRestoreResult({
    required this.success,
    required this.restoredCount,
    this.errorMessage,
  });
}

