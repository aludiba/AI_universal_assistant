//
//  AIUAVIPManager.m
//  AIUniversalAssistant
//
//  VIP权限管理工具类
//

#import "AIUAVIPManager.h"
#import "AIUAIAPManager.h"
#import "AIUAMembershipViewController.h"
#import "AIUAMacros.h"

@implementation AIUAVIPManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
    static AIUAVIPManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AIUAVIPManager alloc] init];
    });
    return instance;
}

#pragma mark - Public Methods

- (BOOL)isVIPUser {
    return [[AIUAIAPManager sharedManager] isVIPMember];
}

- (void)checkVIPPermissionWithViewController:(UIViewController *)viewController featureName:(NSString * _Nullable)featureName completion:(void(^)(BOOL hasPermission))completion {
    BOOL isVIP = [self isVIPUser];
    
    if (isVIP) {
        // 是VIP，直接执行
        if (completion) {
            completion(YES);
        }
    } else {
        // 不是VIP，显示提示弹窗
        [self showVIPAlertWithViewController:viewController featureName:featureName completion:^{
            if (completion) {
                completion(NO);
            }
        }];
    }
}

- (void)showVIPAlertWithViewController:(UIViewController *)viewController
                           featureName:(NSString * _Nullable)featureName
                            completion:(void (^)(void))completion {
    if (!viewController) {
        NSLog(@"[VIP] showVIPAlert: viewController 为空");
        return;
    }
    
    // 构建提示消息
    NSString *message;
    if (featureName && featureName.length > 0) {
        message = [NSString stringWithFormat:L(@"vip_feature_locked_message"), featureName];
    } else {
        message = L(@"vip_general_locked_message");
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:L(@"vip_unlock_required")
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    // "取消" 按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:L(@"cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
        if (completion) {
            completion();
        }
    }];
    
    // "开通会员" 按钮
    UIAlertAction *activateAction = [UIAlertAction actionWithTitle:L(@"activate_membership")
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
        // 导航到会员页面
        [self navigateToMembershipPageFromViewController:viewController];
        if (completion) {
            completion();
        }
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:activateAction];
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

- (void)navigateToMembershipPageFromViewController:(UIViewController *)viewController {
    if (!viewController) {
        NSLog(@"[VIP] navigateToMembershipPage: viewController 为空");
        return;
    }
    
    AIUAMembershipViewController *membershipVC = [[AIUAMembershipViewController alloc] init];
    membershipVC.hidesBottomBarWhenPushed = YES;
    
    // 如果有导航控制器，则 push；否则 present
    if (viewController.navigationController) {
        [viewController.navigationController pushViewController:membershipVC animated:YES];
    } else {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:membershipVC];
        [viewController presentViewController:nav animated:YES completion:nil];
    }
}

@end

