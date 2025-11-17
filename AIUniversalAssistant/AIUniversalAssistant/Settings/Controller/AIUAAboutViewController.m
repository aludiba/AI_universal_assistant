//
//  AIUAAboutViewController.m
//  AIUniversalAssistant
//
//  Created by AI Assistant on 2025/11/3.
//

#import "AIUAAboutViewController.h"
#import <Masonry/Masonry.h>

@interface AIUAAboutViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@end

@implementation AIUAAboutViewController

- (void)setupUI {
    [super setupUI];
    
    self.title = L(@"about_us");
    self.view.backgroundColor = AIUAUIColorRGB(246, 248, 250);
    
    // 创建滚动视图
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.scrollView];
    
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // 内容视图
    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:self.contentView];
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
    }];
    
    [self setupContent];
}

- (void)setupContent {
    // Logo - 使用App Icon
    UIView *logoContainer = [[UIView alloc] init];
    logoContainer.layer.cornerRadius = 20;
    logoContainer.layer.masksToBounds = YES;
    [self.contentView addSubview:logoContainer];
    
    // 尝试获取 App Icon
    UIImage *appIcon = [self getAppIcon];
    
    if (appIcon) {
        // 成功获取到图标，使用ImageView显示
        UIImageView *iconImageView = [[UIImageView alloc] init];
        iconImageView.image = appIcon;
        iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        [logoContainer addSubview:iconImageView];
        
        [iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(logoContainer);
        }];
    } else {
        // 如果获取不到，使用蓝色背景和文字作为占位
        logoContainer.backgroundColor = AIUAUIColorRGB(59, 130, 246);
        
        UILabel *placeholderLabel = [[UILabel alloc] init];
        placeholderLabel.text = @"AI";
        placeholderLabel.font = AIUAUIFontBold(40);
        placeholderLabel.textColor = [UIColor whiteColor];
        placeholderLabel.textAlignment = NSTextAlignmentCenter;
        [logoContainer addSubview:placeholderLabel];
        
        [placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(logoContainer);
        }];
    }
    
    // App名称
    UILabel *appNameLabel = [[UILabel alloc] init];
    appNameLabel.text = L(@"app_name");
    appNameLabel.font = AIUAUIFontBold(24);
    appNameLabel.textColor = AIUAUIColorRGB(31, 35, 41);
    appNameLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:appNameLabel];
    
    // 版本号
    UILabel *versionLabel = [[UILabel alloc] init];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    versionLabel.text = [NSString stringWithFormat:L(@"app_version"), version ?: @"1.0.0"];
    versionLabel.font = AIUAUIFontSystem(14);
    versionLabel.textColor = AIUAUIColorRGB(156, 163, 175);
    versionLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:versionLabel];
    
    // 简介卡片
    UIView *introCard = [self createCardWithTitle:L(@"app_intro_title")
                                           content:L(@"app_intro_content")];
    [self.contentView addSubview:introCard];
    
    // 功能卡片
    UIView *featuresCard = [self createCardWithTitle:L(@"main_features_title")
                                              content:L(@"main_features_content")];
    [self.contentView addSubview:featuresCard];
    
    // 链接按钮
    UIButton *userAgreementBtn = [self createLinkButtonWithTitle:L(@"user_agreement")];
    [userAgreementBtn addTarget:self action:@selector(showUserAgreement) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:userAgreementBtn];
    
    UIButton *privacyPolicyBtn = [self createLinkButtonWithTitle:L(@"privacy_policy")];
    [privacyPolicyBtn addTarget:self action:@selector(showPrivacyPolicy) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:privacyPolicyBtn];
    
    // 版权信息
    UILabel *copyrightLabel = [[UILabel alloc] init];
    copyrightLabel.text = L(@"copyright_text");
    copyrightLabel.font = AIUAUIFontSystem(12);
    copyrightLabel.textColor = AIUAUIColorRGB(156, 163, 175);
    copyrightLabel.textAlignment = NSTextAlignmentCenter;
    copyrightLabel.numberOfLines = 0;
    [self.contentView addSubview:copyrightLabel];
    
    // 布局
    [logoContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(40);
        make.centerX.equalTo(self.contentView);
        make.width.height.equalTo(@100);
    }];
    
    [appNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(logoContainer.mas_bottom).offset(16);
        make.centerX.equalTo(self.contentView);
    }];
    
    [versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(appNameLabel.mas_bottom).offset(4);
        make.centerX.equalTo(self.contentView);
    }];
    
    [introCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(versionLabel.mas_bottom).offset(32);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
    }];
    
    [featuresCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(introCard.mas_bottom).offset(16);
        make.left.right.equalTo(introCard);
    }];
    
    [userAgreementBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(featuresCard.mas_bottom).offset(24);
        make.left.right.equalTo(introCard);
        make.height.equalTo(@50);
    }];
    
    [privacyPolicyBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(userAgreementBtn.mas_bottom).offset(12);
        make.left.right.equalTo(introCard);
        make.height.equalTo(@50);
    }];
    
    [copyrightLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(privacyPolicyBtn.mas_bottom).offset(32);
        make.centerX.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView).offset(-32);
    }];
}

