//
//  AIUAWordPackViewController.m
//  AIUniversalAssistant
//
//  创作字数包购买页面 - 集成WordPackManager
//

#import "AIUAWordPackViewController.h"
#import "AIUAWordPackManager.h"
#import "AIUAIAPManager.h"
#import "AIUAAlertHelper.h"
#import "AIUAMembershipViewController.h"
#import "AIUAMacros.h"
#import <Masonry/Masonry.h>
#import <MBProgressHUD/MBProgressHUD.h>

@interface AIUAWordPackViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

// 字数显示区域
@property (nonatomic, strong) UIView *wordsInfoView;
@property (nonatomic, strong) UILabel *vipGiftedWordsLabel;
@property (nonatomic, strong) UILabel *purchasedWordsLabel;
@property (nonatomic, strong) UIView *expiringWarningContainer; // 即将过期提醒容器
@property (nonatomic, strong) UILabel *expiringWarningLabel; // 即将过期提醒标签
@property (nonatomic, strong) UILabel *totalWordsLabel;

// VIP赠送提示卡片
@property (nonatomic, strong) UIView *vipGiftTipView;

// 字数包选项
@property (nonatomic, strong) NSMutableArray<UIView *> *packOptionViews;
@property (nonatomic, assign) AIUAWordPackType selectedPackType;
@property (nonatomic, strong) NSMutableDictionary<NSString *, SKProduct *> *productsDict; // 存储产品信息，key为产品ID

// 购买按钮
@property (nonatomic, strong) UIButton *purchaseButton;

@end

@implementation AIUAWordPackViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // 停止监听支付队列
    [[AIUAIAPManager sharedManager] stopObservingPaymentQueue];
}

- (void)setupUI {
    [super setupUI];
    self.title = L(@"writing_word_packs");
    
    self.selectedPackType = AIUAWordPackType500K;
    self.packOptionViews = [NSMutableArray array];
    self.productsDict = [NSMutableDictionary dictionary];
    
    // 监听字数包变化
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wordPackChanged:)
                                                 name:AIUAWordPackPurchasedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(wordPackChanged:)
                                                 name:AIUAWordConsumedNotification
                                               object:nil];
    
    // 开始监听支付队列
    [[AIUAIAPManager sharedManager] startObservingPaymentQueue];
    
    // 创建滚动视图
    [self setupScrollView];
    
    // 字数信息显示
    [self setupWordsInfoView];
    
    // VIP赠送提示
    [self setupVIPGiftTip];
    
    // 购买选项
    [self setupPurchaseOptions];
    
    // 立即开通按钮
    [self setupPurchaseButton];
    
    // 购买须知
    [self setupPurchaseNotes];
    
    // 获取字数包产品信息
    [self fetchWordPackProducts];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 刷新字数显示
    [self updateWordsDisplay];
}

#pragma mark - Fetch Products

- (void)fetchWordPackProducts {
    [[AIUAIAPManager sharedManager] fetchWordPackProductsWithCompletion:^(NSArray<SKProduct *> * _Nullable products, NSString * _Nullable errorMessage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (products && products.count > 0) {
                [self updateWordPackProductPrices:products];
            } else {
                [AIUAAlertHelper showDebugErrorAlert:errorMessage context:@"获取字数包产品失败"];
            }
        });
    }];
}

- (void)updateWordPackProductPrices:(NSArray<SKProduct *> *)products {
    // 将产品信息存储到字典中，key为产品ID
    for (SKProduct *product in products) {
        self.productsDict[product.productIdentifier] = product;
        NSLog(@"[WordPack] 产品: %@ - %@ - %@", product.productIdentifier, product.localizedTitle, product.price);
    }
    
    // 获取字数包管理器
    AIUAWordPackManager *wordPackManager = [AIUAWordPackManager sharedManager];
    
    // 更新每个字数包选项的价格
    for (UIView *optionView in self.packOptionViews) {
        AIUAWordPackType packType = (AIUAWordPackType)optionView.tag;
        
        // 获取对应的产品ID
        NSString *productID = [wordPackManager productIDForPackType:packType];
        
        // 查找对应的产品
        SKProduct *product = self.productsDict[productID];
        if (product) {
            // 格式化价格
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            formatter.numberStyle = NSNumberFormatterCurrencyStyle;
            formatter.locale = product.priceLocale;
            NSString *formattedPrice = [formatter stringFromNumber:product.price];
            
            // 更新价格标签（tag为200表示价格标签）
            UILabel *priceLabel = [optionView viewWithTag:200];
            if (priceLabel) {
                priceLabel.text = formattedPrice;
                NSLog(@"[WordPack] 更新价格: %@ -> %@", productID, formattedPrice);
            }
        }
    }
    
    NSLog(@"[WordPack] 已更新字数包产品价格，共 %lu 个产品", (unsigned long)products.count);
}

