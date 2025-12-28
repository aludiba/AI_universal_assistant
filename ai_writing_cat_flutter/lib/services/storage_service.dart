import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_pack_model.dart';
import '../models/subscription_model.dart';

/// 本地存储服务
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  SharedPreferences? _prefs;
  
  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService未初始化，请先调用init()');
    }
    return _prefs!;
  }
  
  // ==================== 订阅相关 ====================
  
  /// 保存订阅信息
  Future<void> saveSubscription(SubscriptionModel subscription) async {
    await prefs.setString('subscription', jsonEncode(subscription.toJson()));
  }
  
  /// 获取订阅信息
  SubscriptionModel? getSubscription() {
    final data = prefs.getString('subscription');
    if (data == null) return null;
    return SubscriptionModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }
  
  /// 清除订阅信息
  Future<void> clearSubscription() async {
    await prefs.remove('subscription');
  }
  
  /// 是否是VIP
  bool get isVip {
    final subscription = getSubscription();
    return subscription?.isVip ?? false;
  }
  
  // ==================== 字数包相关 ====================
  
  /// 保存字数包统计
  Future<void> saveWordPackStats(WordPackStats stats) async {
    await prefs.setString('word_pack_stats', jsonEncode(stats.toJson()));
  }
  
  /// 获取字数包统计
  WordPackStats getWordPackStats() {
    final data = prefs.getString('word_pack_stats');
    if (data == null) {
      return WordPackStats(
        vipGiftWords: 0,
        purchasedWords: 0,
        rewardWords: 0,
        consumedWords: 0,
      );
    }
    return WordPackStats.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }
  
  /// 保存字数包列表
  Future<void> saveWordPacks(List<WordPackModel> packs) async {
    final data = packs.map((p) => p.toJson()).toList();
    await prefs.setString('word_packs', jsonEncode(data));
  }
  
  /// 获取字数包列表
  List<WordPackModel> getWordPacks() {
    final data = prefs.getString('word_packs');
    if (data == null) return [];
    final List<dynamic> list = jsonDecode(data) as List;
    return list.map((e) => WordPackModel.fromJson(e as Map<String, dynamic>)).toList();
  }
  
  /// 消耗字数
  Future<bool> consumeWords(int words) async {
    final stats = getWordPackStats();
    if (!stats.hasEnoughWords(words)) {
      return false;
    }
    
    final newStats = WordPackStats(
      vipGiftWords: stats.vipGiftWords,
      purchasedWords: stats.purchasedWords,
      rewardWords: stats.rewardWords,
      consumedWords: stats.consumedWords + words,
    );
    
    await saveWordPackStats(newStats);
    return true;
  }
  
  /// 添加字数（购买或赠送）
  Future<void> addWords({
    int vipGift = 0,
    int purchased = 0,
    int reward = 0,
  }) async {
    final stats = getWordPackStats();
    final newStats = WordPackStats(
      vipGiftWords: stats.vipGiftWords + vipGift,
      purchasedWords: stats.purchasedWords + purchased,
      rewardWords: stats.rewardWords + reward,
      consumedWords: stats.consumedWords,
    );
    await saveWordPackStats(newStats);
  }
  
  // ==================== 试用相关 ====================
  
  /// 获取试用次数
  int getTrialCount() {
    return prefs.getInt('trial_count') ?? 0;
  }
  
  /// 增加试用次数
  Future<void> incrementTrialCount() async {
    final count = getTrialCount();
    await prefs.setInt('trial_count', count + 1);
  }
  
  /// 是否还有试用次数
  bool hasTrialRemaining() {
    return getTrialCount() < 3; // 最多3次试用
  }
  
  // ==================== 激励视频相关 ====================
  
  /// 获取今日观看次数
  int getTodayRewardCount() {
    final lastDate = prefs.getString('reward_last_date');
    final today = DateTime.now().toString().substring(0, 10);
    
    if (lastDate != today) {
      return 0;
    }
    
    return prefs.getInt('reward_count') ?? 0;
  }
  
  /// 增加观看次数
  Future<void> incrementRewardCount() async {
    final today = DateTime.now().toString().substring(0, 10);
    await prefs.setString('reward_last_date', today);
    
    final count = getTodayRewardCount();
    await prefs.setInt('reward_count', count + 1);
  }
  
  /// 是否可以观看激励视频
  bool canWatchRewardAd() {
    return getTodayRewardCount() < 4; // 每天最多4次
  }
  
  // ==================== 搜索历史 ====================
  
  /// 保存搜索历史
  Future<void> saveSearchHistory(List<String> history) async {
    await prefs.setStringList('search_history', history);
  }
  
  /// 获取搜索历史
  List<String> getSearchHistory() {
    return prefs.getStringList('search_history') ?? [];
  }
  
  /// 添加搜索记录
  Future<void> addSearchHistory(String keyword) async {
    final history = getSearchHistory();
    history.remove(keyword); // 移除重复项
    history.insert(0, keyword); // 插入到最前面
    if (history.length > 20) {
      history.removeRange(20, history.length); // 最多保留20条
    }
    await saveSearchHistory(history);
  }
  
  /// 清空搜索历史
  Future<void> clearSearchHistory() async {
    await prefs.remove('search_history');
  }
  
  // ==================== 应用设置 ====================
  
  /// 获取启动次数
  int getLaunchCount() {
    return prefs.getInt('launch_count') ?? 0;
  }
  
  /// 增加启动次数
  Future<void> incrementLaunchCount() async {
    final count = getLaunchCount();
    await prefs.setInt('launch_count', count + 1);
  }
  
  /// 是否显示过引导
  bool hasShownGuide() {
    return prefs.getBool('has_shown_guide') ?? false;
  }
  
  /// 设置已显示引导
  Future<void> setShownGuide() async {
    await prefs.setBool('has_shown_guide', true);
  }
  
  /// 获取主题模式
  String getThemeMode() {
    return prefs.getString('theme_mode') ?? 'system';
  }
  
  /// 设置主题模式
  Future<void> setThemeMode(String mode) async {
    await prefs.setString('theme_mode', mode);
  }
  
  /// 获取语言
  String? getLanguage() {
    return prefs.getString('language');
  }
  
  /// 设置语言
  Future<void> setLanguage(String language) async {
    await prefs.setString('language', language);
  }
  
  /// 清空所有数据
  Future<void> clearAll() async {
    await prefs.clear();
  }
}