#pragma mark - Helper Methods

- (UIView *)createCardWithTitle:(NSString *)title content:(NSString *)content {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = 12;
    card.layer.masksToBounds = YES;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = AIUAUIFontBold(16);
    titleLabel.textColor = AIUAUIColorRGB(31, 35, 41);
    [card addSubview:titleLabel];
    
    UILabel *contentLabel = [[UILabel alloc] init];
    contentLabel.text = content;
    contentLabel.font = AIUAUIFontSystem(14);
    contentLabel.textColor = AIUAUIColorRGB(75, 85, 99);
    contentLabel.numberOfLines = 0;
    [card addSubview:contentLabel];
    
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(card).offset(16);
        make.right.equalTo(card).offset(-16);
    }];
    
    [contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(titleLabel.mas_bottom).offset(12);
        make.left.right.equalTo(titleLabel);
        make.bottom.equalTo(card).offset(-16);
    }];
    
    return card;
}

- (UIButton *)createLinkButtonWithTitle:(NSString *)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:AIUAUIColorRGB(59, 130, 246) forState:UIControlStateNormal];
    button.titleLabel.font = AIUAUIFontSystem(15);
    button.backgroundColor = [UIColor whiteColor];
    button.layer.cornerRadius = 8;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
    
    UIImageView *arrowView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.right"]];
    arrowView.tintColor = AIUAUIColorRGB(209, 213, 219);
    arrowView.userInteractionEnabled = NO;
    [button addSubview:arrowView];
    
    [arrowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(button).offset(-16);
        make.centerY.equalTo(button);
        make.width.equalTo(@12);
        make.height.equalTo(@16);
    }];
    
    return button;
}

- (UIImage *)getAppIcon {
    // 尝试多种方式获取 App Icon
    UIImage *icon = nil;
    
    // 方式1：iOS 10.3+ 直接获取 AppIcon
    if (@available(iOS 10.3, *)) {
        icon = [UIImage imageNamed:@"AppIcon"];
        if (icon) {
            return icon;
        }
    }
    
    // 方式2：从bundle中获取已安装应用的图标
    NSString *iconFilename = [[[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIcons"] objectForKey:@"CFBundlePrimaryIcon"] objectForKey:@"CFBundleIconFiles"] lastObject];
    if (iconFilename) {
        icon = [UIImage imageNamed:iconFilename];
        if (icon) {
            return icon;
        }
    }
    
    // 方式3：尝试从文件路径加载（针对开发环境）
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *iconPath = [bundlePath stringByAppendingPathComponent:@"Assets.xcassets/AppIcon.appiconset/ai_writing_cat_logo_bright.png"];
    icon = [UIImage imageWithContentsOfFile:iconPath];
    if (icon) {
        return icon;
    }
    
    // 方式4：直接通过Assets加载（需要先将图片添加为独立的Image Set）
    icon = [UIImage imageNamed:@"ai_writing_cat_logo_bright"];
    
    return icon;
}

#pragma mark - Actions

- (void)showUserAgreement {
    UIViewController *vc = [[UIViewController alloc] init];
    vc.title = L(@"user_agreement");
    vc.view.backgroundColor = [UIColor whiteColor];
    
    UITextView *textView = [[UITextView alloc] init];
    textView.font = AIUAUIFontSystem(14);
    textView.textColor = AIUAUIColorRGB(75, 85, 99);
    textView.text = L(@"user_agreement_content");
    textView.editable = NO;
    textView.textContainerInset = UIEdgeInsetsMake(16, 16, 16, 16);
    [vc.view addSubview:textView];
    
    [textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(vc.view);
    }];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showPrivacyPolicy {
    UIViewController *vc = [[UIViewController alloc] init];
    vc.title = L(@"privacy_policy");
    vc.view.backgroundColor = [UIColor whiteColor];
    
    UITextView *textView = [[UITextView alloc] init];
    textView.font = AIUAUIFontSystem(14);
    textView.textColor = AIUAUIColorRGB(75, 85, 99);
    textView.text = L(@"privacy_policy_content");
    textView.editable = NO;
    textView.textContainerInset = UIEdgeInsetsMake(16, 16, 16, 16);
    [vc.view addSubview:textView];
    
    [textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(vc.view);
    }];
    
    [self.navigationController pushViewController:vc animated:YES];
}

@end