#pragma mark - UI Setup

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = AIUA_BACK_COLOR;
    self.scrollView.showsVerticalScrollIndicator = YES;
    [self.view addSubview:self.scrollView];
    
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.contentView = [[UIView alloc] init];
    [self.scrollView addSubview:self.contentView];
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
}

- (void)setupWordsInfoView {
    self.wordsInfoView = [[UIView alloc] init];
    self.wordsInfoView.backgroundColor = AIUAUIColorRGB(245, 247, 250);
    self.wordsInfoView.layer.cornerRadius = 12;
    [self.contentView addSubview:self.wordsInfoView];
    
    [self.wordsInfoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(16);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
    }];
    
    // VIP赠送字数
    self.vipGiftedWordsLabel = [[UILabel alloc] init];
    self.vipGiftedWordsLabel.font = AIUAUIFontSystem(14);
    self.vipGiftedWordsLabel.textColor = [UIColor grayColor];
    [self.wordsInfoView addSubview:self.vipGiftedWordsLabel];
    
    [self.vipGiftedWordsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.wordsInfoView).offset(16);
        make.left.equalTo(self.wordsInfoView).offset(16);
        make.right.equalTo(self.wordsInfoView).offset(-16);
    }];
    
    // 购买字数
    self.purchasedWordsLabel = [[UILabel alloc] init];
    self.purchasedWordsLabel.font = AIUAUIFontSystem(14);
    self.purchasedWordsLabel.textColor = [UIColor grayColor];
    [self.wordsInfoView addSubview:self.purchasedWordsLabel];
    
    [self.purchasedWordsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.vipGiftedWordsLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.vipGiftedWordsLabel);
    }];
    
    // 即将过期提醒容器
    self.expiringWarningContainer = [[UIView alloc] init];
    self.expiringWarningContainer.backgroundColor = [UIColor clearColor];
    self.expiringWarningContainer.hidden = YES; // 默认隐藏
    [self.wordsInfoView addSubview:self.expiringWarningContainer];
    
    [self.expiringWarningContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.purchasedWordsLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.vipGiftedWordsLabel);
    }];
    
    // 即将过期提醒标签
    self.expiringWarningLabel = [[UILabel alloc] init];
    self.expiringWarningLabel.font = AIUAUIFontSystem(13);
    self.expiringWarningLabel.textColor = AIUAUIColorRGB(200, 50, 0);
    self.expiringWarningLabel.numberOfLines = 0;
    [self.expiringWarningContainer addSubview:self.expiringWarningLabel];
    
    [self.expiringWarningLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.expiringWarningContainer);
        make.left.right.equalTo(self.expiringWarningContainer);
        make.bottom.equalTo(self.expiringWarningContainer);
    }];
    
    // 分隔线
    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = AIUAUIColorRGB(220, 220, 220);
    [self.wordsInfoView addSubview:divider];
    
    [divider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.expiringWarningContainer.mas_bottom).offset(12);
        make.left.equalTo(self.wordsInfoView).offset(16);
        make.right.equalTo(self.wordsInfoView).offset(-16);
        make.height.equalTo(@0.5);
    }];
    
    // 总字数
    self.totalWordsLabel = [[UILabel alloc] init];
    self.totalWordsLabel.font = AIUAUIFontBold(18);
    self.totalWordsLabel.textColor = [UIColor systemGreenColor];
    [self.wordsInfoView addSubview:self.totalWordsLabel];
    
    [self.totalWordsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(divider.mas_bottom).offset(12);
        make.left.right.equalTo(self.vipGiftedWordsLabel);
        make.bottom.equalTo(self.wordsInfoView).offset(-16);
    }];
}

