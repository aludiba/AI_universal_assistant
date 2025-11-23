//
//  AIUASettingsViewController.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/3/25.
//

#import "AIUASettingsViewController.h"
#import "AIUASettingsCell.h"
#import "AIUAWritingRecordsViewController.h"
#import "AIUAAboutViewController.h"
#import "AIUAMembershipViewController.h"
#import "AIUAWordPackViewController.h"
#import "AIUAIAPManager.h"
#import "AIUADataManager.h"
#import <Masonry/Masonry.h>
#import <StoreKit/StoreKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "AIUAWordPackManager.h"
#import "AIUARewardAdManager.h"

@interface AIUASettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *settingsData;
@property (nonatomic, strong) UIView *headerView;

@end

@implementation AIUASettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 监听订阅状态变化
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(subscriptionStatusChanged:)
                                                 name:@"AIUASubscriptionStatusChanged"
                                               object:nil];
    
    // 监听缓存清理完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cacheCleared:)
                                                 name:AIUACacheClearedNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 每次显示时刷新缓存大小
    [self updateCacheSizeDisplay];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupUI {
    self.navigationItem.title = L(@"tab_settings");
    [self setupTableView];
    [self setupData];
}

- (void)subscriptionStatusChanged:(NSNotification *)notification {
    // 订阅状态改变，刷新会员特权行
    // 同步更新数据源中的副标题，避免出现先空后刷新的延迟感
    if (self.settingsData.count > 0) {
        NSMutableArray *mutable = [self.settingsData mutableCopy];
        NSMutableDictionary *first = [mutable[0] mutableCopy];
        first[@"subtitle"] = [self getMembershipStatusText];
        mutable[0] = first;
        self.settingsData = [mutable copy];
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)cacheCleared:(NSNotification *)notification {
    // 缓存清理完成，刷新缓存大小显示
    [self updateCacheSizeDisplay];
}

#pragma mark - VIP Gate
- (BOOL)ensureVIPOrPrompt {
    BOOL isVIP = [[AIUAIAPManager sharedManager] isVIPMember];
    if (!isVIP) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:L(@"vip_unlock_required")
                                                                       message:L(@"vip_general_locked_message")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *go = [UIAlertAction actionWithTitle:L(@"activate_now") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showMemberPrivileges];
        }];
        [alert addAction:cancel];
        [alert addAction:go];
        [self presentViewController:alert animated:YES completion:nil];
    }
    return isVIP;
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.showsVerticalScrollIndicator = NO;
    [self.tableView registerClass:[AIUASettingsCell class] forCellReuseIdentifier:@"AIUASettingsCell"];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.right.bottom.equalTo(self.view);
    }];
}

