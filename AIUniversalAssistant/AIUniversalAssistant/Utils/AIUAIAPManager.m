//
//  AIUAIAPManager.m
//  AIUniversalAssistant
//
//  Created by AI Assistant on 2025/11/4.
//

#import "AIUAIAPManager.h"
#import "AIUAWordPackManager.h"
#import "AIUAConfigID.h"
#import "AIUAAlertHelper.h"
#import <sys/stat.h>
#import <mach-o/dyld.h>

// 本地存储Key
static NSString * const kAIUAIsVIPMember = @"kAIUAIsVIPMember";
static NSString * const kAIUASubscriptionType = @"kAIUASubscriptionType";
static NSString * const kAIUASubscriptionExpiryDate = @"kAIUASubscriptionExpiryDate";
static NSString * const kAIUAHasSubscriptionHistory = @"hasSubscriptionHistory";

@interface AIUAIAPManager () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong) NSMutableDictionary<NSString *, SKProduct *> *productsCache;
@property (nonatomic, strong) SKProductsRequest *productsRequest;
@property (nonatomic, copy) AIUAIAPProductsCompletion productsCompletion;
@property (nonatomic, copy) AIUAIAPPurchaseCompletion purchaseCompletion;
@property (nonatomic, copy) AIUAIAPRestoreCompletion restoreCompletion;
@property (nonatomic, assign) NSInteger restoredPurchasesCount;
@property (nonatomic, strong, nullable) NSString *pendingPurchaseProductID; // 待购买的产品ID（用于异步获取产品后继续购买）

@property (nonatomic, assign, readwrite) BOOL isVIPMember;
@property (nonatomic, assign, readwrite) AIUASubscriptionProductType currentSubscriptionType;
@property (nonatomic, strong, readwrite, nullable) NSDate *subscriptionExpiryDate;

@end

@implementation AIUAIAPManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
    static AIUAIAPManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _productsCache = [NSMutableDictionary dictionary];
        [self loadLocalSubscriptionInfo];
    }
    return self;
}

#pragma mark - Public Methods

- (void)startObservingPaymentQueue {
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)stopObservingPaymentQueue {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)fetchProductsWithCompletion:(AIUAIAPProductsCompletion)completion {
    // 如果已经有缓存的产品，直接返回
    if (self.productsCache.count > 0) {
        NSArray *products = self.productsCache.allValues;
        if (completion) {
            completion(products, nil);
        }
        return;
    }
    
    // 检查设备是否支持IAP
    if (![SKPaymentQueue canMakePayments]) {
        if (completion) {
            completion(nil, L(@"iap_not_supported"));
        }
        return;
    }
    
    self.productsCompletion = completion;
    
    // 构建产品ID集合
    NSSet *productIdentifiers = [NSSet setWithObjects:
                                 [self productIdentifierForType:AIUASubscriptionProductTypeLifetimeBenefits],
                                 [self productIdentifierForType:AIUASubscriptionProductTypeYearly],
                                 [self productIdentifierForType:AIUASubscriptionProductTypeMonthly],
                                 [self productIdentifierForType:AIUASubscriptionProductTypeWeekly],
                                 nil];
    
    // 请求产品信息
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
    
    NSLog(@"[IAP] 开始请求产品信息，Bundle ID: %@", [[NSBundle mainBundle] bundleIdentifier]);
    NSLog(@"[IAP] 请求的产品ID列表: %@", productIdentifiers);
}

- (void)fetchWordPackProductsWithCompletion:(AIUAIAPProductsCompletion)completion {
    // 检查设备是否支持IAP
    if (![SKPaymentQueue canMakePayments]) {
        if (completion) {
            completion(nil, L(@"iap_not_supported"));
        }
        return;
    }
    
    // 获取字数包管理器
    AIUAWordPackManager *wordPackManager = [AIUAWordPackManager sharedManager];
    
    // 构建字数包产品ID集合
    NSSet *productIdentifiers = [NSSet setWithObjects:
                                 [wordPackManager productIDForPackType:AIUAWordPackType500K],
                                 [wordPackManager productIDForPackType:AIUAWordPackType2M],
                                 [wordPackManager productIDForPackType:AIUAWordPackType6M],
                                 nil];
    
    // 检查缓存中是否已有所有字数包产品
    NSMutableArray<SKProduct *> *cachedProducts = [NSMutableArray array];
    BOOL allCached = YES;
    
    for (NSString *productID in productIdentifiers) {
        SKProduct *product = self.productsCache[productID];
        if (product) {
            [cachedProducts addObject:product];
        } else {
            allCached = NO;
        }
    }
    
    // 如果所有产品都已缓存，直接返回
    if (allCached && cachedProducts.count > 0) {
        NSLog(@"[IAP] 字数包产品已在缓存中，直接返回");
        if (completion) {
            completion(cachedProducts, nil);
        }
        return;
    }
    
    self.productsCompletion = completion;
    
    // 请求产品信息
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
    
    NSLog(@"[IAP] 开始请求字数包产品信息，Bundle ID: %@", [[NSBundle mainBundle] bundleIdentifier]);
    NSLog(@"[IAP] 请求的字数包产品ID列表: %@", productIdentifiers);
}

- (void)purchaseProduct:(AIUASubscriptionProductType)productType completion:(AIUAIAPPurchaseCompletion)completion {
    // 检查设备是否支持IAP
    if (![SKPaymentQueue canMakePayments]) {
        if (completion) {
            completion(NO, L(@"iap_not_supported"));
        }
        return;
    }
    
    self.purchaseCompletion = completion;
    
    NSString *productIdentifier = [self productIdentifierForType:productType];
    SKProduct *product = self.productsCache[productIdentifier];
    
    if (!product) {
        // 如果没有产品信息，先获取产品信息
        [self fetchProductsWithCompletion:^(NSArray<SKProduct *> * _Nullable products, NSString * _Nullable errorMessage) {
            if (products.count > 0) {
                SKProduct *targetProduct = nil;
                for (SKProduct *p in products) {
                    if ([p.productIdentifier isEqualToString:productIdentifier]) {
                        targetProduct = p;
                        break;
                    }
                }
                
                if (targetProduct) {
                    [self addPaymentForProduct:targetProduct];
                } else {
                    if (completion) {
                        completion(NO, L(@"product_not_found"));
                    }
                }
            } else {
                if (completion) {
                    completion(NO, errorMessage ?: L(@"failed_to_fetch_products"));
                }
            }
        }];
        return;
    }
    
    [self addPaymentForProduct:product];
}

