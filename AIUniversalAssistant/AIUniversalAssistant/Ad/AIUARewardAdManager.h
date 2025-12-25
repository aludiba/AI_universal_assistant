//
//  AIUARewardAdManager.h
//  AIUniversalAssistant
//
//  激励视频广告管理器（穿山甲）
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AIUAConfigID.h"

#if AIUA_AD_ENABLED && __has_include(<BUAdSDK/BUAdSDK.h>)
#import <BUAdSDK/BUAdSDK.h>
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void(^AIUARewardAdLoaded)(void);
typedef void(^AIUARewardAdEarnedReward)(void);
typedef void(^AIUARewardAdClosed)(void);
typedef void(^AIUARewardAdFailed)(NSError *error);

#if AIUA_AD_ENABLED && __has_include(<BUAdSDK/BUAdSDK.h>)
@interface AIUARewardAdManager : NSObject <BUNativeExpressRewardedVideoAdDelegate>
#else
@interface AIUARewardAdManager : NSObject
#endif

+ (instancetype)sharedManager;

// 加载并展示激励视频
- (void)loadAndShowFromViewController:(UIViewController *)viewController
                               loaded:(AIUARewardAdLoaded)loaded
                         earnedReward:(AIUARewardAdEarnedReward)earnedReward
                               closed:(AIUARewardAdClosed)closed
                               failed:(AIUARewardAdFailed)failed;

@end

NS_ASSUME_NONNULL_END
