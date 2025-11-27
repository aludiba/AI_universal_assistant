//
//  AIUAMembershipViewController.m
//  AIUniversalAssistant
//
//  Created by AI Assistant on 2025/11/4.
//

#import "AIUAMembershipViewController.h"
#import "AIUAAlertHelper.h"
#import "AIUAMembershipBenefitCell.h"
#import "AIUAIAPManager.h"
#import "AIUAMBProgressManager.h"
#import "AIUATextViewController.h"
#import <Masonry/Masonry.h>

typedef NS_ENUM(NSInteger, AIUASubscriptionPlan) {
    AIUASubscriptionPlanLifetime = 0,
    AIUASubscriptionPlanYearly,
    AIUASubscriptionPlanMonthly,
    AIUASubscriptionPlanWeekly
};

typedef NS_ENUM(NSInteger, AIUAMembershipSection) {
    AIUAMembershipSectionHeader = 0,
    AIUAMembershipSectionBenefits,
    AIUAMembershipSectionCount
};

@interface AIUAMembershipViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *benefits;
@property (nonatomic, strong) NSMutableArray<UIView *> *planCards;
@property (nonatomic, assign) AIUASubscriptionPlan selectedPlan;
@property (nonatomic, strong) UIButton *agreeCheckbox;
@property (nonatomic, assign) BOOL agreedToTerms;
@property (nonatomic, strong) UIView *footerView;
@property (nonatomic, strong) NSMutableDictionary<NSString *, SKProduct *> *productsDict; // 存储产品信息，key为产品ID

@end

@implementation AIUAMembershipViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.selectedPlan = AIUASubscriptionPlanLifetime;
    self.agreedToTerms = NO;
    self.productsDict = [NSMutableDictionary dictionary];
    
    self.benefits = @[
        @{@"icon": @"square.grid.3x3.fill", @"title": L(@"unlock_templates"), @"desc": L(@"unlock_templates_desc")},
        @{@"icon": @"text.badge.plus", @"title": L(@"daily_word_quota"), @"desc": L(@"daily_word_quota_desc")},
        @{@"icon": @"wand.and.stars", @"title": L(@"ai_writing_assist"), @"desc": L(@"ai_writing_assist_desc")}
    ];
    
    // 开始监听支付队列
    [[AIUAIAPManager sharedManager] startObservingPaymentQueue];
    
    // 获取产品信息
    [self fetchProducts];
}

- (void)dealloc {
    // 停止监听支付队列
    [[AIUAIAPManager sharedManager] stopObservingPaymentQueue];
}

- (void)fetchProducts {
    [AIUAMBProgressManager showHUD:self.view];
    
    [[AIUAIAPManager sharedManager] fetchProductsWithCompletion:^(NSArray<SKProduct *> * _Nullable products, NSString * _Nullable errorMessage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [AIUAMBProgressManager hideHUD:self.view];
            
            if (products && products.count > 0) {
                NSLog(@"[IAP] 成功获取 %lu 个产品", (unsigned long)products.count);
                // 产品信息已缓存，可以在这里更新UI显示真实价格
                [self updateProductPrices:products];
            } else {
                NSLog(@"[IAP] 获取产品失败: %@", errorMessage);
                // 在测试环境下，可能无法获取产品，这里不弹错误提示
            }
        });
    }];
}

- (void)updateProductPrices:(NSArray<SKProduct *> *)products {
    // 将产品信息存储到字典中，key为产品ID
    for (SKProduct *product in products) {
        self.productsDict[product.productIdentifier] = product;
    }
    
    // 获取IAP管理器
    AIUAIAPManager *iapManager = [AIUAIAPManager sharedManager];
    
    // 更新每个卡片的价格
    for (UIView *card in self.planCards) {
        AIUASubscriptionPlan planType = (AIUASubscriptionPlan)card.tag;
        
        // 转换为IAP产品类型
        AIUASubscriptionProductType productType = [self convertToIAPProductType:planType];
        NSString *productID = [iapManager productIdentifierForType:productType];
        
        // 查找对应的产品
        SKProduct *product = self.productsDict[productID];
        if (product) {
            // 格式化价格
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            formatter.numberStyle = NSNumberFormatterCurrencyStyle;
            formatter.locale = product.priceLocale;
            NSString *formattedPrice = [formatter stringFromNumber:product.price];
            
            // 更新价格标签（tag为888表示价格标签）
            UILabel *priceLabel = [card viewWithTag:888];
            if (priceLabel) {
                priceLabel.text = formattedPrice;
            }
        }
    }
    
    NSLog(@"[Membership] 已更新产品价格，共 %lu 个产品", (unsigned long)products.count);
}


