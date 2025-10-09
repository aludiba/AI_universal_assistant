//
//  AIUAMBProgressManager.h
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/10/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AIUAMBProgressManager : NSObject

// 显示加载中
+ (void)showHUD:(nullable UIView *)view;

// 隐藏
+ (void)hideHUD:(nullable UIView *)view;

// 带文字的加载中
+ (void)showTextHUD:(nullable UIView *)view withText:(nullable NSString *)text andSubText:(nullable NSString *)subText;

// 只显示文字（不带加载中）
+ (void)showText:(nullable UIView *)view withText:(nullable NSString *)text andSubText:(nullable NSString *)subText isBottom:(BOOL)isBottom;

// 显示成功/失败的提示图标
+ (void)showActionResult:(nullable UIView *)view isSuccess:(BOOL)isSuccess;

@end

NS_ASSUME_NONNULL_END
