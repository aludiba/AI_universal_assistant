//
//  AIUASplashViewController.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/11/20.
//

#import "AIUASplashViewController.h"
#import "AppDelegate.h"
#import "AIUAConfigID.h"
#import <BUAdSDK/BUAdSDK.h>
#import <Network/Network.h>

@interface AIUASplashViewController () <BUSplashAdDelegate>

@property (nonatomic, strong) BUSplashAd *splashAd;
@property (nonatomic, strong) nw_path_monitor_t monitor;
@property (nonatomic, assign) BOOL hasLoaded;

@end

@implementation AIUASplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.hasLoaded = NO;
    [self setupNetworkMonitor];
}

- (void)setupNetworkMonitor {
    self.monitor = nw_path_monitor_create();
    nw_path_monitor_set_queue(self.monitor, dispatch_get_main_queue());
    
    __weak typeof(self) weakSelf = self;
    nw_path_monitor_set_update_handler(self.monitor, ^(nw_path_t  _Nonnull path) {
        nw_path_status_t status = nw_path_get_status(path);
        if (status == nw_path_status_satisfied) {
            [weakSelf loadInitialPage];
        } else {
            // 网络不可用，如果需要可以弹窗提示，这里简单处理为等待或直接进入主页
            // 如果没有网络，可能会一直停留在开屏页（或者显示Alert）
            // 这里为了用户体验，如果网络不可用，延迟一小段时间后如果还没网就直接进主页
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!weakSelf.hasLoaded) {
                     [weakSelf enterMainUI];
                }
            });
        }
    });
    
    nw_path_monitor_start(self.monitor);
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
    NSString *slotID = AIUA_SPLASH_AD_SLOT_ID;
    if (!slotID || slotID.length == 0) {
        [self enterMainUI];
        return;
    }
    
    self.splashAd = [[BUSplashAd alloc] initWithSlotID:slotID adSize:[UIScreen mainScreen].bounds.size];
    self.splashAd.delegate = self;
    self.splashAd.tolerateTimeout = 10.0;
}

// 触发广告加载
- (void)loadAdData {
    [self.splashAd loadAdData];
}

- (void)enterMainUI {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate respondsToSelector:@selector(enterMainUI)]) {
        [appDelegate enterMainUI];
    }
}

#pragma mark - BUSplashAdDelegate

- (void)splashAdLoadSuccess:(nonnull BUSplashAd *)splashAd {
    NSLog(@"[穿山甲] 开屏广告加载成功");
    // 在当前VC上显示
    [splashAd showSplashViewInRootViewController:self];
}

- (void)splashAdLoadFail:(BUSplashAd *)splashAd error:(BUAdError *)error {
    NSLog(@"❌ [穿山甲] 开屏广告加载失败");
    NSLog(@"错误码: %ld", (long)error.code);
    NSLog(@"错误描述: %@", error.localizedDescription);
    [self enterMainUI];
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

@end

