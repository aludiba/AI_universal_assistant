/// 应用配置
class AppConfig {
  // DeepSeek API配置
  static const String deepSeekApiKey = 'sk-ecdd2f67aa60478bab7cb3fdd0e83343';
  static const String deepSeekBaseUrl = 'https://api.deepseek.com';
  static const String deepSeekModel = 'deepseek-chat';
  static const int requestTimeout = 60; // 秒

  // IAP产品ID配置
  static const String iapLifetimeProductId = 'com.aiassistant.lifetime';
  static const String iapYearlyProductId = 'com.aiassistant.yearly';
  static const String iapMonthlyProductId = 'com.aiassistant.monthly';
  static const String iapWeeklyProductId = 'com.aiassistant.weekly';
  
  // 字数包产品ID
  static const String wordPack500KProductId = 'com.aiassistant.wordpack.500k';
  static const String wordPack2MProductId = 'com.aiassistant.wordpack.2m';
  static const String wordPack6MProductId = 'com.aiassistant.wordpack.6m';

  // 字数包配置
  static const Map<String, int> wordPackSizes = {
    wordPack500KProductId: 500000,
    wordPack2MProductId: 2000000,
    wordPack6MProductId: 6000000,
  };

  static const Map<String, String> wordPackPrices = {
    wordPack500KProductId: '¥6',
    wordPack2MProductId: '¥18',
    wordPack6MProductId: '¥38',
  };

  // VIP配置
  static const int vipDailyGiftWords = 500000; // 每日赠送50万字
  static const int wordPackValidDays = 90; // 字数包有效期90天
  static const int rewardVideoWords = 50000; // 激励视频奖励5万字
  static const int rewardVideoDailyLimit = 4; // 每日最多4次

  // 广告配置（可选）
  static const bool adEnabled = true;
  static const String pangleAppId = '5755016';
  static const String pangleSplashAdSlotId = '893331808';
  static const String pangleRewardAdSlotId = '972751105';

  // 应用信息
  static const String appName = '万能写作大师';
  static const String appVersion = '1.0.0';
}

