//
//  AIUASplashAdManager.m
//  AIUniversalAssistant
//
//  Created by AI Assistant on 2025/11/9.
//

#import "AIUASplashAdManager.h"

// 判断是否已接入穿山甲SDK
#if __has_include(<BUAdSDK/BUAdSDK.h>)
#import <BUAdSDK/BUAdSDK.h>
#define HAS_PANGLE_SDK 1
#else
#define HAS_PANGLE_SDK 0
#endif

@interface AIUASplashAdManager ()
#if HAS_PANGLE_SDK
<BUSplashAdDelegate>
#endif

#if HAS_PANGLE_SDK
@property (nonatomic, strong) BUSplashAd *splashAd;
#endif

@property (nonatomic, copy) AIUASplashAdLoadedBlock loadedBlock;
@property (nonatomic, copy) AIUASplashAdClosedBlock closedBlock;
@property (nonatomic, copy) AIUASplashAdFailedBlock failedBlock;
@property (nonatomic, weak) UIWindow *adWindow;

@end

@implementation AIUASplashAdManager

#pragma mark - 单例

+ (instancetype)sharedManager {
    static AIUASplashAdManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - Public Methods

- (void)loadAndShowSplashAdInWindow:(UIWindow *)window
                             loaded:(AIUASplashAdLoadedBlock)loadedBlock
                             closed:(AIUASplashAdClosedBlock)closedBlock
                             failed:(AIUASplashAdFailedBlock)failedBlock {
    
#if !HAS_PANGLE_SDK
    NSLog(@"[穿山甲] SDK未集成，请执行 pod install");
    if (failedBlock) {
        NSError *error = [NSError errorWithDomain:@"AIUASplashAdManager"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"穿山甲SDK未集成"}];
        failedBlock(error);
    }
    return;
#else
    
    if (!window) {
        NSLog(@"[穿山甲] 窗口不能为空");
        if (failedBlock) {
            NSError *error = [NSError errorWithDomain:@"AIUASplashAdManager"
                                                 code:-2
                                             userInfo:@{NSLocalizedDescriptionKey: @"窗口不能为空"}];
            failedBlock(error);
        }
        return;
    }
    
    self.loadedBlock = loadedBlock;
    self.closedBlock = closedBlock;
    self.failedBlock = failedBlock;
    self.adWindow = window;
    
    // 从配置文件读取代码位ID
    NSString *slotID = AIUA_SPLASH_AD_SLOT_ID;
    if (!slotID || slotID.length == 0) {
        NSLog(@"[穿山甲] 开屏广告代码位ID未配置");
        if (failedBlock) {
            NSError *error = [NSError errorWithDomain:@"AIUASplashAdManager"
                                                 code:-3
                                             userInfo:@{NSLocalizedDescriptionKey: @"开屏广告代码位ID未配置"}];
            failedBlock(error);
        }
        return;
    }
    
    NSLog(@"[穿山甲] 开始加载开屏广告，代码位ID: %@", slotID);
    NSLog(@"[穿山甲] 窗口尺寸: %@", NSStringFromCGSize(window.bounds.size));
    
    // 创建开屏广告
    CGSize adSize = CGSizeMake(window.bounds.size.width, window.bounds.size.height);
    self.splashAd = [[BUSplashAd alloc] initWithSlotID:slotID adSize:adSize];
    self.splashAd.delegate = self;
    
    // 设置超时时间（秒）- 增加到5秒，真机网络可能较慢
    self.splashAd.tolerateTimeout = 5.0;
    NSLog(@"[穿山甲] 设置超时时间: 5秒");
    
    // 设置超时回调（作为兜底方案，防止SDK没有回调）
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf && strongSelf.splashAd) {
            NSLog(@"⚠️ [穿山甲] 广告加载超时（8秒），可能的原因：");
            NSLog(@"   1. 网络连接问题");
            NSLog(@"   2. 代码位无广告填充");
            NSLog(@"   3. 账号或代码位未激活");
            NSLog(@"   建议：使用测试代码位验证 (AppID: 5001121, 代码位: 887382973)");
            
            if (strongSelf.failedBlock) {
                NSError *error = [NSError errorWithDomain:@"AIUASplashAdManager"
                                                     code:-1001
                                                 userInfo:@{NSLocalizedDescriptionKey: @"广告加载超时"}];
                strongSelf.failedBlock(error);
            }
            [strongSelf cleanup];
        }
    });
    
    // 加载广告
    NSLog(@"[穿山甲] 开始请求广告数据...");
    [self.splashAd loadAdData];
