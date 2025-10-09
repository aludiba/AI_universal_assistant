//
//  AIUAMBProgressManager.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/10/9.
//

#import "AIUAMBProgressManager.h"
#import <MBProgressHUD.h>
#import "AIUAToolsManager.h"

@implementation AIUAMBProgressManager

+ (void)showHUD:(nullable UIView *)view {
    if (view) {
        [MBProgressHUD showHUDAddedTo:view animated:YES];
    } else {
        UIWindow *window = [AIUAToolsManager currentWindow];
        [MBProgressHUD showHUDAddedTo:window animated:YES];
    }
}

+ (void)hideHUD:(nullable UIView *)view {
    if (view) {
        [MBProgressHUD hideHUDForView:view animated:YES];
    } else {
        UIWindow *window = [AIUAToolsManager currentWindow];
        [MBProgressHUD hideHUDForView:window animated:YES];
    }
}

+ (void)showTextHUD:(nullable UIView *)view withText:(nullable NSString *)text andSubText:(nullable NSString *)subText {
    UIWindow *window = [AIUAToolsManager currentWindow];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view ? view : window  animated:YES];
    hud.label.text = text;  // 主文字
    hud.detailsLabel.text = subText; // 可选：副标题
    // 设置背景色为黑色
    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.bezelView.color = [UIColor colorWithWhite:0 alpha:0.3];
}

+ (void)showText:(nullable UIView *)view withText:(nullable NSString *)text andSubText:(nullable NSString *)subText  isBottom:(BOOL)isBottom {
    UIWindow *window = [AIUAToolsManager currentWindow];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view ? view : window animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    hud.detailsLabel.text = subText; // 可选：副标题
    hud.margin = 10.f;
    // 设置背景色为黑色
    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.bezelView.color = [UIColor colorWithWhite:0 alpha:0.3];
    if (isBottom) {
        hud.offset = CGPointMake(0, MBProgressMaxOffset); // 可选：显示在底部
    }
    [hud hideAnimated:YES afterDelay:2]; // 延时2秒隐藏
}

+ (void)showActionResult:(nullable UIView *)view isSuccess:(BOOL)isSuccess {
    UIWindow *window = [AIUAToolsManager currentWindow];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view ? view : window animated:YES];
    hud.mode = MBProgressHUDModeCustomView;
    if (isSuccess) {
        UIImage *successImage = [UIImage systemImageNamed:@"checkmark.circle.fill"];
        UIImageView *successView = [[UIImageView alloc] initWithImage:successImage];
        successView.tintColor = [UIColor systemGreenColor]; // ✅ 成功提示绿色
        hud.customView = successView;
        hud.label.text = L(@"success");
    } else {
        UIImage *errorImage = [UIImage systemImageNamed:@"xmark.circle.fill"];
        UIImageView *errorView = [[UIImageView alloc] initWithImage:errorImage];
        errorView.tintColor = [UIColor systemRedColor]; // ❌ 失败提示红色
        hud.customView = errorView;
        hud.label.text = L(@"failure");
    }
    // 设置背景色为黑色
    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.bezelView.color = [UIColor colorWithWhite:0 alpha:0.3];
    [hud hideAnimated:YES afterDelay:2.0];
}

@end
