//
//  AIUAToolsManager.h
//  AIUniversalAssistant
//
//  Created by 褚红彪 on 2025/10/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AIUAToolsManager : NSObject

+ (UIViewController *)topViewController;

+ (UIViewController *)topViewControllerFrom:(UIViewController *)vc;

// json格式文件序列化
+ (NSDictionary *)serializationFromJson:(NSString *)path;

+ (UIWindow *)currentWindow;

+ (UIViewController *)getTopViewController;

@end

NS_ASSUME_NONNULL_END