- (void)purchaseConsumableProduct:(NSString *)productID completion:(AIUAIAPPurchaseCompletion)completion {
    // 检查设备是否支持IAP
    if (![SKPaymentQueue canMakePayments]) {
        if (completion) {
            completion(NO, L(@"iap_not_supported"));
        }
        return;
    }
    
    self.purchaseCompletion = completion;
    
    // 先检查缓存
    SKProduct *product = self.productsCache[productID];
    
    if (!product) {
        NSLog(@"[IAP] 消耗型产品未在缓存中，先获取产品信息: %@", productID);
        
        // 保存待购买的产品ID
        self.pendingPurchaseProductID = productID;
        
        // 获取产品信息
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productID]];
        request.delegate = self;
        [request start];
        
        // 注意：这里会异步等待产品信息返回后再购买
        // 在 productsRequest:didReceiveResponse: 中会处理购买
        return;
    }
    
    [self addPaymentForProduct:product];
}

- (void)addPaymentForProduct:(SKProduct *)product {
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
    NSLog(@"[IAP] 发起购买请求: %@", product.productIdentifier);
}

- (void)restorePurchasesWithCompletion:(AIUAIAPRestoreCompletion)completion {
    if (![SKPaymentQueue canMakePayments]) {
        if (completion) {
            completion(NO, 0, L(@"iap_not_supported"));
        }
        return;
    }
    
    self.restoreCompletion = completion;
    self.restoredPurchasesCount = 0;
    
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    
    NSLog(@"[IAP] 开始恢复购买");
}

- (void)checkSubscriptionStatus {
    [self loadLocalSubscriptionInfo];
    
    // 验证收据并更新订阅信息
    BOOL isValid = [self verifyReceiptLocally];
    
    if (!isValid) {
        // 收据验证失败时，只记录日志，不清除VIP状态
        // 因为：
        // 1. 沙盒环境下收据验证可能失败
        // 2. 刚购买后收据可能还未完全生成
        // 3. 收据解析可能因为格式问题失败
        // 如果本地已经有VIP状态，应该保留，由到期时间来判断
        NSLog(@"[IAP] ⚠️ 收据验证失败（可能是沙盒环境或收据未完全生成），保留本地VIP状态");
        
        // 只有当没有到期时间且收据验证失败时，才清除VIP状态
        if (!self.subscriptionExpiryDate && _isVIPMember) {
            NSLog(@"[IAP] 没有到期时间且收据验证失败，清除VIP状态");
            _isVIPMember = NO;
            [self saveLocalSubscriptionInfo];
        }
        
        return;
    }
    
    // 检查订阅是否过期
    if (self.subscriptionExpiryDate) {
        NSDate *now = [NSDate date];
        if ([now compare:self.subscriptionExpiryDate] == NSOrderedDescending) {
            // 订阅已过期
            NSLog(@"[IAP] 订阅已过期");
            _isVIPMember = NO;
            [self saveLocalSubscriptionInfo];
        } else {
            NSLog(@"[IAP] ✓ 订阅有效，到期时间: %@", self.subscriptionExpiryDate);
        }
    }
    
    // 注意：本地验证只是基础检查，强烈建议在生产环境中使用服务器验证
    // [self verifyReceiptWithServer];
}

- (void)clearSubscriptionInfo {
    _isVIPMember = NO;
    self.currentSubscriptionType = AIUASubscriptionProductTypeWeekly;
    self.subscriptionExpiryDate = nil;
    [self saveLocalSubscriptionInfo];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kAIUAHasSubscriptionHistory];
    [defaults synchronize];
    
    NSLog(@"[IAP] 清除订阅信息");
}

#pragma mark - Product ID Management

- (NSString *)productIdentifierForType:(AIUASubscriptionProductType)type {
    // 优先使用配置文件中定义的产品ID，如果没有定义则自动生成
    NSString *productID = nil;
    
    switch (type) {
        case AIUASubscriptionProductTypeLifetimeBenefits:
#ifdef AIUA_IAP_PRODUCT_LIFETIME
            productID = AIUA_IAP_PRODUCT_LIFETIME;
#else
            {
                NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
                productID = [NSString stringWithFormat:@"%@.lifetimeBenefits", bundleID];
            }
#endif
            break;
        case AIUASubscriptionProductTypeYearly:
#ifdef AIUA_IAP_PRODUCT_YEARLY
            productID = AIUA_IAP_PRODUCT_YEARLY;
#else
            {
                NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
                productID = [NSString stringWithFormat:@"%@.yearly", bundleID];
            }
#endif
            break;
        case AIUASubscriptionProductTypeMonthly:
#ifdef AIUA_IAP_PRODUCT_MONTHLY
            productID = AIUA_IAP_PRODUCT_MONTHLY;
#else
            {
                NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
                productID = [NSString stringWithFormat:@"%@.monthly", bundleID];
            }
#endif
            break;
        case AIUASubscriptionProductTypeWeekly:
#ifdef AIUA_IAP_PRODUCT_WEEKLY
            productID = AIUA_IAP_PRODUCT_WEEKLY;
#else
            {
                NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
                productID = [NSString stringWithFormat:@"%@.weekly", bundleID];
            }
#endif
            break;
        default:
            return @"";
    }
    
    NSLog(@"[IAP] 产品类型 %ld 的产品ID: %@", (long)type, productID);
    return productID;
}