- (void)setupUI {
    [super setupUI];
    
    self.view.backgroundColor = AIUAUIColorRGB(250, 251, 252);
    
    // 导航栏
    [self setupNavigationBar];
    
    // TableView
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    [self.tableView registerClass:[AIUAMembershipBenefitCell class] forCellReuseIdentifier:@"BenefitCell"];
    [self.view addSubview:self.tableView];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // 设置footerView
    self.tableView.tableFooterView = [self createFooterView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // 更新初始选中状态
    [self updateSelectedPlanUI];
}

- (void)setupNavigationBar {
    self.navigationItem.title = L(@"activate_membership");
    
    // 恢复订阅按钮
    UIBarButtonItem *restoreButton = [[UIBarButtonItem alloc] initWithTitle:L(@"restore_subscription")
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(restoreSubscription)];
    restoreButton.tintColor = AIUAUIColorRGB(59, 130, 246);
    self.navigationItem.rightBarButtonItem = restoreButton;
}

#pragma mark - UITableView DataSource & Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return AIUAMembershipSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == AIUAMembershipSectionHeader) {
        return 0; // 使用header view
    } else if (section == AIUAMembershipSectionBenefits) {
        return self.benefits.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == AIUAMembershipSectionBenefits) {
        AIUAMembershipBenefitCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BenefitCell" forIndexPath:indexPath];
        NSDictionary *benefit = self.benefits[indexPath.row];
        [cell configureWithIcon:benefit[@"icon"] title:benefit[@"title"] desc:benefit[@"desc"]];
        return cell;
    }
    return [[UITableViewCell alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == AIUAMembershipSectionHeader) {
        return 100;
    } else if (section == AIUAMembershipSectionBenefits) {
        return 40;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == AIUAMembershipSectionHeader) {
        return [self createHeaderView];
    } else if (section == AIUAMembershipSectionBenefits) {
        return [self createBenefitsTitleView];
    }
    return nil;
}

- (UIView *)createHeaderView {
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor clearColor];
    
    // VIP标题容器
    UIView *titleContainer = [[UIView alloc] init];
    [headerView addSubview:titleContainer];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = L(@"activate_membership");
    titleLabel.font = AIUAUIFontBold(22);
    titleLabel.textColor = AIUAUIColorRGB(17, 24, 39);
    [titleContainer addSubview:titleLabel];
    
    // VIP徽章
    UIView *vipBadge = [[UIView alloc] init];
    vipBadge.backgroundColor = AIUAUIColorRGB(249, 115, 22);
    vipBadge.layer.cornerRadius = 10;
    vipBadge.layer.masksToBounds = YES;
    [titleContainer addSubview:vipBadge];
    
    UIImageView *crownIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"crown.fill"]];
    crownIcon.tintColor = [UIColor whiteColor];
    [vipBadge addSubview:crownIcon];
    
    UILabel *vipLabel = [[UILabel alloc] init];
    vipLabel.text = @"VIP";
    vipLabel.font = AIUAUIFontBold(12);
    vipLabel.textColor = [UIColor whiteColor];
    [vipBadge addSubview:vipLabel];
    
    // 副标题
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = L(@"unlock_all_features");
    subtitleLabel.font = AIUAUIFontSystem(13);
    subtitleLabel.textColor = AIUAUIColorRGB(107, 114, 128);
    subtitleLabel.numberOfLines = 0;
    [headerView addSubview:subtitleLabel];
    
    // 布局
    [titleContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(headerView).offset(16);
        make.left.equalTo(headerView).offset(20);
        make.right.equalTo(headerView).offset(-20);
        make.height.equalTo(@30);
    }];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(titleContainer);
    }];
    
    [vipBadge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleLabel.mas_right).offset(10);
        make.centerY.equalTo(titleContainer);
        make.width.equalTo(@60);
        make.height.equalTo(@24);
    }];
    
    [crownIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(vipBadge).offset(6);
        make.centerY.equalTo(vipBadge);
        make.width.height.equalTo(@12);
    }];
    
    [vipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(crownIcon.mas_right).offset(4);
        make.centerY.equalTo(vipBadge);
    }];
    
    [subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleContainer.mas_bottom).offset(8);
        make.left.right.equalTo(titleContainer);
    }];
    
    return headerView;
}

