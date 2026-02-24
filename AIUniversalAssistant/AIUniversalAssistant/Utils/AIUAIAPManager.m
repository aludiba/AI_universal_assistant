//
//  AIUAIAPManager.m
//  AIUniversalAssistant
//
//  Created by AI Assistant on 2025/11/4.
//

#import "AIUAIAPManager.h"
#import "AIUAWordPackManager.h"
#import "AIUATrialManager.h"
#import "AIUAConfigID.h"
#import "AIUAAlertHelper.h"
#import <sys/stat.h>
#import <mach-o/dyld.h>

// 本地存储Key
static NSString * const kAIUAIsVIPMember = @"kAIUAIsVIPMember";
static NSString * const kAIUASubscriptionType = @"kAIUASubscriptionType";
static NSString * const kAIUASubscriptionExpiryDate = @"kAIUASubscriptionExpiryDate";
static NSString * const kAIUAHasSubscriptionHistory = @"hasSubscriptionHistory";
/// 用户主动清除购买数据后置为 YES，仅在用户点击「恢复购买」且恢复成功时清除，用于避免清除后冷启动/收据验证再次自动恢复
static NSString * const kAIUAUserClearedPurchaseData = @"AIUAUserClearedPurchaseData";

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

// 交易队列观察者引用计数（防止多个页面 start/stop 导致误移除观察者，从而"购买成功但不回调/一直处理中"）
@property (nonatomic, assign) NSInteger paymentObserverRefCount;

// 上次收据验证时间（避免频繁验证收据）
@property (nonatomic, strong) NSDate *lastReceiptVerificationTime;

// 上次自动恢复购买尝试时间（用于网络恢复后重试，避免频繁请求）
@property (nonatomic, strong) NSDate *lastRestoreAttemptDate;

// 本次恢复是否已预约过“网络错误延迟重试”（仅重试一次）
@property (nonatomic, assign) BOOL hasScheduledRestoreRetryForNetworkError;
// 是否处于“冷启动恢复窗口”（仅在指定场景允许自动恢复）
@property (nonatomic, assign) BOOL launchRestoreWindowActive;
// 当前是否为自动恢复流程（用于完成后关闭窗口）
@property (nonatomic, assign) BOOL autoRestoreInProgress;

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
        _paymentObserverRefCount = 0;
        [self loadLocalSubscriptionInfo];
    }
    return self;
}

#pragma mark - Product ID Helpers

- (BOOL)isWordPackProductId:(NSString *)productId {
    if (productId.length == 0) {
        return NO;
    }
    return [productId.lowercaseString containsString:@"wordpack"];
}

- (BOOL)isLifetimeProductId:(NSString *)productId {
    if (productId.length == 0) {
        return NO;
    }
    NSString *lowercaseProductId = productId.lowercaseString;
    return [productId isEqualToString:AIUA_IAP_PRODUCT_LIFETIME] ||
           [lowercaseProductId containsString:@"lifetimebenefits"] ||
           ([lowercaseProductId containsString:@"lifetime"] && ![self isWordPackProductId:productId]);
}

#pragma mark - Public Methods

