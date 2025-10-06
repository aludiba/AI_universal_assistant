//
//  AIUASettingsViewController.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/3/25.
//

#import "AIUASettingsViewController.h"

@interface AIUASettingsViewController ()

@end

@implementation AIUASettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = L(@"tab_settings");
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"设置 页面（示例）";
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

@end
