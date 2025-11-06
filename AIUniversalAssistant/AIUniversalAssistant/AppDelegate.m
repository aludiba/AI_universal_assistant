//
//  AppDelegate.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/9/30.
//

#import "AppDelegate.h"
#import "AIUATabBarController.h"
#import "AIUAIAPManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 越狱检测
    if ([AIUAIAPManager isJailbroken]) {
        NSLog(@"[Security] 检测到越狱设备，应用将退出");
        
        // 显示提示后退出
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:L(@"security_alert")
                                                                        message:L(@"jailbreak_detected_message")
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *exitAction = [UIAlertAction actionWithTitle:L(@"confirm")
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
            exit(0);
        }];
        
        [alert addAction:exitAction];
        
        // 创建临时窗口显示警告
        self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.window.rootViewController = [[UIViewController alloc] init];
        [self.window makeKeyAndVisible];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        
        return YES;
    }
    
    // 初始化 IAP 管理器
    [[AIUAIAPManager sharedManager] startObservingPaymentQueue];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[AIUATabBarController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // 这会从本地收据中提取订阅信息，即使用户重新下载或更换设备
    [[AIUAIAPManager sharedManager] checkSubscriptionStatus];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskPortrait;
}



@end
