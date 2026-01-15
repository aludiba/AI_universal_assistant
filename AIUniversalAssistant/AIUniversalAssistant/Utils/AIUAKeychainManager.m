//
//  AIUAKeychainManager.m
//  AIUniversalAssistant
//
//  钥匙串管理器实现
//

#import "AIUAKeychainManager.h"
#import <Security/Security.h>

// Keychain Service 需要稳定且与 Bundle ID 匹配；同时兼容旧版本写入的 service（用于迁移）。
static NSString * const kAIUAKeychainLegacyService = @"com.yourcompany.aiassistant.keychain";
static NSString * const kAIUAKeychainPreviousFixedService = @"com.hujiaofen.writingCat.keychain";

static inline NSString *AIUAKeychainPrimaryService(void) {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (!bundleID || bundleID.length == 0) {
        bundleID = @"aiua";
    }
    return [NSString stringWithFormat:@"%@.keychain", bundleID];
}

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

- (NSMutableDictionary *)baseQueryForKey:(NSString *)key service:(NSString *)service {
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrService] = service;
    query[(__bridge id)kSecAttrAccount] = key;
    return query;
}

- (BOOL)setData:(NSData *)data forKey:(NSString *)key {
    if (!key || key.length == 0) {
        return NO;
    }
    
    NSMutableDictionary *query = [self baseQueryForKey:key service:AIUAKeychainPrimaryService()];
    
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

    // 依次尝试：primary（当前bundleID） -> 旧固定 -> 旧占位符
    NSArray<NSString *> *servicesToTry = @[
        AIUAKeychainPrimaryService(),
        kAIUAKeychainPreviousFixedService,
        kAIUAKeychainLegacyService
    ];

    for (NSUInteger idx = 0; idx < servicesToTry.count; idx++) {
        NSString *service = servicesToTry[idx];
        NSMutableDictionary *query = [self baseQueryForKey:key service:service];
        query[(__bridge id)kSecReturnData] = @YES;
        query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

        CFTypeRef result = NULL;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);

        if (status == errSecSuccess && result) {
            NSData *data = (__bridge_transfer NSData *)result;
            NSLog(@"[Keychain] 读取成功: %@ (service=%@)", key, service);

            // 如果不是 primary service，做一次迁移到 primary，避免后续读取不一致
            NSString *primary = AIUAKeychainPrimaryService();
            if (![service isEqualToString:primary]) {
                NSLog(@"[Keychain] 迁移 Keychain 项到 primary service: %@ -> %@", service, primary);
                [self setData:data forKey:key];
                SecItemDelete((__bridge CFDictionaryRef)query);
            }
            return data;
        }

        if (status != errSecItemNotFound) {
            NSLog(@"[Keychain] 读取失败: %@ (service=%@), 错误码: %d", key, service, (int)status);
            // 非 not found 的错误，继续尝试下一个 service 没意义，直接返回
            return nil;
        }
    }

    NSLog(@"[Keychain] 键不存在: %@", key);
    return nil;
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
    NSData *archived = nil;
    if (@available(iOS 11.0, *)) {
        archived = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:NO error:&error];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        archived = [NSKeyedArchiver archivedDataWithRootObject:object];
#pragma clang diagnostic pop
    }
    
    if (error || !archived) {
        NSLog(@"[Keychain] 对象归档失败: %@", error.localizedDescription);
        return NO;
    }
    
    return [self setData:archived forKey:key];
}

- (id)objectForKey:(NSString *)key {
    NSData *data = [self dataForKey:key];
    if (!data) {
        return nil;
    }
    
    NSError *error = nil;
    id object = nil;
    if (@available(iOS 11.0, *)) {
        // 允许可变容器（很多业务会存 NSMutableArray/NSMutableDictionary；若不允许会导致解档失败、字数包等数据读不出来）
        NSSet *allowed = [NSSet setWithArray:@[
            [NSArray class],
            [NSMutableArray class],
            [NSDictionary class],
            [NSMutableDictionary class],
            [NSString class],
            [NSNumber class],
            [NSDate class],
            [NSData class],
            [NSNull class]
        ]];
        object = [NSKeyedUnarchiver unarchivedObjectOfClasses:allowed fromData:data error:&error];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#pragma clang diagnostic pop
    }
    
    if (error) {
        NSLog(@"[Keychain] 对象解档失败: %@", error.localizedDescription);
        return nil;
    }
    return object;
}

- (BOOL)removeObjectForKey:(NSString *)key {
    if (!key || key.length == 0) {
        return NO;
    }

    // 尝试删除所有可能 service 下的同名 key
    NSArray<NSString *> *servicesToTry = @[
        AIUAKeychainPrimaryService(),
        kAIUAKeychainPreviousFixedService,
        kAIUAKeychainLegacyService
    ];

    OSStatus lastStatus = errSecItemNotFound;
    for (NSString *service in servicesToTry) {
        NSMutableDictionary *query = [self baseQueryForKey:key service:service];
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
        if (status == errSecSuccess) {
            lastStatus = status;
        } else if (status != errSecItemNotFound) {
            lastStatus = status;
        }
    }
    
    if (lastStatus == errSecSuccess || lastStatus == errSecItemNotFound) {
        NSLog(@"[Keychain] 删除成功: %@", key);
        return YES;
    } else {
        NSLog(@"[Keychain] 删除失败: %@, 错误码: %d", key, (int)lastStatus);
        return NO;
    }
}

- (BOOL)hasObjectForKey:(NSString *)key {
    return [self dataForKey:key] != nil;
}

- (BOOL)removeAllObjects {
    // 删除所有可能 service 下的 Keychain 数据（兼容历史版本）
    NSArray<NSString *> *servicesToDelete = @[
        AIUAKeychainPrimaryService(),
        kAIUAKeychainPreviousFixedService,
        kAIUAKeychainLegacyService
    ];
    
    OSStatus lastStatus = errSecItemNotFound;
    for (NSString *service in servicesToDelete) {
        NSMutableDictionary *query = [NSMutableDictionary dictionary];
        query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
        query[(__bridge id)kSecAttrService] = service;
        
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
        if (status == errSecSuccess) {
            lastStatus = status;
            NSLog(@"[Keychain] 成功删除所有钥匙串数据 (service=%@)", service);
        } else if (status == errSecItemNotFound) {
            NSLog(@"[Keychain] service=%@ 没有数据需要删除", service);
            if (lastStatus == errSecItemNotFound) {
                lastStatus = status;
            }
        } else {
            NSLog(@"[Keychain] 删除所有钥匙串数据失败 (service=%@)，错误码: %d", service, (int)status);
            lastStatus = status;
        }
    }
    
    return (lastStatus == errSecSuccess || lastStatus == errSecItemNotFound);
}

@end

