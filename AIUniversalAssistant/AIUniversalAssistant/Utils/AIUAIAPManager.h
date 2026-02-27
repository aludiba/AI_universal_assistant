//
//  AIUAIAPManager.h
//  AIUniversalAssistant
//
//  Created by AI Assistant on 2025/11/4.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

// 订阅产品ID（需要在App Store Connect中创建）
typedef NS_ENUM(NSInteger, AIUASubscriptionProductType) {
    AIUASubscriptionProductTypeLifetimeBenefits = 0,
    AIUASubscriptionProductTypeYearly,
    AIUASubscriptionProductTypeMonthly,
    AIUASubscriptionProductTypeWeekly           
};

// 购买结果回调（success 时 errorMessage 通常为 nil；若为 AIUARestoredExistingSubscriptionHint 表示检测到已有订阅并恢复，未产生新扣款）
typedef void(^AIUAIAPPurchaseCompletion)(BOOL success, NSString * _Nullable errorMessage);

/// 当 success=YES 且 errorMessage 等于此常量时，表示「检测到已有订阅并恢复」，建议展示「已恢复」而非「购买成功」
extern NSString * const AIUARestoredExistingSubscriptionHint;
typedef void(^AIUAIAPProductsCompletion)(NSArray<SKProduct *> * _Nullable products, NSString * _Nullable errorMessage);
typedef void(^AIUAIAPRestoreCompletion)(BOOL success, NSInteger restoredCount, NSString * _Nullable errorMessage);

@interface AIUAIAPManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/// 是否是VIP会员
@property (nonatomic, assign, readonly) BOOL isVIPMember;

/// 当前订阅类型
@property (nonatomic, assign, readonly) AIUASubscriptionProductType currentSubscriptionType;

/// 订阅到期时间
@property (nonatomic, strong, readonly, nullable) NSDate *subscriptionExpiryDate;

/// 初始化IAP，监听支付队列
- (void)startObservingPaymentQueue;

/// 停止监听支付队列
- (void)stopObservingPaymentQueue;

/// 获取产品信息
- (void)fetchProductsWithCompletion:(AIUAIAPProductsCompletion)completion;

/// 预加载产品信息（在 App 启动时调用，异步获取并缓存产品信息）
- (void)preloadProducts;

/// 从缓存获取产品信息（不包含网络请求）
- (nullable NSArray<SKProduct *> *)getCachedProducts;

/// 从缓存获取指定类型的产品
- (nullable SKProduct *)getCachedProductForType:(AIUASubscriptionProductType)type;

/// 获取字数包产品信息
- (void)fetchWordPackProductsWithCompletion:(AIUAIAPProductsCompletion)completion;

/// 购买订阅产品
- (void)purchaseProduct:(AIUASubscriptionProductType)productType completion:(AIUAIAPPurchaseCompletion)completion;

/// 购买消耗型产品（如字数包）
- (void)purchaseConsumableProduct:(NSString *)productID completion:(AIUAIAPPurchaseCompletion)completion;

/// 恢复购买
- (void)restorePurchasesWithCompletion:(AIUAIAPRestoreCompletion)completion;

/// 标记一次“冷启动恢复窗口”（仅本次启动有效）
- (void)beginLaunchRestoreWindow;

/// 若无订阅且距上次恢复尝试超过 30 秒，则自动重试恢复（用于网络恢复后补恢复）
- (void)retryRestoreIfNoSubscriptionWithCompletion:(nullable AIUAIAPRestoreCompletion)completion;

/// 获取产品ID
- (NSString *)productIdentifierForType:(AIUASubscriptionProductType)type;

/// 获取产品显示名称
- (NSString *)productNameForType:(AIUASubscriptionProductType)type;

/// 检查订阅状态（从本地和服务器验证）
- (void)checkSubscriptionStatus;

/// 清除订阅信息（仅用于测试）
- (void)clearSubscriptionInfo;

/// 清除所有购买数据（包括订阅、字数包、试用次数，仅用于测试）
/// ⚠️ 警告：此操作不可逆！
- (void)clearAllPurchaseData;

/// 本地验证收据
- (BOOL)verifyReceiptLocally;

/// 检测设备是否越狱
+ (BOOL)isJailbroken;

@end

NS_ASSUME_NONNULL_END

