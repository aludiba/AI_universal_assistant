//
//  AIUAWordPackManager.m
//  AIUniversalAssistant
//
//  字数包管理器实现
//

#import "AIUAWordPackManager.h"
#import "AIUAIAPManager.h"
#import "AIUAMacros.h"
#import <UIKit/UIKit.h>

// 通知名称
NSString * const AIUAWordPackPurchasedNotification = @"AIUAWordPackPurchasedNotification";
NSString * const AIUAWordConsumedNotification = @"AIUAWordConsumedNotification";

// 本地存储Key
static NSString * const kAIUAVIPGiftedWords = @"kAIUAVIPGiftedWords";
static NSString * const kAIUAVIPGiftedWordsLastRefreshDate = @"kAIUAVIPGiftedWordsLastRefreshDate"; // 上次刷新日期
static NSString * const kAIUAPurchasedWords = @"kAIUAPurchasedWords";
static NSString * const kAIUAConsumedWords = @"kAIUAConsumedWords";
static NSString * const kAIUAWordPackPurchases = @"kAIUAWordPackPurchases";

// iCloud Keys
static NSString * const kAIUAiCloudWordPackData = @"AIUAWordPackData";

// VIP赠送字数常量
static const NSInteger kVIPDailyGiftWords = 500000; // 每天赠送50万字

// 字数包产品ID
static NSString * const kProductIDWordPack500K = @"com.yourcompany.aiassistant.wordpack.500k";
static NSString * const kProductIDWordPack2M = @"com.yourcompany.aiassistant.wordpack.2m";
static NSString * const kProductIDWordPack6M = @"com.yourcompany.aiassistant.wordpack.6m";

@interface AIUAWordPackManager ()

@property (nonatomic, strong) NSUbiquitousKeyValueStore *iCloudStore;
@property (nonatomic, assign) BOOL iCloudSyncEnabled;

@end

@implementation AIUAWordPackManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
    static AIUAWordPackManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AIUAWordPackManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _iCloudStore = [NSUbiquitousKeyValueStore defaultStore];
        _iCloudSyncEnabled = NO;
        
        // 监听VIP状态变化
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(subscriptionStatusChanged:)
                                                     name:@"AIUASubscriptionStatusChanged"
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 订阅状态监听

- (void)subscriptionStatusChanged:(NSNotification *)notification {
    NSLog(@"[WordPack] VIP订阅状态变化，刷新赠送字数");
    [self refreshVIPGiftedWords];
}

#pragma mark - 字数查询

- (NSInteger)vipGiftedWords {
    // 检查VIP状态
    BOOL isVIP = [[AIUAIAPManager sharedManager] isVIPMember];
    if (!isVIP) {
        NSLog(@"[WordPack] 用户不是VIP，每日赠送字数为0");
        return 0;
    }
    
    // 检查是否需要刷新（新的一天）
    [self checkAndRefreshDailyGift];
    
    NSInteger giftedWords = [[NSUserDefaults standardUserDefaults] integerForKey:kAIUAVIPGiftedWords];
    NSLog(@"[WordPack] VIP今日剩余赠送字数: %ld", (long)giftedWords);
    return MAX(0, giftedWords);
}

// 检查并刷新每日赠送
- (void)checkAndRefreshDailyGift {
    NSDate *lastRefreshDate = [[NSUserDefaults standardUserDefaults] objectForKey:kAIUAVIPGiftedWordsLastRefreshDate];
    NSDate *now = [NSDate date];
    
    // 检查是否是新的一天
    if (![self isSameDay:lastRefreshDate date2:now]) {
        NSLog(@"[WordPack] 新的一天，刷新VIP每日赠送字数为 %ld", (long)kVIPDailyGiftWords);
        
        // 重置为50万字
        [[NSUserDefaults standardUserDefaults] setInteger:kVIPDailyGiftWords forKey:kAIUAVIPGiftedWords];
        [[NSUserDefaults standardUserDefaults] setObject:now forKey:kAIUAVIPGiftedWordsLastRefreshDate];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // 同步到iCloud
        if (self.iCloudSyncEnabled) {
            [self syncToiCloud];
        }
    }
}

// 判断两个日期是否是同一天
- (BOOL)isSameDay:(NSDate *)date1 date2:(NSDate *)date2 {
    if (!date1 || !date2) {
        return NO;
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components1 = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                 fromDate:date1];
    NSDateComponents *components2 = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                 fromDate:date2];
    
    return components1.year == components2.year &&
           components1.month == components2.month &&
           components1.day == components2.day;
}

