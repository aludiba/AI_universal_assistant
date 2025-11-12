//
//  AIUAKeychainManager.m
//  AIUniversalAssistant
//
//  钥匙串管理器实现
//

#import "AIUAKeychainManager.h"
#import <Security/Security.h>

// 钥匙串服务标识
static NSString * const kAIUAKeychainService = @"com.yourcompany.aiassistant.keychain";

@interface AIUAKeychainManager ()

@end

@implementation AIUAKeychainManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
    static AIUAKeychainManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AIUAKeychainManager alloc] init];
    });
    return instance;
}

#pragma mark - 私有方法 - Keychain操作

- (NSMutableDictionary *)baseQueryForKey:(NSString *)key {
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrService] = kAIUAKeychainService;
    query[(__bridge id)kSecAttrAccount] = key;
    return query;
}

- (BOOL)setData:(NSData *)data forKey:(NSString *)key {
    if (!key || key.length == 0) {
        return NO;
    }
    
    NSMutableDictionary *query = [self baseQueryForKey:key];
    
    // 先删除旧值
    SecItemDelete((__bridge CFDictionaryRef)query);
    
    // 添加新值
    query[(__bridge id)kSecValueData] = data;
    query[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    
    if (status == errSecSuccess) {
        NSLog(@"[Keychain] 保存成功: %@", key);
        return YES;
    } else {
        NSLog(@"[Keychain] 保存失败: %@, 错误码: %d", key, (int)status);
        return NO;
    }
}

- (NSData * _Nullable)dataForKey:(NSString *)key {
    if (!key || key.length == 0) {
        return nil;
    }
    
    NSMutableDictionary *query = [self baseQueryForKey:key];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    
    if (status == errSecSuccess && result) {
        NSData *data = (__bridge_transfer NSData *)result;
        NSLog(@"[Keychain] 读取成功: %@", key);
        return data;
    } else if (status == errSecItemNotFound) {
        NSLog(@"[Keychain] 键不存在: %@", key);
        return nil;
    } else {
        NSLog(@"[Keychain] 读取失败: %@, 错误码: %d", key, (int)status);
        return nil;
    }
}

#pragma mark - 公开方法

- (BOOL)setString:(NSString *)value forKey:(NSString *)key {
    if (!value) {
        return [self removeObjectForKey:key];
    }
    
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    return [self setData:data forKey:key];
}

- (NSString *)stringForKey:(NSString *)key {
    NSData *data = [self dataForKey:key];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (BOOL)setInteger:(NSInteger)value forKey:(NSString *)key {
    NSString *stringValue = [NSString stringWithFormat:@"%ld", (long)value];
    return [self setString:stringValue forKey:key];
}

- (NSInteger)integerForKey:(NSString *)key {
    NSString *stringValue = [self stringForKey:key];
    if (stringValue) {
        return [stringValue integerValue];
    }
    return 0;
}

- (BOOL)setObject:(id)object forKey:(NSString *)key {
    if (!object) {
        return [self removeObjectForKey:key];
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    
    if (error || !jsonData) {
        NSLog(@"[Keychain] JSON序列化失败: %@", error.localizedDescription);
        return NO;
    }
    
    return [self setData:jsonData forKey:key];
}

- (id)objectForKey:(NSString *)key {
    NSData *data = [self dataForKey:key];
    if (!data) {
        return nil;
    }
    
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error) {
        NSLog(@"[Keychain] JSON反序列化失败: %@", error.localizedDescription);
        return nil;
    }
    
    return object;
}

- (BOOL)removeObjectForKey:(NSString *)key {
    if (!key || key.length == 0) {
        return NO;
    }
    
    NSMutableDictionary *query = [self baseQueryForKey:key];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    
    if (status == errSecSuccess || status == errSecItemNotFound) {
        NSLog(@"[Keychain] 删除成功: %@", key);
        return YES;
    } else {
        NSLog(@"[Keychain] 删除失败: %@, 错误码: %d", key, (int)status);
        return NO;
    }
}

- (BOOL)hasObjectForKey:(NSString *)key {
    return [self dataForKey:key] != nil;
}

@end

