/// 应用配置
class AppConfig {
  // AI 代理服务配置（与 iOS AIUAConfigID.h 对齐）
  static const String aiProxyUrl = 'https://api.hujiaofenwritingcat.top/ai';
  // 与服务端 APP_CLIENT_TOKEN 对齐；不需要时可留空
  static const String appClientToken = '';
  // 与服务端 APP_SIGNING_SECRET 对齐；启用“版本+时间戳签名”时填写
  static const String appSigningSecret = '';
  static const String billingBaseUrl = 'https://api.hujiaofenwritingcat.top';
  static const String billingApiPath = '/v1/billing';
  static const String billingAppToken = '';
  static const String wechatAppId = '';

  // 兼容旧字段：不再使用客户端直连 DeepSeek Key
  static const String deepseekApiKey = '';
  static const String deepseekBaseUrl = aiProxyUrl;
  static const String deepseekModel = 'deepseek-chat';
  
  // 应用配置
  static const String appName = 'AI创作喵';
  static const String appVersion = '1.0.0';
  
  // 广告开关（可在此控制广告功能）
  static const bool adEnabled = false; // Flutter版本暂不支持广告
  
  // VIP检测开关
  static const bool vipCheckEnabled = false;
  
  // IAP产品ID配置
  static const String iapProductLifetime = 'membership.lifetime';
  static const String iapProductYearly = 'membership.yearly';
  static const String iapProductMonthly = 'membership.monthly';
  static const String iapProductWeekly = 'membership.weekly';
  
  // 字数包产品ID
  static const String iapWordPack500k = 'wordpack.500k';
  static const String iapWordPack2m = 'wordpack.2m';
  static const String iapWordPack6m = 'wordpack.6m';
  
  // 字数配置
  static const int subscriptionGiftWords = 500000; // 订阅赠送50万字
  static const int wordPackValidityDays = 90; // 字数包有效期90天
  static const int dailyRewardWords = 50000; // 每日激励视频奖励5万字
  static const int maxDailyRewardCount = 4; // 每日最多观看4次
  
  // 试用配置
  static const int maxTrialCount = 3; // 最多试用3次
  
  // API超时配置
  static const Duration apiTimeout = Duration(seconds: 120);
  
  // 缓存配置
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
}