- (NSInteger)purchasedWords {
    // 遍历所有购买记录，计算未过期的字数
    NSArray *purchases = [[NSUserDefaults standardUserDefaults] objectForKey:kAIUAWordPackPurchases];
    if (!purchases) {
        return 0;
    }
    
    NSInteger totalWords = 0;
    NSDate *now = [NSDate date];
    
    for (NSDictionary *purchase in purchases) {
        NSDate *expiryDate = purchase[@"expiryDate"];
        if (expiryDate && [now compare:expiryDate] == NSOrderedAscending) {
            // 未过期
            NSInteger remainingWords = [purchase[@"remainingWords"] integerValue];
            totalWords += remainingWords;
        }
    }
    
    NSLog(@"[WordPack] 购买字数（未过期）: %ld", (long)totalWords);
    return totalWords;
}

- (NSInteger)totalAvailableWords {
    NSInteger total = [self vipGiftedWords] + [self purchasedWords];
    NSLog(@"[WordPack] 总可用字数: %ld", (long)total);
    return total;
}

- (NSInteger)consumedWords {
    NSInteger consumed = [[NSUserDefaults standardUserDefaults] integerForKey:kAIUAConsumedWords];
    return consumed;
}

#pragma mark - 字数包购买

- (void)purchaseWordPack:(AIUAWordPackType)type
              completion:(void (^)(BOOL, NSError * _Nullable))completion {
    NSLog(@"[WordPack] 开始购买字数包，类型: %lu", (unsigned long)type);
    
    NSString *productID = [self productIDForPackType:type];
    NSInteger words = [self wordsForPackType:type];
    
    // 调用IAP管理器购买消耗型产品（字数包）
    // 注意：AIUAIAPManager的completion参数是(BOOL success, NSString *errorMessage)
    [[AIUAIAPManager sharedManager] purchaseConsumableProduct:productID completion:^(BOOL success, NSString * _Nullable errorMessage) {
        if (success) {
            NSLog(@"[WordPack] 购买成功，添加 %ld 字", (long)words);
            
            // 添加购买记录
            [self addPurchaseRecord:words forProductID:productID];
            
            // 同步到iCloud
            if (self.iCloudSyncEnabled) {
                [self syncToiCloud];
            }
            
            // 发送通知
            [[NSNotificationCenter defaultCenter] postNotificationName:AIUAWordPackPurchasedNotification
                                                                object:nil
                                                              userInfo:@{@"words": @(words)}];
            
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(YES, nil);
                });
            }
        } else {
            NSLog(@"[WordPack] 购买失败: %@", errorMessage);
            
            // 将NSString错误消息转换为NSError
            NSError *error = nil;
            if (errorMessage) {
                error = [NSError errorWithDomain:@"AIUAWordPackManager"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
            }
            
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, error);
                });
            }
        }
    }];
}

- (void)addPurchaseRecord:(NSInteger)words forProductID:(NSString *)productID {
    NSMutableArray *purchases = [[[NSUserDefaults standardUserDefaults] objectForKey:kAIUAWordPackPurchases] mutableCopy];
    if (!purchases) {
        purchases = [NSMutableArray array];
    }
    
    // 创建购买记录
    NSDate *now = [NSDate date];
    NSDate *expiryDate = [now dateByAddingTimeInterval:90 * 24 * 60 * 60]; // 90天后过期
    
    NSDictionary *purchase = @{
        @"productID": productID,
        @"words": @(words),
        @"remainingWords": @(words),
        @"purchaseDate": now,
        @"expiryDate": expiryDate
    };
    
    [purchases addObject:purchase];
    
    // 保存
    [[NSUserDefaults standardUserDefaults] setObject:purchases forKey:kAIUAWordPackPurchases];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSLog(@"[WordPack] 购买记录已保存: %@ 字，过期时间: %@", @(words), expiryDate);
}

- (NSInteger)wordsForPackType:(AIUAWordPackType)type {
    switch (type) {
        case AIUAWordPackType500K:
            return 500000;
        case AIUAWordPackType2M:
            return 2000000;
        case AIUAWordPackType6M:
            return 6000000;
    }
}

- (NSString *)priceForPackType:(AIUAWordPackType)type {
    switch (type) {
        case AIUAWordPackType500K:
            return @"6";
        case AIUAWordPackType2M:
            return @"18";
        case AIUAWordPackType6M:
            return @"38";
    }
}

- (NSString *)productIDForPackType:(AIUAWordPackType)type {
    switch (type) {
        case AIUAWordPackType500K:
            return kProductIDWordPack500K;
        case AIUAWordPackType2M:
            return kProductIDWordPack2M;
        case AIUAWordPackType6M:
            return kProductIDWordPack6M;
    }
}

