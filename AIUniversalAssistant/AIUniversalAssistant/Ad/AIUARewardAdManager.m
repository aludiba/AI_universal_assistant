//
//  AIUARewardAdManager.m
//  AIUniversalAssistant
//

#import "AIUARewardAdManager.h"
#import "AIUAConfigID.h"

#if AIUA_AD_ENABLED && __has_include(<BUAdSDK/BUAdSDK.h>)
#import <BUAdSDK/BUAdSDK.h>
#endif

static NSError *AIUAFindUnderlyingNetworkError(NSError *error) {
    if (!error) {
        return nil;
    }
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        switch (error.code) {
            case NSURLErrorNotConnectedToInternet:
            case NSURLErrorNetworkConnectionLost:
            case NSURLErrorTimedOut:
            case NSURLErrorCannotFindHost:
            case NSURLErrorCannotConnectToHost:
            case NSURLErrorDNSLookupFailed:
                return error;
            default:
                break;
        }
    }
    NSError *underlying = error.userInfo[NSUnderlyingErrorKey];
    if ([underlying isKindOfClass:[NSError class]]) {
        return AIUAFindUnderlyingNetworkError(underlying);
    }
    return nil;
}

static NSString *AIUAReadableRewardErrorMessage(NSError *error) {
    NSError *networkError = AIUAFindUnderlyingNetworkError(error) ?: ([error.domain isEqualToString:NSURLErrorDomain] ? error : nil);
    if (networkError) {
        return @"当前网络不可用，广告请求被拦截。请检查网络连接，或关闭/调整 VPN、代理后重试。";
    }
    
    NSString *desc = error.localizedDescription ?: @"加载失败";
    NSString *lowerDesc = desc.lowercaseString;
    if ([lowerDesc containsString:@"data analysis error"] || [lowerDesc containsString:@"parse"]) {
        return @"广告数据解析失败，请确认代码位已生效，并检查网络是否可访问穿山甲广告服务。";
    }
    return desc;
}

static void AIUALogRewardError(NSError *error) {
    if (!error) {
        return;
    }
    NSLog(@"❌ [穿山甲][Reward] 加载失败 - domain=%@, code=%ld, desc=%@", error.domain, (long)error.code, error.localizedDescription);
    NSError *underlying = error.userInfo[NSUnderlyingErrorKey];
    NSInteger level = 1;
    while ([underlying isKindOfClass:[NSError class]] && level <= 3) {
        NSLog(@"   ↳ underlying[%ld] domain=%@, code=%ld, desc=%@", (long)level, underlying.domain, (long)underlying.code, underlying.localizedDescription);
        underlying = underlying.userInfo[NSUnderlyingErrorKey];
        level += 1;
    }
}

@interface AIUARewardAdManager ()

@property (nonatomic, weak) UIViewController *presentingVC;
@property (nonatomic, copy) AIUARewardAdLoaded onLoaded;
@property (nonatomic, copy) AIUARewardAdEarnedReward onEarned;
@property (nonatomic, copy) AIUARewardAdClosed onClosed;
@property (nonatomic, copy) AIUARewardAdFailed onFailed;

#if AIUA_AD_ENABLED && __has_include(<BUAdSDK/BUAdSDK.h>)
@property (nonatomic, strong) BUNativeExpressRewardedVideoAd *rewardAd;
#endif

@end

@implementation AIUARewardAdManager

+ (instancetype)sharedManager {
    static AIUARewardAdManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AIUARewardAdManager alloc] init];
    });
    return instance;
}

- (void)cleanup {
#if AIUA_AD_ENABLED && __has_include(<BUAdSDK/BUAdSDK.h>)
    self.rewardAd.delegate = nil;
    self.rewardAd = nil;
#endif
    self.presentingVC = nil;
    self.onLoaded = nil;
    self.onEarned = nil;
    self.onClosed = nil;
    self.onFailed = nil;
}

- (void)loadAndShowFromViewController:(UIViewController *)viewController
                               loaded:(AIUARewardAdLoaded)loaded
                         earnedReward:(AIUARewardAdEarnedReward)earnedReward
                               closed:(AIUARewardAdClosed)closed
                               failed:(AIUARewardAdFailed)failed {
    self.presentingVC = viewController;
    self.onLoaded = loaded;
    self.onEarned = earnedReward;
    self.onClosed = closed;
    self.onFailed = failed;

#if !AIUA_AD_ENABLED
    if (self.onFailed) {
        NSError *e = [NSError errorWithDomain:@"AIUAReward" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"广告已关闭"}];
        self.onFailed(e);
    }
    [self cleanup];
    return;
