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
#define AIUAUIColorRGB(r, g, b) AIUAUIColorRGBA(r, g, b, 1.0)

// ========== 暗黑模式适配的颜色宏定义 ==========

// 背景颜色（适配暗黑模式）
#define AIUA_BACK_COLOR  [UIColor systemBackgroundColor]
#define AIUA_SECONDARY_BACK_COLOR  [UIColor secondarySystemBackgroundColor]
#define AIUA_TERTIARY_BACK_COLOR  [UIColor tertiarySystemBackgroundColor]

// 文本颜色（适配暗黑模式）
#define AIUA_LABEL_COLOR  [UIColor labelColor]
#define AIUA_SECONDARY_LABEL_COLOR  [UIColor secondaryLabelColor]
#define AIUA_TERTIARY_LABEL_COLOR  [UIColor tertiaryLabelColor]

// 分隔线和边框颜色（适配暗黑模式）
#define AIUA_DIVIDER_COLOR  [UIColor separatorColor]
#define AIUA_GRAY_COLOR  [UIColor secondaryLabelColor]

// 卡片背景颜色（适配暗黑模式）
#define AIUA_CARD_BACKGROUND_COLOR  [UIColor secondarySystemBackgroundColor]

// 系统颜色（适配暗黑模式）
#define AIUA_WHITE_COLOR  [UIColor systemBackgroundColor]
#define AIUA_BLACK_COLOR  [UIColor labelColor]

// 动态颜色辅助宏：根据模式返回不同颜色
#define AIUA_DynamicColor(lightColor, darkColor) \
    ([UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) { \
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) { \
            return darkColor; \
        } else { \
            return lightColor; \
        } \
    }])

// 常用动态颜色组合
#define AIUA_GroupedBackgroundColor  [UIColor systemGroupedBackgroundColor]
#define AIUA_SecondaryGroupedBackgroundColor  [UIColor secondarySystemGroupedBackgroundColor]
#define AIUA_TertiaryGroupedBackgroundColor  [UIColor tertiarySystemGroupedBackgroundColor]

// 蓝色（保持固定，但可以添加暗黑模式变体）
#define AIUA_BLUE_COLOR  AIUAUIColorSimplifyRGB(0.2, 0.4, 0.8)
#define L(key) NSLocalizedString((key), nil)
#define WeakType(type)  __weak typeof(type) weak##type = type
#define StrongType(type)  __strong typeof(type) strong##type = weak##type


extern BOOL AIUA_isNotchScreen(void);

NS_ASSUME_NONNULL_BEGIN

@interface AIUAMacros : NSObject

@end

NS_ASSUME_NONNULL_END