- (void)startObservingPaymentQueue {
    @synchronized (self) {
        self.paymentObserverRefCount += 1;
        if (self.paymentObserverRefCount == 1) {
            [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
            NSLog(@"[IAP] ✅ 已添加交易队列观察者 (ref=%ld)", (long)self.paymentObserverRefCount);
        } else {
            NSLog(@"[IAP] 已在观察交易队列，增加引用计数 (ref=%ld)", (long)self.paymentObserverRefCount);
        }
    }
}

- (void)stopObservingPaymentQueue {
    @synchronized (self) {
        if (self.paymentObserverRefCount <= 0) {
            // 防御：避免多次 stop 导致 ref 负数
            self.paymentObserverRefCount = 0;
            NSLog(@"[IAP] ⚠️ stopObservingPaymentQueue 被多次调用，忽略移除观察者");
            return;
        }
        self.paymentObserverRefCount -= 1;
        if (self.paymentObserverRefCount == 0) {
            [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
            NSLog(@"[IAP] 已移除交易队列观察者 (ref=0)");
        } else {
            NSLog(@"[IAP] 保留交易队列观察者，仅减少引用计数 (ref=%ld)", (long)self.paymentObserverRefCount);
        }
    }
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

- (void)preloadProducts {
    // 如果已经有缓存的产品，无需重复获取
    if (self.productsCache.count > 0) {
        NSLog(@"[IAP] 预加载：产品已在缓存中，跳过请求");
        return;
    }
    
    // 检查设备是否支持IAP
    if (![SKPaymentQueue canMakePayments]) {
        NSLog(@"[IAP] 预加载：设备不支持IAP");
        return;
    }
    
    // 构建产品ID集合
    NSSet *productIdentifiers = [NSSet setWithObjects:
                                 [self productIdentifierForType:AIUASubscriptionProductTypeLifetimeBenefits],
                                 [self productIdentifierForType:AIUASubscriptionProductTypeYearly],
                                 [self productIdentifierForType:AIUASubscriptionProductTypeMonthly],
                                 [self productIdentifierForType:AIUASubscriptionProductTypeWeekly],
                                 nil];
    
    // 异步请求产品信息（不阻塞启动流程）
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
        request.delegate = self;
        [request start];
        
        NSLog(@"[IAP] 预加载：异步请求产品信息");
    });
}

- (nullable NSArray<SKProduct *> *)getCachedProducts {
    if (self.productsCache.count == 0) {
        return nil;
    }
    return [self.productsCache.allValues copy];
}

- (nullable SKProduct *)getCachedProductForType:(AIUASubscriptionProductType)type {
    NSString *productIdentifier = [self productIdentifierForType:type];
    return self.productsCache[productIdentifier];
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
    self.lastRestoreAttemptDate = [NSDate date];
    self.hasScheduledRestoreRetryForNetworkError = NO; // 允许本次恢复在网络错误时延迟重试一次
    
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    
    NSLog(@"[IAP] 开始恢复购买");
}

- (void)beginLaunchRestoreWindow {
    // 用户若曾主动清除购买数据，不再开启自动恢复窗口，避免清除后随便操作又恢复
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kAIUAUserClearedPurchaseData]) {
        NSLog(@"[IAP] 检测到用户曾清除购买数据，不开启冷启动恢复窗口");
        return;
    }
    self.launchRestoreWindowActive = YES;
    self.autoRestoreInProgress = NO;
    self.lastRestoreAttemptDate = nil;
    NSLog(@"[IAP] 已开启冷启动恢复窗口");
}

- (void)retryRestoreIfNoSubscriptionWithCompletion:(AIUAIAPRestoreCompletion)completion {
    // 非冷启动恢复窗口内，不进行自动恢复（避免进入会员页等场景误恢复）
    if (!self.launchRestoreWindowActive) {
        return;
    }
    if (self.isVIPMember || self.subscriptionExpiryDate) {
        // 已有订阅则关闭窗口
        self.launchRestoreWindowActive = NO;
        return;
    }
    NSTimeInterval since = 999;
    if (self.lastRestoreAttemptDate) {
        since = [[NSDate date] timeIntervalSinceDate:self.lastRestoreAttemptDate];
    }
    if (since < 30.0) {
        return;
    }
    self.autoRestoreInProgress = YES;
    [self restorePurchasesWithCompletion:completion];
}

