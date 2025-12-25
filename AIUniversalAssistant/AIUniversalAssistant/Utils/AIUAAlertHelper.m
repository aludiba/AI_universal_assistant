//
//  AIUAAlertHelper.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/10/9.
//

#import "AIUAAlertHelper.h"
#import "AIUAToolsManager.h"
#import <objc/runtime.h>

@implementation AIUAAlertHelper

+ (instancetype)sharedHelper {
    static AIUAAlertHelper *helper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[self alloc] init];
    });
    return helper;
}

+ (void)showAlertWithTitle:(nullable NSString *)title
                   message:(nullable NSString *)message
             cancelBtnText:(nullable NSString *)cancelText
            confirmBtnText:(nullable NSString *)confirmText
              inController:(nullable UIViewController *)controller
              cancelAction:(nullable AIUAAlertActionBlock)cancelAction
             confirmAction:(nullable AIUAAlertActionBlock)confirmAction {
    // 如果没有传 controller，则使用顶层控制器
    if (!controller) {
        controller = [AIUAToolsManager topViewController];
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    if (cancelText) {
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:cancelText
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * _Nonnull action) {
            if (cancelAction) {
                cancelAction();
            }
        }];
        [alert addAction:cancel];
    }
    
    if (confirmText) {
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:confirmText
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
            if (confirmAction) {
                confirmAction();
            }
        }];
        [alert addAction:confirm];
    }
    
    if (controller) {
        [controller presentViewController:alert animated:YES completion:nil];
    } else {
        [[AIUAToolsManager topViewController] presentViewController:alert animated:YES completion:nil];
    }
}

+ (void)showActionWithTitle:(nullable NSString *)title
                         message:(nullable NSString *)message
                         actions:(nullable NSArray *)actions
                         preferredStyle:(UIAlertControllerStyle)preferredStyle
                         inController:(nullable UIViewController *)controller
                         actionHandler:(nullable  void(^)(NSString *actionTitle))handler {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:preferredStyle];
    
    for (NSDictionary *actionDict in actions) {
        NSString *actionTitle = actionDict[@"title"];
        NSNumber *styleNumber = actionDict[@"style"];
        UIAlertActionStyle style = (UIAlertActionStyle)[styleNumber integerValue];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:actionTitle
                                                         style:style
                                                       handler:^(UIAlertAction * _Nonnull action) {
            if (handler) {
                handler(actionTitle);
            }
        }];
        [alertController addAction:action];
    }
    
    // 添加取消按钮
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:L(@"cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alertController addAction:cancelAction];
    
    [controller presentViewController:alertController animated:YES completion:nil];
}

+ (void)showDebugErrorAlert:(NSString *)errorMessage context:(nullable NSString *)context {
#if AIUA_SHOW_DEBUG_ERROR_ALERTS
    if (!errorMessage || errorMessage.length == 0) {
        return;
    }
    
    // 构建标题
    NSString *title = context ? [NSString stringWithFormat:@"[调试] %@", context] : @"[调试] 错误提示";
    
    // 获取顶层视图控制器
    UIViewController *topVC = [AIUAToolsManager topViewController];
    if (!topVC) {
        NSLog(@"[AlertHelper] 无法显示调试错误弹窗：无法获取顶层视图控制器");
        return;
    }
    
    // 显示弹窗
    [self showAlertWithTitle:title
                     message:errorMessage
               cancelBtnText:nil
              confirmBtnText:L(@"confirm") ?: @"确定"
                inController:topVC
                cancelAction:nil
               confirmAction:nil];
    
    NSLog(@"[AlertHelper] 显示调试错误弹窗: %@ - %@", context ?: @"未知", errorMessage);
#endif
}

@end