- (UIView *)createBenefitsTitleView {
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor clearColor];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = L(@"member_benefits");
    titleLabel.font = AIUAUIFontBold(18);
    titleLabel.textColor = AIUAUIColorRGB(17, 24, 39);
    [headerView addSubview:titleLabel];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(headerView).offset(20);
        make.bottom.equalTo(headerView).offset(-8);
    }];
    
    return headerView;
}


- (UIView *)createFooterView {
    CGFloat footerHeight = 300;
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, AIUAScreenWidth, footerHeight)];
    footerView.backgroundColor = [UIColor whiteColor];
    
    // 订阅方案标题
    UILabel *plansTitleLabel = [[UILabel alloc] init];
    plansTitleLabel.text = L(@"select_plan");
    plansTitleLabel.font = AIUAUIFontBold(18);
    plansTitleLabel.textColor = AIUAUIColorRGB(17, 24, 39);
    [footerView addSubview:plansTitleLabel];
    
    [plansTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(footerView).offset(16);
        make.left.equalTo(footerView).offset(20);
    }];
    
    // 横向滚动的订阅方案
    UIScrollView *plansScrollView = [[UIScrollView alloc] init];
    plansScrollView.backgroundColor = [UIColor clearColor];
    plansScrollView.showsHorizontalScrollIndicator = NO;
    [footerView addSubview:plansScrollView];
    
    [plansScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(plansTitleLabel.mas_bottom).offset(12);
        make.left.right.equalTo(footerView);
        make.height.equalTo(@120);
    }];
    
    // 订阅方案数据
    NSArray *plans = @[
        @{@"type": @(AIUASubscriptionPlanLifetime), @"name": L(@"lifetime_member"), @"price": @"198", @"desc": L(@"lifetime_desc"), @"badge": L(@"recommended")},
        @{@"type": @(AIUASubscriptionPlanYearly), @"name": L(@"yearly_plan"), @"price": @"168", @"desc": L(@"yearly_desc"), @"badge": @""},
        @{@"type": @(AIUASubscriptionPlanMonthly), @"name": L(@"monthly_plan"), @"price": @"68", @"desc": L(@"monthly_desc"), @"badge": @""},
        @{@"type": @(AIUASubscriptionPlanWeekly), @"name": L(@"weekly_plan"), @"price": @"38", @"desc": L(@"weekly_desc"), @"badge": @""}
    ];
    
    self.planCards = [NSMutableArray array];
    CGFloat xOffset = 20;
    
    for (NSDictionary *plan in plans) {
        UIView *planCard = [self createPlanCardWithPlan:plan];
        [plansScrollView addSubview:planCard];
        [self.planCards addObject:planCard];
        
        [planCard mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(plansScrollView).offset(xOffset);
            make.top.equalTo(plansScrollView).offset(8);
            make.width.equalTo(@(AIUAScreenWidth * 0.65));
            make.height.equalTo(@100);
        }];
        
        xOffset += AIUAScreenWidth * 0.65 + 12;
    }
    
    // 设置scrollView的contentSize
    [plansScrollView.subviews.lastObject mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(plansScrollView).offset(-20);
    }];
    
    // 自动续费说明
    UILabel *autoRenewLabel = [[UILabel alloc] init];
    autoRenewLabel.text = L(@"auto_renew_notice");
    autoRenewLabel.font = AIUAUIFontSystem(11);
    autoRenewLabel.textColor = AIUAUIColorRGB(156, 163, 175);
    autoRenewLabel.textAlignment = NSTextAlignmentCenter;
    [footerView addSubview:autoRenewLabel];
    
    [autoRenewLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(plansScrollView.mas_bottom).offset(8);
        make.centerX.equalTo(footerView);
    }];
    
    // 协议勾选
    UIView *agreementContainer = [[UIView alloc] init];
    [footerView addSubview:agreementContainer];
    
    self.agreeCheckbox = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.agreeCheckbox setImage:[self checkboxImageWithSelected:NO] forState:UIControlStateNormal];
    [self.agreeCheckbox addTarget:self action:@selector(toggleAgreement) forControlEvents:UIControlEventTouchUpInside];
    [agreementContainer addSubview:self.agreeCheckbox];
    
    UILabel *agreementLabel = [[UILabel alloc] init];
    agreementLabel.font = AIUAUIFontSystem(11);
    agreementLabel.textColor = AIUAUIColorRGB(107, 114, 128);
    agreementLabel.numberOfLines = 2;
    
    NSString *agreementText = L(@"agree_to_terms");
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:agreementText];
    
    // 高亮用户协议和自动续费协议
    NSRange userAgreementRange = [agreementText rangeOfString:L(@"user_agreement")];
    NSRange autoRenewRange = [agreementText rangeOfString:L(@"auto_renew_agreement")];
    
    if (userAgreementRange.location != NSNotFound) {
        [attrString addAttribute:NSForegroundColorAttributeName
                           value:AIUAUIColorRGB(59, 130, 246)
                           range:userAgreementRange];
    }
    
    if (autoRenewRange.location != NSNotFound) {
        [attrString addAttribute:NSForegroundColorAttributeName
                           value:AIUAUIColorRGB(59, 130, 246)
                           range:autoRenewRange];
    }
    
    agreementLabel.attributedText = attrString;
    agreementLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAgreementTap:)];
    [agreementLabel addGestureRecognizer:tap];
    [agreementContainer addSubview:agreementLabel];
    
    // 立即开通按钮
    UIButton *subscribeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [subscribeButton setTitle:L(@"activate_now") forState:UIControlStateNormal];
    [subscribeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    subscribeButton.titleLabel.font = AIUAUIFontBold(17);
    subscribeButton.backgroundColor = AIUAUIColorRGB(16, 185, 129);
    subscribeButton.layer.cornerRadius = 12;
    [subscribeButton addTarget:self action:@selector(activateSubscription) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:subscribeButton];
    
    // 布局
    [agreementContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(autoRenewLabel.mas_bottom).offset(12);
        make.centerX.equalTo(footerView);
    }];
    
    [self.agreeCheckbox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(agreementContainer);
        make.width.height.equalTo(@18);
    }];
    
    [agreementLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.agreeCheckbox.mas_right).offset(6);
        make.top.right.bottom.equalTo(agreementContainer);
        make.width.lessThanOrEqualTo(@280);
    }];
    
    [subscribeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(agreementContainer.mas_bottom).offset(12);
        make.left.equalTo(footerView).offset(20);
        make.right.equalTo(footerView).offset(-20);
        make.height.equalTo(@50);
    }];
    
    return footerView;
}

