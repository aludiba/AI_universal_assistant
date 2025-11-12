# Keychain钥匙串存储方案

## 📋 概述

当iCloud不可用时，应用使用**Keychain（钥匙串）**作为本地存储方案，提供比NSUserDefaults更安全的数据存储。

---

## 🔐 Keychain优势

### 1. 安全性

- ✅ **加密存储**：数据在Keychain中自动加密
- ✅ **系统级保护**：由iOS系统管理，应用无法直接访问其他应用的数据
- ✅ **访问控制**：可以设置访问权限（如需要设备解锁）

### 2. 持久化

- ✅ **数据保留**：即使应用卸载，数据也可能保留（取决于配置）
- ✅ **备份支持**：可以配置是否包含在iTunes备份中

### 3. 性能

- ✅ **快速读写**：Keychain操作速度快
- ✅ **系统优化**：iOS系统对Keychain进行了优化

---

## 🛠️ 实现方案

### 1. Keychain管理器

**文件**: `AIUAKeychainManager.h/m`

提供统一的Keychain操作接口：

```objective-c
// 保存字符串
- (BOOL)setString:(NSString *)value forKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;

// 保存整数
- (BOOL)setInteger:(NSInteger)value forKey:(NSString *)key;
- (NSInteger)integerForKey:(NSString *)key;

// 保存对象（自动JSON序列化）
- (BOOL)setObject:(id)object forKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;

// 删除
- (BOOL)removeObjectForKey:(NSString *)key;
```

### 2. 字数包管理器集成

**文件**: `AIUAWordPackManager.m`

所有本地存储操作都通过Keychain：

```objective-c
// 本地存储辅助方法（使用Keychain）
- (void)setLocalInteger:(NSInteger)value forKey:(NSString *)key {
    [self.keychainManager setInteger:value forKey:key];
}

- (NSInteger)localIntegerForKey:(NSString *)key {
    return [self.keychainManager integerForKey:key];
}

- (void)setLocalObject:(id)object forKey:(NSString *)key {
    [self.keychainManager setObject:object forKey:key];
}

- (id)localObjectForKey:(NSString *)key {
    return [self.keychainManager objectForKey:key];
}
```

---

## 📊 存储的数据

### 存储在Keychain中的数据

1. **VIP赠送字数** (`kAIUAVIPGiftedWords`)
   - 类型：整数
   - 说明：VIP用户每日剩余赠送字数

2. **VIP刷新日期** (`kAIUAVIPGiftedWordsLastRefreshDate`)
   - 类型：NSDate对象（序列化为JSON）
   - 说明：上次刷新VIP赠送字数的日期

3. **购买记录** (`kAIUAWordPackPurchases`)
   - 类型：NSArray（序列化为JSON）
   - 说明：字数包购买记录数组

4. **消耗记录** (`kAIUAConsumedWords`)
   - 类型：整数
   - 说明：累计消耗的字数

---

## 🔄 数据流程

### 存储流程

```
应用写入数据
    ↓
AIUAWordPackManager
    ↓
setLocalInteger/setLocalObject
    ↓
AIUAKeychainManager
    ↓
Keychain Services API
    ↓
iOS Keychain（加密存储）
```

### 读取流程

```
应用读取数据
    ↓
AIUAWordPackManager
    ↓
localIntegerForKey/localObjectForKey
    ↓
AIUAKeychainManager
    ↓
Keychain Services API
    ↓
iOS Keychain（解密读取）
```

---

## 🔐 Keychain配置

### 访问权限

当前配置：`kSecAttrAccessibleAfterFirstUnlock`

- ✅ **设备首次解锁后可用**：设备重启后，首次解锁即可访问
- ✅ **适合应用数据**：适合存储应用数据，不需要每次解锁设备

### 其他可选配置

- `kSecAttrAccessibleWhenUnlocked`：设备解锁时可用（最安全）
- `kSecAttrAccessibleAlways`：始终可用（不推荐，安全性较低）
- `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`：需要密码且仅本设备（最安全）

---

## 📝 使用示例

### 保存数据

```objective-c
// 保存整数
[[AIUAKeychainManager sharedManager] setInteger:500000 forKey:@"vipGiftedWords"];

// 保存对象
NSDictionary *data = @{@"key": @"value"};
[[AIUAKeychainManager sharedManager] setObject:data forKey:@"purchases"];
```

### 读取数据

```objective-c
// 读取整数
NSInteger words = [[AIUAKeychainManager sharedManager] integerForKey:@"vipGiftedWords"];

// 读取对象
NSDictionary *data = [[AIUAKeychainManager sharedManager] objectForKey:@"purchases"];
```

### 删除数据

```objective-c
[[AIUAKeychainManager sharedManager] removeObjectForKey:@"vipGiftedWords"];
```

---

## ⚠️ 注意事项

### 1. 数据大小限制

- Keychain适合存储**小型数据**（KB级别）
- 大型数据（MB级别）建议使用文件系统

### 2. 序列化限制

- 对象必须可以JSON序列化
- NSDate等特殊类型会自动转换为时间戳

### 3. 线程安全

- Keychain操作是**线程安全**的
- 可以在任何线程调用

### 4. 错误处理

- Keychain操作可能失败（如Keychain已满）
- 建议检查返回值

---

## 🎯 总结

### ✅ 优势

1. ✅ **安全性高**：加密存储，系统级保护
2. ✅ **持久化**：数据可能保留即使应用卸载
3. ✅ **性能好**：读写速度快
4. ✅ **易用性**：统一的API接口

### 📌 适用场景

- ✅ 存储敏感数据（如字数包信息）
- ✅ 需要持久化的配置数据
- ✅ 小型数据存储（KB级别）

### 🔄 与iCloud的配合

- **iCloud可用**：Keychain + iCloud同步
- **iCloud不可用**：仅Keychain存储
- **无缝切换**：自动降级，用户无感知

---

**Keychain提供了安全、可靠的本地存储方案，确保用户数据的安全性！** 🔐

