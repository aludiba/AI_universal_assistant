//
//  AIUAToolsManager.h
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/10/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AIUAToolsManager : NSObject

+ (UIViewController *)topViewController;

+ (UIViewController *)topViewControllerFrom:(UIViewController *)vc;

// json格式文件序列化
+ (NSDictionary *)serializationFromJson:(NSString *)path;

+ (UIWindow *)currentWindow;

// 去TabBar的模块
+ (void)goToTabBarModule:(NSUInteger)selectedIndex;

// 移除Markdown符号的辅助方法
+ (NSString *)removeMarkdownSymbols:(NSString *)text;

#pragma mark - 评分相关

// 前往App Store评分
+ (void)rateApp;

// 随机弹出评分提示（根据使用次数智能判断）
+ (void)tryShowRandomRatingPrompt;

// 检查是否应该显示评分提示
+ (BOOL)shouldShowRatingPrompt;

// 增加应用启动次数（在AppDelegate中调用）
+ (void)incrementLaunchCount;

// 记录用户拒绝评分
+ (void)userDeclinedRating;

@end

NS_ASSUME_NONNULL_END
