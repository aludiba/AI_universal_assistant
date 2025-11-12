//
//  AIUAWordPackManager.h
//  AIUniversalAssistant
//
//  字数包管理器 - 管理VIP赠送和购买的字数包
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 字数包类型
typedef NS_ENUM(NSUInteger, AIUAWordPackType) {
    AIUAWordPackType500K = 0,   // 500,000字 - ¥6
    AIUAWordPackType2M,          // 2,000,000字 - ¥18
    AIUAWordPackType6M           // 6,000,000字 - ¥38
};

// 字数包购买通知
extern NSString * const AIUAWordPackPurchasedNotification;
// 字数消耗通知
extern NSString * const AIUAWordConsumedNotification;

/**
 * 字数包管理器
 * 功能：管理VIP赠送字数、购买字数包、字数消耗、iCloud同步
 */
@interface AIUAWordPackManager : NSObject

/**
 * 获取单例
 */
+ (instancetype)sharedManager;

#pragma mark - 字数查询

/**
 * 获取VIP赠送字数（剩余）
 */
- (NSInteger)vipGiftedWords;

/**
 * 获取购买的字数（剩余）
 */
- (NSInteger)purchasedWords;

/**
 * 获取总可用字数
 */
- (NSInteger)totalAvailableWords;

/**
 * 获取已消耗字数
 */
- (NSInteger)consumedWords;

#pragma mark - 字数包购买

/**
 * 购买字数包
 * @param type 字数包类型
 * @param completion 购买完成回调
 */
- (void)purchaseWordPack:(AIUAWordPackType)type
              completion:(void(^)(BOOL success, NSError * _Nullable error))completion;

/**
 * 获取字数包对应的字数
 */
- (NSInteger)wordsForPackType:(AIUAWordPackType)type;

/**
 * 获取字数包对应的价格
 */
- (NSString *)priceForPackType:(AIUAWordPackType)type;

/**
 * 获取字数包对应的产品ID
 */
- (NSString *)productIDForPackType:(AIUAWordPackType)type;

#pragma mark - VIP赠送

/**
 * 刷新VIP赠送字数
 * 当用户订阅VIP时调用，赠送50万字
 */
- (void)refreshVIPGiftedWords;

#pragma mark - 字数消耗

/**
 * 消耗字数
 * @param words 要消耗的字数
 * @param completion 消耗完成回调，success表示是否成功，remainingWords表示剩余字数
 */
- (void)consumeWords:(NSInteger)words
          completion:(void(^)(BOOL success, NSInteger remainingWords))completion;

/**
 * 检查字数是否足够
 */
- (BOOL)hasEnoughWords:(NSInteger)words;

/**
 * 根据字数统计规则计算文本的字数
 * 规则：1个中文字符、英文字母、数字、标点或空格均计为1字
 * @param text 要统计的文本
 * @return 字数
 */
+ (NSInteger)countWordsInText:(NSString *)text;

#pragma mark - iCloud同步

/**
 * 检查iCloud是否可用
 * @return YES表示iCloud可用，NO表示不可用（未登录Apple ID或未开启iCloud Drive）
 */
- (BOOL)isiCloudAvailable;

/**
 * 启用iCloud同步（如果可用）
 * 如果iCloud不可用，会自动降级到本地存储
 */
- (void)enableiCloudSync;

/**
 * 从iCloud同步数据
 */
- (void)syncFromiCloud;

/**
 * 上传数据到iCloud
 */
- (void)syncToiCloud;

#pragma mark - 数据导出/导入（iCloud不可用时的替代方案）

/**
 * 导出字数包数据为JSON字符串（用于手动备份）
 * @return JSON字符串，如果失败返回nil
 */
- (NSString * _Nullable)exportWordPackData;

/**
 * 导入字数包数据（从JSON字符串）
 * @param jsonString JSON格式的数据字符串
 * @param completion 导入完成回调，success表示是否成功
 */
- (void)importWordPackData:(NSString *)jsonString
                completion:(void(^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END

