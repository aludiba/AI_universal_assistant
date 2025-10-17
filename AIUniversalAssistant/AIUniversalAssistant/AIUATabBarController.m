//
//  AIUATabBarController.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/3/25.
//

#import "AIUATabBarController.h"
#import "AIUAHotViewController.h"
#import "AIUAWriterViewController.h"
#import "AIUADocumentsViewController.h"
#import "AIUASettingsViewController.h"

@interface AIUATabBarController ()

@end

@implementation AIUATabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViewControllers];
}

- (void)setupViewControllers {
    // 热门页面
    AIUAHotViewController *hotVC = [[AIUAHotViewController alloc] init];
    UINavigationController *hotNav = [[UINavigationController alloc] initWithRootViewController:hotVC];
    
    UIImage *hotImage = [UIImage systemImageNamed:@"flame"];
    UIImage *hotSelectedImage = [UIImage systemImageNamed:@"flame.fill"];
    hotNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:L(@"tab_hot")
                                                       image:hotImage
                                               selectedImage:hotSelectedImage];
    
    // 写作页面
    AIUAWriterViewController *writerVC = [[AIUAWriterViewController alloc] init];
    UINavigationController *writerNav = [[UINavigationController alloc] initWithRootViewController:writerVC];
    
    UIImage *writeImage = [UIImage systemImageNamed:@"pencil"];
    UIImage *writeSelectedImage = [UIImage systemImageNamed:@"pencil.circle.fill"];
    writerNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:L(@"tab_writer")
                                                          image:writeImage
                                                  selectedImage:writeSelectedImage];
    
    // 文档页面
    AIUADocumentsViewController *docsVC = [[AIUADocumentsViewController alloc] init];
    UINavigationController *docsNav = [[UINavigationController alloc] initWithRootViewController:docsVC];
    
    UIImage *docsImage = [UIImage systemImageNamed:@"doc.text"];
    UIImage *docsSelectedImage = [UIImage systemImageNamed:@"doc.text.fill"];
    docsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:L(@"tab_docs")
                                                        image:docsImage
                                                selectedImage:docsSelectedImage];
    
    // 设置页面
    AIUASettingsViewController *settingsVC = [[AIUASettingsViewController alloc] init];
    UINavigationController *settingsNav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    
    UIImage *settingsImage = [UIImage systemImageNamed:@"gearshape"];
    UIImage *settingsSelectedImage = [UIImage systemImageNamed:@"gearshape.fill"];
    settingsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:L(@"tab_settings")
                                                            image:settingsImage
                                                    selectedImage:settingsSelectedImage];
    
    self.viewControllers = @[hotNav, writerNav, docsNav, settingsNav];
    
    // 自定义 tabBar 外观
    [self customizeTabBarAppearance];
}

- (void)customizeTabBarAppearance {
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance configureWithDefaultBackground];
    
    // 设置未选中状态的颜色
    appearance.stackedLayoutAppearance.normal.titleTextAttributes = @{
        NSForegroundColorAttributeName: AIUA_GRAY_COLOR,
        NSFontAttributeName: AIUAUIFontMedium(10)
    };
    
    // 设置选中状态的颜色
    appearance.stackedLayoutAppearance.selected.titleTextAttributes = @{
        NSForegroundColorAttributeName: AIUA_BLUE_COLOR,
        NSFontAttributeName: AIUAUIFontSemibold(10)
    };
    
    // 设置图标颜色
    appearance.stackedLayoutAppearance.normal.iconColor = AIUA_GRAY_COLOR;
    appearance.stackedLayoutAppearance.selected.iconColor = AIUA_BLUE_COLOR;
    
    self.tabBar.standardAppearance = appearance;
    
    self.tabBar.scrollEdgeAppearance = appearance;
}

@end
