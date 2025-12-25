//
//  AIUATrialManager.m
//  AIUniversalAssistant
//
//  试用管理器 - 管理应用试用次数（使用Keychain存储）
//

#import "AIUATrialManager.h"
#import "AIUAKeychainManager.h"

// Keychain存储使用的Key
static NSString * const kAIUATrialUsedCountKey = @"aiua_trial_used_count";
static const NSInteger kAIUATrialMaxCount = 2; // 最大试用次数

@interface AIUATrialManager ()

@property (nonatomic, strong) AIUAKeychainManager *keychainManager;
@property (nonatomic, assign) BOOL inTrialSession; // 是否处于试用会话中

@end

@implementation AIUATrialManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
    static AIUATrialManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AIUATrialManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 初始化Keychain管理器
        _keychainManager = [AIUAKeychainManager sharedManager];
        _inTrialSession = NO; // 初始状态不在试用会话中
        
        NSLog(@"[Trial] 试用管理器初始化完成，当前剩余试用次数: %ld", (long)[self remainingTrialCount]);
    }
    return self;
}

#pragma mark - Public Methods

- (NSInteger)remainingTrialCount {
    // 从Keychain获取已使用的试用次数
    NSString *usedCountStr = [self.keychainManager objectForKey:kAIUATrialUsedCountKey];
    NSInteger usedCount = usedCountStr ? [usedCountStr integerValue] : 0;
    
    // 计算剩余次数
    NSInteger remaining = kAIUATrialMaxCount - usedCount;
    
    // 确保不会出现负数
    if (remaining < 0) {
        remaining = 0;
    }
    
    return remaining;
}

- (BOOL)hasTrialRemaining {
    return [self remainingTrialCount] > 0;
}

- (BOOL)useTrialOnce {
    // 检查是否还有剩余次数
    if (![self hasTrialRemaining]) {
        NSLog(@"[Trial] 试用次数已用完");
        return NO;
    }
    
    // 获取当前已使用次数
    NSString *usedCountStr = [self.keychainManager objectForKey:kAIUATrialUsedCountKey];
    NSInteger usedCount = usedCountStr ? [usedCountStr integerValue] : 0;
    
    // 增加已使用次数
    usedCount++;
    [self.keychainManager setObject:[@(usedCount) stringValue] forKey:kAIUATrialUsedCountKey];
    
    NSLog(@"[Trial] 使用一次试用机会，剩余次数: %ld", (long)[self remainingTrialCount]);
    
    return YES;
}

- (void)resetTrialCount {
    [self.keychainManager setObject:@"0" forKey:kAIUATrialUsedCountKey];
    
    NSLog(@"[Trial] 试用次数已重置");
}

#pragma mark - Trial Session Management

- (BOOL)isInTrialSession {
    return self.inTrialSession;
}

- (void)beginTrialSession {
    self.inTrialSession = YES;
    NSLog(@"[Trial] 开始试用会话");
}

- (void)endTrialSession {
    self.inTrialSession = NO;
    NSLog(@"[Trial] 结束试用会话");
}

@end
