//
//  AIUAToolsManager.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/10/9.
//

#import "AIUAToolsManager.h"

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

@end
