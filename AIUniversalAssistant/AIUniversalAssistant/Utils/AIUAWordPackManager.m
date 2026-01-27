//
//  AIUAWordPackManager.m
//  AIUniversalAssistant
//
//  字数包管理器实现
//

#import "AIUAWordPackManager.h"
#import "AIUAIAPManager.h"
#import "AIUATrialManager.h"
#import "AIUAKeychainManager.h"
#import "AIUAAlertHelper.h"
#import "AIUAToolsManager.h"
#import "AIUAMacros.h"
#import "AIUAConfigID.h"
#import <UIKit/UIKit.h>

// 通知名称
NSString * const AIUAWordPackPurchasedNotification = @"AIUAWordPackPurchasedNotification";
NSString * const AIUAWordConsumedNotification = @"AIUAWordConsumedNotification";

// 本地存储Key
static NSString * const kAIUAVIPGiftedWords = @"kAIUAVIPGiftedWords";
static NSString * const kAIUAVIPGiftedWordsLastRefreshDate = @"kAIUAVIPGiftedWordsLastRefreshDate"; // 已废弃，保留用于兼容
static NSString * const kAIUAVIPGiftAwarded = @"kAIUAVIPGiftAwarded"; // 标记是否已赠送过一次性50万字
static NSString * const kAIUAPurchasedWords = @"kAIUAPurchasedWords";
static NSString * const kAIUAConsumedWords = @"kAIUAConsumedWords";
static NSString * const kAIUAWordPackPurchases = @"kAIUAWordPackPurchases";

// iCloud Keys
static NSString * const kAIUAiCloudWordPackData = @"AIUAWordPackData";

// VIP赠送字数常量
static const NSInteger kVIPOneTimeGiftWords = 500000; // 订阅后一次性赠送50万字

// 字数包产品ID（如果配置文件中定义了则使用配置的，否则基于Bundle ID生成）
static NSString * kProductIDWordPack500K = nil;
static NSString * kProductIDWordPack2M = nil;
static NSString * kProductIDWordPack6M = nil;

@interface AIUAWordPackManager ()

@property (nonatomic, strong) NSUbiquitousKeyValueStore *iCloudStore;
@property (nonatomic, assign) BOOL iCloudSyncEnabled;
@property (nonatomic, strong) AIUAKeychainManager *keychainManager;

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
        _keychainManager = [AIUAKeychainManager sharedManager];

        // 移除危险的兜底重置逻辑
        // 原因：初始化时VIP状态可能还未加载完成，错误地清除赠送字数会导致用户损失
        // VIP状态的变化由通知机制处理（subscriptionStatusChanged）
        
        // 启动时清除已过期的购买记录
        [self cleanExpiredPurchases];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 本地存储辅助方法（使用Keychain）

- (void)setLocalInteger:(NSInteger)value forKey:(NSString *)key {
    [self.keychainManager setInteger:value forKey:key];
}

- (NSInteger)localIntegerForKey:(NSString *)key {
    return [self.keychainManager integerForKey:key];
}

- (void)setLocalBool:(BOOL)value forKey:(NSString *)key {
    [self.keychainManager setInteger:value ? 1 : 0 forKey:key];
}

- (BOOL)localBoolForKey:(NSString *)key {
    return [self.keychainManager integerForKey:key] != 0;
}

- (void)setLocalObject:(id)object forKey:(NSString *)key {
    [self.keychainManager setObject:object forKey:key];
}

- (id)localObjectForKey:(NSString *)key {
    return [self.keychainManager objectForKey:key];
}

#pragma mark - 字数查询

- (NSInteger)vipGiftedWords {
    // 检查VIP状态
    BOOL isVIP = [[AIUAIAPManager sharedManager] isVIPMember];
    if (!isVIP) {
        NSLog(@"[WordPack] 用户不是VIP，赠送字数为0");
        return 0;
    }
    
    // 不再每日刷新，直接返回已赠送的字数
    NSInteger giftedWords = [self localIntegerForKey:kAIUAVIPGiftedWords];
    NSLog(@"[WordPack] VIP剩余赠送字数: %ld", (long)giftedWords);
    return MAX(0, giftedWords);
}

