//
//  AIUAMacros.h
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#import <Foundation/Foundation.h>
#import "UIView+AIUA.h"
#import "AIUAToolsManager.h"

#define AIUAScreenWidth            [[UIScreen mainScreen] bounds].size.width
#define AIUAScreenHeight           [[UIScreen mainScreen] bounds].size.height
#define AIUAMAXScreenSide          MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)
// 宏定义 - 状态栏高度
#define AIUA_STATUS_BAR_HEIGHT \
^CGFloat{ \
    UIWindow *window = [AIUAToolsManager currentWindow]; \
    return window.windowScene.statusBarManager.statusBarFrame.size.height; \
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
#define AIUAUIColorSimplifyRGBA(r, g, b, a) [UIColor colorWithRed:(r) \
                                                    green:(g) \
                                                     blue:(b) \
                                                    alpha:(a)]
#define AIUAUIColorSimplifyRGB(r, g, b) AIUAUIColorSimplifyRGBA(r, g, b, 1.0)
#define AIUAUIColorRGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.0 \
                                                    green:(g)/255.0 \
                                                     blue:(b)/255.0 \
                                                    alpha:(a)]
#define AIUAUIColorRGB(r, g, b) AIUAUIColorFromRGBA(r, g, b, 1.0)
#define AIUA_BACK_COLOR  [UIColor colorWithWhite:0.95 alpha:1]
#define AIUA_GRAY_COLOR  [UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1.0]
#define AIUA_DIVIDER_COLOR  [UIColor colorWithWhite:0.9 alpha:1.0]
#define AIUA_BLUE_COLOR  AIUAUIColorSimplifyRGB(0.2, 0.4, 0.8)
#define L(key) NSLocalizedString((key), nil)
#define WeakType(type)  __weak typeof(type) weak##type = type
#define StrongType(type)  __strong typeof(type) strong##type = weak##type

extern BOOL AIUA_isNotchScreen(void);

NS_ASSUME_NONNULL_BEGIN

@interface AIUAMacros : NSObject

@end

NS_ASSUME_NONNULL_END
