//
//  AIUARewardAdManager.m
//  AIUniversalAssistant
//

#import "AIUARewardAdManager.h"
#import "AIUAConfigID.h"

#if __has_include(<BUAdSDK/BUAdSDK.h>)
#import <BUAdSDK/BUAdSDK.h>
#endif

@interface AIUARewardAdManager ()

@property (nonatomic, weak) UIViewController *presentingVC;
@property (nonatomic, copy) AIUARewardAdLoaded onLoaded;
@property (nonatomic, copy) AIUARewardAdEarnedReward onEarned;
@property (nonatomic, copy) AIUARewardAdClosed onClosed;
@property (nonatomic, copy) AIUARewardAdFailed onFailed;

#if __has_include(<BUAdSDK/BUAdSDK.h>)
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
#if __has_include(<BUAdSDK/BUAdSDK.h>)
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

#if __has_include(<BUAdSDK/BUAdSDK.h>)
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

#if __has_include(<BUAdSDK/BUAdSDK.h>)
#pragma mark - BUNativeExpressRewardedVideoAdDelegate

- (void)nativeExpressRewardedVideoAdDidLoad:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    if (self.onLoaded) self.onLoaded();
}

- (void)nativeExpressRewardedVideoAdDidDownLoadVideo:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    if (self.presentingVC && self.rewardAd) {
        [self.rewardAd showAdFromRootViewController:self.presentingVC];
    }
}

- (void)nativeExpressRewardedVideoAdDidVisible:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {}
- (void)nativeExpressRewardedVideoAdDidClick:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {}

- (void)nativeExpressRewardedVideoAdDidClose:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd {
    if (self.onClosed) self.onClosed();
    [self cleanup];
}

- (void)nativeExpressRewardedVideoAd:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
    if (self.onFailed) self.onFailed(error ?: [NSError errorWithDomain:@"AIUAReward" code:-5 userInfo:@{NSLocalizedDescriptionKey: @"未知错误"}]);
    [self cleanup];
}

- (void)nativeExpressRewardedVideoAdServerRewardDidSucceed:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd verify:(BOOL)verify {
    if (verify && self.onEarned) self.onEarned();
}

- (void)nativeExpressRewardedVideoAdDidPlayFinish:(BUNativeExpressRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
    // 播放结束，不一定代表奖励，奖励以回调为准
}
#endif

@end
