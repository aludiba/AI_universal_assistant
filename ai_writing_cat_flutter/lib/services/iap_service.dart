import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/subscription_model.dart';
import 'data_manager.dart';

/// 内购服务
class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();
  
  InAppPurchase? _iap;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  final _dataManager = DataManager();
  
  // 产品ID列表
  final Set<String> _productIds = {
    AppConfig.iapProductLifetime,
    AppConfig.iapProductYearly,
    AppConfig.iapProductMonthly,
    AppConfig.iapProductWeekly,
    AppConfig.iapWordPack500k,
    AppConfig.iapWordPack2m,
    AppConfig.iapWordPack6m,
  };
  
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _initialized = false;
  
  /// 初始化IAP（在鸿蒙等不支持的平台上会优雅降级）
  Future<void> init() async {
    if (_initialized) return;
    
    try {
      // 尝试获取 IAP 实例（在不支持的平台上可能会抛出异常）
      _iap = InAppPurchase.instance;
      
      // 检查是否可用
      try {
        _isAvailable = await _iap!.isAvailable();
      } catch (e) {
        _isAvailable = false;
        debugPrint('IAP isAvailable failed (platform may not support IAP): $e');
        _initialized = true;
        return;
      }
      
      if (!_isAvailable) {
        debugPrint('IAP is not available on this platform');
        _initialized = true;
        return;
      }
      
      // 监听购买更新
      try {
        _subscription = _iap!.purchaseStream.listen(
          _onPurchaseUpdate,
          onError: (error) {
            // 处理错误
            debugPrint('IAP purchaseStream error: $error');
          },
        );
      } catch (e) {
        debugPrint('IAP purchaseStream setup failed: $e');
        _isAvailable = false;
        _initialized = true;
        return;
      }
      
      // 加载产品信息
      await loadProducts();
      
      // 恢复未完成的购买
      try {
        await _iap!.restorePurchases();
      } catch (e) {
        // iOS 模拟器未登录 App Store 时会报 "No active account"
        debugPrint('IAP restorePurchases failed (ignored): $e');
      }
      
      _initialized = true;
    } catch (e, stackTrace) {
      // 捕获所有异常，确保应用不会因 IAP 初始化失败而崩溃
      debugPrint('IAP init failed completely (platform may not support IAP): $e');
      debugPrint('Stack trace: $stackTrace');
      _isAvailable = false;
      _iap = null;
      _initialized = true;
    }
  }
  
  /// 加载产品信息
  Future<void> loadProducts() async {
    if (!_isAvailable || _iap == null) return;
    
    try {
      final ProductDetailsResponse response = await _iap!.queryProductDetails(_productIds);
      
      if (response.error != null) {
        // iOS 模拟器未登录 App Store 时可能会失败：不影响启动，直接降级为空列表
        debugPrint('IAP queryProductDetails error (ignored): ${response.error!.message}');
        _products = [];
        return;
      }
      
      _products = response.productDetails;
    } catch (e) {
      // 不要抛出，避免阻塞 App 启动
      debugPrint('IAP loadProducts failed (ignored): $e');
      _products = [];
    }
  }
  
  /// 获取所有产品
  List<ProductDetails> get products => _products;
  
  /// 根据ID获取产品
  ProductDetails? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }
  
  /// 购买产品
  Future<bool> purchaseProduct(String productId) async {
    if (!_isAvailable || _iap == null) {
      throw Exception('应用内购买不可用');
    }
    
    final product = getProductById(productId);
    if (product == null) {
      throw Exception('产品不存在');
    }
    
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      return await _iap!.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      throw Exception('购买失败: $e');
    }
  }
  
  /// 恢复购买
  Future<void> restorePurchases() async {
    if (!_isAvailable || _iap == null) {
      throw Exception('应用内购买不可用');
    }
    
    try {
      await _iap!.restorePurchases();
    } catch (e) {
      // 主动恢复购买：这里仍然抛出，便于 UI 提示
      throw Exception('恢复购买失败: $e');
    }
  }
  
  /// 处理购买更新
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    if (_iap == null) return;
    
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // 购买待处理
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // 购买失败
        _handleError(purchaseDetails.error!);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // 购买成功或恢复成功
        _handlePurchaseSuccess(purchaseDetails);
      }
      
      // 完成购买
      if (purchaseDetails.pendingCompletePurchase) {
        _iap!.completePurchase(purchaseDetails);
      }
    }
  }
  
  /// 处理购买成功
  void _handlePurchaseSuccess(PurchaseDetails details) {
    final productId = details.productID;
    
    // 判断是订阅还是字数包
    if (_isSubscriptionProduct(productId)) {
      _handleSubscriptionPurchase(productId);
    } else if (_isWordPackProduct(productId)) {
      _handleWordPackPurchase(productId);
    }
  }
  
  /// 处理订阅购买
  void _handleSubscriptionPurchase(String productId) {
    SubscriptionType type;
    bool isLifetime = false;
    
    if (productId == AppConfig.iapProductLifetime) {
      type = SubscriptionType.lifetime;
      isLifetime = true;
    } else if (productId == AppConfig.iapProductYearly) {
      type = SubscriptionType.yearly;
    } else if (productId == AppConfig.iapProductMonthly) {
      type = SubscriptionType.monthly;
    } else if (productId == AppConfig.iapProductWeekly) {
      type = SubscriptionType.weekly;
    } else {
      return;
    }
    
    // 保存订阅信息
    final subscription = SubscriptionModel(
      productId: productId,
      type: type,
      purchaseDate: DateTime.now(),
      expiryDate: isLifetime ? null : _calculateExpiryDate(type),
      isActive: true,
      isLifetime: isLifetime,
    );
    
    _dataManager.saveSubscription(subscription);
    
    // 赠送字数
    _dataManager.addWords(vipGift: AppConfig.subscriptionGiftWords);
  }
  
  /// 处理字数包购买
  void _handleWordPackPurchase(String productId) {
    int words = 0;
    
    if (productId == AppConfig.iapWordPack500k) {
      words = 500000;
    } else if (productId == AppConfig.iapWordPack2m) {
      words = 2000000;
    } else if (productId == AppConfig.iapWordPack6m) {
      words = 6000000;
    }
    
    if (words > 0) {
      _dataManager.addWords(purchased: words);
    }
  }
  
  /// 处理错误
  void _handleError(IAPError error) {
    // 可以在这里添加错误处理逻辑
  }
  
  /// 判断是否为订阅产品
  bool _isSubscriptionProduct(String productId) {
    return productId == AppConfig.iapProductLifetime ||
        productId == AppConfig.iapProductYearly ||
        productId == AppConfig.iapProductMonthly ||
        productId == AppConfig.iapProductWeekly;
  }
  
  /// 判断是否为字数包产品
  bool _isWordPackProduct(String productId) {
    return productId == AppConfig.iapWordPack500k ||
        productId == AppConfig.iapWordPack2m ||
        productId == AppConfig.iapWordPack6m;
  }
  
  /// 计算过期时间
  DateTime _calculateExpiryDate(SubscriptionType type) {
    final now = DateTime.now();
    switch (type) {
      case SubscriptionType.weekly:
        return now.add(const Duration(days: 7));
      case SubscriptionType.monthly:
        return now.add(const Duration(days: 30));
      case SubscriptionType.yearly:
        return now.add(const Duration(days: 365));
      default:
        return now;
    }
  }
  
  /// 销毁
  void dispose() {
    _subscription?.cancel();
  }
}