- (void)checkSubscriptionStatus {
    [self loadLocalSubscriptionInfo];
    
    NSDate *now = [NSDate date];
    BOOL hasNoLocalSubscription = (!self.subscriptionExpiryDate && !_isVIPMember);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL userClearedPurchase = [defaults boolForKey:kAIUAUserClearedPurchaseData];
    // 用户曾清除购买时，不允许通过收据重新填充订阅，避免「清除后随便操作又恢复」
    if (hasNoLocalSubscription && userClearedPurchase) {
        NSLog(@"[IAP] 用户曾清除购买数据，跳过收据验证，不自动恢复");
        if (self.subscriptionExpiryDate) {
            if ([now compare:self.subscriptionExpiryDate] == NSOrderedDescending) {
                _isVIPMember = NO;
                [self saveLocalSubscriptionInfo];
            }
        }
        return;
    }
    
    // 检查是否需要重新验证收据（距离上次验证不到 30 秒则跳过）
    if (self.lastReceiptVerificationTime) {
        NSTimeInterval timeSinceLastVerification = [now timeIntervalSinceDate:self.lastReceiptVerificationTime];
        if (timeSinceLastVerification < 30.0) {
            NSLog(@"[IAP] ⏭️ 距离上次收据验证仅 %.1f 秒，跳过本次验证", timeSinceLastVerification);
            if (self.subscriptionExpiryDate) {
                if ([now compare:self.subscriptionExpiryDate] == NSOrderedDescending) {
                    _isVIPMember = NO;
                    [self saveLocalSubscriptionInfo];
                }
            }
            return;
        }
    }
    
    BOOL isValid = [self verifyReceiptLocally];
    self.lastReceiptVerificationTime = now; // 记录验证时间
    
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

- (void)clearAllPurchaseData {
    NSLog(@"[IAP] ⚠️ 开始清除所有购买数据...");
    
    // 1. 清除订阅信息
    [self clearSubscriptionInfo];
    
    // 2. 清除字数包数据
    [[AIUAWordPackManager sharedManager] clearAllWordPackData];
    
    // 3. 重置试用次数
    [[AIUATrialManager sharedManager] resetTrialCount];
    
    // 4. 清除收据验证时间缓存
    self.lastReceiptVerificationTime = nil;
    // 5. 关闭冷启动恢复窗口
    self.launchRestoreWindowActive = NO;
    self.autoRestoreInProgress = NO;
    // 6. 标记「用户已清除购买」，后续不根据收据自动恢复，直到用户点击恢复购买且成功
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kAIUAUserClearedPurchaseData];
    [defaults synchronize];
    
    // 7. 发送通知，更新UI
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AIUASubscriptionStatusChanged"
                                                        object:nil
                                                      userInfo:nil];
    
    NSLog(@"[IAP] ✓ 所有购买数据已清除");
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
    if (self.autoRestoreInProgress) {
        self.autoRestoreInProgress = NO;
        self.launchRestoreWindowActive = NO;
    }
    // 用户主动点击恢复且成功，清除「用户曾清除购买」标记，允许后续冷启动时再根据收据恢复
    if (self.restoredPurchasesCount > 0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:kAIUAUserClearedPurchaseData];
        [defaults synchronize];
    }
    
    // 恢复完成后，从收据中重新验证订阅状态，确保使用实际的到期时间
    [self checkSubscriptionStatus];
    
    // 通知 UI 刷新（首次启动自动恢复时，设置页等需立即更新）
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AIUASubscriptionStatusChanged" object:nil];
    });
    
    // 恢复订阅时，同时从 iCloud 同步字数包数据
    AIUAWordPackManager *wordPackManager = [AIUAWordPackManager sharedManager];
    if ([wordPackManager isiCloudAvailable]) {
        NSLog(@"[IAP] 恢复订阅完成，启用 iCloud 同步并同步字数包数据");
        // 确保 iCloud 同步已启用
        [wordPackManager enableiCloudSync];
        // 从 iCloud 同步字数包数据（包括购买记录、VIP赠送字数等）
        [wordPackManager syncFromiCloud];
    } else {
        NSLog(@"[IAP] iCloud 不可用，跳过字数包数据同步");
    }
    
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
    NSString *errorMessage = error.localizedDescription ?: @"";
    NSLog(@"[IAP] 恢复购买失败: %@", errorMessage);
    
    BOOL isNetworkError = ([errorMessage containsString:@"断开"] ||
                           [errorMessage containsString:@"互联网"] ||
                           [errorMessage containsString:@"网络"] ||
                           [errorMessage containsString:@"connection"] ||
                           [errorMessage containsString:@"Connection"] ||
                           error.code == NSURLErrorNotConnectedToInternet ||
                           error.code == NSURLErrorNetworkConnectionLost);
    
    AIUAIAPRestoreCompletion completion = self.restoreCompletion;
    self.restoreCompletion = nil;
    
    if (isNetworkError && !self.hasScheduledRestoreRetryForNetworkError && !self.isVIPMember && !self.subscriptionExpiryDate) {
        self.hasScheduledRestoreRetryForNetworkError = YES;
        __weak typeof(self) wself = self;
        NSLog(@"[IAP] 恢复因网络失败，5 秒后自动重试一次（用户选择网络后可能成功）");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(wself) sself = wself;
            if (!sself || sself.isVIPMember || sself.subscriptionExpiryDate) {
                if (completion) completion(NO, 0, errorMessage);
                return;
            }
            NSLog(@"[IAP] 执行网络错误后的延迟恢复...");
            sself.autoRestoreInProgress = YES;
            [sself restorePurchasesWithCompletion:^(BOOL success, NSInteger restoredCount, NSString * _Nullable errMsg) {
                if (completion) completion(success, restoredCount, errMsg);
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"AIUASubscriptionStatusChanged" object:nil];
                    });
                }
            }];
        });
    } else {
        if (self.autoRestoreInProgress) {
            // 自动恢复在非网络可重试错误下结束，关闭窗口避免误触发
            self.autoRestoreInProgress = NO;
            self.launchRestoreWindowActive = NO;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [AIUAAlertHelper showDebugErrorAlert:errorMessage context:@"恢复购买失败"];
            if (completion) completion(NO, 0, errorMessage);
        });
    }
}

