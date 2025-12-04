//
//  AIUAToolsManager.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/10/9.
//

#import "AIUAToolsManager.h"
#import <StoreKit/StoreKit.h>

// 评分相关的UserDefaults键
static NSString * const kAppLaunchCountKey = @"AIUAAppLaunchCount";
static NSString * const kAppUsageCountKey = @"AIUAAppUsageCount";
static NSString * const kLastRatingPromptDateKey = @"AIUALastRatingPromptDate";
static NSString * const kUserHasRatedKey = @"AIUAUserHasRated";
static NSString * const kUserDeclinedRatingKey = @"AIUAUserDeclinedRating";

@implementation AIUAToolsManager

+ (UIViewController *)topViewController {
    UIViewController *rootVC = [self currentWindow].rootViewController;
    return [self topViewControllerFrom:rootVC];
}

+ (UIViewController *)topViewControllerFrom:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self topViewControllerFrom:((UINavigationController *)vc).visibleViewController];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self topViewControllerFrom:((UITabBarController *)vc).selectedViewController];
    } else if (vc.presentedViewController) {
        return [self topViewControllerFrom:vc.presentedViewController];
    } else {
        return vc;
    }
}

+ (NSDictionary *)serializationFromJson:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    return json;
}

+ (UIWindow *)currentWindow {
    UIWindow *window = nil;
    NSSet *scenes = UIApplication.sharedApplication.connectedScenes;
    for (UIWindowScene *scene in scenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            for (UIWindow *w in scene.windows) {
                if (w.isKeyWindow) {
                    window = w;
                    break;
                }
            }
        }
    }
    return window;
}

+ (void)goToTabBarModule:(NSUInteger)selectedIndex {
    UIViewController *topViewController = [self topViewController];
    // 跳转到写作模块
    UITabBarController *tabBarController = [topViewController tabBarController];
    
    if (!tabBarController) {
        // 如果没有 tabBarController，尝试从 appDelegate 获取
        tabBarController = (UITabBarController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    }
    
    if (tabBarController && [tabBarController isKindOfClass:[UITabBarController class]]) {
        if (tabBarController.viewControllers.count > selectedIndex) {
            // 切换到第二个 tab
            tabBarController.selectedIndex = selectedIndex;
            
            // 返回到搜索页面的根视图，这样下次进入搜索时是干净的
            if (topViewController.navigationController) {
                [topViewController.navigationController popToRootViewControllerAnimated:NO];
            }
        } else {
            NSLog(@"TabBar 没有足够的视图控制器");
        }
    } else {
        NSLog(@"未找到 TabBarController");
    }
}

+ (NSString *)removeMarkdownSymbols:(NSString *)text {
    if (!text) return @"";
    
    NSMutableString *cleanText = [text mutableCopy];
    
    // 移除粗体符号
    NSRegularExpression *boldRegex = [NSRegularExpression regularExpressionWithPattern:@"(\\*\\*|__)(.*?)\\1" options:0 error:nil];
    [boldRegex replaceMatchesInString:cleanText options:0 range:NSMakeRange(0, cleanText.length) withTemplate:@"$2"];
    
    // 移除斜体符号
    NSRegularExpression *italicRegex = [NSRegularExpression regularExpressionWithPattern:@"(\\*|_)(.*?)\\1" options:0 error:nil];
    [italicRegex replaceMatchesInString:cleanText options:0 range:NSMakeRange(0, cleanText.length) withTemplate:@"$2"];
    
    // 移除标题符号
    NSRegularExpression *headerRegex = [NSRegularExpression regularExpressionWithPattern:@"^(#{1,6})\\s+" options:NSRegularExpressionAnchorsMatchLines error:nil];
    [headerRegex replaceMatchesInString:cleanText options:0 range:NSMakeRange(0, cleanText.length) withTemplate:@""];
    
    // 移除代码符号
    NSRegularExpression *codeRegex = [NSRegularExpression regularExpressionWithPattern:@"`(.*?)`" options:0 error:nil];
    [codeRegex replaceMatchesInString:cleanText options:0 range:NSMakeRange(0, cleanText.length) withTemplate:@"$1"];
    
    // 移除链接符号
    NSRegularExpression *linkRegex = [NSRegularExpression regularExpressionWithPattern:@"\\[(.*?)\\]\\(.*?\\)" options:0 error:nil];
    [linkRegex replaceMatchesInString:cleanText options:0 range:NSMakeRange(0, cleanText.length) withTemplate:@"$1"];
    
    return [cleanText copy];
}

#pragma mark - 评分相关

/**
 * 前往App Store评分
 */
+ (void)rateApp {
    NSLog(@"[评分] 调用评分功能");
    
    // iOS 10.3+ 使用SKStoreReviewController（推荐）
    if (@available(iOS 10.3, *)) {
        // 使用系统原生评分弹窗
        [SKStoreReviewController requestReview];
        NSLog(@"[评分] 调用系统评分弹窗");
        
        // 标记用户已经看到评分弹窗
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserHasRatedKey];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastRatingPromptDateKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        // iOS 10.3以下版本，跳转到App Store评分页面
        [self openAppStoreRatingPage];
    }
}