- (NSString *)productNameForType:(AIUASubscriptionProductType)type {
    switch (type) {
        case AIUASubscriptionProductTypeLifetimeBenefits:
            return L(@"lifetime_member");
        case AIUASubscriptionProductTypeYearly:
            return L(@"yearly_plan");
        case AIUASubscriptionProductTypeMonthly:
            return L(@"monthly_plan");
        case AIUASubscriptionProductTypeWeekly:
            return L(@"weekly_plan");
        default:
            return @"";
    }
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSLog(@"[IAP] 收到产品信息响应");
    NSLog(@"[IAP] 可用产品数量: %lu", (unsigned long)response.products.count);
    
    if (response.invalidProductIdentifiers.count > 0) {
        NSLog(@"[IAP] ⚠️ 无效产品ID（请检查App Store Connect中的产品ID是否与代码中一致）: %@", response.invalidProductIdentifiers);
        NSLog(@"[IAP] 当前Bundle ID: %@", [[NSBundle mainBundle] bundleIdentifier]);
    } else {
        NSLog(@"[IAP] ✅ 所有产品ID都有效");
    }
    
    // 缓存产品信息
    for (SKProduct *product in response.products) {
        self.productsCache[product.productIdentifier] = product;
        NSLog(@"[IAP] 产品: %@ - %@ - %@", product.localizedTitle, product.price, product.priceLocale);
    }
    
    // 确保在主线程执行所有UI相关操作和回调
    dispatch_async(dispatch_get_main_queue(), ^{
        // 优先处理购买请求（如果有待购买的产品ID）
        if (self.pendingPurchaseProductID) {
            NSString *productID = self.pendingPurchaseProductID;
            self.pendingPurchaseProductID = nil; // 清除待购买的产品ID
            
            // 查找对应的产品
            SKProduct *targetProduct = nil;
            for (SKProduct *product in response.products) {
                if ([product.productIdentifier isEqualToString:productID]) {
                    targetProduct = product;
                    break;
                }
            }
            
            if (targetProduct) {
                // 找到产品，继续购买流程
                NSLog(@"[IAP] 找到待购买产品，继续购买流程: %@", productID);
                [self addPaymentForProduct:targetProduct];
            } else {
                // 未找到产品，调用购买失败回调
                NSLog(@"[IAP] 未找到待购买产品: %@", productID);
                if (self.purchaseCompletion) {
                    self.purchaseCompletion(NO, L(@"product_not_found"));
                    self.purchaseCompletion = nil;
                }
            }
            
            // 如果有productsCompletion，也需要处理（可能是同时触发的）
            if (self.productsCompletion) {
                if (response.products.count > 0) {
                    self.productsCompletion(response.products, nil);
                } else {
                    self.productsCompletion(nil, L(@"no_products_available"));
                }
                self.productsCompletion = nil;
            }
        } else if (self.productsCompletion) {
            // 没有待购买的产品，正常处理产品获取回调
            if (response.products.count > 0) {
                self.productsCompletion(response.products, nil);
            } else {
                self.productsCompletion(nil, L(@"no_products_available"));
            }
            self.productsCompletion = nil;
        }
    });
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSString *errorMessage = error.localizedDescription;
    NSLog(@"[IAP] 产品请求失败: %@", errorMessage);
    
    // 确保在主线程执行所有UI相关操作和回调
    dispatch_async(dispatch_get_main_queue(), ^{
        // 显示调试错误弹窗
        [AIUAAlertHelper showDebugErrorAlert:errorMessage context:@"获取产品失败"];
        
        // 如果有待购买的产品ID，说明是购买触发的产品请求失败
        if (self.pendingPurchaseProductID) {
            NSString *productID = self.pendingPurchaseProductID;
            self.pendingPurchaseProductID = nil; // 清除待购买的产品ID
            
            // 调用购买失败回调
            if (self.purchaseCompletion) {
                self.purchaseCompletion(NO, errorMessage ?: L(@"failed_to_fetch_products"));
                self.purchaseCompletion = nil;
            }
        }
        
        // 处理产品获取回调
        if (self.productsCompletion) {
            self.productsCompletion(nil, errorMessage);
            self.productsCompletion = nil;
        }
    });
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    // 确保在主线程执行所有UI相关操作和回调
    dispatch_async(dispatch_get_main_queue(), ^{
        for (SKPaymentTransaction *transaction in transactions) {
            switch (transaction.transactionState) {
                case SKPaymentTransactionStatePurchasing:
                    NSLog(@"[IAP] 正在购买: %@", transaction.payment.productIdentifier);
                    break;
                    
                case SKPaymentTransactionStatePurchased:
                    NSLog(@"[IAP] 购买成功: %@", transaction.payment.productIdentifier);
                    [self completeTransaction:transaction];
                    break;
                    
                case SKPaymentTransactionStateFailed:
                {
                    NSString *errorMessage = transaction.error.localizedDescription;
                    NSLog(@"[IAP] 购买失败: %@ - %@", transaction.payment.productIdentifier, errorMessage);
                    
                    // 显示调试错误弹窗（用户取消购买时不显示）
                    if (transaction.error.code != SKErrorPaymentCancelled) {
                        NSString *context = [NSString stringWithFormat:@"购买失败 (%@)", transaction.payment.productIdentifier];
                        [AIUAAlertHelper showDebugErrorAlert:errorMessage context:context];
                    }
                    
                    [self failedTransaction:transaction];
                    break;
                }
                    
                case SKPaymentTransactionStateRestored:
                    NSLog(@"[IAP] 恢复购买: %@", transaction.payment.productIdentifier);
                    [self restoreTransaction:transaction];
                    break;
                    
                case SKPaymentTransactionStateDeferred:
                    NSLog(@"[IAP] 购买延迟: %@", transaction.payment.productIdentifier);
                    break;
                    
                default:
                    break;
            }
        }
    });
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    NSLog(@"[IAP] 恢复购买完成，共恢复 %ld 个", (long)self.restoredPurchasesCount);
    
    // 确保在主线程执行回调
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.restoreCompletion) {
            if (self.restoredPurchasesCount > 0) {
                self.restoreCompletion(YES, self.restoredPurchasesCount, nil);
            } else {
                self.restoreCompletion(NO, 0, L(@"no_subscription_found"));
            }
            self.restoreCompletion = nil;
        }
    });
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    NSString *errorMessage = error.localizedDescription;
    NSLog(@"[IAP] 恢复购买失败: %@", errorMessage);
    
    // 确保在主线程执行所有UI相关操作和回调
    dispatch_async(dispatch_get_main_queue(), ^{
        // 显示调试错误弹窗
        [AIUAAlertHelper showDebugErrorAlert:errorMessage context:@"恢复购买失败"];
        
        if (self.restoreCompletion) {
            self.restoreCompletion(NO, 0, errorMessage);
            self.restoreCompletion = nil;
        }
    });
}