#pragma mark - VIP赠送

- (void)refreshVIPGiftedWords {
    BOOL isVIP = [[AIUAIAPManager sharedManager] isVIPMember];
    
    if (isVIP) {
        NSLog(@"[WordPack] 检测到VIP用户，检查每日赠送字数");
        
        // 获取上次刷新日期
        NSDate *lastRefreshDate = [[NSUserDefaults standardUserDefaults] objectForKey:kAIUAVIPGiftedWordsLastRefreshDate];
        NSDate *now = [NSDate date];
        
        // 如果是新的一天或首次使用，则刷新为50万字
        if (![self isSameDay:lastRefreshDate date2:now]) {
            NSLog(@"[WordPack] 新的一天，重置VIP每日赠送字数为 %ld", (long)kVIPDailyGiftWords);
            [[NSUserDefaults standardUserDefaults] setInteger:kVIPDailyGiftWords forKey:kAIUAVIPGiftedWords];
            [[NSUserDefaults standardUserDefaults] setObject:now forKey:kAIUAVIPGiftedWordsLastRefreshDate];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            // 同步到iCloud
            if (self.iCloudSyncEnabled) {
                [self syncToiCloud];
            }
        } else {
            NSInteger currentWords = [[NSUserDefaults standardUserDefaults] integerForKey:kAIUAVIPGiftedWords];
            NSLog(@"[WordPack] 今日VIP赠送字数已刷新过，当前剩余: %ld", (long)currentWords);
        }
    } else {
        NSLog(@"[WordPack] 用户不是VIP，无每日赠送字数");
        // 清除赠送字数
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kAIUAVIPGiftedWords];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - 字数消耗

- (void)consumeWords:(NSInteger)words completion:(void (^)(BOOL, NSInteger))completion {
    NSLog(@"[WordPack] 尝试消耗 %ld 字", (long)words);
    
    // 检查是否有足够字数
    if (![self hasEnoughWords:words]) {
        NSLog(@"[WordPack] ❌ 字数不足");
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, [self totalAvailableWords]);
            });
        }
        return;
    }
    
    NSInteger remainingToConsume = words;
    
    // 1. 优先消耗VIP赠送字数
    NSInteger vipWords = [self vipGiftedWords];
    if (vipWords > 0) {
        NSInteger consumeFromVIP = MIN(remainingToConsume, vipWords);
        NSInteger newVIPWords = vipWords - consumeFromVIP;
        
        [[NSUserDefaults standardUserDefaults] setInteger:newVIPWords forKey:kAIUAVIPGiftedWords];
        remainingToConsume -= consumeFromVIP;
        
        NSLog(@"[WordPack] 从VIP赠送消耗 %ld 字，剩余 %ld 字", (long)consumeFromVIP, (long)newVIPWords);
    }
    
    // 2. 如果还需要消耗，则从购买的字数包中消耗
    if (remainingToConsume > 0) {
        [self consumeFromPurchasedPacks:remainingToConsume];
    }
    
    // 3. 更新总消耗字数
    NSInteger totalConsumed = [[NSUserDefaults standardUserDefaults] integerForKey:kAIUAConsumedWords];
    totalConsumed += words;
    [[NSUserDefaults standardUserDefaults] setInteger:totalConsumed forKey:kAIUAConsumedWords];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSLog(@"[WordPack] ✓ 消耗完成，累计消耗: %ld 字", (long)totalConsumed);
    
    // 同步到iCloud
    if (self.iCloudSyncEnabled) {
        [self syncToiCloud];
    }
    
    // 发送通知
    [[NSNotificationCenter defaultCenter] postNotificationName:AIUAWordConsumedNotification
                                                        object:nil
                                                      userInfo:@{@"words": @(words)}];
    
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(YES, [self totalAvailableWords]);
        });
    }
}

