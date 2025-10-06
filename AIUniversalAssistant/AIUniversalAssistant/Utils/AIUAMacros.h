//
//  AIUAMacros.h
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#import <Foundation/Foundation.h>
#import "UIView+AIUA.h"

#define AIUAScreenWidth            [[UIScreen mainScreen] bounds].size.width
#define AIUAScreenHeight           [[UIScreen mainScreen] bounds].size.height
#define AIUAMAXScreenSide          MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)
// 宏定义 - 状态栏高度
#define AIUA_STATUS_BAR_HEIGHT \
^CGFloat{ \
    if (@available(iOS 13.0, *)) { \
        UIWindow *window = UIApplication.sharedApplication.windows.firstObject; \
        return window.windowScene.statusBarManager.statusBarFrame.size.height; \
    } else { \
        return UIApplication.sharedApplication.statusBarFrame.size.height; \
    } \
}()
// 宏定义 - 导航栏高度
#define AIUA_NAV_BAR_HEIGHT       44.0
// 宏定义 - 状态栏 + 导航栏总高度
#define AIUA_NAV_BAR_TOTAL_HEIGHT (AIUA_STATUS_BAR_HEIGHT + AIUA_NAV_BAR_HEIGHT)

#define AIUA_IS_iphoneX            (AIUA_isNotchScreen())
#define AIUA_bottomHeight          (AIUA_IS_iphoneX?34:0)
#define AIUA_tabBarHeight          (50+AIUA_bottomHeight)

#define AIUAUIFontSystem(size) [UIFont systemFontOfSize:(size)]
#define AIUAUIFontBold(size) [UIFont boldSystemFontOfSize:(size)]
#define AIUAUIFontLight(size) [UIFont systemFontOfSize:(size) weight:UIFontWeightLight]
#define AIUAUIFontMedium(size) [UIFont systemFontOfSize:(size) weight:UIFontWeightMedium]
#define AIUAUIFontSemibold(size) [UIFont systemFontOfSize:(size) weight:UIFontWeightSemibold]
#define AIUAUIColorFromRGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0 \
                                                    green:(g)/255.0 \
                                                     blue:(b)/255.0 \
                                                    alpha:(a)]
#define AIUAUIColorFromRGB(r, g, b) AIUAUIColorFromRGBA(r, g, b, 1.0)
#define AIUA_BACK_COLOR  [UIColor colorWithWhite:0.95 alpha:1]



extern BOOL AIUA_isNotchScreen(void);

NS_ASSUME_NONNULL_BEGIN

@interface AIUAMacros : NSObject

@end

NS_ASSUME_NONNULL_END