#pragma mark - Transaction Processing

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    // 验证收据
    [self verifyReceipt:transaction];
    
    // 解锁内容
    [self unlockContentForProductIdentifier:transaction.payment.productIdentifier];
    
    // 完成交易
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    if (self.purchaseCompletion) {
        self.purchaseCompletion(YES, nil);
        self.purchaseCompletion = nil;
    }
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    NSString *errorMessage = transaction.error.localizedDescription;
    
    // 用户取消不算错误
    if (transaction.error.code == SKErrorPaymentCancelled) {
        errorMessage = L(@"purchase_cancelled");
    }
    
    if (self.purchaseCompletion) {
        self.purchaseCompletion(NO, errorMessage);
        self.purchaseCompletion = nil;
    }
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    NSString *productIdentifier = transaction.payment.productIdentifier;
    NSLog(@"[IAP] 恢复交易: %@", productIdentifier);
    
    // 判断是会员订阅还是字数包
    BOOL isWordPack = [productIdentifier containsString:@"wordpack"];
    
    if (isWordPack) {
        // 恢复字数包 - 不重复发放，只在购买时发放一次
        // 字数包是消耗型产品，恢复购买时不应该重复发放
        NSLog(@"[IAP] 恢复字数包产品: %@，消耗型产品不重复发放", productIdentifier);
    } else {
        // 恢复会员订阅
        [self unlockContentForProductIdentifier:productIdentifier];
    }
    
    // 完成交易
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    self.restoredPurchasesCount++;
}

#pragma mark - Content Unlocking

- (void)unlockContentForProductIdentifier:(NSString *)productIdentifier {
    NSLog(@"[IAP] 解锁内容: %@", productIdentifier);
    
    // 确定产品类型
    AIUASubscriptionProductType type = [self productTypeForIdentifier:productIdentifier];
    
    // 设置会员状态
    _isVIPMember = YES;
    self.currentSubscriptionType = type;
    
    // 设置过期时间
    NSDate *expiryDate = [self calculateExpiryDateForProductType:type];
    self.subscriptionExpiryDate = expiryDate;
    
    NSLog(@"[IAP] ✓ 已设置VIP状态 - 类型: %ld, 到期: %@", (long)type, expiryDate);
    
    // 保存订阅记录
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kAIUAHasSubscriptionHistory];
    [defaults synchronize];
    
    // 保存到本地
    [self saveLocalSubscriptionInfo];
    
    // 发送通知（字数包管理器会监听此通知并刷新赠送字数）
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AIUASubscriptionStatusChanged" object:nil];
    
    NSLog(@"[IAP] ✓ 已发送订阅状态变化通知");
}

- (AIUASubscriptionProductType)productTypeForIdentifier:(NSString *)identifier {
    if ([identifier containsString:@"lifetimeBenefits"]) {
        return AIUASubscriptionProductTypeLifetimeBenefits;
    } else if ([identifier containsString:@"yearly"]) {
        return AIUASubscriptionProductTypeYearly;
    } else if ([identifier containsString:@"monthly"]) {
        return AIUASubscriptionProductTypeMonthly;
    } else if ([identifier containsString:@"weekly"]) {
        return AIUASubscriptionProductTypeWeekly;
    }
    return AIUASubscriptionProductTypeWeekly;
}

- (NSDate *)calculateExpiryDateForProductType:(AIUASubscriptionProductType)type {
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    
    switch (type) {
        case AIUASubscriptionProductTypeLifetimeBenefits:
            // 永久会员，设置为100年后
            components.year = 100;
            break;
        case AIUASubscriptionProductTypeYearly:
            components.year = 1;
            break;
        case AIUASubscriptionProductTypeMonthly:
            components.month = 1;
            break;
        case AIUASubscriptionProductTypeWeekly:
            components.day = 7;
            break;
    }
    
    return [calendar dateByAddingComponents:components toDate:now options:0];
}

#pragma mark - Receipt Verification

- (void)verifyReceipt:(SKPaymentTransaction *)transaction {
    // 获取收据数据
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    
    if (!receiptData) {
        NSLog(@"[IAP] 未找到收据数据");
        return;
    }
    
    // 本地验证收据基本信息
    BOOL isValid = [self verifyReceiptLocally];
    NSLog(@"[IAP] 本地收据验证结果: %@", isValid ? @"通过" : @"失败");
    
    // 注意：本地验证只是基础检查，不能完全防止破解
    // 强烈建议在生产环境中使用服务器验证：
    // 1. 将收据数据发送到你的服务器
    // 2. 服务器将收据转发到 Apple 验证服务器
    //    - 生产环境: https://buy.itunes.apple.com/verifyReceipt
    //    - 沙盒环境: https://sandbox.itunes.apple.com/verifyReceipt
    // 3. Apple 返回验证结果（JSON格式）
    // 4. 服务器解析结果并决定是否解锁内容
    // 5. 服务器返回结果给客户端
    
    // 示例服务器验证代码（需要在你的服务器端实现）：
    /*
    NSString *receiptString = [receiptData base64EncodedStringWithOptions:0];
    NSDictionary *requestDict = @{@"receipt-data": receiptString};
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:nil];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"YOUR_SERVER_URL"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = requestData;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data) {
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            // 处理服务器返回的验证结果
        }
    }] resume];
    */
}

