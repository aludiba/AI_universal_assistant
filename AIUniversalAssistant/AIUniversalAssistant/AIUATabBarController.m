//
//  AIUATabBarController.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/3/25.
//

#import "AIUATabBarController.h"
#import "AIUAHotViewController.h"
#import "AIUAWriterViewController.h"
#import "AIUADocsViewController.h"
#import "AIUASettingsViewController.h"

@interface AIUATabBarController ()

@end

@implementation AIUATabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViewControllers];
}

- (void)setupViewControllers {
    AIUAHotViewController *hotVC = [[AIUAHotViewController alloc] init];
    UINavigationController *hotNav = [[UINavigationController alloc] initWithRootViewController:hotVC];
    hotNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:L(@"tab_hot") image:[UIImage imageNamed:@"hot"] tag:0];
    
    AIUAWriterViewController *writerVC = [[AIUAWriterViewController alloc] init];
    UINavigationController *writerNav = [[UINavigationController alloc] initWithRootViewController:writerVC];
    writerNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:L(@"tab_writer") image:[UIImage imageNamed:@"write"] tag:1];
    
    AIUADocsViewController *docsVC = [[AIUADocsViewController alloc] init];
    UINavigationController *docsNav = [[UINavigationController alloc] initWithRootViewController:docsVC];
    docsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:L(@"tab_docs") image:[UIImage imageNamed:@"docs"] tag:2];
    
    AIUASettingsViewController *settingsVC = [[AIUASettingsViewController alloc] init];
    UINavigationController *settingsNav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    settingsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:L(@"tab_settings") image:[UIImage imageNamed:@"settings"] tag:3];
    
    self.viewControllers = @[hotNav, writerNav, docsNav, settingsNav];
    // 可选：自定义 tabBar 外观
    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
        [appearance configureWithDefaultBackground];
        self.tabBar.standardAppearance = appearance;
        if (@available(iOS 15.0, *)) {
            self.tabBar.scrollEdgeAppearance = appearance;
        }
    }
}

@end
