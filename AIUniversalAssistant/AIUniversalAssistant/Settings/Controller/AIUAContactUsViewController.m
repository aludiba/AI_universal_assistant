//
//  AIUAContactUsViewController.m
//  AIUniversalAssistant
//
//  Created by AI Assistant on 2025/12/4.
//

#import "AIUAContactUsViewController.h"
#import <Masonry/Masonry.h>

@interface AIUAContactUsViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *qrCodeImageView;
@property (nonatomic, strong) UIButton *contactButton;

@end

@implementation AIUAContactUsViewController

- (void)setupUI {
    [super setupUI];
    
    self.view.backgroundColor = AIUA_BACK_COLOR;
    
    self.title = L(@"contact_us");
    
    // 创建滚动视图
    [self setupScrollView];
    
    // 创建二维码图片
    [self setupQRCodeImageView];
    
    // 创建联系按钮
    [self setupContactButton];
}

- (void)setupScrollView {
    // 滚动视图
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.showsVerticalScrollIndicator = YES;
    self.scrollView.alwaysBounceVertical = YES;
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
}

- (void)setupQRCodeImageView {
    // 二维码图片视图
    self.qrCodeImageView = [[UIImageView alloc] init];
    self.qrCodeImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.qrCodeImageView.image = [UIImage imageNamed:@"contactUs"];
    self.qrCodeImageView.backgroundColor = [UIColor clearColor];
    self.qrCodeImageView.layer.cornerRadius = 16;
    self.qrCodeImageView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.qrCodeImageView];
    
    // 如果图片不存在，显示占位符（适配暗黑模式）
    if (!self.qrCodeImageView.image) {
        self.qrCodeImageView.backgroundColor = AIUA_TERTIARY_BACK_COLOR;
        
        UILabel *placeholderLabel = [[UILabel alloc] init];
        placeholderLabel.text = @"请添加二维码图片\n(contactUs)";
        placeholderLabel.numberOfLines = 0;
        placeholderLabel.font = AIUAUIFontSystem(14);
        placeholderLabel.textColor = AIUA_SECONDARY_LABEL_COLOR;
        placeholderLabel.textAlignment = NSTextAlignmentCenter;
        [self.qrCodeImageView addSubview:placeholderLabel];
        
        [placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.qrCodeImageView);
        }];
    }
    
    // 获取屏幕宽度，让二维码占据更大比例
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat qrCodeSize = screenWidth; // 左右各20的边距
    
    [self.qrCodeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(40);
        make.centerX.equalTo(self.contentView);
        make.width.height.mas_equalTo(qrCodeSize);
    }];
}

- (void)setupContactButton {
    self.contactButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.contactButton.backgroundColor = AIUAUIColorRGB(59, 130, 246);
    self.contactButton.layer.cornerRadius = 25;
    self.contactButton.layer.masksToBounds = YES;
    
    [self.contactButton setTitle:@"联系客服" forState:UIControlStateNormal];
    [self.contactButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.contactButton.titleLabel.font = AIUAUIFontMedium(16);
    
    [self.contactButton addTarget:self action:@selector(contactButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.contactButton];
    
    [self.contactButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.qrCodeImageView.mas_bottom).offset(40);
        make.left.equalTo(self.contentView).offset(40);
        make.right.equalTo(self.contentView).offset(-40);
        make.height.mas_equalTo(50);
        make.bottom.equalTo(self.contentView).offset(-40); // 设置底部约束，确定contentSize
    }];
}

#pragma mark - Actions

- (void)contactButtonTapped {
    NSLog(@"[联系客服] 点击联系客服按钮");
    
    // QQ群号
    NSString *qqGroupNumber = @"319539849";
    
    // 方式1: 使用QQ群号直接打开加群页面
    NSString *qqGroupUrl = [NSString stringWithFormat:@"mqqapi://card/show_pslcard?src_type=internal&version=1&uin=%@&card_type=group&source=qrcode", qqGroupNumber];
    NSURL *url = [NSURL URLWithString:qqGroupUrl];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            if (success) {
                NSLog(@"[联系客服] 成功打开QQ加群页面");
            } else {
                NSLog(@"[联系客服] 打开QQ加群页面失败");
                [self showJoinGroupTips];
            }
        }];
    } else {
        NSLog(@"[联系客服] 无法打开QQ，可能未安装QQ应用");
        [self showJoinGroupTips];
    }
}

- (void)showJoinGroupTips {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"加入QQ群"
                                                                   message:@"群号：463574369\n\n请打开手机QQ，点击右上角「+」，选择「加群/群号」手动添加，或扫描二维码加入。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *copyAction = [UIAlertAction actionWithTitle:@"复制群号"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = @"463574369";
        NSLog(@"[联系客服] 群号已复制到剪贴板");
        [self showToast:@"群号已复制"];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"知道了"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alert addAction:copyAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showToast:(NSString *)message {
    UILabel *toast = [[UILabel alloc] init];
    toast.text = message;
    toast.font = AIUAUIFontSystem(14);
    // 使用动态颜色，适配暗黑模式
    toast.textColor = [UIColor systemBackgroundColor]; // 白色文字在暗黑模式下会自动变为深色背景上的浅色文字
    toast.backgroundColor = AIUA_DynamicColor(
        [[UIColor blackColor] colorWithAlphaComponent:0.7],  // 浅色模式：黑色半透明
        [[UIColor whiteColor] colorWithAlphaComponent:0.9]    // 暗黑模式：白色半透明
    );
    toast.textAlignment = NSTextAlignmentCenter;
    toast.layer.cornerRadius = 8;
    toast.layer.masksToBounds = YES;
    toast.alpha = 0;
    
    [self.view addSubview:toast];
    
    [toast mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.centerY.equalTo(self.view).offset(100);
        make.height.mas_equalTo(36);
        make.width.mas_greaterThanOrEqualTo(120);
        make.left.greaterThanOrEqualTo(self.view).offset(60);
        make.right.lessThanOrEqualTo(self.view).offset(-60);
    }];
    
    [UIView animateWithDuration:0.3 animations:^{
        toast.alpha = 1;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                toast.alpha = 0;
            } completion:^(BOOL finished) {
                [toast removeFromSuperview];
            }];
        });
    }];
}

@end

