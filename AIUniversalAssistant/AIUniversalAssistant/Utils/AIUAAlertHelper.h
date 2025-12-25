//
//  AIUAAlertHelper.h
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/10/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AIUAAlertActionBlock)(void);

@interface AIUAAlertHelper : NSObject

+ (instancetype)sharedHelper;

+ (void)showAlertWithTitle:(nullable NSString *)title
                   message:(nullable NSString *)message
             cancelBtnText:(nullable NSString *)cancelText
              confirmBtnText:(nullable NSString *)confirmText
              inController:(nullable UIViewController *)controller
               cancelAction:(nullable AIUAAlertActionBlock)cancelAction
              confirmAction:(nullable AIUAAlertActionBlock)confirmAction;

+ (void)showActionWithTitle:(nullable NSString *)title
                         message:(nullable NSString *)message
                         actions:(nullable NSArray *)actions
                         preferredStyle:(UIAlertControllerStyle)preferredStyle
                         inController:(nullable UIViewController *)controller
                         actionHandler:(nullable  void(^)(NSString *actionTitle))handler;

/**
 * 显示调试错误弹窗（仅在 AIUA_SHOW_DEBUG_ERROR_ALERTS 为1时显示）
 * @param errorMessage 错误信息
 * @param context 错误上下文（可选，用于标识错误来源）
 */
+ (void)showDebugErrorAlert:(NSString *)errorMessage context:(nullable NSString *)context;

@end

NS_ASSUME_NONNULL_END
