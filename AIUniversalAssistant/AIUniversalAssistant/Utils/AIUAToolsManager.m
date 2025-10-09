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

+ (UIViewController *)getTopViewController {
    UIWindow *keyWindow = [self currentWindow];
    UIViewController *rootVC = keyWindow.rootViewController;
    UIViewController *presentingVC = rootVC;

    // 递归查找最顶层的 presentedViewController
    while (presentingVC.presentedViewController) {
        presentingVC = presentingVC.presentedViewController;
    }
    return presentingVC;
}

@end