- (void)setupVIPGiftTip {
    // 提示卡片
    self.vipGiftTipView = [[UIView alloc] init];
    self.vipGiftTipView.backgroundColor = AIUAUIColorRGB(255, 250, 240);
    self.vipGiftTipView.layer.cornerRadius = 8;
    self.vipGiftTipView.layer.borderWidth = 1;
    self.vipGiftTipView.layer.borderColor = AIUAUIColorRGB(255, 220, 150).CGColor;
    [self.contentView addSubview:self.vipGiftTipView];
    
    // VIP提示卡片的约束：优先依赖即将过期提醒，如果隐藏则依赖字数信息视图
    [self.vipGiftTipView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.wordsInfoView.mas_bottom).offset(16);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
    }];
    
    // 图标
    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.image = [UIImage systemImageNamed:@"gift.fill"];
    iconView.tintColor = [UIColor systemOrangeColor];
    [self.vipGiftTipView addSubview:iconView];
    
    [iconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.vipGiftTipView).offset(12);
        make.centerY.equalTo(self.vipGiftTipView);
        make.width.height.equalTo(@20);
    }];
    
    // 文字
    UILabel *tipLabel = [[UILabel alloc] init];
    tipLabel.font = AIUAUIFontSystem(13);
    tipLabel.textColor = AIUAUIColorRGB(200, 100, 0);
    tipLabel.text = L(@"word_pack_note_3"); // 订阅任意会员套餐可获赠50万字
    tipLabel.numberOfLines = 0;
    [self.vipGiftTipView addSubview:tipLabel];
    
    [tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.vipGiftTipView).offset(12);
        make.left.equalTo(iconView.mas_right).offset(8);
        make.right.equalTo(self.vipGiftTipView).offset(-12);
        make.bottom.equalTo(self.vipGiftTipView).offset(-12);
    }];
    
    // 添加点击事件
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openMembership)];
    self.vipGiftTipView.userInteractionEnabled = YES;
    [self.vipGiftTipView addGestureRecognizer:tap];
}

- (void)setupPurchaseOptions {
    NSLog(@"[WordPack] setupPurchaseOptions 开始");
    
    // 标题（适配暗黑模式）
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = AIUAUIFontBold(16);
    titleLabel.textColor = AIUA_LABEL_COLOR; // 使用系统标签颜色，自动适配暗黑模式
    titleLabel.text = [NSString stringWithFormat:@"💰 %@", L(@"purchase_word_pack")];
    [self.contentView addSubview:titleLabel];
    
    // 明确引用VIP提示卡片，而不是使用subviews lastObject
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.vipGiftTipView.mas_bottom).offset(24);
        make.left.equalTo(self.contentView).offset(20);
    }];
    
    // 创建三个字数包选项
    NSArray *packOptions = @[
        @{@"words": @500000, @"price": @"6", @"type": @(AIUAWordPackType500K)},
        @{@"words": @2000000, @"price": @"18", @"type": @(AIUAWordPackType2M)},
        @{@"words": @6000000, @"price": @"38", @"type": @(AIUAWordPackType6M)}
    ];
    
    UIView *lastOptionView = titleLabel;
    for (NSDictionary *option in packOptions) {
        UIView *optionView = [self createPackOptionView:option];
        if (optionView) {
            [self.contentView addSubview:optionView];
            [self.packOptionViews addObject:optionView];
            
            [optionView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(lastOptionView.mas_bottom).offset(12);
                make.left.equalTo(self.contentView).offset(20);
                make.right.equalTo(self.contentView).offset(-20);
                make.height.equalTo(@56);
            }];
            
            lastOptionView = optionView;
        }
    }
    
    NSLog(@"[WordPack] 创建了 %lu 个字数包选项", (unsigned long)self.packOptionViews.count);
    
    // 更新选中状态
    [self updatePackOptionsUI];
}

- (UIView *)createPackOptionView:(NSDictionary *)option {
    UIView *containerView = [[UIView alloc] init];
    containerView.backgroundColor = AIUA_CARD_BACKGROUND_COLOR;
    containerView.layer.cornerRadius = 8;
    containerView.layer.borderWidth = 1;
    containerView.layer.borderColor = AIUA_DIVIDER_COLOR.CGColor;
    containerView.tag = [option[@"type"] integerValue];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(packOptionTapped:)];
    [containerView addGestureRecognizer:tap];
    
    // 选中图标
    UIImageView *checkIcon = [[UIImageView alloc] init];
    checkIcon.tag = 100;
    checkIcon.image = [UIImage systemImageNamed:@"checkmark.circle.fill"];
    checkIcon.tintColor = [UIColor systemGreenColor];
    [containerView addSubview:checkIcon];
    
    [checkIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(containerView).offset(16);
        make.centerY.equalTo(containerView);
        make.width.height.equalTo(@24);
    }];
    
    // 字数标签（适配暗黑模式）
    UILabel *wordsLabel = [[UILabel alloc] init];
    wordsLabel.font = AIUAUIFontSystem(16);
    wordsLabel.textColor = AIUA_LABEL_COLOR;
    wordsLabel.text = [NSString stringWithFormat:@"%@%@", [self formatNumber:[option[@"words"] integerValue]], L(@"words")];
    [containerView addSubview:wordsLabel];
    
    [wordsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(checkIcon.mas_right).offset(12);
        make.centerY.equalTo(containerView);
    }];
    
    // 价格标签
    UILabel *priceLabel = [[UILabel alloc] init];
    priceLabel.font = AIUAUIFontBold(16);
    priceLabel.textColor = [UIColor systemGreenColor];
    priceLabel.text = [NSString stringWithFormat:@"%@%@", @"¥", option[@"price"]];
    priceLabel.tag = 200; // 设置tag以便后续更新价格
    [containerView addSubview:priceLabel];
    
    [priceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(containerView).offset(-16);
        make.centerY.equalTo(containerView);
    }];
    
    return containerView;
}