- (UIView *)createPlanCardWithPlan:(NSDictionary *)plan {
    AIUASubscriptionPlan planType = [plan[@"type"] integerValue];
    
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = 16;
    card.layer.borderWidth = 2;
    card.layer.borderColor = AIUAUIColorRGB(229, 231, 235).CGColor;
    card.tag = planType;
    
    // 添加点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectPlan:)];
    [card addGestureRecognizer:tap];
    
    // 推荐标签
    NSString *badge = plan[@"badge"];
    UILabel *badgeLabel;
    if (badge && badge.length > 0) {
        badgeLabel = [[UILabel alloc] init];
        badgeLabel.text = badge;
        badgeLabel.font = AIUAUIFontBold(11);
        badgeLabel.textColor = [UIColor whiteColor];
        badgeLabel.backgroundColor = AIUAUIColorRGB(16, 185, 129);
        badgeLabel.textAlignment = NSTextAlignmentCenter;
        badgeLabel.layer.cornerRadius = 10;
        badgeLabel.layer.masksToBounds = YES;
        [card addSubview:badgeLabel];
        
        [badgeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(card).offset(12);
            make.left.equalTo(card).offset(16);
            make.width.greaterThanOrEqualTo(@60);
            make.height.equalTo(@20);
        }];
    }
    
    // 套餐名称
    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = plan[@"name"];
    nameLabel.font = AIUAUIFontBold(18);
    nameLabel.textColor = AIUAUIColorRGB(17, 24, 39);
    [card addSubview:nameLabel];
    
    // 价格
    UILabel *priceLabel = [[UILabel alloc] init];
    priceLabel.text = [NSString stringWithFormat:@"¥%@", plan[@"price"]];
    priceLabel.font = AIUAUIFontBold(32);
    priceLabel.textColor = AIUAUIColorRGB(16, 185, 129);
    priceLabel.tag = 888; // 设置tag以便后续更新价格
    [card addSubview:priceLabel];
    
    // 描述
    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.text = plan[@"desc"];
    descLabel.font = AIUAUIFontSystem(13);
    descLabel.textColor = AIUAUIColorRGB(107, 114, 128);
    [card addSubview:descLabel];
    
    // 选中图标
    UIImageView *checkIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark.circle.fill"]];
    checkIcon.tintColor = AIUAUIColorRGB(16, 185, 129);
    checkIcon.hidden = YES;
    checkIcon.tag = 999;
    [card addSubview:checkIcon];
    
    // 布局
    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        if (badgeLabel) {
            make.top.equalTo(badgeLabel.mas_bottom).offset(4);
        } else {
            make.centerY.equalTo(card).offset(-10);
        }
        make.left.equalTo(card).offset(16);
    }];
    
    [priceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-16);
        make.centerY.equalTo(card).offset(-10);
    }];
    
    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(nameLabel);
        make.top.equalTo(nameLabel.mas_bottom).offset(4);
    }];
    
    [checkIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-12);
        make.bottom.equalTo(card).offset(-12);
        make.width.height.equalTo(@24);
    }];
    
    return card;
}