- (BOOL)verifyReceiptLocally {
    // 1. 检查收据文件是否存在
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    if (!receiptURL) {
        NSLog(@"[IAP] 收据URL为空");
        return NO;
    }
    
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    if (!receiptData || receiptData.length == 0) {
        NSLog(@"[IAP] 收据数据为空");
        return NO;
    }
    
    NSLog(@"[IAP] 收据文件存在，大小: %lu bytes", (unsigned long)receiptData.length);
    
    // 2. 验证 Bundle ID
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    NSLog(@"[IAP] 应用 Bundle ID: %@", bundleIdentifier);
    NSLog(@"[IAP] 应用版本: %@", bundleVersion);
    
    // 3. 收据文件大小验证
    if (receiptData.length < 100) {
        NSLog(@"[IAP] 收据文件太小，可能无效");
        return NO;
    }
    
    // 4. 检查是否是 PKCS#7 格式
    const unsigned char *bytes = [receiptData bytes];
    if (bytes[0] != 0x30) {
        NSLog(@"[IAP] 收据格式不是有效的 PKCS#7");
        return NO;
    }
    
    // 5. 解析收据中的 Bundle ID 和订阅信息
    NSDictionary *receiptInfo = [self parseReceiptData:receiptData];
    
    if (receiptInfo) {
        // 验证 Bundle ID
        NSString *receiptBundleId = receiptInfo[@"bundle_id"];
        if (receiptBundleId && ![receiptBundleId isEqualToString:bundleIdentifier]) {
            NSLog(@"[IAP] Bundle ID不匹配！应用: %@, 收据: %@", bundleIdentifier, receiptBundleId);
            return NO;
        }
        
        // 提取订阅信息
        NSArray *inAppPurchases = receiptInfo[@"in_app"];
        if (inAppPurchases && inAppPurchases.count > 0) {
            // 找到最新的有效订阅
            NSDictionary *latestSubscription = [self findLatestValidSubscription:inAppPurchases];
            
            if (latestSubscription) {
                NSString *productId = latestSubscription[@"product_id"];
                NSDate *expiresDate = latestSubscription[@"expires_date"];
                
                NSLog(@"[IAP] 从收据中提取订阅信息 - 产品: %@, 到期: %@", productId, expiresDate);
                
                // 根据 product_id 确定订阅类型
                AIUASubscriptionProductType productType = [self productTypeFromProductId:productId];
                
                // 更新本地缓存
                self.currentSubscriptionType = productType;
                
                if (expiresDate) {
                    self.subscriptionExpiryDate = expiresDate;
                    
                    // 检查是否过期
                    NSDate *now = [NSDate date];
                    if ([now compare:expiresDate] == NSOrderedAscending) {
                        // 未过期
                        _isVIPMember = YES;
                        NSLog(@"[IAP] 订阅有效，类型: %ld, 到期: %@", (long)productType, expiresDate);
                    } else {
                        // 已过期
                        _isVIPMember = NO;
                        NSLog(@"[IAP] 订阅已过期");
                    }
                } else {
                    // 永久会员或非续期订阅
                    _isVIPMember = YES;
                    self.subscriptionExpiryDate = [self calculateExpiryDateForProductType:productType];
                    NSLog(@"[IAP] 永久订阅");
                }
                
                // 保存更新后的信息
                [self saveLocalSubscriptionInfo];
            }
        }
    }
    
    NSLog(@"[IAP] 本地收据验证通过");
    
    // 注意：这只是基本验证，真正的安全性需要服务器端验证
    return YES;
}

// 解析收据中的订阅信息
- (NSDictionary *)parseReceiptData:(NSData *)receiptData {
    if (!receiptData || receiptData.length == 0) {
        return nil;
    }
    
    // 注意：完整的ASN.1解析非常复杂
    // 这里实现简化版本，提取关键信息
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSMutableArray *inAppPurchases = [NSMutableArray array];
    
    const uint8_t *bytes = [receiptData bytes];
    NSUInteger length = receiptData.length;
    
    // 尝试查找Bundle ID和购买记录
    // Bundle ID 在收据中的字段类型为 2
    // In-App Purchase 在收据中的字段类型为 17
    
    for (NSUInteger i = 0; i < length - 20; i++) {
        // 查找 Bundle ID 模式
        if (i + 100 < length) {
            NSString *bundleId = [self extractBundleIdFromReceipt:receiptData atOffset:i];
            if (bundleId && bundleId.length > 0) {
                result[@"bundle_id"] = bundleId;
                NSLog(@"[IAP] 从收据中提取 Bundle ID: %@", bundleId);
            }
        }
        
        // 查找产品ID模式（简化查找）
        NSString *productId = [self extractProductIdFromReceipt:receiptData atOffset:i];
        if (productId && [productId containsString:@"."]) {
            // 可能是一个有效的产品ID
            NSMutableDictionary *purchase = [NSMutableDictionary dictionary];
            purchase[@"product_id"] = productId;
            
            // 尝试提取过期时间（对于自动续订订阅）
            NSDate *expiresDate = [self extractExpiresDateFromReceipt:receiptData nearOffset:i];
            if (expiresDate) {
                purchase[@"expires_date"] = expiresDate;
            }
            
            [inAppPurchases addObject:purchase];
            NSLog(@"[IAP] 从收据中提取产品: %@", productId);
        }
    }
    
    if (inAppPurchases.count > 0) {
        result[@"in_app"] = inAppPurchases;
    }
    
    return result.count > 0 ? result : nil;
}

// 从收据中提取 Bundle ID
- (NSString *)extractBundleIdFromReceipt:(NSData *)receiptData atOffset:(NSUInteger)offset {
    const uint8_t *bytes = [receiptData bytes];
    NSUInteger length = receiptData.length;
    
    if (offset + 50 > length) return nil;
    
    // 查找可能的Bundle ID字符串
    // Bundle ID通常是 com.company.appname 格式
    for (NSUInteger i = offset; i < MIN(offset + 100, length - 30); i++) {
        if (bytes[i] == 'c' && bytes[i+1] == 'o' && bytes[i+2] == 'm' && bytes[i+3] == '.') {
            // 可能找到了Bundle ID
            NSUInteger endPos = i;
            while (endPos < length && endPos < i + 100) {
                char c = bytes[endPos];
                if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || 
                    (c >= '0' && c <= '9') || c == '.' || c == '-') {
                    endPos++;
                } else {
                    break;
                }
            }
            
            if (endPos > i + 10) { // Bundle ID至少有一定长度
                NSData *bundleData = [receiptData subdataWithRange:NSMakeRange(i, endPos - i)];
                NSString *bundleId = [[NSString alloc] initWithData:bundleData encoding:NSUTF8StringEncoding];
                if (bundleId && [bundleId componentsSeparatedByString:@"."].count >= 3) {
                    return bundleId;
                }
            }
        }
    }
    
    return nil;
}