- (void)setupPurchaseButton {
    NSLog(@"[WordPack] setupPurchaseButton 开始");
    
    self.purchaseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.purchaseButton setTitle:L(@"buy_now") forState:UIControlStateNormal];
    [self.purchaseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.purchaseButton.titleLabel.font = AIUAUIFontBold(16);
    self.purchaseButton.backgroundColor = [UIColor systemGreenColor];
    self.purchaseButton.layer.cornerRadius = 8;
    [self.purchaseButton addTarget:self action:@selector(purchaseButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.purchaseButton];
    
    // 获取最后一个字数包选项视图
    UIView *lastOptionView = [self.packOptionViews lastObject];
    if (!lastOptionView) {
        NSLog(@"[WordPack] ⚠️ packOptionViews 为空，使用 vipGiftTipView 作为参考");
        lastOptionView = self.vipGiftTipView;
    } else {
        NSLog(@"[WordPack] ✓ 找到最后一个字数包选项视图");
    }
    
    if (!lastOptionView) {
        NSLog(@"[WordPack] ❌ lastOptionView 仍然为 nil！");
        return;
    }
    
    [self.purchaseButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(lastOptionView.mas_bottom).offset(24);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.equalTo(@48);
    }];
    
    NSLog(@"[WordPack] setupPurchaseButton 完成");
}

- (void)setupPurchaseNotes {
    // 标题（适配暗黑模式）
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = AIUAUIFontBold(16);
    titleLabel.textColor = AIUA_LABEL_COLOR; // 使用系统标签颜色，自动适配暗黑模式
    titleLabel.text = [NSString stringWithFormat:@"💰 %@", L(@"purchase_notes")];
    [self.contentView addSubview:titleLabel];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.purchaseButton.mas_bottom).offset(32);
        make.left.equalTo(self.contentView).offset(20);
    }];
    
    // 购买须知内容（新文案）
    NSArray *notes = @[
        L(@"word_pack_note_1"),
        L(@"word_pack_note_2"),
        L(@"word_pack_note_4")
    ];
    
    UILabel *lastLabel = titleLabel;
    for (NSString *note in notes) {
        UILabel *noteLabel = [[UILabel alloc] init];
        noteLabel.font = AIUAUIFontSystem(14);
        noteLabel.textColor = [UIColor grayColor];
        noteLabel.text = [NSString stringWithFormat:@"• %@", note];
        noteLabel.numberOfLines = 0;
        [self.contentView addSubview:noteLabel];
        
        [noteLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(lastLabel.mas_bottom).offset(12);
            make.left.equalTo(self.contentView).offset(20);
            make.right.equalTo(self.contentView).offset(-20);
        }];
        
        lastLabel = noteLabel;
    }
    
    // 设置 contentView 的底部约束
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(lastLabel.mas_bottom).offset(32);
    }];
}

#pragma mark - Data Update

