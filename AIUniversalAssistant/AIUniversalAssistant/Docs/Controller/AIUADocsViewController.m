//
//  AIUADocsViewController.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/3/25.
//

#import "AIUADocsViewController.h"

@interface AIUADocsViewController ()

@end

@implementation AIUADocsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"文档";
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"文档 页面（示例）";
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

@end