- (void)setupData {
    // 预计算会员状态文案，避免Cell里二次计算导致的视觉延迟
    NSString *memberSubtitle = [self getMembershipStatusText];
    self.settingsData = @[
        @{@"title": L(@"member_privileges"), @"icon": @"crown.fill", @"color": @"#FFD700", @"action": @"memberPrivileges", @"subtitle": memberSubtitle ?: @""},
        @{@"title": L(@"creation_records"), @"icon": @"doc.text.fill", @"color": @"#3B82F6", @"action": @"creationRecords"},
        @{@"title": L(@"writing_word_packs"), @"icon": @"cube.fill", @"color": @"#10B981", @"action": @"wordPacks"},
        @{@"title": L(@"clear_cache"), @"icon": @"trash.fill", @"color": @"#F97316", @"action": @"clearCache"},
        @{@"title": L(@"rate_app"), @"icon": @"star.fill", @"color": @"#EF4444", @"action": @"rateApp"},
        @{@"title": L(@"share_app"), @"icon": @"square.and.arrow.up.fill", @"color": @"#06B6D4", @"action": @"shareApp"},
        @{@"title": L(@"watch_reward_title"), @"icon": @"play.rectangle.on.rectangle.fill", @"color": @"#22C55E", @"action": @"watchReward"},
        @{@"title": L(@"contact_us"), @"icon": @"envelope.fill", @"color": @"#F59E0B", @"action": @"contactUs"},
        @{@"title": L(@"about_us"), @"icon": @"info.circle.fill", @"color": @"#8B5CF6", @"action": @"aboutUs"}
    ];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.settingsData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AIUASettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AIUASettingsCell" forIndexPath:indexPath];
    
    NSDictionary *item = self.settingsData[indexPath.row];
    NSString *iconName = item[@"icon"];
    NSString *colorHex = item[@"color"];
    NSString *title = item[@"title"];
    NSString *action = item[@"action"];
    
    // 创建带颜色背景的图标
    UIImage *icon = [self createIconWithSystemName:iconName color:[self colorFromHex:colorHex]];
    
    // 为会员特权和清理缓存添加状态信息
    NSString *subtitle = item[@"subtitle"]; // 优先使用预计算的，避免刷新延迟
    if ([action isEqualToString:@"memberPrivileges"]) {
        // 如果未预置，兜底计算一次
        if (subtitle.length == 0) subtitle = [self getMembershipStatusText];
    } else if ([action isEqualToString:@"clearCache"]) {
        subtitle = [self getCacheSizeText];
    } else if ([action isEqualToString:@"watchReward"]) {
        // 展示今日已观看次数
        NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"yyyy-MM-dd";
        NSString *today = [fmt stringFromDate:[NSDate date]];
        NSString *savedDate = [ud stringForKey:@"AIUARewardWatchDate"];
        NSInteger count = [ud integerForKey:@"AIUARewardWatchCount"];
        if (savedDate == nil || ![savedDate isEqualToString:today]) {
            count = 0;
        }
        subtitle = [NSString stringWithFormat:L(@"watch_reward_progress"), (long)count, (long)4];
    }
    
    [cell configureWithIcon:icon title:title subtitle:subtitle];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *item = self.settingsData[indexPath.row];
    NSString *action = item[@"action"];
    
    if ([action isEqualToString:@"memberPrivileges"]) {
        [self showMemberPrivileges];
    } else if ([action isEqualToString:@"creationRecords"]) {
        [self showCreationRecords];
    } else if ([action isEqualToString:@"wordPacks"]) {
        if (![self ensureVIPOrPrompt]) return; // 非VIP禁止进入
        [self showWordPacks];
    } else if ([action isEqualToString:@"clearCache"]) {
        [self showClearCacheAlert];
    } else if ([action isEqualToString:@"rateApp"]) {
        [self rateApp];
    } else if ([action isEqualToString:@"shareApp"]) {
        [self shareApp];
    } else if ([action isEqualToString:@"watchReward"]) {
        if (![self ensureVIPOrPrompt]) return; // 非VIP禁止观看
        [self watchReward];
    } else if ([action isEqualToString:@"contactUs"]) {
        [self showContactUs];
    } else if ([action isEqualToString:@"aboutUs"]) {
        [self showAboutUs];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72;
}

#pragma mark - Actions

- (void)showMemberPrivileges {
    AIUAMembershipViewController *vc = [[AIUAMembershipViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (NSString *)getMembershipStatusText {
    AIUAIAPManager *iapManager = [AIUAIAPManager sharedManager];
    
    if (!iapManager.isVIPMember) {
        return L(@"not_vip_member");
    }
    
    // 获取订阅类型
    NSString *subscriptionType = [iapManager productNameForType:iapManager.currentSubscriptionType];
    
    // 获取到期时间
    if (iapManager.subscriptionExpiryDate) {
        // 如果是永久会员（到期时间>50年），显示"永久会员"
        NSTimeInterval timeInterval = [iapManager.subscriptionExpiryDate timeIntervalSinceNow];
        if (timeInterval > 50 * 365 * 24 * 60 * 60) {
            return [NSString stringWithFormat:@"%@ - %@", subscriptionType, L(@"lifetime")];
        }
        
        // 显示到期时间
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd";
        NSString *expiryDateString = [formatter stringFromDate:iapManager.subscriptionExpiryDate];
        return [NSString stringWithFormat:@"%@ - %@ %@", subscriptionType, L(@"expires_on"), expiryDateString];
    }
    
    return subscriptionType;
}

- (void)showCreationRecords {
    AIUAWritingRecordsViewController *vc = [[AIUAWritingRecordsViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    vc.isAllRecords = YES; // 显示所有创作记录
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showWordPacks {
    AIUAWordPackViewController *vc = [[AIUAWordPackViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showContactUs {
    // TODO: 实现联系我们页面
    NSLog(@"显示联系我们");
}

- (void)showAboutUs {
    AIUAAboutViewController *vc = [[AIUAAboutViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - 激励视频（每日4次，每次+5万字）

- (void)watchReward {
    // VIP 门禁
    if (![[AIUAIAPManager sharedManager] isVIPMember]) {
        [self showAlertWithTitle:L(@"vip_unlock_required") message:L(@"vip_general_locked_message")];
        return;
    }
    NSInteger dailyLimit = 4;
    NSString *dateKey = @"AIUARewardWatchDate";
    NSString *countKey = @"AIUARewardWatchCount";
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd";
    NSString *today = [fmt stringFromDate:[NSDate date]];
    
    NSString *savedDate = [ud stringForKey:dateKey];
    NSInteger count = [ud integerForKey:countKey];
    if (savedDate == nil || ![savedDate isEqualToString:today]) {
        savedDate = today;
        count = 0;
        [ud setObject:savedDate forKey:dateKey];
        [ud setInteger:count forKey:countKey];
        [ud synchronize];
    }
    if (count >= dailyLimit) {
        [self showAlertWithTitle:L(@"limit_reached_title") message:L(@"reward_daily_limit_reached")];
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    __weak typeof(self) weakSelf = self;
    [[AIUARewardAdManager sharedManager] loadAndShowFromViewController:self loaded:^{
        NSLog(@"[Reward] 激励视频已加载");
    } earnedReward:^{
        // 发放5万字（90天有效）
        [[AIUAWordPackManager sharedManager] awardBonusWords:50000 validDays:90 completion:^{
            // 刷新显示
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        }];
        NSInteger newCount = count + 1;
        [ud setObject:today forKey:dateKey];
        [ud setInteger:newCount forKey:countKey];
        [ud synchronize];
        NSLog(@"[Reward] 已发放50000字，今日第 %ld 次", (long)newCount);
    } closed:^{
        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
        // 刷新该行显示今日次数
        [weakSelf.tableView reloadData];
    } failed:^(NSError *error) {
        [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
        [weakSelf showAlertWithTitle:L(@"reward_failed_title") message:error.localizedDescription ?: @"加载失败"];
    }];
}

#pragma mark - 清理缓存

- (NSString *)getCacheSizeText {
    AIUADataManager *dataManager = [AIUADataManager sharedManager];
    unsigned long long cacheSize = [dataManager calculateCacheSize];
    NSString *formattedSize = [dataManager formatCacheSize:cacheSize];
    return formattedSize;
}

- (void)updateCacheSizeDisplay {
    // 找到清理缓存行的索引
    NSInteger cacheIndex = -1;
    for (NSInteger i = 0; i < self.settingsData.count; i++) {
        NSDictionary *item = self.settingsData[i];
        if ([item[@"action"] isEqualToString:@"clearCache"]) {
            cacheIndex = i;
            break;
        }
    }
    
    if (cacheIndex >= 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:cacheIndex inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)showClearCacheAlert {
    AIUADataManager *dataManager = [AIUADataManager sharedManager];
    unsigned long long cacheSize = [dataManager calculateCacheSize];
    NSString *formattedSize = [dataManager formatCacheSize:cacheSize];
    
    // 如果缓存为0，显示提示
    if (cacheSize == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:L(@"prompt")
                                                                       message:L(@"cache_already_empty")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:L(@"confirm")
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    NSString *message = [NSString stringWithFormat:L(@"clear_cache_message"), formattedSize];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:L(@"clear_cache")
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:L(@"cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:L(@"confirm")
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * _Nonnull action) {
        [self performClearCache];
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:confirmAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performClearCache {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = L(@"clearing_cache");
    hud.mode = MBProgressHUDModeIndeterminate;
    
    [[AIUADataManager sharedManager] clearCacheWithCompletion:^(BOOL success, NSString * _Nullable errorMessage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            
            if (success) {
                // 显示成功提示
                MBProgressHUD *successHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                successHud.mode = MBProgressHUDModeText;
                successHud.label.text = L(@"cache_cleared_success");
                successHud.label.numberOfLines = 0;
                [successHud hideAnimated:YES afterDelay:1.5];
                
                // 刷新缓存大小显示
                [self updateCacheSizeDisplay];
            } else {
                // 显示错误提示
                [self showAlertWithTitle:L(@"error") message:errorMessage ?: L(@"cache_clear_failed")];
            }
        });
    }];
}

#pragma mark - 评分和分享

/**
 * 前往App Store评分
 */
- (void)rateApp {
    NSLog(@"[设置] 用户点击前往评分");
    
    // 方法1: iOS 10.3+ 使用SKStoreReviewController（推荐）
    if (@available(iOS 10.3, *)) {
        // 使用系统原生评分弹窗（每年限制3次）
        [SKStoreReviewController requestReview];
        NSLog(@"[设置] 调用系统评分弹窗");
    } else {
        // 方法2: 跳转到App Store评分页面
        [self openAppStoreRatingPage];
    }
    
    // 可选：延迟1秒后打开App Store评分页面（作为补充）
    // 如果用户没有在系统弹窗中评分，可以引导去App Store
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 可以在这里添加一个确认对话框，询问用户是否要去App Store评分
    });
}

/**
 * 打开App Store评分页面
 */
- (void)openAppStoreRatingPage {
    // 获取App Store ID（需要在上架后获得）
    NSString *appID = @"YOUR_APP_STORE_ID"; // TODO: 替换为实际的App Store ID
    
    // 方法1: iOS 11+ 使用新的URL格式
    NSString *urlString = [NSString stringWithFormat:@"https://apps.apple.com/app/id%@?action=write-review", appID];
    NSURL *url = [NSURL URLWithString:urlString];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            if (success) {
                NSLog(@"[设置] 成功打开App Store评分页面");
            } else {
                NSLog(@"[设置] 打开App Store评分页面失败");
            }
        }];
    } else {
        NSLog(@"[设置] 无法打开App Store URL");
        // 显示提示
        [self showAlertWithTitle:L(@"prompt") message:L(@"cannot_open_app_store")];
    }
}

/**
 * 分享APP
 */
- (void)shareApp {
    NSLog(@"[设置] 用户点击分享APP");
    
    // 准备分享内容
    NSString *appName = @"AI写作喵";
    NSString *appDescription = L(@"share_app_description"); // "一款强大的AI写作助手，帮你轻松完成各种写作任务"
    
    // App Store链接（上架后替换为实际链接）
    NSString *appStoreURL = @"https://apps.apple.com/app/YOUR_APP_STORE_ID"; // TODO: 替换为实际的App Store链接
    
    // 分享文本
    NSString *shareText = [NSString stringWithFormat:@"%@\n\n%@\n\n%@", appName, appDescription, appStoreURL];
    
    // 可选：添加应用图标
    UIImage *appIcon = [UIImage imageNamed:@"AppIcon"]; // 如果需要分享图标
    
    // 创建分享内容数组
    NSMutableArray *activityItems = [NSMutableArray array];
    [activityItems addObject:shareText];
    if (appIcon) {
        [activityItems addObject:appIcon];
    }
    
    // 创建分享控制器
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    // 排除某些分享选项（可选）
    activityVC.excludedActivityTypes = @[
        UIActivityTypeAssignToContact,
        UIActivityTypePrint,
        UIActivityTypeOpenInIBooks,
        UIActivityTypeMarkupAsPDF
    ];
    
    // iPad需要设置popover
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        activityVC.popoverPresentationController.sourceView = self.view;
        activityVC.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 0, 0);
    }
    
    // 分享完成回调
    activityVC.completionWithItemsHandler = ^(UIActivityType activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        if (completed) {
            NSLog(@"[设置] 分享成功: %@", activityType);
            // 可以在这里添加分享成功的统计或奖励
        } else {
            NSLog(@"[设置] 分享取消或失败");
        }
    };
    
    // 显示分享界面
    [self presentViewController:activityVC animated:YES completion:nil];
}

/**
 * 显示提示框
 */
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:L(@"confirm")
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (UIImage *)createIconWithSystemName:(NSString *)systemName color:(UIColor *)color {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, [UIScreen mainScreen].scale);
    
    // 绘制背景
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 36, 36) cornerRadius:8];
    [color setFill];
    [path fill];
    
    // 绘制图标
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
    UIImage *icon = [UIImage systemImageNamed:systemName withConfiguration:config];
    UIImage *whiteIcon = [icon imageWithTintColor:[UIColor whiteColor] renderingMode:UIImageRenderingModeAlwaysOriginal];
    [whiteIcon drawInRect:CGRectMake(9, 9, 18, 18)];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIColor *)colorFromHex:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""]];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0
                           green:((rgbValue & 0xFF00) >> 8)/255.0
                            blue:(rgbValue & 0xFF)/255.0
                           alpha:1.0];
}

@end