- (NSInteger)purchasedWords {
    // 先清除已过期的记录（避免数据积累）
    [self cleanExpiredPurchases];
    
    // 遍历所有购买记录，计算未过期的字数
    NSArray *purchases = [self localObjectForKey:kAIUAWordPackPurchases];
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
    NSInteger consumed = [self localIntegerForKey:kAIUAConsumedWords];
    return consumed;
}

- (NSDictionary<NSNumber *, NSNumber *> *)expiringWordsByDays {
    // 检查测试开关
    if (AIUA_EXPIRING_WORDS_TEST_ENABLED) {
        NSLog(@"[WordPack] 使用测试数据 - 过期字数包提醒");
        return [self getTestExpiringWordsByDays];
    }
    
    // 遍历所有购买记录，按天数分组计算7天内即将过期的字数
    NSArray *purchases = [self localObjectForKey:kAIUAWordPackPurchases];
    if (!purchases) {
        return @{};
    }
    
    NSMutableDictionary<NSNumber *, NSNumber *> *expiringByDays = [NSMutableDictionary dictionary];
    NSDate *now = [NSDate date];
    
    for (NSDictionary *purchase in purchases) {
        NSDate *expiryDate = purchase[@"expiryDate"];
        if (expiryDate) {
            // 检查是否未过期
            if ([now compare:expiryDate] == NSOrderedAscending) {
                // 计算剩余天数（向上取整，确保今天过期的也算1天）
                NSTimeInterval timeInterval = [expiryDate timeIntervalSinceDate:now];
                NSInteger daysRemaining = (NSInteger)ceil(timeInterval / (24 * 60 * 60));
                
                // 只处理1-7天内的（不包括今天，今天过期的算1天）
                if (daysRemaining >= 1 && daysRemaining <= 7) {
                    NSInteger remainingWords = [purchase[@"remainingWords"] integerValue];
                    NSNumber *daysKey = @(daysRemaining);
                    
                    // 累加对应天数的字数
                    NSInteger existingWords = [expiringByDays[daysKey] integerValue];
                    expiringByDays[daysKey] = @(existingWords + remainingWords);
                }
            }
        }
    }
    
    NSLog(@"[WordPack] 按天数分组的即将过期字数: %@", expiringByDays);
    return [expiringByDays copy];
}

#pragma mark - 测试数据

- (NSDictionary<NSNumber *, NSNumber *> *)getTestExpiringWordsByDays {
    // 生成测试数据：模拟7天内即将过期的字数
    // 7天后: 10000字
    // 6天后: 5000字
    // 5天后: 8000字
    // 4天后: 3000字
    // 3天后: 12000字
    // 2天后: 6000字
    // 明天: 15000字
    NSDictionary<NSNumber *, NSNumber *> *testData = @{
        @7: @10000,  // 7天后过期10000字
        @6: @5000,   // 6天后过期5000字
        @5: @8000,   // 5天后过期8000字
        @4: @3000,   // 4天后过期3000字
        @3: @12000,  // 3天后过期12000字
        @2: @6000,   // 后天过期6000字
        @1: @15000   // 明天过期15000字
    };
    
    NSLog(@"[WordPack] 测试数据 - 过期字数包提醒: %@", testData);
    return testData;
}

#pragma mark - 清除过期记录