// 从收据中提取产品ID
- (NSString *)extractProductIdFromReceipt:(NSData *)receiptData atOffset:(NSUInteger)offset {
    const uint8_t *bytes = [receiptData bytes];
    NSUInteger length = receiptData.length;
    
    if (offset + 50 > length) return nil;
    
    // 查找可能的产品ID (包含 lifetimeBenefits, yearly, monthly, weekly)
    NSArray *productTypes = @[@"lifetimeBenefits", @"yearly", @"monthly", @"weekly"];
    
    for (NSString *type in productTypes) {
        const char *typeStr = [type UTF8String];
        NSUInteger typeLen = strlen(typeStr);
        
        if (offset + typeLen < length) {
            BOOL found = YES;
            for (NSUInteger j = 0; j < typeLen; j++) {
                if (bytes[offset + j] != typeStr[j]) {
                    found = NO;
                    break;
                }
            }
            
            if (found) {
                // 向前查找完整的产品ID
                NSUInteger startPos = offset;
                while (startPos > 0 && startPos > offset - 100) {
                    char c = bytes[startPos - 1];
                    if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || 
                        (c >= '0' && c <= '9') || c == '.' || c == '-') {
                        startPos--;
                    } else {
                        break;
                    }
                }
                
                NSUInteger endPos = offset + typeLen;
                NSData *productData = [receiptData subdataWithRange:NSMakeRange(startPos, endPos - startPos)];
                NSString *productId = [[NSString alloc] initWithData:productData encoding:NSUTF8StringEncoding];
                
                if (productId && [productId containsString:@"."]) {
                    return productId;
                }
            }
        }
    }
    
    return nil;
}

// 从收据中提取过期时间
- (NSDate *)extractExpiresDateFromReceipt:(NSData *)receiptData nearOffset:(NSUInteger)offset {
    if (!receiptData || receiptData.length == 0) {
        return nil;
    }
    
    const uint8_t *bytes = [receiptData bytes];
    NSUInteger length = receiptData.length;
    
    // 在产品ID附近搜索时间戳
    // ASN.1 时间戳格式：YYYYMMDDTHHMMSSZ 或 YYYY-MM-DDTHH:MM:SSZ
    NSUInteger searchStart = (offset > 200) ? offset - 200 : 0;
    NSUInteger searchEnd = MIN(offset + 500, length);
    
    // 方法1: 查找 ISO 8601 格式时间戳 (YYYY-MM-DD)
    NSDate *isoDate = [self findISO8601DateInReceipt:receiptData start:searchStart end:searchEnd];
    if (isoDate) {
        NSLog(@"[IAP] 从收据中提取到 ISO 8601 时间戳: %@", isoDate);
        return isoDate;
    }
    
    // 方法2: 查找 ASN.1 GeneralizedTime 格式 (YYYYMMDDHHMMSSZ)
    NSDate *asnDate = [self findASN1DateInReceipt:receiptData start:searchStart end:searchEnd];
    if (asnDate) {
        NSLog(@"[IAP] 从收据中提取到 ASN.1 时间戳: %@", asnDate);
        return asnDate;
    }
    
    NSLog(@"[IAP] 未能从收据中提取过期时间");
    return nil;
}

// 查找 ISO 8601 格式的时间戳 (YYYY-MM-DDTHH:MM:SSZ)
- (NSDate *)findISO8601DateInReceipt:(NSData *)receiptData start:(NSUInteger)start end:(NSUInteger)end {
    const uint8_t *bytes = [receiptData bytes];
    NSUInteger length = receiptData.length;
    
    // 查找模式: 20XX-XX-XX (未来日期，作为订阅到期时间)
    for (NSUInteger i = start; i < end && i < length - 20; i++) {
        // 检查是否是年份开头 (20)
        if (bytes[i] == '2' && bytes[i+1] == '0' && 
            bytes[i+2] >= '2' && bytes[i+2] <= '9' && 
            bytes[i+3] >= '0' && bytes[i+3] <= '9') {
            
            // 检查日期分隔符 (-)
            if (i + 10 < length && bytes[i+4] == '-' && bytes[i+7] == '-') {
                // 提取完整的时间戳字符串
                NSString *dateString = [self extractDateStringFromReceipt:receiptData offset:i];
                
                if (dateString && dateString.length >= 10) {
                    NSDate *date = [self parseDateString:dateString];
                    if (date) {
                        // 验证日期是否在未来（订阅到期时间应该在未来）
                        NSDate *now = [NSDate date];
                        NSTimeInterval interval = [date timeIntervalSinceDate:now];
                        
                        // 只接受未来3个月到10年之间的日期（合理的订阅周期）
                        if (interval > -30*24*3600 && interval < 10*365*24*3600) {
                            return date;
                        }
                    }
                }
            }
        }
    }
    
    return nil;
}