- (void)consumeFromPurchasedPacks:(NSInteger)words {
    NSMutableArray *purchases = [[[NSUserDefaults standardUserDefaults] objectForKey:kAIUAWordPackPurchases] mutableCopy];
    if (!purchases || purchases.count == 0) {
        return;
    }
    
    NSInteger remainingToConsume = words;
    NSDate *now = [NSDate date];
    
    // 按购买时间排序（先购买的先消耗）
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"purchaseDate" ascending:YES];
    [purchases sortUsingDescriptors:@[sortDescriptor]];
    
    for (NSMutableDictionary *purchase in purchases) {
        if (remainingToConsume <= 0) {
            break;
        }
        
        // 检查是否过期
        NSDate *expiryDate = purchase[@"expiryDate"];
        if ([now compare:expiryDate] == NSOrderedDescending) {
            continue; // 已过期，跳过
        }
        
        NSInteger remainingWords = [purchase[@"remainingWords"] integerValue];
        if (remainingWords > 0) {
            NSInteger consumeFromThis = MIN(remainingToConsume, remainingWords);
            NSInteger newRemaining = remainingWords - consumeFromThis;
            
            purchase[@"remainingWords"] = @(newRemaining);
            remainingToConsume -= consumeFromThis;
            
            NSLog(@"[WordPack] 从购买字数包消耗 %ld 字，剩余 %ld 字", (long)consumeFromThis, (long)newRemaining);
        }
    }
    
    // 保存更新后的购买记录
    [[NSUserDefaults standardUserDefaults] setObject:purchases forKey:kAIUAWordPackPurchases];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)hasEnoughWords:(NSInteger)words {
    return [self totalAvailableWords] >= words;
}

#pragma mark - iCloud同步

- (void)enableiCloudSync {
    if (self.iCloudSyncEnabled) {
        return;
    }
    
    NSLog(@"[WordPack] 启用iCloud同步");
    self.iCloudSyncEnabled = YES;
    
    // 监听iCloud变化
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(iCloudStoreDidChange:)
                                                 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                               object:self.iCloudStore];
    
    // 同步iCloud数据
    [self.iCloudStore synchronize];
    
    // 首次启用时，从iCloud拉取数据
    [self syncFromiCloud];
}

- (void)iCloudStoreDidChange:(NSNotification *)notification {
    NSLog(@"[WordPack] iCloud数据发生变化，同步到本地");
    [self syncFromiCloud];
}

- (void)syncFromiCloud {
    if (!self.iCloudSyncEnabled) {
        return;
    }
    
    NSLog(@"[WordPack] 从iCloud同步数据");
    
    NSDictionary *iCloudData = [self.iCloudStore dictionaryForKey:kAIUAiCloudWordPackData];
    if (!iCloudData) {
        NSLog(@"[WordPack] iCloud中没有数据");
        return;
    }
    
    // 同步VIP赠送字数
    if (iCloudData[@"vipGiftedWords"]) {
        [[NSUserDefaults standardUserDefaults] setInteger:[iCloudData[@"vipGiftedWords"] integerValue]
                                                   forKey:kAIUAVIPGiftedWords];
    }
    
    // 同步上次刷新日期
    if (iCloudData[@"vipGiftedWordsLastRefreshDate"]) {
        [[NSUserDefaults standardUserDefaults] setObject:iCloudData[@"vipGiftedWordsLastRefreshDate"]
                                                   forKey:kAIUAVIPGiftedWordsLastRefreshDate];
    }
    
    // 同步购买记录
    if (iCloudData[@"purchases"]) {
        [[NSUserDefaults standardUserDefaults] setObject:iCloudData[@"purchases"]
                                                   forKey:kAIUAWordPackPurchases];
    }
    
    // 同步消耗记录
    if (iCloudData[@"consumedWords"]) {
        [[NSUserDefaults standardUserDefaults] setInteger:[iCloudData[@"consumedWords"] integerValue]
                                                   forKey:kAIUAConsumedWords];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"[WordPack] iCloud同步完成");
}

- (void)syncToiCloud {
    if (!self.iCloudSyncEnabled) {
        return;
    }
    
    NSLog(@"[WordPack] 上传数据到iCloud");
    
    // 构建要上传的数据
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    // VIP赠送字数（每日）
    data[@"vipGiftedWords"] = @([[NSUserDefaults standardUserDefaults] integerForKey:kAIUAVIPGiftedWords]);
    
    // VIP赠送字数上次刷新日期
    NSDate *lastRefreshDate = [[NSUserDefaults standardUserDefaults] objectForKey:kAIUAVIPGiftedWordsLastRefreshDate];
    if (lastRefreshDate) {
        data[@"vipGiftedWordsLastRefreshDate"] = lastRefreshDate;
    }
    
    // 购买记录
    NSArray *purchases = [[NSUserDefaults standardUserDefaults] objectForKey:kAIUAWordPackPurchases];
    if (purchases) {
        data[@"purchases"] = purchases;
    }
    
    // 消耗记录
    data[@"consumedWords"] = @([[NSUserDefaults standardUserDefaults] integerForKey:kAIUAConsumedWords]);
    
    // 上传到iCloud
    [self.iCloudStore setDictionary:data forKey:kAIUAiCloudWordPackData];
    [self.iCloudStore synchronize];
    
    NSLog(@"[WordPack] iCloud上传完成");
}

@end