#endif
}

- (void)cancelSplashAd {
#if HAS_PANGLE_SDK
    NSLog(@"[穿山甲] 取消开屏广告");
    self.splashAd = nil;
    self.loadedBlock = nil;
    self.closedBlock = nil;
    self.failedBlock = nil;
#endif
}

#pragma mark - BUSplashAdDelegate

#if HAS_PANGLE_SDK

/**
 * 广告物料加载成功
 */
- (void)splashAdDidLoad:(BUSplashAd *)splashAd {
    NSLog(@"[穿山甲] 开屏广告加载成功");
    
    if (self.loadedBlock) {
        self.loadedBlock();
    }
    
    // 展示广告
    if (self.adWindow) {
        [splashAd showSplashViewInRootViewController:self.adWindow.rootViewController];
        NSLog(@"[穿山甲] 开屏广告展示成功");
    }
}

/**
 * 广告加载失败
 */
- (void)splashAd:(BUSplashAd *)splashAd didFailWithError:(NSError * _Nullable)error {
    NSLog(@"❌❌❌ [穿山甲] 开屏广告加载失败 ❌❌❌");
    NSLog(@"错误码: %ld", (long)error.code);
    NSLog(@"错误域: %@", error.domain);
    NSLog(@"错误描述: %@", error.localizedDescription);
    NSLog(@"错误详情: %@", error.userInfo);
    
    // 常见错误码解释
    switch (error.code) {
        case 20001:
            NSLog(@"💡 提示: 错误码20001 - 无广告填充");
            NSLog(@"   可能原因：");
            NSLog(@"   1. 代码位刚创建，等待激活（可能需要1-3天）");
            NSLog(@"   2. 当前时段无广告");
            NSLog(@"   3. 账号余额不足");
            break;
        case 40002:
            NSLog(@"💡 提示: 错误码40002 - 代码位配置错误");
            NSLog(@"   请检查：");
            NSLog(@"   1. 代码位ID是否正确");
            NSLog(@"   2. 代码位类型是否为开屏广告");
            NSLog(@"   3. 代码位是否已激活");
            break;
        case 40004:
            NSLog(@"💡 提示: 错误码40004 - AppID错误");
            NSLog(@"   请检查AppID是否正确");
            break;
        case 1009:
            NSLog(@"💡 提示: 错误码1009 - 网络连接失败");
            NSLog(@"   请检查网络连接");
            break;
        default:
            NSLog(@"💡 提示: 未知错误码，请查阅穿山甲文档");
            break;
    }
    
    if (self.failedBlock) {
        self.failedBlock(error);
    }
    
    [self cleanup];
}

/**
 * 广告即将展示
 */
- (void)splashAdWillShow:(BUSplashAd *)splashAd {
    NSLog(@"[穿山甲] 开屏广告即将展示");
}

/**
 * 广告已展示
 */
- (void)splashAdDidShow:(BUSplashAd *)splashAd {
    NSLog(@"[穿山甲] 开屏广告已展示");
}

/**
 * 广告点击
 */
- (void)splashAdDidClick:(BUSplashAd *)splashAd {
    NSLog(@"[穿山甲] 开屏广告被点击");
}

/**
 * 广告关闭
 */
- (void)splashAdDidClose:(BUSplashAd *)splashAd closeType:(BUSplashAdCloseType)closeType {
    NSLog(@"[穿山甲] 开屏广告关闭，类型: %ld", (long)closeType);
    
    if (self.closedBlock) {
        self.closedBlock();
    }
    
    [self cleanup];
}

/**
 * 广告倒计时结束
 */
- (void)splashAdCountdownToZero:(BUSplashAd *)splashAd {
    NSLog(@"[穿山甲] 开屏广告倒计时结束");
}

#pragma mark - Private Methods

- (void)cleanup {
    self.splashAd = nil;
    self.loadedBlock = nil;
    self.closedBlock = nil;
    self.failedBlock = nil;
    self.adWindow = nil;
}

#endif

@end