- (void)cleanExpiredPurchases {
    NSArray *existingPurchases = [self localObjectForKey:kAIUAWordPackPurchases];
    if (!existingPurchases || existingPurchases.count == 0) {
        return;
    }
    
    NSMutableArray *validPurchases = [NSMutableArray array];
    NSDate *now = [NSDate date];
    NSInteger expiredCount = 0;
    
    for (NSDictionary *purchase in existingPurchases) {
        NSDate *expiryDate = purchase[@"expiryDate"];
        if (expiryDate && [now compare:expiryDate] == NSOrderedAscending) {
            // 未过期，保留
            [validPurchases addObject:purchase];
        } else {
            // 已过期，清除
            expiredCount++;
            NSInteger expiredWords = [purchase[@"remainingWords"] integerValue];
            if (expiredWords > 0) {
                NSLog(@"[WordPack] 清除过期记录: %@ 字，过期时间: %@", @(expiredWords), expiryDate);
            }
        }
    }
    
    if (expiredCount > 0) {
        // 保存清理后的记录
        [self setLocalObject:[validPurchases copy] forKey:kAIUAWordPackPurchases];
        
        // 同步到iCloud
        if (self.iCloudSyncEnabled) {
            [self syncToiCloud];
        }
        
        NSLog(@"[WordPack] ✓ 已清除 %ld 条过期购买记录，剩余 %ld 条有效记录", 
              (long)expiredCount, (long)validPurchases.count);
        
        // 发送通知，通知UI更新
        [[NSNotificationCenter defaultCenter] postNotificationName:AIUAWordPackPurchasedNotification
                                                            object:nil
                                                          userInfo:nil];
    }
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
            // 显示调试错误弹窗
            [AIUAAlertHelper showDebugErrorAlert:errorMessage context:@"购买字数包失败"];
            
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
    NSArray *existingPurchases = [self localObjectForKey:kAIUAWordPackPurchases];
    NSMutableArray *purchases = existingPurchases ? [existingPurchases mutableCopy] : [NSMutableArray array];
    
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
    
    // 保存到Keychain
    [self setLocalObject:purchases forKey:kAIUAWordPackPurchases];
    
    NSLog(@"[WordPack] 购买记录已保存: %@ 字，过期时间: %@", @(words), expiryDate);
}

#pragma mark - 奖励字数（追加，不覆盖）

- (void)awardBonusWords:(NSInteger)words validDays:(NSInteger)days completion:(void (^ _Nullable)(void))completion {
    if (words <= 0) {
        if (completion) completion();
        return;
    }
    NSArray *existingPurchases = [self localObjectForKey:kAIUAWordPackPurchases];
    NSMutableArray *purchases = existingPurchases ? [existingPurchases mutableCopy] : [NSMutableArray array];
    NSDate *now = [NSDate date];
    NSDate *expiryDate = [now dateByAddingTimeInterval:MAX(1, days) * 24 * 60 * 60];
    NSDictionary *purchase = @{
        @"productID": @"reward.bonus",
        @"words": @(words),
        @"remainingWords": @(words),
        @"purchaseDate": now,
        @"expiryDate": expiryDate
    };
    [purchases addObject:purchase];
    [self setLocalObject:purchases forKey:kAIUAWordPackPurchases];

    // iCloud 同步
    if (self.iCloudSyncEnabled) {
        [self syncToiCloud];
    }
    // 通知刷新
    [[NSNotificationCenter defaultCenter] postNotificationName:AIUAWordPackPurchasedNotification object:nil userInfo:@{ @"words": @(words) }];
    NSLog(@"[WordPack] 奖励入账: %ld 字，当前记录数: %lu", (long)words, (unsigned long)purchases.count);
    if (completion) completion();
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
    // 初始化产品ID（如果还未初始化）
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        
#ifdef AIUA_IAP_WORDPACK_500K
        kProductIDWordPack500K = AIUA_IAP_WORDPACK_500K;
#else
        kProductIDWordPack500K = [NSString stringWithFormat:@"%@.wordpack.500k", bundleID];
#endif
        
#ifdef AIUA_IAP_WORDPACK_2M
        kProductIDWordPack2M = AIUA_IAP_WORDPACK_2M;
#else
        kProductIDWordPack2M = [NSString stringWithFormat:@"%@.wordpack.2m", bundleID];
#endif
        
#ifdef AIUA_IAP_WORDPACK_6M
        kProductIDWordPack6M = AIUA_IAP_WORDPACK_6M;
#else
        kProductIDWordPack6M = [NSString stringWithFormat:@"%@.wordpack.6m", bundleID];
#endif
        
        NSLog(@"[WordPack] 字数包产品ID初始化 - Bundle ID: %@", bundleID);
        NSLog(@"[WordPack] 字数包产品ID - 500K: %@, 2M: %@, 6M: %@", 
              kProductIDWordPack500K, kProductIDWordPack2M, kProductIDWordPack6M);
    });
    
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
    
    NSLog(@"[WordPack] 刷新VIP赠送字数 - 当前VIP状态: %@", isVIP ? @"是" : @"否");
    
    if (isVIP) {
        // 检查是否已经赠送过一次性50万字
        BOOL hasAwarded = [self localBoolForKey:kAIUAVIPGiftAwarded];
        NSLog(@"[WordPack] 是否已赠送过: %@", hasAwarded ? @"是" : @"否");
        
        if (!hasAwarded) {
            // 首次订阅，一次性赠送50万字
            NSLog(@"[WordPack] ✓ 检测到新VIP用户，一次性赠送 %ld 字", (long)kVIPOneTimeGiftWords);
            [self setLocalInteger:kVIPOneTimeGiftWords forKey:kAIUAVIPGiftedWords];
            [self setLocalBool:YES forKey:kAIUAVIPGiftAwarded];
            
            // 同步到iCloud
            if (self.iCloudSyncEnabled) {
                [self syncToiCloud];
            }
            
            // 发送通知
            [[NSNotificationCenter defaultCenter] postNotificationName:AIUAWordPackPurchasedNotification 
                                                                object:nil 
                                                              userInfo:@{ @"words": @(kVIPOneTimeGiftWords) }];
            
            NSLog(@"[WordPack] ✓ 赠送字数已发放并保存");
        } else {
            NSInteger currentWords = [self localIntegerForKey:kAIUAVIPGiftedWords];
            NSLog(@"[WordPack] VIP用户已赠送过一次性字数，当前剩余: %ld", (long)currentWords);
        }
    } else {
        NSLog(@"[WordPack] 用户不是VIP，无赠送字数");
        // 清除赠送字数，但保留已赠送标记（防止用户退订后重新订阅时重复赠送）
        [self setLocalInteger:0 forKey:kAIUAVIPGiftedWords];
    }
}

