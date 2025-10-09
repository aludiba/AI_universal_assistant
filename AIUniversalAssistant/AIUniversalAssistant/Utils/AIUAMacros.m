//
//  AIUAMacros.m
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 10/6/25.
//

#import "AIUAMacros.h"

inline BOOL AIUA_isNotchScreen(void) {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return NO;
    }
    
    BOOL isNotchScreen = AIUAMAXScreenSide >= 812.0;//((AIUAMAXScreenSide == 812.0) || (AIUAMAXScreenSide == 896));
    UIWindow *window = [[UIApplication sharedApplication].windows firstObject];
    if (window) {
        isNotchScreen = window.safeAreaInsets.bottom > 0;
    }
    return isNotchScreen;
}

@implementation AIUAMacros

@end
