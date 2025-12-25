//
//  AIUATrialManager.h
//  AIUniversalAssistant
//
//  试用管理器 - 管理应用试用次数（使用Keychain存储）
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 试用管理器
 * 用于管理应用的试用次数，数据存储在Keychain中（本地存储，避免iCloud同步延迟）
 */
@interface AIUATrialManager : NSObject

/**
 * 获取单例
 */
+ (instancetype)sharedManager;

/**
 * 获取剩余试用次数
 * @return 剩余试用次数（0-2）
 */
- (NSInteger)remainingTrialCount;

/**
 * 检查是否还有试用次数
 * @return YES表示还有试用次数，NO表示已用完
 */
- (BOOL)hasTrialRemaining;

/**
 * 使用一次试用次数
 * @return YES表示使用成功，NO表示没有剩余试用次数
 */
- (BOOL)useTrialOnce;

/**
 * 检查当前是否处于试用会话中
 * 当用户使用试用次数进入功能后，会设置为YES，退出功能后需要手动设置为NO
 * @return YES表示当前处于试用会话中，NO表示不在试用会话中
 */
- (BOOL)isInTrialSession;

/**
 * 开始试用会话
 * 在用户使用试用次数进入功能后调用
 */
- (void)beginTrialSession;

/**
 * 结束试用会话
 * 在用户退出功能后调用
 */
- (void)endTrialSession;

/**
 * 重置试用次数（用于测试）
 */
- (void)resetTrialCount;

@end

NS_ASSUME_NONNULL_END