#pragma mark - 字数消耗

- (void)consumeWords:(NSInteger)words completion:(void (^)(BOOL, NSInteger))completion {
    NSLog(@"[WordPack] 尝试消耗 %ld 字", (long)words);
    
    // 检查是否处于试用会话中（已经使用了试用次数）
    AIUATrialManager *trialManager = [AIUATrialManager sharedManager];
    if ([trialManager isInTrialSession]) {
        NSLog(@"[WordPack] ✓ 用户处于试用会话中，记录消耗但不扣除字数");
        // 试用会话中记录消耗统计，但不实际扣除字数
        [self recordConsumption:words];
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, [self totalAvailableWords]);
            });
        }
        return;
    }
    
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
        
        [self setLocalInteger:newVIPWords forKey:kAIUAVIPGiftedWords];
        remainingToConsume -= consumeFromVIP;
        
        NSLog(@"[WordPack] 从VIP赠送消耗 %ld 字，剩余 %ld 字", (long)consumeFromVIP, (long)newVIPWords);
    }
    
    // 2. 如果还需要消耗，则从购买的字数包中消耗
    if (remainingToConsume > 0) {
        [self consumeFromPurchasedPacks:remainingToConsume];
    }
    
    // 3. 记录消耗统计
    [self recordConsumption:words];
    
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(YES, [self totalAvailableWords]);
        });
    }
}

// 记录字数消耗统计（不实际扣除字数，仅用于统计）
- (void)recordConsumption:(NSInteger)words {
    // 更新总消耗字数
    NSInteger totalConsumed = [self localIntegerForKey:kAIUAConsumedWords];
    totalConsumed += words;
    [self setLocalInteger:totalConsumed forKey:kAIUAConsumedWords];
    
    NSLog(@"[WordPack] ✓ 记录消耗统计: %ld 字，累计消耗: %ld 字", (long)words, (long)totalConsumed);
    
    // 同步到iCloud
    if (self.iCloudSyncEnabled) {
        [self syncToiCloud];
    }
    
    // 发送通知
    [[NSNotificationCenter defaultCenter] postNotificationName:AIUAWordConsumedNotification
                                                        object:nil
                                                      userInfo:@{@"words": @(words)}];
}