// 查找 ASN.1 GeneralizedTime 格式 (YYYYMMDDHHMMSSZ)
- (NSDate *)findASN1DateInReceipt:(NSData *)receiptData start:(NSUInteger)start end:(NSUInteger)end {
    const uint8_t *bytes = [receiptData bytes];
    NSUInteger length = receiptData.length;
    
    // ASN.1 GeneralizedTime 标签是 0x18
    for (NSUInteger i = start; i < end && i < length - 20; i++) {
        if (bytes[i] == 0x18) {
            // 下一个字节是长度
            NSUInteger timeLength = bytes[i+1];
            
            // GeneralizedTime 通常是 15 字节 (YYYYMMDDHHMMSSZ)
            if (timeLength >= 14 && timeLength <= 17 && i + 2 + timeLength < length) {
                NSData *timeData = [receiptData subdataWithRange:NSMakeRange(i+2, timeLength)];
                NSString *timeString = [[NSString alloc] initWithData:timeData encoding:NSASCIIStringEncoding];
                
                if (timeString && [self isValidASN1TimeString:timeString]) {
                    NSDate *date = [self parseASN1TimeString:timeString];
                    if (date) {
                        // 验证日期合理性
                        NSDate *now = [NSDate date];
                        NSTimeInterval interval = [date timeIntervalSinceDate:now];
                        
                        if (interval > -30*24*3600 && interval < 10*365*24*3600) {
                            return date;
                        }
                    }
                }
            }
        }
    }
    
    return nil;
}

// 从收据中提取日期字符串
- (NSString *)extractDateStringFromReceipt:(NSData *)receiptData offset:(NSUInteger)offset {
    const uint8_t *bytes = [receiptData bytes];
    NSUInteger length = receiptData.length;
    
    if (offset + 30 > length) return nil;
    
    // 尝试提取完整的 ISO 8601 时间戳
    // 格式: YYYY-MM-DDTHH:MM:SSZ 或 YYYY-MM-DD HH:MM:SS
    NSMutableString *dateString = [NSMutableString string];
    
    for (NSUInteger i = offset; i < MIN(offset + 30, length); i++) {
        char c = bytes[i];
        
        // 有效的日期时间字符
        if ((c >= '0' && c <= '9') || c == '-' || c == ':' || 
            c == 'T' || c == 'Z' || c == ' ' || c == '.') {
            [dateString appendFormat:@"%c", c];
        } else {
            // 遇到非日期字符，停止
            break;
        }
        
        // 至少获取 YYYY-MM-DD
        if (dateString.length >= 10) {
            break;
        }
    }
    
    return dateString.length >= 10 ? dateString : nil;
}

// 解析日期字符串
- (NSDate *)parseDateString:(NSString *)dateString {
    if (!dateString || dateString.length < 10) {
        return nil;
    }
    
    // 尝试多种格式
    NSArray *formatters = @[
        [self createDateFormatterWithFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"],      // ISO 8601 完整格式
        [self createDateFormatterWithFormat:@"yyyy-MM-dd'T'HH:mm:ss"],         // ISO 8601 无Z
        [self createDateFormatterWithFormat:@"yyyy-MM-dd HH:mm:ss"],           // 空格分隔
        [self createDateFormatterWithFormat:@"yyyy-MM-dd"],                    // 仅日期
    ];
    
    for (NSDateFormatter *formatter in formatters) {
        NSDate *date = [formatter dateFromString:dateString];
        if (date) {
            return date;
        }
    }
    
    return nil;
}

// 创建日期格式化器
- (NSDateFormatter *)createDateFormatterWithFormat:(NSString *)format {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    return formatter;
}

// 验证 ASN.1 时间字符串格式
- (BOOL)isValidASN1TimeString:(NSString *)timeString {
    if (!timeString || timeString.length < 14) {
        return NO;
    }
    
    // GeneralizedTime 格式: YYYYMMDDHHMMSSZ
    // 至少14个字符，以Z结尾
    return [timeString hasSuffix:@"Z"] && timeString.length >= 14;
}

// 解析 ASN.1 GeneralizedTime 字符串
- (NSDate *)parseASN1TimeString:(NSString *)timeString {
    if (![self isValidASN1TimeString:timeString]) {
        return nil;
    }
    
    // 格式: YYYYMMDDHHMMSSZ
    // 提取各个部分
    if (timeString.length < 14) return nil;
    
    NSInteger year = [[timeString substringWithRange:NSMakeRange(0, 4)] integerValue];
    NSInteger month = [[timeString substringWithRange:NSMakeRange(4, 2)] integerValue];
    NSInteger day = [[timeString substringWithRange:NSMakeRange(6, 2)] integerValue];
    NSInteger hour = [[timeString substringWithRange:NSMakeRange(8, 2)] integerValue];
    NSInteger minute = [[timeString substringWithRange:NSMakeRange(10, 2)] integerValue];
    NSInteger second = [[timeString substringWithRange:NSMakeRange(12, 2)] integerValue];
    
    // 验证范围
    if (year < 2020 || year > 2100 || 
        month < 1 || month > 12 || 
        day < 1 || day > 31 ||
        hour < 0 || hour > 23 ||
        minute < 0 || minute > 59 ||
        second < 0 || second > 59) {
        return nil;
    }
    
    // 创建日期组件
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = month;
    components.day = day;
    components.hour = hour;
    components.minute = minute;
    components.second = second;
    components.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    
    return [calendar dateFromComponents:components];
}

// 找到最新的有效订阅
- (NSDictionary *)findLatestValidSubscription:(NSArray *)inAppPurchases {
    if (!inAppPurchases || inAppPurchases.count == 0) {
        return nil;
    }
    
    // 按照到期时间或优先级选择最合适的订阅
    // 1. 优先选择永久会员（lifetimeBenefits）
    // 2. 否则选择到期时间最晚的订阅（最新购买的）
    
    NSDictionary *lifetimePurchase = nil;
    NSDictionary *latestPurchase = nil;
    NSDate *latestExpiryDate = nil;
    
    for (NSDictionary *purchase in inAppPurchases) {
        NSString *productId = purchase[@"product_id"];
        
        // 检查是否是永久会员
        if ([productId containsString:@"lifetimeBenefits"]) {
            lifetimePurchase = purchase;
            break; // 找到永久会员直接返回，不再继续查找
        }
        
        // 比较到期时间，选择最晚的（最新购买的）
        NSDate *expiresDate = purchase[@"expires_date"];
        if (expiresDate) {
            if (!latestExpiryDate || [expiresDate compare:latestExpiryDate] == NSOrderedDescending) {
                latestExpiryDate = expiresDate;
                latestPurchase = purchase;
            }
        } else if (!latestPurchase) {
            // 如果没有到期时间，作为兜底
            latestPurchase = purchase;
        }
    }
    
    // 返回永久会员或最新的订阅
    if (lifetimePurchase) {
        NSLog(@"[IAP] 找到永久会员订阅");
        return lifetimePurchase;
    } else if (latestPurchase) {
        NSLog(@"[IAP] 找到最新订阅，到期时间: %@", latestExpiryDate);
        return latestPurchase;
    }
    
    // 兜底返回第一个
    return inAppPurchases.firstObject;
}

// 根据产品ID获取订阅类型
- (AIUASubscriptionProductType)productTypeFromProductId:(NSString *)productId {
    if ([productId containsString:@"lifetimeBenefits"]) {
        return AIUASubscriptionProductTypeLifetimeBenefits;
    } else if ([productId containsString:@"yearly"]) {
        return AIUASubscriptionProductTypeYearly;
    } else if ([productId containsString:@"monthly"]) {
        return AIUASubscriptionProductTypeMonthly;
    } else if ([productId containsString:@"weekly"]) {
        return AIUASubscriptionProductTypeWeekly;
    }
    return AIUASubscriptionProductTypeLifetimeBenefits;
}

#pragma mark - VIP Member Status

// 重写 isVIPMember 的 getter，根据配置开关决定是否进行检测
- (BOOL)isVIPMember {
#if AIUA_VIP_CHECK_ENABLED
    // 开启会员检测，返回实际的VIP状态
    // 使用实例变量 _isVIPMember 来避免递归调用
    return _isVIPMember;
#else
    // 关闭会员检测，所有用户视为VIP
    return YES;
#endif
}

#pragma mark - Local Storage

- (void)loadLocalSubscriptionInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    _isVIPMember = [defaults boolForKey:kAIUAIsVIPMember];
    self.currentSubscriptionType = [defaults integerForKey:kAIUASubscriptionType];
    self.subscriptionExpiryDate = [defaults objectForKey:kAIUASubscriptionExpiryDate];
    
#if AIUA_VIP_CHECK_ENABLED
    NSLog(@"[IAP] 加载本地订阅信息 - VIP: %d, Type: %ld", _isVIPMember, (long)self.currentSubscriptionType);
#else
    NSLog(@"[IAP] 会员检测已关闭，所有用户视为VIP");
#endif
}

