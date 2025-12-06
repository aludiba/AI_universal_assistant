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

/**
 * 获取即将过期的字数（7天内），按天数分组
 * @return 字典，key为剩余天数（NSNumber），value为对应天数的字数（NSNumber）
 *         例如：@{@7: @10000, @3: @5000} 表示7天后过期10000字，3天后过期5000字
 */
- (NSDictionary<NSNumber *, NSNumber *> *)expiringWordsByDays;

/**
 * 清除已过期的购买记录
 * 自动清理所有过期时间已到的字数包记录，释放存储空间
 */
- (void)cleanExpiredPurchases;

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

#pragma mark - 奖励字数（激励视频等）
/**
 * 发放奖励字数（追加记录，不覆盖既有购买记录）
 * @param words 奖励字数
 * @param days 有效天数（如90天）
 */
- (void)awardBonusWords:(NSInteger)words validDays:(NSInteger)days completion:(void (^ _Nullable)(void))completion;

#pragma mark - VIP赠送

/**
 * 刷新VIP赠送字数
 * 当用户订阅VIP时调用，首次订阅一次性赠送50万字
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
 * 检查iCloud可用性并提示用户（如果需要）
 * @param viewController 用于显示提示的视图控制器，如果为nil则自动查找顶层控制器
 * @param showAlert 是否显示提示，YES表示显示，NO表示静默检查
 * @return YES表示iCloud可用，NO表示不可用
 */
- (BOOL)checkiCloudAvailabilityAndPrompt:(UIViewController * _Nullable)viewController showAlert:(BOOL)showAlert;

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

