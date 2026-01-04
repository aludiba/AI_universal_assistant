import 'package:flutter/material.dart';
import '../services/data_manager.dart';
import '../services/iap_service.dart';
import '../models/subscription_model.dart';
import '../models/word_pack_model.dart';

/// 应用全局状态管理
class AppProvider with ChangeNotifier {
  final _dataManager = DataManager();
  final _iapService = IAPService();
  
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  SubscriptionModel? _subscription;
  WordPackStats? _wordPackStats;
  
  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  SubscriptionModel? get subscription => _subscription;
  WordPackStats? get wordPackStats => _wordPackStats;
  
  /// 是否是VIP
  bool get isVip => _subscription?.isVip ?? false;
  
  /// 剩余字数
  int get remainingWords => _wordPackStats?.remainingWords ?? 0;
  
  /// 初始化
  Future<void> init() async {
    await _dataManager.init();
    
    // 加载主题模式
    final themeModeStr = _dataManager.getThemeMode();
    _themeMode = _getThemeModeFromString(themeModeStr);
    
    // 加载语言
    final languageCode = _dataManager.getLanguage();
    if (languageCode != null) {
      _locale = Locale(languageCode);
    }
    
    // 加载订阅信息
    _subscription = _dataManager.getSubscription();
    
    // 加载字数包统计
    _wordPackStats = _dataManager.getWordPackStats();
    
    // 先把 UI 起起来，再尝试初始化 IAP（失败不阻塞启动）
    try {
      await _iapService.init();
    } catch (e) {
      // ignore: avoid_print
      print('IAP init failed (ignored): $e');
    }
    
    notifyListeners();
  }
  
  /// 切换主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _dataManager.setThemeMode(_getStringFromThemeMode(mode));
    notifyListeners();
  }
  
  /// 切换语言
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _dataManager.setLanguage(locale.languageCode);
    notifyListeners();
  }
  
  /// 刷新订阅信息
  Future<void> refreshSubscription() async {
    _subscription = _dataManager.getSubscription();
    notifyListeners();
  }
  
  /// 刷新字数包统计
  Future<void> refreshWordPackStats() async {
    _wordPackStats = _dataManager.getWordPackStats();
    notifyListeners();
  }
  
  /// 消耗字数
  Future<bool> consumeWords(int words) async {
    final success = await _dataManager.consumeWords(words);
    if (success) {
      await refreshWordPackStats();
    }
    return success;
  }
  
  /// 检查是否有足够的字数
  bool hasEnoughWords(int required) {
    return remainingWords >= required;
  }
  
  /// 购买产品
  Future<bool> purchaseProduct(String productId) async {
    try {
      final success = await _iapService.purchaseProduct(productId);
      if (success) {
        await refreshSubscription();
        await refreshWordPackStats();
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }
  
  /// 恢复购买
  Future<void> restorePurchases() async {
    await _iapService.restorePurchases();
    await refreshSubscription();
    await refreshWordPackStats();
  }
  
  ThemeMode _getThemeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  String _getStringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}