/**
 * 打开App Store评分页面（备用方案）
 */
+ (void)openAppStoreRatingPage {
    // 获取App Store ID（需要在Info.plist或Config中配置）
    NSString *appID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AppStoreID"];
    if (!appID || [appID isEqualToString:@"YOUR_APP_STORE_ID"]) {
        NSLog(@"[评分] App Store ID未配置");
        return;
    }
    
    // iOS 11+ 使用新的URL格式
    NSString *urlString = [NSString stringWithFormat:@"https://apps.apple.com/app/id%@?action=write-review", appID];
    NSURL *url = [NSURL URLWithString:urlString];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            if (success) {
                NSLog(@"[评分] 成功打开App Store评分页面");
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserHasRatedKey];
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastRatingPromptDateKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
            } else {
                NSLog(@"[评分] 打开App Store评分页面失败");
            }
        }];
    } else {
        NSLog(@"[评分] 无法打开App Store URL");
    }
}

/**
 * 增加使用次数计数
 */
+ (void)incrementUsageCount {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger count = [defaults integerForKey:kAppUsageCountKey];
    count++;
    [defaults setInteger:count forKey:kAppUsageCountKey];
    [defaults synchronize];
    
    NSLog(@"[评分] 使用次数: %ld", (long)count);
}

/**
 * 增加启动次数计数
 */
+ (void)incrementLaunchCount {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger count = [defaults integerForKey:kAppLaunchCountKey];
    count++;
    [defaults setInteger:count forKey:kAppLaunchCountKey];
    [defaults synchronize];
    
    NSLog(@"[评分] 启动次数: %ld", (long)count);
}

/**
 * 检查是否应该显示评分提示
 * 策略：
 * 1. 用户已经评分过 - 不再提示
 * 2. 用户明确拒绝过 - 不再频繁提示（间隔30天）
 * 3. 距离上次提示少于7天 - 不提示
 * 4. 启动次数 >= 5次 且 使用次数 >= 10次 - 可以提示
 */
+ (BOOL)shouldShowRatingPrompt {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 1. 检查用户是否已评分
    if ([defaults boolForKey:kUserHasRatedKey]) {
        NSLog(@"[评分] 用户已评分，不再提示");
        return NO;
    }
    
    // 2. 检查用户是否拒绝过评分
    BOOL userDeclined = [defaults boolForKey:kUserDeclinedRatingKey];
    NSDate *lastPromptDate = [defaults objectForKey:kLastRatingPromptDateKey];
    
    if (lastPromptDate) {
        NSTimeInterval daysSinceLastPrompt = [[NSDate date] timeIntervalSinceDate:lastPromptDate] / (24 * 60 * 60);
        
        // 如果用户拒绝过，30天后再提示
        if (userDeclined && daysSinceLastPrompt < 30) {
            NSLog(@"[评分] 用户拒绝过评分，30天内不再提示");
            return NO;
        }
        
        // 普通情况下，7天内不重复提示
        if (daysSinceLastPrompt < 7) {
            NSLog(@"[评分] 距离上次提示不足7天，暂不提示");
            return NO;
        }
    }
    
    // 3. 检查启动次数和使用次数
    NSInteger launchCount = [defaults integerForKey:kAppLaunchCountKey];
    NSInteger usageCount = [defaults integerForKey:kAppUsageCountKey];
    
    // 策略：启动5次以上，且使用10次以上
    if (launchCount >= 5 && usageCount >= 10) {
        NSLog(@"[评分] 满足评分条件 - 启动次数:%ld, 使用次数:%ld", (long)launchCount, (long)usageCount);
        return YES;
    }
    
    NSLog(@"[评分] 未满足评分条件 - 启动次数:%ld, 使用次数:%ld", (long)launchCount, (long)usageCount);
    return NO;
}

/**
 * 随机弹出评分提示
 * 在适当的时机调用此方法，系统会根据策略决定是否显示评分
 */
+ (void)tryShowRandomRatingPrompt {
    // 增加使用次数
    [self incrementUsageCount];
    
    // 检查是否应该显示评分提示
    if (![self shouldShowRatingPrompt]) {
        return;
    }
    
    // 添加随机性：30%的概率显示
    NSInteger randomValue = arc4random_uniform(100);
    if (randomValue < 30) { // 30%概率
        NSLog(@"[评分] 随机触发评分提示");
        
        // 延迟1秒显示，避免打断用户操作
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self rateApp];
        });
    } else {
        NSLog(@"[评分] 未命中随机概率，本次不提示");
    }
}

/**
 * 记录用户拒绝评分
 */
+ (void)userDeclinedRating {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kUserDeclinedRatingKey];
    [defaults setObject:[NSDate date] forKey:kLastRatingPromptDateKey];
    [defaults synchronize];
    NSLog(@"[评分] 用户拒绝评分");
}

@end