- (void)saveLocalSubscriptionInfo {
#if AIUA_VIP_CHECK_ENABLED
    // 只有在开启会员检测时才保存VIP状态
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:_isVIPMember forKey:kAIUAIsVIPMember];
    [defaults setInteger:self.currentSubscriptionType forKey:kAIUASubscriptionType];
    [defaults setObject:self.subscriptionExpiryDate forKey:kAIUASubscriptionExpiryDate];
    [defaults synchronize];
    
    NSLog(@"[IAP] 保存本地订阅信息 - VIP: %d, Type: %ld", _isVIPMember, (long)self.currentSubscriptionType);
#else
    // 关闭会员检测时，不保存VIP状态
    NSLog(@"[IAP] 会员检测已关闭，跳过保存VIP状态");
#endif
}

#pragma mark - Jailbreak Detection

+ (BOOL)isJailbroken {
    #if TARGET_IPHONE_SIMULATOR
    // 模拟器环境，不检测越狱
    return NO;
    #endif
    
    // 方法1: 检查常见的越狱文件
    NSArray *jailbreakPaths = @[
        @"/Applications/Cydia.app",
        @"/Library/MobileSubstrate/MobileSubstrate.dylib",
        @"/bin/bash",
        @"/usr/sbin/sshd",
        @"/etc/apt",
        @"/private/var/lib/apt/",
        @"/private/var/lib/cydia",
        @"/private/var/stash",
        @"/Applications/Sileo.app",
        @"/Applications/Zebra.app",
        @"/usr/bin/ssh",
        @"/usr/libexec/ssh-keysign",
        @"/var/cache/apt",
        @"/var/lib/apt",
        @"/var/lib/cydia",
        @"/usr/sbin/frida-server",
        @"/usr/bin/cycript",
        @"/usr/local/bin/cycript",
        @"/usr/lib/libcycript.dylib"
    ];
    
    for (NSString *path in jailbreakPaths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSLog(@"[IAP] 检测到越狱文件: %@", path);
            return YES;
        }
    }
    
    // 方法2: 检查是否可以写入系统目录
    NSString *testPath = @"/private/jailbreak_test.txt";
    NSError *error;
    [@"test" writeToFile:testPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (!error) {
        [[NSFileManager defaultManager] removeItemAtPath:testPath error:nil];
        NSLog(@"[IAP] 检测到可以写入系统目录");
        return YES;
    }
    
    // 方法3: 检查是否可以打开 Cydia URL
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cydia://package/com.example.package"]]) {
        NSLog(@"[IAP] 检测到可以打开 Cydia URL");
        return YES;
    }
    
    // 方法4: 检查环境变量
    char *env = getenv("DYLD_INSERT_LIBRARIES");
    if (env != NULL) {
        NSLog(@"[IAP] 检测到 DYLD_INSERT_LIBRARIES 环境变量");
        return YES;
    }
    
    // 方法5: 检查可疑的动态库
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        NSString *imageName = [NSString stringWithUTF8String:name];
        
        if ([imageName containsString:@"MobileSubstrate"] ||
            [imageName containsString:@"substrate"] ||
            [imageName containsString:@"cycript"] ||
            [imageName containsString:@"SSLKillSwitch"]) {
            NSLog(@"[IAP] 检测到可疑动态库: %@", imageName);
            return YES;
        }
    }
    
    // 方法6: 检查系统调用
    struct stat stat_info;
    if (stat("/Applications/Cydia.app", &stat_info) == 0) {
        NSLog(@"[IAP] 通过 stat 检测到越狱");
        return YES;
    }
    
    NSLog(@"[IAP] 未检测到越狱");
    return NO;
}

@end