- (void)consumeFromPurchasedPacks:(NSInteger)words {
    NSArray *existingPurchases = [self localObjectForKey:kAIUAWordPackPurchases];
    if (!existingPurchases || existingPurchases.count == 0) {
        return;
    }
    
    // 创建可变数组，并将每个字典转换为可变字典
    NSMutableArray *purchases = [NSMutableArray array];
    for (NSDictionary *purchase in existingPurchases) {
        [purchases addObject:[purchase mutableCopy]];
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
    
    // 保存更新后的购买记录到Keychain（转换为不可变数组）
    [self setLocalObject:[purchases copy] forKey:kAIUAWordPackPurchases];
}

- (BOOL)hasEnoughWords:(NSInteger)words {
    // 检查是否处于试用会话中（已经使用了试用次数）
    AIUATrialManager *trialManager = [AIUATrialManager sharedManager];
    if ([trialManager isInTrialSession]) {
        NSLog(@"[WordPack] 用户处于试用会话中，字数不受限制");
        return YES;
    }
    
    // 正常检查字数
    BOOL hasEnough = [self totalAvailableWords] >= words;
    if (!hasEnough) {
        NSLog(@"[WordPack] 字数不足，需要: %ld，可用: %ld", (long)words, (long)[self totalAvailableWords]);
    }
    return hasEnough;
}

#pragma mark - 字数统计

+ (NSInteger)countWordsInText:(NSString *)text {
    if (!text || text.length == 0) {
        return 0;
    }
    
    // 根据规则：1个中文字符、英文字母、数字、标点或空格均计为1字
    // 实际上就是字符串的长度（每个字符都计为1字）
    // 使用NSString的length属性即可，因为NSString的length返回的是UTF-16代码单元的数量
    // 对于大多数字符（包括中文、英文、数字、标点、空格），每个字符占用1个UTF-16代码单元
    // 对于emoji等特殊字符，可能占用2个UTF-16代码单元，但按照规则也应该计为1字
    
    // 为了准确统计，我们需要遍历字符串并统计实际的字符数量（而不是UTF-16代码单元）
    // 使用enumerateSubstringsInRange:options:usingBlock:来正确处理所有Unicode字符
    __block NSInteger count = 0;
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        // 每个composed character sequence（包括emoji）计为1字
        count++;
    }];
    
    return count;
}

#pragma mark - iCloud同步

- (BOOL)isiCloudAvailable {
    BOOL synced = [self.iCloudStore synchronize];
    NSLog(@"iCloud KVS synchronize: %@", synced ? @"YES" : @"NO");
    // 检查iCloud Key-Value Store是否可用
    // 如果设备未登录Apple ID或未开启iCloud Drive，会返回nil或无法访问
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *ubiquityURL = [fileManager URLForUbiquityContainerIdentifier:nil];
    
    if (ubiquityURL == nil) {
        NSLog(@"[WordPack] iCloud不可用：设备未登录Apple ID或未开启iCloud Drive");
        return NO;
    }
    
    // 尝试访问iCloud Store
    @try {
        // 尝试读取一个测试值
        id testValue = [self.iCloudStore objectForKey:@"__test_icloud_availability__"];
        NSLog(@"[WordPack] iCloud可用");
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"[WordPack] iCloud不可用：%@", exception.reason);
        return NO;
    }
}

- (BOOL)checkiCloudAvailabilityAndPrompt:(UIViewController *)viewController showAlert:(BOOL)showAlert {
    BOOL isAvailable = [self isiCloudAvailable];
    
    if (!isAvailable && showAlert) {
        // 显示提示并引导用户到设置页面
        NSString *title = L(@"icloud_unavailable_title");
        NSString *message = L(@"icloud_unavailable_message");
        NSString *cancelText = L(@"cancel");
        NSString *confirmText = L(@"go_to_settings");
        
        [AIUAAlertHelper showAlertWithTitle:title
                                   message:message
                             cancelBtnText:cancelText
                            confirmBtnText:confirmText
                              inController:viewController
                              cancelAction:nil
                             confirmAction:^{
            // 跳转到设置页面
            [self openiCloudSettings];
        }];
    }
    
    return isAvailable;
}

