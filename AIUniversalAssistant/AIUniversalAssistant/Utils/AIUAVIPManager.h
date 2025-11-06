//
//  AIUAVIPManager.h
//  AIUniversalAssistant
//
//  VIP权限管理工具类
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * VIP权限管理器
 * 用于统一管理应用内的VIP功能权限检查和提示
 */
@interface AIUAVIPManager : NSObject

/**
 * 获取单例
 */
+ (instancetype)sharedManager;

/**
 * 检查是否为VIP用户
 */
- (BOOL)isVIPUser;

/**
 * 检查VIP权限，如果不是VIP则显示提示弹窗
 * @param viewController 当前视图控制器
 * @param completion 回调，YES表示有权限（是VIP），NO表示无权限（不是VIP）
 */
- (void)checkVIPPermissionWithViewController:(UIViewController *)viewController
                                  completion:(void(^)(BOOL hasPermission))completion;

/**
 * 显示VIP权限提示弹窗
 * @param viewController 当前视图控制器
 * @param featureName 功能名称（如："创作模版"、"续写"等）
 * @param completion 用户点击"开通会员"后的回调
 */
- (void)showVIPAlertWithViewController:(UIViewController *)viewController
                           featureName:(NSString * _Nullable)featureName
                            completion:(void(^ _Nullable)(void))completion;

/**
 * 导航到会员开通页面
 * @param viewController 当前视图控制器
 */
- (void)navigateToMembershipPageFromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END

