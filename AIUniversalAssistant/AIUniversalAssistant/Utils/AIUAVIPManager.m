//
//  AIUAVIPManager.m
//  AIUniversalAssistant
//
//  VIP权限管理工具类
//

#import "AIUAVIPManager.h"
#import "AIUAIAPManager.h"
#import "AIUATrialManager.h"
#import "AIUAMembershipViewController.h"
#import "AIUAMacros.h"
#import "AIUAConfigID.h"

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
#if AIUA_VIP_CHECK_ENABLED
    // 开启会员检测，正常检查VIP状态
    return [[AIUAIAPManager sharedManager] isVIPMember];
#else
    // 关闭会员检测，所有用户视为VIP
    return YES;
#endif
}

- (void)checkVIPPermissionWithViewController:(UIViewController *)viewController featureName:(NSString * _Nullable)featureName completion:(void(^)(BOOL hasPermission))completion {
#if AIUA_VIP_CHECK_ENABLED
    // 开启会员检测，检查VIP状态和试用次数
    BOOL isVIP = [self isVIPUser];
    
    if (isVIP) {
        // 是VIP，直接执行
        if (completion) {
            completion(YES);
        }
        return;
    }
    
    // 不是VIP，检查试用次数
    AIUATrialManager *trialManager = [AIUATrialManager sharedManager];
    
    // 先结束之前的试用会话（如果有的话）
    if ([trialManager isInTrialSession]) {
        NSLog(@"[VIP] 结束上一次试用会话");
        [trialManager endTrialSession];
    }
    
    NSInteger remainingBefore = [trialManager remainingTrialCount];
    
    if (remainingBefore > 0) {
        // 有试用次数，静默使用一次试用（不显示提示）
        BOOL useSuccess = [trialManager useTrialOnce];
        
        if (useSuccess) {
            // 开始试用会话
            [trialManager beginTrialSession];
            
            NSLog(@"[VIP] 使用一次试用机会，剩余次数: %ld", (long)[trialManager remainingTrialCount]);
            
            // 直接执行，不显示提示
            if (completion) {
                completion(YES);
            }
        } else {
            // 使用试用失败（理论上不应该发生）
            [self showTrialExpiredAlertWithViewController:viewController completion:^{
                if (completion) {
                    completion(NO);
                }
            }];
        }
    } else {
        // 没有试用次数，显示"试用已结束"提示
        [self showTrialExpiredAlertWithViewController:viewController completion:^{
            if (completion) {
                completion(NO);
            }
        }];
    }
#else
    // 关闭会员检测，所有用户视为VIP，直接执行
    if (completion) {
        completion(YES);
    }
#endif
}

- (void)showVIPAlertWithViewController:(UIViewController *)viewController
                           featureName:(NSString * _Nullable)featureName
                            completion:(void (^)(void))completion {
    if (!viewController) {
        NSLog(@"[VIP] showVIPAlert: viewController 为空");
        return;
    }
    
    // 检查试用状态，构建更友好的提示消息
    AIUATrialManager *trialManager = [AIUATrialManager sharedManager];
    BOOL hasTrialRemaining = [trialManager hasTrialRemaining];
    
    NSString *title;
    NSString *message;
    
    if (hasTrialRemaining) {
        // 还有试用次数，提示试用次数已用完
        title = L(@"trial_expired_title");
        message = L(@"trial_expired_message");
    } else {
        // 没有试用次数，提示开通会员
        title = L(@"vip_unlock_required");
        if (featureName && featureName.length > 0) {
            message = [NSString stringWithFormat:L(@"vip_feature_locked_message"), featureName];
        } else {
            message = L(@"vip_general_locked_message");
        }
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
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

- (void)showTrialExpiredAlertWithViewController:(UIViewController *)viewController
                                      completion:(void (^)(void))completion {
    if (!viewController) {
        NSLog(@"[VIP] showTrialExpiredAlert: viewController 为空");
        return;
    }
    
    NSString *title = L(@"trial_expired_title");
    NSString *message = L(@"trial_expired_message");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
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