#pragma mark - Transaction Processing

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSString *productIdentifier = transaction.payment.productIdentifier;
    BOOL isWordPack = [self isWordPackProductId:productIdentifier];
    
    // 用户曾清除购买数据时，不根据收据或队列中的订阅交易恢复会员（只处理本次发起的字数包购买）
    BOOL userClearedPurchase = [[NSUserDefaults standardUserDefaults] boolForKey:kAIUAUserClearedPurchaseData];
    if (!isWordPack && userClearedPurchase) {
        NSLog(@"[IAP] 用户已清除购买数据，忽略队列中的订阅交易 %@，不恢复会员", productIdentifier);
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        return;
    }
    
    self.lastReceiptVerificationTime = nil;
    [self verifyReceipt:transaction];
    
    if (!isWordPack) {
        [self unlockContentForProductIdentifier:productIdentifier];
    } else {
        NSLog(@"[IAP] 字数包购买完成: %@，不修改会员到期时间", productIdentifier);
        // 仅刷新字数包相关展示（赠送字数等），不发送订阅状态变化
        [[AIUAWordPackManager sharedManager] refreshVIPGiftedWords];
    }
    
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
    
    BOOL isWordPack = [self isWordPackProductId:productIdentifier];
    BOOL userClearedPurchase = [[NSUserDefaults standardUserDefaults] boolForKey:kAIUAUserClearedPurchaseData];
    if (!isWordPack && userClearedPurchase) {
        NSLog(@"[IAP] 用户已清除购买数据，忽略恢复的订阅交易 %@，不恢复会员", productIdentifier);
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        return;
    }
    
    if (isWordPack) {
        NSLog(@"[IAP] 恢复字数包产品: %@，消耗型产品不重复发放", productIdentifier);
    } else {
        BOOL isLifetimeProduct = [self isLifetimeProductId:productIdentifier];
        // 若当前已是永久会员，则只接受永久会员交易，有限期交易不覆盖
        BOOL isCurrentlyLifetime = NO;
        if (self.subscriptionExpiryDate) {
            NSTimeInterval timeInterval = [self.subscriptionExpiryDate timeIntervalSinceNow];
            isCurrentlyLifetime = (timeInterval > 50 * 365 * 24 * 60 * 60);
        }
        
        if (isCurrentlyLifetime && !isLifetimeProduct) {
            NSLog(@"[IAP] 当前已是永久会员，跳过有限期交易 %@，保持永久会员状态", productIdentifier);
        } else {
            [self unlockContentForProductIdentifier:productIdentifier];
            self.restoredPurchasesCount++;
        }
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

#pragma mark - Content Unlocking

- (void)unlockContentForProductIdentifier:(NSString *)productIdentifier {
    NSLog(@"[IAP] 解锁内容: %@", productIdentifier);
    
    // 确定产品类型
    AIUASubscriptionProductType type = [self productTypeForIdentifier:productIdentifier];
    
    // 若当前已是永久会员（到期>50年），不得被有限期订阅覆盖（恢复时可能先处理年付再处理永久）
    BOOL isCurrentlyLifetime = NO;
    if (self.subscriptionExpiryDate) {
        NSTimeInterval interval = [self.subscriptionExpiryDate timeIntervalSinceNow];
        isCurrentlyLifetime = (interval > 50 * 365 * 24 * 60 * 60);
    }
    if (isCurrentlyLifetime && type != AIUASubscriptionProductTypeLifetimeBenefits) {
        NSLog(@"[IAP] 当前已是永久会员，跳过有限期订阅 %@，保持永久状态", productIdentifier);
        [self saveLocalSubscriptionInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AIUASubscriptionStatusChanged" object:nil];
        return;
    }
    
    // 设置会员状态
    _isVIPMember = YES;
    self.currentSubscriptionType = type;
    
    // 计算过期时间（支持累加）
    NSDate *expiryDate = [self calculateExpiryDateForProductType:type withAccumulation:YES];
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

    // 关键修复：不依赖"字数包页面是否已打开/WordPackManager是否已初始化"
    // 购买成功后立刻触发一次赠送字数入账，确保字数包页面能立刻显示 50 万字
    [[AIUAWordPackManager sharedManager] refreshVIPGiftedWords];
}

- (AIUASubscriptionProductType)productTypeForIdentifier:(NSString *)identifier {
    if ([self isLifetimeProductId:identifier]) {
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
    return [self calculateExpiryDateForProductType:type withAccumulation:NO];
}

- (NSDate *)calculateExpiryDateForProductType:(AIUASubscriptionProductType)type withAccumulation:(BOOL)accumulate {
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    
    // 永久会员：不累加，直接设置为100年后
    // 如果已经是永久会员（到期时间在50年后），则保持不变
    if (type == AIUASubscriptionProductTypeLifetimeBenefits) {
        if (self.subscriptionExpiryDate) {
            // 检查是否已经是永久会员（到期时间在50年后）
            NSTimeInterval timeInterval = [self.subscriptionExpiryDate timeIntervalSinceNow];
            if (timeInterval > 50 * 365 * 24 * 60 * 60) {
                NSLog(@"[IAP] 用户已经是永久会员，保持现有到期时间: %@", self.subscriptionExpiryDate);
                return self.subscriptionExpiryDate;
            }
        }
        components.year = 100;
        NSDate *lifetimeExpiry = [calendar dateByAddingComponents:components toDate:now options:0];
        NSLog(@"[IAP] 设置永久会员，到期时间: %@", lifetimeExpiry);
        return lifetimeExpiry;
    }
    
    // 其他订阅类型：计算订阅时长
    switch (type) {
        case AIUASubscriptionProductTypeYearly:
            components.year = 1;
            break;
        case AIUASubscriptionProductTypeMonthly:
            components.month = 1;
            break;
        case AIUASubscriptionProductTypeWeekly:
            components.day = 7;
            break;
        default:
            components.day = 7;
            break;
    }
    
    // 如果需要累加，且已有未过期的订阅，则从现有到期时间开始累加
    if (accumulate && self.subscriptionExpiryDate) {
        NSDate *existingExpiry = self.subscriptionExpiryDate;
        NSDate *baseDate = existingExpiry;
        
        // 如果现有订阅已过期，则从当前时间开始计算
        if ([now compare:existingExpiry] == NSOrderedDescending) {
            baseDate = now;
            NSLog(@"[IAP] 现有订阅已过期，从当前时间开始计算新订阅");
        } else {
            NSLog(@"[IAP] 现有订阅未过期（到期: %@），从现有到期时间累加", existingExpiry);
        }
        
        NSDate *newExpiryDate = [calendar dateByAddingComponents:components toDate:baseDate options:0];
        NSLog(@"[IAP] 订阅累加: 基础时间 %@ + 订阅时长 = 新到期时间 %@", baseDate, newExpiryDate);
        return newExpiryDate;
    }
    
    // 不需要累加或没有现有订阅，从当前时间开始计算
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
        NSLog(@"[IAP] ❌ 收据URL为空");
        return NO;
    }
    
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    if (!receiptData || receiptData.length == 0) {
        NSLog(@"[IAP] ❌ 收据数据为空（可能是重装后收据未生成）");
        NSLog(@"[IAP] 💡 解决方案：请在App中点击「恢复购买」按钮，系统会自动刷新收据并恢复订阅");
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
        
        // 检查当前是否已是永久会员（到期时间>50年），如果是则不再从收据中覆盖
        BOOL isCurrentlyLifetime = NO;
        if (self.subscriptionExpiryDate) {
            NSTimeInterval timeInterval = [self.subscriptionExpiryDate timeIntervalSinceNow];
            isCurrentlyLifetime = (timeInterval > 50 * 365 * 24 * 60 * 60);
        }
        
        if (isCurrentlyLifetime) {
            NSLog(@"[IAP] 当前已是永久会员，跳过收据解析，保持永久会员状态");
            return YES;
        }
        
        // 若本地已有未过期的订阅到期时间，通常不以收据覆盖；但如果不是永久会员且距上次验证超过7天，仍需刷新以同步最新订阅
        NSDate *now = [NSDate date];
        if (self.subscriptionExpiryDate && [now compare:self.subscriptionExpiryDate] == NSOrderedAscending) {
            BOOL isLocalLifetime = ([self.subscriptionExpiryDate timeIntervalSinceNow] > 50 * 365 * 24 * 60 * 60);
            // 永久会员或近期刚验证过的订阅：保留本地，跳过覆盖
            if (isLocalLifetime || (self.lastReceiptVerificationTime && [now timeIntervalSinceDate:self.lastReceiptVerificationTime] < 7 * 24 * 60 * 60)) {
                NSLog(@"[IAP] 本地订阅未过期（到期: %@），%@，跳过从收据覆盖", self.subscriptionExpiryDate, isLocalLifetime ? @"永久会员" : @"近期刚验证");
                return YES;
            }
            // 非永久且距上次验证超过7天：仍走收据刷新，防止用户在其它设备订阅/升级后本地未同步
            NSLog(@"[IAP] 本地订阅未过期但距上次验证超过7天，从收据刷新最新状态");
        }
        
        // 提取订阅信息
        NSArray *inAppPurchases = receiptInfo[@"in_app"];
        NSLog(@"[IAP] 收据中共有 %lu 个购买项", (unsigned long)(inAppPurchases ? inAppPurchases.count : 0));
        
        if (inAppPurchases && inAppPurchases.count > 0) {
            // 优先：若收据中任意一项为永久会员，直接按永久处理，避免被有限期覆盖（删除重装恢复后永久会员应显示永久有效）
            for (NSDictionary *purchase in inAppPurchases) {
                NSString *pid = purchase[@"product_id"];
                if (!pid || [self isWordPackProductId:pid]) continue;
                BOOL isLifetime = [self isLifetimeProductId:pid];
                if (isLifetime) {
                    _isVIPMember = YES;
                    self.currentSubscriptionType = AIUASubscriptionProductTypeLifetimeBenefits;
                    NSDate *now = [NSDate date];
                    NSCalendar *calendar = [NSCalendar currentCalendar];
                    NSDateComponents *components = [[NSDateComponents alloc] init];
                    components.year = 100;
                    self.subscriptionExpiryDate = [calendar dateByAddingComponents:components toDate:now options:0];
                    NSLog(@"[IAP] 收据中发现永久会员产品 %@，强制按永久有效处理", pid);
                    [self saveLocalSubscriptionInfo];
                    return YES;
                }
            }
            
            // 找到最新的有效订阅
            NSDictionary *latestSubscription = [self findLatestValidSubscription:inAppPurchases];
            
            if (latestSubscription) {
                NSString *productId = latestSubscription[@"product_id"];
                // 字数包与会员周期无关，不得用收据中的字数包项覆盖订阅状态
                if ([self isWordPackProductId:productId]) {
                    NSLog(@"[IAP] 收据中该项为字数包，跳过订阅覆盖: %@", productId);
                } else {
                // 二次确认：若收据中任一项为永久会员（可能首轮未匹配到），优先按永久处理，避免恢复后误显示过期时间
                for (NSDictionary *p in inAppPurchases) {
                    NSString *pid = p[@"product_id"];
                    if (pid && ![self isWordPackProductId:pid] && [self isLifetimeProductId:pid]) {
                        _isVIPMember = YES;
                        self.currentSubscriptionType = AIUASubscriptionProductTypeLifetimeBenefits;
                        NSDate *now = [NSDate date];
                        NSCalendar *calendar = [NSCalendar currentCalendar];
                        NSDateComponents *components = [[NSDateComponents alloc] init];
                        components.year = 100;
                        self.subscriptionExpiryDate = [calendar dateByAddingComponents:components toDate:now options:0];
                        NSLog(@"[IAP] 收据二次扫描发现永久会员 %@，按永久有效处理", pid);
                        [self saveLocalSubscriptionInfo];
                        return YES;
                    }
                }
                NSDate *expiresDate = latestSubscription[@"expires_date"];
                
                NSLog(@"[IAP] 从收据中提取订阅信息 - 产品: %@, 到期: %@", productId, expiresDate);
                
                // 若收据中的到期时间超过 20 年，视为有效永久会员（兜底，防止产品ID未识别为 lifetime）
                NSDate *now = [NSDate date];
                if (expiresDate && [expiresDate timeIntervalSinceDate:now] > 20 * 365 * 24 * 60 * 60) {
                    _isVIPMember = YES;
                    self.currentSubscriptionType = AIUASubscriptionProductTypeLifetimeBenefits;
                    NSCalendar *calendar = [NSCalendar currentCalendar];
                    NSDateComponents *components = [[NSDateComponents alloc] init];
                    components.year = 100;
                    self.subscriptionExpiryDate = [calendar dateByAddingComponents:components toDate:now options:0];
                    NSLog(@"[IAP] 收据到期时间超过20年，视为永久会员并设置为永久有效");
                    [self saveLocalSubscriptionInfo];
                    return YES;
                }
                
                // 根据 product_id 确定订阅类型
                AIUASubscriptionProductType productType = [self productTypeFromProductId:productId];
                
                // 如果是永久会员，直接设置为永久，忽略收据中的到期时间（避免被错误的有限期覆盖）
                if (productType == AIUASubscriptionProductTypeLifetimeBenefits) {
                    _isVIPMember = YES;
                    self.currentSubscriptionType = productType;
                    // 永久会员统一设置为100年后，不使用收据中的 expiresDate
                    NSDate *now = [NSDate date];
                    NSCalendar *calendar = [NSCalendar currentCalendar];
                    NSDateComponents *components = [[NSDateComponents alloc] init];
                    components.year = 100;
                    self.subscriptionExpiryDate = [calendar dateByAddingComponents:components toDate:now options:0];
                    NSLog(@"[IAP] 从收据中识别到永久会员（产品: %@），设置为永久有效（忽略收据到期时间）", productId);
                    [self saveLocalSubscriptionInfo];
                    return YES;
                }
                
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
                    // 非永久会员但没有到期时间，从当前时间计算
                    _isVIPMember = YES;
                    self.subscriptionExpiryDate = [self calculateExpiryDateForProductType:productType];
                    NSLog(@"[IAP] 订阅无到期时间，从当前时间计算");
                }
                
                // 保存更新后的信息
                [self saveLocalSubscriptionInfo];
                }
            } else {
                NSLog(@"[IAP] ⚠️ 收据中有 %lu 个购买项，但未找到有效订阅（可能都是字数包或已过期订阅）", (unsigned long)inAppPurchases.count);
            }
        } else {
            NSLog(@"[IAP] ⚠️ 收据解析成功，但没有找到任何购买项（可能是新设备或收据未同步）");
            NSLog(@"[IAP] 💡 建议：点击「恢复购买」按钮手动同步订阅信息");
        }
    } else {
        NSLog(@"[IAP] ❌ 收据解析失败，无法从收据中提取订阅信息");
    }
    
    NSLog(@"[IAP] 本地收据验证完成");
    
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
    NSMutableSet *foundProductIds = [NSMutableSet set]; // 避免重复添加相同产品
    
    const uint8_t *bytes = [receiptData bytes];
    NSUInteger length = receiptData.length;
    
    BOOL bundleIdFound = NO; // 标记是否已找到 Bundle ID
    
    // 尝试查找Bundle ID和购买记录
    // Bundle ID 在收据中的字段类型为 2
    // In-App Purchase 在收据中的字段类型为 17
    
    for (NSUInteger i = 0; i < length - 20; i++) {
        // 查找 Bundle ID 模式（只查找一次）
        if (!bundleIdFound && i + 100 < length) {
            NSString *bundleId = [self extractBundleIdFromReceipt:receiptData atOffset:i];
            if (bundleId && bundleId.length > 0) {
                result[@"bundle_id"] = bundleId;
                NSLog(@"[IAP] ✓ 从收据中提取 Bundle ID: %@", bundleId);
                bundleIdFound = YES; // 找到后不再重复查找
            }
        }
        
        // 查找产品ID模式（简化查找）
        NSString *productId = [self extractProductIdFromReceipt:receiptData atOffset:i];
        if (productId && [productId containsString:@"."] && ![foundProductIds containsObject:productId]) {
            // 可能是一个有效的产品ID，且未重复添加
            NSMutableDictionary *purchase = [NSMutableDictionary dictionary];
            purchase[@"product_id"] = productId;
            
            // 尝试提取过期时间（对于自动续订订阅）
            NSDate *expiresDate = [self extractExpiresDateFromReceipt:receiptData nearOffset:i];
            if (expiresDate) {
                purchase[@"expires_date"] = expiresDate;
            }
            
            [inAppPurchases addObject:purchase];
            [foundProductIds addObject:productId]; // 标记为已找到
            NSLog(@"[IAP] ✓ 从收据中提取产品: %@", productId);
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
    
    // 查找可能的产品ID（收据中可能为 lifetimeBenefits 或 LifetimeBenefits）
    NSArray *productTypes = @[@"lifetimeBenefits", @"LifetimeBenefits", @"yearly", @"monthly", @"weekly"];
    
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
        
        // 字数包为消耗型产品，与会员周期无关，不参与“最新订阅”选择
        if ([self isWordPackProductId:productId]) {
            continue;
        }
        
        // 检查是否是永久会员（兼容配置ID、lifetimeBenefits 及含 lifetime 的产品ID，大小写不敏感）
        if (productId && ![self isWordPackProductId:productId]) {
            if ([self isLifetimeProductId:productId]) {
                lifetimePurchase = purchase;
                break; // 找到永久会员直接返回，不再继续查找
            }
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
    
    // 无有效订阅时不兜底返回 firstObject，避免把字数包等非订阅项当作订阅
    return nil;
}

// 根据产品ID获取订阅类型
- (AIUASubscriptionProductType)productTypeFromProductId:(NSString *)productId {
    if ([self isLifetimeProductId:productId]) {
        return AIUASubscriptionProductTypeLifetimeBenefits;
    } else if ([productId containsString:@"yearly"]) {
        return AIUASubscriptionProductTypeYearly;
    } else if ([productId containsString:@"monthly"]) {
        return AIUASubscriptionProductTypeMonthly;
    } else if ([productId containsString:@"weekly"]) {
        return AIUASubscriptionProductTypeWeekly;
    }
    // 未知产品ID不应默认为永久会员，记录日志后返回周会员（最保守的订阅类型）
    NSLog(@"[IAP] ⚠️ 未识别的产品ID: %@，默认按周会员处理", productId);
    return AIUASubscriptionProductTypeWeekly;
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
    if (!self.subscriptionExpiryDate && !_isVIPMember) {
        NSLog(@"[IAP] 本地无订阅信息（可能是首次安装或删除重装），将从收据恢复");
    } else {
        NSLog(@"[IAP] 加载本地订阅信息 - VIP: %d, Type: %ld, 到期: %@", _isVIPMember, (long)self.currentSubscriptionType, self.subscriptionExpiryDate);
    }
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