- (void)openiCloudSettings {
    // 注意：使用 App-Prefs:root=CASTLE 是私有 API，可能导致 App Store 审核被拒
    // 因此使用安全的公开 API：跳转到应用设置页面，并提供详细的操作指引
    
    // 先跳转到应用设置页面（这是公开的 API，审核安全）
//    [self openAppSettings];
    
    // 然后显示详细的操作指引，引导用户手动进入 iCloud 设置
    // 注意：这里延迟显示，确保设置页面已经打开
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showiCloudSettingsGuide];
    });
}

- (void)openAppSettings {
    // 使用公开的 API 跳转到应用自己的设置页面
    // 这是 Apple 官方推荐的方式，审核安全
    NSURL *appSettingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:appSettingsURL options:@{} completionHandler:^(BOOL success) {
            if (success) {
                NSLog(@"[WordPack] 已跳转到应用设置页面");
            } else {
                NSLog(@"[WordPack] 跳转应用设置页面失败");
            }
        }];
    } else {
        [[UIApplication sharedApplication] openURL:appSettingsURL];
        NSLog(@"[WordPack] 已跳转到应用设置页面");
    }
}

- (void)showiCloudSettingsGuide {
    // 显示详细的操作指引，引导用户进入 iCloud 设置
    UIViewController *topVC = [AIUAToolsManager topViewController];
    if (!topVC) {
        return;
    }
    
    NSString *title = L(@"icloud_settings_guide_title") ?: @"如何开启iCloud";
    NSString *message = L(@"icloud_settings_guide_message") ?: @"请按照以下步骤操作：\n\n1. 在设置页面，点击顶部的「Apple ID」\n2. 选择「iCloud」\n3. 确保「iCloud云盘」已开启\n\n完成后返回应用即可。";
    NSString *confirmText = L(@"confirm") ?: @"确定";
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:confirmText
                                                             style:UIAlertActionStyleDefault
                                                           handler:nil];
    [alert addAction:confirmAction];
    
    // 延迟显示，确保设置页面已经打开
    dispatch_async(dispatch_get_main_queue(), ^{
        [topVC presentViewController:alert animated:YES completion:nil];
    });
}

- (void)enableiCloudSync {
    if (self.iCloudSyncEnabled) {
        return;
    }
    
    // 检查iCloud是否可用
    if (![self isiCloudAvailable]) {
        NSLog(@"[WordPack] iCloud不可用，使用本地存储");
        // iCloud不可用时，数据保存在Keychain中，只是不会同步到iCloud
        // 这是自动降级，用户无需任何操作
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
        [self setLocalInteger:[iCloudData[@"vipGiftedWords"] integerValue] forKey:kAIUAVIPGiftedWords];
    }
    
    // 同步是否已赠送标记
    if (iCloudData[@"vipGiftAwarded"] != nil) {
        [self setLocalBool:[iCloudData[@"vipGiftAwarded"] boolValue] forKey:kAIUAVIPGiftAwarded];
    }
    
    // 同步上次刷新日期（保留兼容性，但不再使用）
    if (iCloudData[@"vipGiftedWordsLastRefreshDate"]) {
        [self setLocalObject:iCloudData[@"vipGiftedWordsLastRefreshDate"] forKey:kAIUAVIPGiftedWordsLastRefreshDate];
    }
    
    // 同步购买记录
    if (iCloudData[@"purchases"]) {
        [self setLocalObject:iCloudData[@"purchases"] forKey:kAIUAWordPackPurchases];
    }
    
    // 同步消耗记录
    if (iCloudData[@"consumedWords"]) {
        [self setLocalInteger:[iCloudData[@"consumedWords"] integerValue] forKey:kAIUAConsumedWords];
    }
    NSLog(@"[WordPack] iCloud同步完成");
}

