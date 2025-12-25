//
//  AIUASuperViewController.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/3/25.
//

#import "AIUASuperViewController.h"

@interface AIUASuperViewController ()

@end

@implementation AIUASuperViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = AIUA_BACK_COLOR;
    [self setupUI];
    [self setupData];
}

- (void)setupUI {
    // 创建返回图标（使用系统颜色，自动适配暗黑模式）
    UIImage *backImage = [[UIImage systemImageNamed:@"chevron.left"] imageWithTintColor:[UIColor labelColor] renderingMode:UIImageRenderingModeAlwaysOriginal];
    
    // 创建UIBarButtonItem
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:backImage
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(backButtonTapped)];
    
    // 设置导航栏左侧按钮
    self.navigationItem.leftBarButtonItem = backItem;
}

- (void)setupData {
    
}

#pragma mark - actions

// 返回按钮点击事件
- (void)backButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
