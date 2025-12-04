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
    AIUASubscriptionProductTypeLifetimeBenefits = 0,    // com.aiassistant.lifetimeBenefits
    AIUASubscriptionProductTypeYearly,          // com.aiassistant.yearly
    AIUASubscriptionProductTypeMonthly,         // com.aiassistant.monthly
    AIUASubscriptionProductTypeWeekly           // com.aiassistant.weekly
};

// 购买结果回调
typedef void(^AIUAIAPPurchaseCompletion)(BOOL success, NSString * _Nullable errorMessage);
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

/// 获取字数包产品信息
- (void)fetchWordPackProductsWithCompletion:(AIUAIAPProductsCompletion)completion;

/// 购买订阅产品
- (void)purchaseProduct:(AIUASubscriptionProductType)productType completion:(AIUAIAPPurchaseCompletion)completion;

/// 购买消耗型产品（如字数包）
- (void)purchaseConsumableProduct:(NSString *)productID completion:(AIUAIAPPurchaseCompletion)completion;

/// 恢复购买
- (void)restorePurchasesWithCompletion:(AIUAIAPRestoreCompletion)completion;

/// 获取产品ID
- (NSString *)productIdentifierForType:(AIUASubscriptionProductType)type;

/// 获取产品显示名称
- (NSString *)productNameForType:(AIUASubscriptionProductType)type;

/// 检查订阅状态（从本地和服务器验证）
- (void)checkSubscriptionStatus;

/// 清除订阅信息（仅用于测试）
- (void)clearSubscriptionInfo;

/// 本地验证收据
- (BOOL)verifyReceiptLocally;

/// 检测设备是否越狱
+ (BOOL)isJailbroken;

@end

NS_ASSUME_NONNULL_END

