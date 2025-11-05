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
#import "AIUAIAPManager.h"
#import <Masonry/Masonry.h>

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
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
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
    self.settingsData = @[
        @{@"title": L(@"member_privileges"), @"icon": @"crown.fill", @"color": @"#FFD700", @"action": @"memberPrivileges"},
        @{@"title": L(@"creation_records"), @"icon": @"doc.text.fill", @"color": @"#3B82F6", @"action": @"creationRecords"},
        @{@"title": L(@"writing_word_packs"), @"icon": @"cube.fill", @"color": @"#10B981", @"action": @"wordPacks"},
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
    
    // 为会员特权添加状态信息
    NSString *subtitle = nil;
    if ([action isEqualToString:@"memberPrivileges"]) {
        subtitle = [self getMembershipStatusText];
    }
    
    [cell configureWithIcon:icon title:title subtitle:subtitle];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.settingsData[indexPath.row];
    NSString *action = item[@"action"];
    
    if ([action isEqualToString:@"memberPrivileges"]) {
        [self showMemberPrivileges];
    } else if ([action isEqualToString:@"creationRecords"]) {
        [self showCreationRecords];
    } else if ([action isEqualToString:@"wordPacks"]) {
        [self showWordPacks];
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
    // TODO: 实现创作字数包页面
    NSLog(@"显示创作字数包");
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