- (void)updateWordsDisplay {
    AIUAWordPackManager *manager = [AIUAWordPackManager sharedManager];
    BOOL isVIP = [[AIUAIAPManager sharedManager] isVIPMember];
    // 兜底：每次进入页面刷新显示前，确保VIP赠送字数已按当前订阅状态同步
    [manager refreshVIPGiftedWords];
    
    NSInteger vipWords = [manager vipGiftedWords];
    NSInteger purchasedWords = [manager purchasedWords];
    NSInteger totalWords = [manager totalAvailableWords];
    NSDictionary<NSNumber *, NSNumber *> *expiringByDays = [manager expiringWordsByDays];
    
    self.vipGiftedWordsLabel.text = [NSString stringWithFormat:L(@"vip_gifted_words"), [self formatNumber:vipWords]];
    self.purchasedWordsLabel.text = [NSString stringWithFormat:L(@"purchased_words"), [self formatNumber:purchasedWords]];
    if (isVIP) {
        self.totalWordsLabel.text = [NSString stringWithFormat:L(@"total_remaining_words"), L(@"unlimited")];
    } else {
        self.totalWordsLabel.text = [NSString stringWithFormat:L(@"total_remaining_words"), [self formatNumber:totalWords]];
    }
    
    // 更新即将过期提醒
    [self updateExpiringWarnings:expiringByDays];
    
    NSLog(@"[WordPack] 字数显示已更新 - VIP:%ld, 购买:%ld, 总计:%ld, 即将过期分组:%@", 
          (long)vipWords, (long)purchasedWords, (long)totalWords, expiringByDays);
}

- (void)updateExpiringWarnings:(NSDictionary<NSNumber *, NSNumber *> *)expiringByDays {
    // 计算所有7天内即将过期的总字数
    NSInteger totalExpiringWords = 0;
    for (NSNumber *daysKey in expiringByDays.allKeys) {
        NSInteger words = [expiringByDays[daysKey] integerValue];
        totalExpiringWords += words;
    }
    
    if (totalExpiringWords == 0) {
        // 没有即将过期的字数，隐藏容器
        self.expiringWarningContainer.hidden = YES;
        return;
    }
    
    // 显示容器并更新标签文本
    self.expiringWarningContainer.hidden = NO;
    self.expiringWarningLabel.text = [NSString stringWithFormat:L(@"expiring_words_in_7_days"), [self formatNumber:totalExpiringWords]];
}

#pragma mark - Actions

- (void)packOptionTapped:(UITapGestureRecognizer *)gesture {
    UIView *optionView = gesture.view;
    self.selectedPackType = (AIUAWordPackType)optionView.tag;
    [self updatePackOptionsUI];
}

- (void)updatePackOptionsUI {
    for (UIView *optionView in self.packOptionViews) {
        BOOL isSelected = (optionView.tag == self.selectedPackType);
        
        optionView.layer.borderColor = isSelected ? [UIColor systemGreenColor].CGColor : [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0].CGColor;
        optionView.layer.borderWidth = isSelected ? 2 : 1;
        
        UIImageView *checkIcon = [optionView viewWithTag:100];
        if (isSelected) {
            checkIcon.image = [UIImage systemImageNamed:@"checkmark.circle.fill"];
            checkIcon.tintColor = [UIColor systemGreenColor];
        } else {
            checkIcon.image = [UIImage systemImageNamed:@"circle"];
            checkIcon.tintColor = [UIColor lightGrayColor];
        }
    }
}

- (void)purchaseButtonTapped {
    AIUAWordPackManager *manager = [AIUAWordPackManager sharedManager];
    
    NSInteger words = [manager wordsForPackType:self.selectedPackType];
    NSString *price = [manager priceForPackType:self.selectedPackType];
    
    NSString *message = [NSString stringWithFormat:L(@"confirm_purchase_word_pack"), [self formatNumber:words], price];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:L(@"confirm_purchase")
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:L(@"cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:L(@"confirm")
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
        [self performPurchase];
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:confirmAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performPurchase {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = L(@"processing");
    
    AIUAWordPackManager *manager = [AIUAWordPackManager sharedManager];
    
    // 调用真实IAP购买
    [manager purchaseWordPack:self.selectedPackType completion:^(BOOL success, NSError * _Nullable error) {
        [hud hideAnimated:YES];
        
        if (success) {
            NSInteger words = [manager wordsForPackType:self.selectedPackType];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:L(@"purchase_success")
                                                                           message:[NSString stringWithFormat:L(@"word_pack_purchase_success"), [self formatNumber:words]]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:L(@"confirm")
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];
            
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
            
            // 刷新显示
            [self updateWordsDisplay];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:L(@"purchase_failed")
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:L(@"confirm")
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil];
            
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)openMembership {
    AIUAMembershipViewController *vc = [[AIUAMembershipViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Notifications

- (void)wordPackChanged:(NSNotification *)notification {
    NSLog(@"[WordPack] 字数包数据变化，刷新显示");
    [self updateWordsDisplay];
}

#pragma mark - Helper Methods

- (NSString *)formatNumber:(NSInteger)number {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.groupingSeparator = @",";
    formatter.usesGroupingSeparator = YES;
    return [formatter stringFromNumber:@(number)];
}

@end
