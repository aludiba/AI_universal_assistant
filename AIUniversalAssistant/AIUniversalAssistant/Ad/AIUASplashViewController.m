//
//  AIUASplashViewController.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/11/20.
//

#import "AIUASplashViewController.h"
#import "AppDelegate.h"
#import "AIUAConfigID.h"
#if AIUA_AD_ENABLED && __has_include(<BUAdSDK/BUAdSDK.h>)
#import <BUAdSDK/BUAdSDK.h>
#endif
#import <Network/Network.h>

@interface AIUASplashViewController ()
#if AIUA_AD_ENABLED && __has_include(<BUAdSDK/BUAdSDK.h>)
<BUSplashAdDelegate>
#endif

#if AIUA_AD_ENABLED && __has_include(<BUAdSDK/BUAdSDK.h>)
@property (nonatomic, strong) BUSplashAd *splashAd;
#endif
@property (nonatomic, strong) nw_path_monitor_t monitor;
@property (nonatomic, assign) BOOL hasLoaded;
@property (nonatomic, assign) BOOL networkTimeoutFired;
@property (nonatomic, assign) BOOL hasEnteredMainUI;
@property (nonatomic, assign) NSInteger adLoadRetryCount;

@end

@implementation AIUASplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.hasLoaded = NO;
    self.hasEnteredMainUI = NO;
    self.adLoadRetryCount = 0;
    [self setupNetworkMonitor];
}

- (void)setupNetworkMonitor {
    self.monitor = nw_path_monitor_create();
    nw_path_monitor_set_queue(self.monitor, dispatch_get_main_queue());
    self.networkTimeoutFired = NO;
    
    __weak typeof(self) weakSelf = self;
    nw_path_monitor_set_update_handler(self.monitor, ^(nw_path_t  _Nonnull path) {
        nw_path_status_t status = nw_path_get_status(path);
        if (status == nw_path_status_satisfied) {
            NSLog(@"[穿山甲][Splash] 网络状态可用，开始加载开屏广告");
            weakSelf.networkTimeoutFired = NO;
            [weakSelf loadInitialPage];
        } else {
            NSLog(@"[穿山甲][Splash] 网络状态不可用，等待用户授权网络（最长 %d 秒）", 20);
        }
    });
    
    nw_path_monitor_start(self.monitor);
    
    // 首次安装时 iOS 会弹出网络授权弹窗，用户需要时间操作；
    // 给足 20 秒等待用户选择网络权限 + 广告重试，超时后再跳过
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!weakSelf.hasEnteredMainUI) {
            weakSelf.networkTimeoutFired = YES;
            NSLog(@"[穿山甲][Splash] 等待网络超时（20秒），跳过开屏广告进入主界面");
            [weakSelf enterMainUI];
        }
    });
}

- (void)loadInitialPage {
    if (self.hasLoaded) {
        return;
    }
    self.hasLoaded = YES;
    
    // 停止网络监听
    if (self.monitor) {
        nw_path_monitor_cancel(self.monitor);
        self.monitor = nil;
    }
    
    [self buildAd];
    [self loadAdData];
}

// 创建广告对象
- (void)buildAd {
#if AIUA_AD_ENABLED && __has_include(<BUAdSDK/BUAdSDK.h>)
    NSString *slotID = AIUA_SPLASH_AD_SLOT_ID;
    if (!slotID || slotID.length == 0) {
        [self enterMainUI];
        return;
    }
    
    self.splashAd = [[BUSplashAd alloc] initWithSlotID:slotID adSize:[UIScreen mainScreen].bounds.size];
    self.splashAd.delegate = self;
    self.splashAd.tolerateTimeout = 10.0;
#else
    [self enterMainUI];
#endif
}

// 触发广告加载
- (void)loadAdData {
#if AIUA_AD_ENABLED && __has_include(<BUAdSDK/BUAdSDK.h>)
    [self.splashAd loadAdData];
#else
    [self enterMainUI];
#endif
}

- (void)enterMainUI {
    if (self.hasEnteredMainUI) return;
    self.hasEnteredMainUI = YES;
    
    if (self.monitor) {
        nw_path_monitor_cancel(self.monitor);
        self.monitor = nil;
    }
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate respondsToSelector:@selector(enterMainUI)]) {
        [appDelegate enterMainUI];
    }
}

#pragma mark - BUSplashAdDelegate

#if AIUA_AD_ENABLED && __has_include(<BUAdSDK/BUAdSDK.h>)
- (void)splashAdLoadSuccess:(nonnull BUSplashAd *)splashAd {
    NSLog(@"[穿山甲] 开屏广告加载成功");
    // 在当前VC上显示
    [splashAd showSplashViewInRootViewController:self];
}

- (void)splashAdLoadFail:(BUSplashAd *)splashAd error:(BUAdError *)error {
    NSLog(@"❌ [穿山甲] 开屏广告加载失败（第 %ld 次）", (long)(self.adLoadRetryCount + 1));
    NSLog(@"错误码: %ld", (long)error.code);
    NSLog(@"错误描述: %@", error.localizedDescription);
    
    // 首次安装时，iOS 网络权限弹窗可能尚未消失导致第一次加载失败；
    // 最多重试 2 次，每次间隔 3 秒，给用户足够时间完成网络授权
    if (self.adLoadRetryCount < 2 && !self.hasEnteredMainUI) {
        self.adLoadRetryCount++;
        NSLog(@"[穿山甲][Splash] 将在 3 秒后重试加载开屏广告（第 %ld 次重试）", (long)self.adLoadRetryCount);
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!weakSelf.hasEnteredMainUI) {
                [weakSelf buildAd];
                [weakSelf loadAdData];
            }
        });
    } else {
        [self enterMainUI];
    }
}

// 广告点击
- (void)splashAdDidClick:(BUSplashAd *)splashAd {
    NSLog(@"[穿山甲] 开屏广告点击");
    // 点击后通常需要关闭广告并进入主页，或者SDK会自动处理关闭
    // 点击广告后，SDK会处理跳转，回来时会回调 close
}

// 广告播放控制器关闭(跳过或者播放完成)
- (void)splashAdViewControllerDidClose:(BUSplashAd *)splashAd {
    NSLog(@"[穿山甲] 开屏广告关闭");
    [self enterMainUI];
}

// 倒计时归零
- (void)splashAdCountdownToZero:(BUSplashAd *)splashAd {
    NSLog(@"[穿山甲] 开屏广告倒计时结束");
    // 通常倒计时结束会自动关闭或用户手动关闭
}
#endif

@end