- (void)syncToiCloud {
    if (!self.iCloudSyncEnabled) {
        return;
    }
    
    NSLog(@"[WordPack] 上传数据到iCloud");
    
    // 构建要上传的数据
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    // VIP赠送字数（一次性）
    data[@"vipGiftedWords"] = @([self localIntegerForKey:kAIUAVIPGiftedWords]);
    
    // VIP是否已赠送标记
    data[@"vipGiftAwarded"] = @([self localBoolForKey:kAIUAVIPGiftAwarded]);

    // VIP赠送字数上次刷新日期（保留兼容性，但不再使用）
    NSDate *lastRefreshDate = [self localObjectForKey:kAIUAVIPGiftedWordsLastRefreshDate];
    if (lastRefreshDate) {
        data[@"vipGiftedWordsLastRefreshDate"] = lastRefreshDate;
    }
    
    // 购买记录
    NSArray *purchases = [self localObjectForKey:kAIUAWordPackPurchases];
    if (purchases) {
        data[@"purchases"] = purchases;
    }
    
    // 消耗记录
    data[@"consumedWords"] = @([self localIntegerForKey:kAIUAConsumedWords]);
    
    // 上传到iCloud
    [self.iCloudStore setDictionary:data forKey:kAIUAiCloudWordPackData];
    [self.iCloudStore synchronize];
    
    NSLog(@"[WordPack] iCloud上传完成");
}

#pragma mark - 数据导出/导入（iCloud不可用时的替代方案）

- (NSString *)exportWordPackData {
    NSLog(@"[WordPack] 导出字数包数据");
    
    // 构建要导出的数据
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    // VIP赠送字数
    data[@"vipGiftedWords"] = @([self localIntegerForKey:kAIUAVIPGiftedWords]);
    
    // VIP是否已赠送标记
    data[@"vipGiftAwarded"] = @([self localBoolForKey:kAIUAVIPGiftAwarded]);
    
    // VIP赠送字数上次刷新日期（保留兼容性，但不再使用）
    NSDate *lastRefreshDate = [self localObjectForKey:kAIUAVIPGiftedWordsLastRefreshDate];
    if (lastRefreshDate) {
        data[@"vipGiftedWordsLastRefreshDate"] = @([lastRefreshDate timeIntervalSince1970]);
    }
    
    // 购买记录
    NSArray *purchases = [self localObjectForKey:kAIUAWordPackPurchases];
    if (purchases) {
        // 将NSDate转换为时间戳，以便JSON序列化
        NSMutableArray *purchasesJSON = [NSMutableArray array];
        for (NSDictionary *purchase in purchases) {
            NSMutableDictionary *purchaseJSON = [purchase mutableCopy];
            if (purchase[@"purchaseDate"]) {
                NSDate *purchaseDate = purchase[@"purchaseDate"];
                purchaseJSON[@"purchaseDate"] = @([purchaseDate timeIntervalSince1970]);
            }
            if (purchase[@"expiryDate"]) {
                NSDate *expiryDate = purchase[@"expiryDate"];
                purchaseJSON[@"expiryDate"] = @([expiryDate timeIntervalSince1970]);
            }
            [purchasesJSON addObject:purchaseJSON];
        }
        data[@"purchases"] = purchasesJSON;
    }
    
    // 消耗记录
    data[@"consumedWords"] = @([self localIntegerForKey:kAIUAConsumedWords]);
    
    // 添加版本号和导出时间
    data[@"version"] = @1;
    data[@"exportTime"] = @([[NSDate date] timeIntervalSince1970]);
    
    // 转换为JSON字符串
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) {
        NSLog(@"[WordPack] 导出失败: %@", error.localizedDescription);
        return nil;
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"[WordPack] 导出成功，数据大小: %lu 字节", (unsigned long)jsonString.length);
    
    return jsonString;
}