- (void)selectPlan:(UITapGestureRecognizer *)gesture {
    UIView *selectedCard = gesture.view;
    self.selectedPlan = selectedCard.tag;
    [self updateSelectedPlanUI];
}

- (void)updateSelectedPlanUI {
    // 更新所有卡片的选中状态
    for (UIView *card in self.planCards) {
        BOOL isSelected = (card.tag == self.selectedPlan);
        
        if (isSelected) {
            card.layer.borderColor = AIUAUIColorRGB(16, 185, 129).CGColor;
            card.backgroundColor = AIUAUIColorRGB(240, 253, 244);
        } else {
            card.layer.borderColor = AIUAUIColorRGB(229, 231, 235).CGColor;
            card.backgroundColor = [UIColor whiteColor];
        }
        
        // 更新选中图标
        UIView *checkIcon = [card viewWithTag:999];
        if (checkIcon) {
            checkIcon.hidden = !isSelected;
        }
    }
}

- (void)toggleAgreement {
    self.agreedToTerms = !self.agreedToTerms;
    [self.agreeCheckbox setImage:[self checkboxImageWithSelected:self.agreedToTerms] forState:UIControlStateNormal];
}

- (UIImage *)checkboxImageWithSelected:(BOOL)selected {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 20), NO, [UIScreen mainScreen].scale);
    
    if (selected) {
        // 选中状态
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 20, 20) cornerRadius:10];
        [AIUAUIColorRGB(16, 185, 129) setFill];
        [path fill];
        
        // 绘制对勾
        UIBezierPath *checkPath = [UIBezierPath bezierPath];
        [checkPath moveToPoint:CGPointMake(6, 10)];
        [checkPath addLineToPoint:CGPointMake(9, 13)];
        [checkPath addLineToPoint:CGPointMake(14, 7)];
        checkPath.lineWidth = 2;
        [[UIColor whiteColor] setStroke];
        [checkPath stroke];
    } else {
        // 未选中状态
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 20, 20) cornerRadius:10];
        [AIUAUIColorRGB(209, 213, 219) setStroke];
        path.lineWidth = 1.5;
        [path stroke];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)handleAgreementTap:(UITapGestureRecognizer *)gesture {
    UILabel *label = (UILabel *)gesture.view;
    CGPoint location = [gesture locationInView:label];
    
    NSString *text = label.attributedText.string;
    NSRange userAgreementRange = [text rangeOfString:L(@"user_agreement")];
    NSRange autoRenewRange = [text rangeOfString:L(@"auto_renew_agreement")];
    
    // 简单判断点击位置（实际项目中可以使用更精确的方法）
    if (location.x < label.bounds.size.width / 2 && userAgreementRange.location != NSNotFound) {
        [self showUserAgreement];
    } else if (autoRenewRange.location != NSNotFound) {
        [self showAutoRenewAgreement];
    }
}

#pragma mark - Actions

- (void)restoreSubscription {
    [AIUAMBProgressManager showHUD:self.view];
    
    [[AIUAIAPManager sharedManager] restorePurchasesWithCompletion:^(BOOL success, NSInteger restoredCount, NSString * _Nullable errorMessage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [AIUAMBProgressManager hideHUD:self.view];
            
            if (success && restoredCount > 0) {
                // 恢复成功
                [AIUAAlertHelper showAlertWithTitle:L(@"restore_success")
                                            message:[NSString stringWithFormat:L(@"subscription_restored_count"), (long)restoredCount]
                                      cancelBtnText:nil
                                     confirmBtnText:L(@"confirm")
                                       inController:self
                                       cancelAction:nil
                                      confirmAction:^{
                    [self.navigationController popViewControllerAnimated:YES];
                }];
            } else {
                // 没有订阅记录或恢复失败
                NSString *message = errorMessage ?: L(@"no_subscription_found");
                [AIUAAlertHelper showAlertWithTitle:L(@"cannot_subscribe")
                                            message:message
                                      cancelBtnText:nil
                                     confirmBtnText:L(@"confirm")
                                       inController:self
                                       cancelAction:nil
                                      confirmAction:nil];
            }
        });
    }];
}

