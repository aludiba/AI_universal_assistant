//
//  AppDelegate.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/9/30.
//

#import "AppDelegate.h"
#import "AIUATabBarController.h"
#import "AIUAIAPManager.h"
#import "AIUAWordPackManager.h"
#import "AIUASplashViewController.h"
#import "AIUAToolsManager.h"

// 判断是否已接入穿山甲SDK
#if __has_include(<BUAdSDK/BUAdSDK.h>)
#import <BUAdSDK/BUAdSDK.h>
#define HAS_PANGLE_SDK 1
#else
#define HAS_PANGLE_SDK 0
#endif

@interface AppDelegate ()

@property (nonatomic, assign) BOOL splashAdShown; // 开屏广告是否已展示

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"========== 应用启动开始 ==========");
    
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
    
    NSLog(@"[启动] 越狱检测通过");
    
    // 初始化 IAP 管理器
    [[AIUAIAPManager sharedManager] startObservingPaymentQueue];
    NSLog(@"[启动] IAP管理器初始化完成");
    
    if (AIUA_AD_ENABLED) {
        // 初始化穿山甲SDK
        [self initPangleSDK];
    }
    
    // 创建主窗口
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    NSLog(@"[启动] 主窗口创建完成");
    
    // 判断是否展示开屏广告
    NSLog(@"[启动] 广告开关: %d", AIUA_AD_ENABLED);
    BOOL showAd = [self shouldShowSplashAd];
    NSLog(@"[启动] 是否应展示开屏广告: %d", showAd);
    
    if (AIUA_AD_ENABLED && showAd) {
        // 使用自定义的开屏广告控制器
        self.window.rootViewController = [[AIUASplashViewController alloc] init];
        [self.window makeKeyAndVisible];
        NSLog(@"[启动] 准备展示开屏广告 (AIUASplashViewController)");
    } else {
        // 不展示广告，直接进入主界面
        NSLog(@"[启动] 跳过广告，直接进入主界面");
        self.window.rootViewController = [[AIUATabBarController alloc] init];
        [self.window makeKeyAndVisible];
    }
    
    // 记录应用启动次数
    [AIUAToolsManager incrementLaunchCount];
    
    NSLog(@"========== 应用启动完成 ==========");
    return YES;
}

#pragma mark - 穿山甲SDK初始化

- (void)initPangleSDK {
#if HAS_PANGLE_SDK
    NSString *appID = AIUA_APPID;
    
    if (!appID || appID.length == 0) {
        NSLog(@"[穿山甲] AppID未配置，跳过SDK初始化");
        return;
    }
    
    NSLog(@"[穿山甲] 开始初始化SDK，AppID: %@", appID);
    
    // 创建配置（SDK 6.7+ 版本简化了配置，只需设置AppID）
    BUAdSDKConfiguration *configuration = [BUAdSDKConfiguration configuration];
    configuration.appID = appID;
    
    // 注意：新版本SDK已移除 appName 和 logLevel 属性
    // 如需调试日志，请在Xcode中查看控制台输出
    
    // 初始化SDK
    [BUAdSDKManager startWithAsyncCompletionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"[穿山甲] SDK初始化成功");
        } else {
            NSLog(@"[穿山甲] SDK初始化失败: %@", error.localizedDescription);
        }
    }];
#else
    NSLog(@"[穿山甲] SDK未集成，请执行 pod install 安装依赖");
#endif
}

#pragma mark - 开屏广告

- (BOOL)shouldShowSplashAd {
    // 可以根据业务需求添加条件判断
    // 例如：首次启动、距离上次展示超过一定时间等
    
    // 这里简单判断：如果配置了代码位ID，则展示
    NSString *slotID = AIUA_SPLASH_AD_SLOT_ID;
    return (slotID && slotID.length > 0);
}

- (void)enterMainUI {
    [self showMainWindow];
}

- (void)showMainWindow {
    if (self.splashAdShown) {
        return; // 避免重复展示
    }
    self.splashAdShown = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.window.rootViewController = [[AIUATabBarController alloc] init];
        [self.window makeKeyAndVisible];
        NSLog(@"[主界面] 已展示");
    });
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // 这会从本地收据中提取订阅信息，即使用户重新下载或更换设备
    [[AIUAIAPManager sharedManager] checkSubscriptionStatus];
    
    // 检查iCloud可用性并提示用户（如果需要）
    // 只在应用激活时提示一次，避免频繁打扰用户
    static BOOL hasShowniCloudAlert = NO;
    if (!hasShowniCloudAlert) {
        UIViewController *topVC = [AIUAToolsManager topViewController];
        BOOL isAvailable = [[AIUAWordPackManager sharedManager] checkiCloudAvailabilityAndPrompt:topVC showAlert:YES];
        if (!isAvailable) {
            hasShowniCloudAlert = YES;
            // 延迟重置标志，避免用户设置后无法再次提示
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(24 * 60 * 60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                hasShowniCloudAlert = NO;
            });
        }
    }
    
    // 启用iCloud同步
    [[AIUAWordPackManager sharedManager] enableiCloudSync];
    
    // 刷新VIP赠送字数
    [[AIUAWordPackManager sharedManager] refreshVIPGiftedWords];
    
    // 随机触发评分提示（在合适的时机）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [AIUAToolsManager tryShowRandomRatingPrompt];
    });
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskPortrait;
}

@end