- (void)importWordPackData:(NSString *)jsonString completion:(void (^)(BOOL, NSError * _Nullable))completion {
    NSLog(@"[WordPack] 导入字数包数据");
    
    if (!jsonString || jsonString.length == 0) {
        NSError *error = [NSError errorWithDomain:@"AIUAWordPackManager"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"导入数据为空"}];
        if (completion) {
            completion(NO, error);
        }
        return;
    }
    
    // 解析JSON字符串
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error || !data) {
        NSLog(@"[WordPack] 导入失败：JSON解析错误 - %@", error.localizedDescription);
        if (completion) {
            completion(NO, error);
        }
        return;
    }
    
    // 验证版本号
    NSInteger version = [data[@"version"] integerValue];
    if (version != 1) {
        NSError *versionError = [NSError errorWithDomain:@"AIUAWordPackManager"
                                                     code:-2
                                                 userInfo:@{NSLocalizedDescriptionKey: @"不支持的导入数据版本"}];
        if (completion) {
            completion(NO, versionError);
        }
        return;
    }
    
    // 导入VIP赠送字数
    if (data[@"vipGiftedWords"]) {
        [self setLocalInteger:[data[@"vipGiftedWords"] integerValue] forKey:kAIUAVIPGiftedWords];
    }
    
    // 导入VIP是否已赠送标记
    if (data[@"vipGiftAwarded"] != nil) {
        [self setLocalBool:[data[@"vipGiftAwarded"] boolValue] forKey:kAIUAVIPGiftAwarded];
    }
    
    // 导入VIP赠送字数上次刷新日期（保留兼容性，但不再使用）
    if (data[@"vipGiftedWordsLastRefreshDate"]) {
        NSTimeInterval timestamp = [data[@"vipGiftedWordsLastRefreshDate"] doubleValue];
        NSDate *lastRefreshDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
        [self setLocalObject:lastRefreshDate forKey:kAIUAVIPGiftedWordsLastRefreshDate];
    }
    
    // 导入购买记录
    if (data[@"purchases"]) {
        NSArray *purchasesJSON = data[@"purchases"];
        NSMutableArray *purchases = [NSMutableArray array];
        
        for (NSDictionary *purchaseJSON in purchasesJSON) {
            NSMutableDictionary *purchase = [purchaseJSON mutableCopy];
            
            // 转换时间戳为NSDate
            if (purchaseJSON[@"purchaseDate"]) {
                NSTimeInterval timestamp = [purchaseJSON[@"purchaseDate"] doubleValue];
                purchase[@"purchaseDate"] = [NSDate dateWithTimeIntervalSince1970:timestamp];
            }
            if (purchaseJSON[@"expiryDate"]) {
                NSTimeInterval timestamp = [purchaseJSON[@"expiryDate"] doubleValue];
                purchase[@"expiryDate"] = [NSDate dateWithTimeIntervalSince1970:timestamp];
            }
            
            [purchases addObject:purchase];
        }
        
        [self setLocalObject:purchases forKey:kAIUAWordPackPurchases];
    }
    
    // 导入消耗记录
    if (data[@"consumedWords"]) {
        [self setLocalInteger:[data[@"consumedWords"] integerValue] forKey:kAIUAConsumedWords];
    }
    
    NSLog(@"[WordPack] 导入成功");
    
    // 如果iCloud可用，同步到iCloud
    if (self.iCloudSyncEnabled && [self isiCloudAvailable]) {
        [self syncToiCloud];
    }
    
    // 发送通知
    [[NSNotificationCenter defaultCenter] postNotificationName:AIUAWordPackPurchasedNotification
                                                        object:nil
                                                      userInfo:nil];
    
    if (completion) {
        completion(YES, nil);
    }
}

#pragma mark - 调试/测试功能

- (void)clearAllWordPackData {
    NSLog(@"[WordPack] ⚠️ 开始清除所有字数包数据...");
    
    // 清除VIP赠送字数
    [self.keychainManager removeObjectForKey:kAIUAVIPGiftedWords];
    [self.keychainManager removeObjectForKey:kAIUAVIPGiftAwarded];
    [self.keychainManager removeObjectForKey:kAIUAVIPGiftedWordsLastRefreshDate];
    
    // 清除购买记录
    [self.keychainManager removeObjectForKey:kAIUAWordPackPurchases];
    [self.keychainManager removeObjectForKey:kAIUAPurchasedWords];
    
    // 清除消耗记录
    [self.keychainManager removeObjectForKey:kAIUAConsumedWords];
    
    // 清除iCloud数据
    if (self.iCloudSyncEnabled && [self isiCloudAvailable]) {
        [self.iCloudStore removeObjectForKey:kAIUAiCloudWordPackData];
        [self.iCloudStore synchronize];
        NSLog(@"[WordPack] 已清除iCloud字数包数据");
    }
    
    // 发送通知，更新UI
    [[NSNotificationCenter defaultCenter] postNotificationName:AIUAWordPackPurchasedNotification
                                                        object:nil
                                                      userInfo:nil];
    
    NSLog(@"[WordPack] ✓ 所有字数包数据已清除");
}

@end

