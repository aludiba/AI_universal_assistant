//
//  AIUASplashAdManager.h
//  AIUniversalAssistant
//
//  Created by AI Assistant on 2025/11/9.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 开屏广告加载完成回调
typedef void(^AIUASplashAdLoadedBlock)(void);

/// 开屏广告关闭回调
typedef void(^AIUASplashAdClosedBlock)(void);

/// 开屏广告失败回调
typedef void(^AIUASplashAdFailedBlock)(NSError * _Nullable error);

/**
 * 穿山甲开屏广告管理器
 * 负责加载和展示开屏广告
 */
@interface AIUASplashAdManager : NSObject

/// 单例
+ (instancetype)sharedManager;

/**
 * 加载并展示开屏广告
 * @param window 展示广告的窗口
 * @param loadedBlock 广告加载成功回调
 * @param closedBlock 广告关闭回调
 * @param failedBlock 广告加载失败回调
 */
- (void)loadAndShowSplashAdInWindow:(UIWindow *)window
                             loaded:(nullable AIUASplashAdLoadedBlock)loadedBlock
                             closed:(nullable AIUASplashAdClosedBlock)closedBlock
                             failed:(nullable AIUASplashAdFailedBlock)failedBlock;

/**
 * 取消开屏广告加载
 */
- (void)cancelSplashAd;

@end

NS_ASSUME_NONNULL_END

