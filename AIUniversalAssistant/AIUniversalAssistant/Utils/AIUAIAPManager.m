//
//  AIUAIAPManager.m
//  AIUniversalAssistant
//
//  Created by AI Assistant on 2025/11/4.
//

#import "AIUAIAPManager.h"

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
                                 [self productIdentifierForType:AIUASubscriptionProductTypeLifetime],
                                 [self productIdentifierForType:AIUASubscriptionProductTypeYearly],
                                 [self productIdentifierForType:AIUASubscriptionProductTypeMonthly],
                                 [self productIdentifierForType:AIUASubscriptionProductTypeWeekly],
                                 nil];
    
    // 请求产品信息
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
    
    NSLog(@"[IAP] 开始请求产品信息: %@", productIdentifiers);
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
    
    // 检查订阅是否过期
    if (self.subscriptionExpiryDate) {
        NSDate *now = [NSDate date];
        if ([now compare:self.subscriptionExpiryDate] == NSOrderedDescending) {
            // 订阅已过期
            self.isVIPMember = NO;
            [self saveLocalSubscriptionInfo];
            NSLog(@"[IAP] 订阅已过期");
        }
    }
    
    // TODO: 可以添加服务器验证逻辑
    // [self verifyReceiptWithServer];
}

- (void)clearSubscriptionInfo {
    self.isVIPMember = NO;
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
    // 注意：这些Product ID需要在App Store Connect中创建
    // 格式建议: com.yourcompany.appname.productname
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    switch (type) {
        case AIUASubscriptionProductTypeLifetime:
            return [NSString stringWithFormat:@"%@.lifetime", bundleID];
        case AIUASubscriptionProductTypeYearly:
            return [NSString stringWithFormat:@"%@.yearly", bundleID];
        case AIUASubscriptionProductTypeMonthly:
            return [NSString stringWithFormat:@"%@.monthly", bundleID];
        case AIUASubscriptionProductTypeWeekly:
            return [NSString stringWithFormat:@"%@.weekly", bundleID];
        default:
            return @"";
    }
}

- (NSString *)productNameForType:(AIUASubscriptionProductType)type {
    switch (type) {
        case AIUASubscriptionProductTypeLifetime:
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
    NSLog(@"[IAP] 无效产品ID: %@", response.invalidProductIdentifiers);
    
    // 缓存产品信息
    for (SKProduct *product in response.products) {
        self.productsCache[product.productIdentifier] = product;
        NSLog(@"[IAP] 产品: %@ - %@ - %@", product.localizedTitle, product.price, product.priceLocale);
    }
    
    if (self.productsCompletion) {
        if (response.products.count > 0) {
            self.productsCompletion(response.products, nil);
        } else {
            self.productsCompletion(nil, L(@"no_products_available"));
        }
        self.productsCompletion = nil;
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"[IAP] 产品请求失败: %@", error.localizedDescription);
    
    if (self.productsCompletion) {
        self.productsCompletion(nil, error.localizedDescription);
        self.productsCompletion = nil;
    }
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
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
                NSLog(@"[IAP] 购买失败: %@ - %@", transaction.payment.productIdentifier, transaction.error.localizedDescription);
                [self failedTransaction:transaction];
                break;
                
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
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    NSLog(@"[IAP] 恢复购买完成，共恢复 %ld 个", (long)self.restoredPurchasesCount);
    
    if (self.restoreCompletion) {
        if (self.restoredPurchasesCount > 0) {
            self.restoreCompletion(YES, self.restoredPurchasesCount, nil);
        } else {
            self.restoreCompletion(NO, 0, L(@"no_subscription_found"));
        }
        self.restoreCompletion = nil;
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    NSLog(@"[IAP] 恢复购买失败: %@", error.localizedDescription);
    
    if (self.restoreCompletion) {
        self.restoreCompletion(NO, 0, error.localizedDescription);
        self.restoreCompletion = nil;
    }
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
    // 解锁内容
    [self unlockContentForProductIdentifier:transaction.payment.productIdentifier];
    
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
    self.isVIPMember = YES;
    self.currentSubscriptionType = type;
    
    // 设置过期时间
    NSDate *expiryDate = [self calculateExpiryDateForProductType:type];
    self.subscriptionExpiryDate = expiryDate;
    
    // 保存订阅记录
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kAIUAHasSubscriptionHistory];
    [defaults synchronize];
    
    // 保存到本地
    [self saveLocalSubscriptionInfo];
    
    // 发送通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AIUASubscriptionStatusChanged" object:nil];
}

- (AIUASubscriptionProductType)productTypeForIdentifier:(NSString *)identifier {
    if ([identifier containsString:@"lifetime"]) {
        return AIUASubscriptionProductTypeLifetime;
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
        case AIUASubscriptionProductTypeLifetime:
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
    
    // TODO: 将收据发送到服务器进行验证
    // 这是推荐的做法，可以防止越狱设备绕过验证
    NSString *receiptString = [receiptData base64EncodedStringWithOptions:0];
    NSLog(@"[IAP] 收据数据长度: %lu", (unsigned long)receiptString.length);
    
    // 实际项目中应该：
    // 1. 将 receiptString 发送到你的服务器
    // 2. 服务器将收据发送到 Apple 验证服务器
    // 3. Apple 返回验证结果
    // 4. 服务器根据结果决定是否解锁内容
}

#pragma mark - Local Storage

- (void)loadLocalSubscriptionInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    self.isVIPMember = [defaults boolForKey:kAIUAIsVIPMember];
    self.currentSubscriptionType = [defaults integerForKey:kAIUASubscriptionType];
    self.subscriptionExpiryDate = [defaults objectForKey:kAIUASubscriptionExpiryDate];
    
    NSLog(@"[IAP] 加载本地订阅信息 - VIP: %d, Type: %ld", self.isVIPMember, (long)self.currentSubscriptionType);
}

- (void)saveLocalSubscriptionInfo {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:self.isVIPMember forKey:kAIUAIsVIPMember];
    [defaults setInteger:self.currentSubscriptionType forKey:kAIUASubscriptionType];
    [defaults setObject:self.subscriptionExpiryDate forKey:kAIUASubscriptionExpiryDate];
    [defaults synchronize];
    
    NSLog(@"[IAP] 保存本地订阅信息 - VIP: %d, Type: %ld", self.isVIPMember, (long)self.currentSubscriptionType);
}

@end

