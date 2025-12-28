/// 应用配置
class AppConfig {
  // DeepSeek API配置
  static const String deepseekApiKey = 'sk-ecdd2f67aa60478bab7cb3fdd0e83343';
  static const String deepseekBaseUrl = 'https://api.deepseek.com/v1';
  static const String deepseekModel = 'deepseek-chat';
  
  // 应用配置
  static const String appName = 'AI创作喵';
  static const String appVersion = '1.0.0';
  
  // 广告开关（可在此控制广告功能）
  static const bool adEnabled = false; // Flutter版本暂不支持广告
  
  // VIP检测开关
  static const bool vipCheckEnabled = true;
  
  // IAP产品ID配置
  static const String iapProductLifetime = 'com.hujiaofen.writingCat.lifetimeBenefits';
  static const String iapProductYearly = 'com.hujiaofen.writingCat.yearly';
  static const String iapProductMonthly = 'com.hujiaofen.writingCat.monthly';
  static const String iapProductWeekly = 'com.hujiaofen.writingCat.weekly';
  
  // 字数包产品ID
  static const String iapWordPack500k = 'com.hujiaofen.writingCat.wordpack.500k';
  static const String iapWordPack2m = 'com.hujiaofen.writingCat.wordpack.2m';
  static const String iapWordPack6m = 'com.hujiaofen.writingCat.wordpack.6m';
  
  // 字数配置
  static const int subscriptionGiftWords = 500000; // 订阅赠送50万字
  static const int wordPackValidityDays = 90; // 字数包有效期90天
  static const int dailyRewardWords = 50000; // 每日激励视频奖励5万字
  static const int maxDailyRewardCount = 4; // 每日最多观看4次
  
  // 试用配置
  static const int maxTrialCount = 3; // 最多试用3次
  
  // API超时配置
  static const Duration apiTimeout = Duration(seconds: 60);
  
  // 缓存配置
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
}