#endif

#if AIUA_AD_ENABLED && __has_include(<BUAdSDK/BUAdSDK.h>)
    if (AIUA_APPID.length == 0) {
        if (self.onFailed) {
            NSError *e = [NSError errorWithDomain:@"AIUAReward" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"未配置穿山甲AppID"}];
            self.onFailed(e);
        }
        [self cleanup];
        return;
    }
    if (AIUA_REWARD_AD_SLOT_ID.length == 0) {
        if (self.onFailed) {
            NSError *e = [NSError errorWithDomain:@"AIUAReward" code:-3 userInfo:@{NSLocalizedDescriptionKey: @"未配置激励视频代码位"}];
            self.onFailed(e);
        }
        [self cleanup];
        return;
    }
    
    NSLog(@"[穿山甲][Reward] 开始加载激励视频，AppID=%@, SlotID=%@", AIUA_APPID, AIUA_REWARD_AD_SLOT_ID);

    BURewardedVideoModel *model = [[BURewardedVideoModel alloc] init];
    model.userId = @"aiua_user"; // 可按需设置

    self.rewardAd = [[BUNativeExpressRewardedVideoAd alloc] initWithSlotID:AIUA_REWARD_AD_SLOT_ID rewardedVideoModel:model];
    self.rewardAd.delegate = self;
    [self.rewardAd loadAdData];
#else
    if (self.onFailed) {
        NSError *e = [NSError errorWithDomain:@"AIUAReward" code:-4 userInfo:@{NSLocalizedDescriptionKey: @"未集成BUAdSDK"}];
        self.onFailed(e);
    }
    [self cleanup];
#endif
}

#if AIUA_AD_ENABLED && __has_include(<BUAdSDK/BUAdSDK.h>)
#pragma mark - BUNativeExpressRewardedVideoAdDelegate

- (void)nativeExpressRewardedVideoAdDidLoad:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    NSLog(@"[穿山甲][Reward] 激励视频素材加载完成");
    if (self.onLoaded) self.onLoaded();
}

- (void)nativeExpressRewardedVideoAdDidDownLoadVideo:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    NSLog(@"[穿山甲][Reward] 激励视频缓存完成，准备展示");
    if (self.presentingVC && self.rewardAd) {
        [self.rewardAd showAdFromRootViewController:self.presentingVC];
    }
}

- (void)nativeExpressRewardedVideoAdDidVisible:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {}
- (void)nativeExpressRewardedVideoAdDidClick:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {}

- (void)nativeExpressRewardedVideoAdDidClose:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    NSLog(@"[穿山甲][Reward] 激励视频已关闭");
    if (self.onClosed) self.onClosed();
    [self cleanup];
}

- (void)nativeExpressRewardedVideoAd:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
    NSError *rawError = error ?: [NSError errorWithDomain:@"AIUAReward" code:-5 userInfo:@{NSLocalizedDescriptionKey: @"未知错误"}];
    AIUALogRewardError(rawError);
    
    NSError *finalError = rawError;
    NSString *message = AIUAReadableRewardErrorMessage(rawError);
    if (message.length > 0 && ![message isEqualToString:rawError.localizedDescription]) {
        NSMutableDictionary *userInfo = [rawError.userInfo mutableCopy] ?: [NSMutableDictionary dictionary];
        userInfo[NSLocalizedDescriptionKey] = message;
        finalError = [NSError errorWithDomain:rawError.domain code:rawError.code userInfo:userInfo];
    }
    if (self.onFailed) self.onFailed(finalError);
    [self cleanup];
}

- (void)nativeExpressRewardedVideoAdServerRewardDidSucceed:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd verify:(BOOL)verify {
    NSLog(@"[穿山甲][Reward] 服务端奖励校验回调，verify=%d", verify);
    if (verify && self.onEarned) self.onEarned();
}

- (void)nativeExpressRewardedVideoAdDidPlayFinish:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
    // 播放结束，不一定代表奖励，奖励以回调为准
}
#endif

@end
