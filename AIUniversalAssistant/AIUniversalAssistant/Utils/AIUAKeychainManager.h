//
//  AIUAKeychainManager.h
//  AIUniversalAssistant
//
//  钥匙串管理器 - 安全存储敏感数据
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 钥匙串管理器
 * 用于安全存储敏感数据，如字数包信息
 */
@interface AIUAKeychainManager : NSObject

/**
 * 获取单例
 */
+ (instancetype)sharedManager;

#pragma mark - 基础操作

/**
 * 保存字符串到钥匙串
 * @param value 要保存的字符串
 * @param key 键名
 * @return YES表示成功，NO表示失败
 */
- (BOOL)setString:(NSString *)value forKey:(NSString *)key;

/**
 * 从钥匙串读取字符串
 * @param key 键名
 * @return 字符串，如果不存在返回nil
 */
- (NSString * _Nullable)stringForKey:(NSString *)key;

/**
 * 保存整数到钥匙串
 * @param value 要保存的整数
 * @param key 键名
 * @return YES表示成功，NO表示失败
 */
- (BOOL)setInteger:(NSInteger)value forKey:(NSString *)key;

/**
 * 从钥匙串读取整数
 * @param key 键名
 * @return 整数值，如果不存在返回0
 */
- (NSInteger)integerForKey:(NSString *)key;

/**
 * 保存对象到钥匙串（会自动序列化为JSON）
 * @param object 要保存的对象（必须是可JSON序列化的）
 * @param key 键名
 * @return YES表示成功，NO表示失败
 */
- (BOOL)setObject:(id)object forKey:(NSString *)key;

/**
 * 从钥匙串读取对象（会自动反序列化JSON）
 * @param key 键名
 * @return 对象，如果不存在返回nil
 */
- (id _Nullable)objectForKey:(NSString *)key;

/**
 * 删除钥匙串中的值
 * @param key 键名
 * @return YES表示成功，NO表示失败
 */
- (BOOL)removeObjectForKey:(NSString *)key;

/**
 * 检查钥匙串中是否存在某个键
 * @param key 键名
 * @return YES表示存在，NO表示不存在
 */
- (BOOL)hasObjectForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