- (void)activateSubscription {
    if (!self.agreedToTerms) {
        [AIUAAlertHelper showAlertWithTitle:L(@"prompt")
                                    message:L(@"please_agree_to_terms")
                              cancelBtnText:nil
                             confirmBtnText:L(@"confirm")
                               inController:self
                               cancelAction:nil
                              confirmAction:nil];
        return;
    }
    
    // 获取选中的套餐信息
    NSString *planName = [self getPlanName:self.selectedPlan];
    NSString *planPrice = [self getPlanPrice:self.selectedPlan];
    
    NSString *message = [NSString stringWithFormat:L(@"confirm_purchase_plan"), planName, planPrice];
    
    [AIUAAlertHelper showAlertWithTitle:L(@"confirm_purchase")
                                message:message
                          cancelBtnText:L(@"cancel")
                         confirmBtnText:L(@"confirm")
                           inController:self
                           cancelAction:nil
                         confirmAction:^{
        [self performSubscription];
    }];
}

- (void)performSubscription {
    // 转换为IAP产品类型
    AIUASubscriptionProductType productType = [self convertToIAPProductType:self.selectedPlan];
    
    [AIUAMBProgressManager showHUD:self.view];
    
    [[AIUAIAPManager sharedManager] purchaseProduct:productType completion:^(BOOL success, NSString * _Nullable errorMessage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [AIUAMBProgressManager hideHUD:self.view];
            
            if (success) {
                // 购买成功
                [AIUAAlertHelper showAlertWithTitle:L(@"subscription_success")
                                            message:L(@"enjoy_vip_benefits")
                                      cancelBtnText:nil
                                     confirmBtnText:L(@"confirm")
                                       inController:self
                                       cancelAction:nil
                                      confirmAction:^{
                    [self.navigationController popViewControllerAnimated:YES];
                }];
            } else {
                // 购买失败
                if (errorMessage && ![errorMessage isEqualToString:L(@"purchase_cancelled")]) {
                    [AIUAAlertHelper showAlertWithTitle:L(@"purchase_failed")
                                                message:errorMessage
                                          cancelBtnText:nil
                                         confirmBtnText:L(@"confirm")
                                           inController:self
                                           cancelAction:nil
                                          confirmAction:nil];
                }
            }
        });
    }];
}

- (AIUASubscriptionProductType)convertToIAPProductType:(AIUASubscriptionPlan)plan {
    switch (plan) {
        case AIUASubscriptionPlanLifetime:
            return AIUASubscriptionProductTypeLifetime;
        case AIUASubscriptionPlanYearly:
            return AIUASubscriptionProductTypeYearly;
        case AIUASubscriptionPlanMonthly:
            return AIUASubscriptionProductTypeMonthly;
        case AIUASubscriptionPlanWeekly:
            return AIUASubscriptionProductTypeWeekly;
        default:
            return AIUASubscriptionProductTypeLifetime;
    }
}

- (NSString *)getPlanName:(AIUASubscriptionPlan)plan {
    switch (plan) {
        case AIUASubscriptionPlanLifetime:
            return L(@"lifetime_member");
        case AIUASubscriptionPlanYearly:
            return L(@"yearly_plan");
        case AIUASubscriptionPlanMonthly:
            return L(@"monthly_plan");
        case AIUASubscriptionPlanWeekly:
            return L(@"weekly_plan");
    }
}

- (NSString *)getPlanPrice:(AIUASubscriptionPlan)plan {
    switch (plan) {
        case AIUASubscriptionPlanLifetime:
            return @"198";
        case AIUASubscriptionPlanYearly:
            return @"168";
        case AIUASubscriptionPlanMonthly:
            return @"68";
        case AIUASubscriptionPlanWeekly:
            return @"38";
    }
}

- (void)showUserAgreement {
    AIUATextViewController *vc = [[AIUATextViewController alloc] init];
    vc.htmlFileName = @"用户协议.html";
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showAutoRenewAgreement {
    AIUATextViewController *vc = [[AIUATextViewController alloc] init];
    vc.htmlFileName = @"自动续费服务协议.html";
    [self.navigationController pushViewController:vc animated:YES];
}

@end

