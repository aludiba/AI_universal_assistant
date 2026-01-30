# iCloud 配置文档

本文档详细说明了如何在 iOS 应用中配置和使用 iCloud Key-Value Storage 来实现数据跨设备同步。

## 📋 目录

1. [概述](#概述)
2. [Apple Developer 配置](#apple-developer-配置)
3. [Xcode 项目配置](#xcode-项目配置)
4. [代码实现说明](#代码实现说明)
5. [使用指南](#使用指南)
6. [注意事项](#注意事项)
7. [故障排除](#故障排除)

---

## 概述

本项目使用 **iCloud Key-Value Storage (NSUbiquitousKeyValueStore)** 来实现字数包数据的跨设备同步。

### 功能特点

- ✅ **自动同步**：数据变更后自动同步到 iCloud
- ✅ **跨设备共享**：同一 Apple ID 下的所有设备自动同步
- ✅ **自动降级**：iCloud 不可用时自动使用 Keychain 本地存储
- ✅ **零服务器成本**：无需后端服务器支持
- ✅ **数据安全**：由 Apple 保障数据安全

### 同步的数据

- VIP 赠送字数
- VIP 赠送标记
- 购买的字数包记录
- 字数消耗记录

---

## Apple Developer 配置

### 步骤 1: 登录 Apple Developer Portal

1. 访问 [Apple Developer Portal](https://developer.apple.com/account/)
2. 使用 Apple ID 登录

### 步骤 2: 配置 App ID

1. 进入 **Certificates, Identifiers & Profiles**
2. 选择 **Identifiers** → **App IDs**
3. 选择你的 App ID（例如：`com.yourcompany.aiassistant`）
4. 点击 **Edit** 按钮

### 步骤 3: 启用 iCloud 功能

1. 在 **Capabilities** 部分，找到 **iCloud**
2. 勾选 **iCloud** 选项
3. 在 iCloud 选项中，勾选 **Key-value storage**
4. 点击 **Save** 保存配置

### 步骤 4: 生成 Provisioning Profile

1. 如果修改了 App ID，需要重新生成 Provisioning Profile
2. 进入 **Profiles** → **Development** / **Distribution**
3. 选择对应的 Profile，点击 **Edit**
4. 确认 iCloud 已启用后，点击 **Save**
5. 下载新的 Provisioning Profile

---

## Xcode 项目配置

### 步骤 1: 打开项目设置

1. 在 Xcode 中打开项目（`.xcworkspace`）
2. 选择项目文件（最顶层的蓝色图标）
3. 选择 **TARGETS** → 你的应用 Target
4. 点击 **Signing & Capabilities** 标签

### 步骤 2: 配置 Bundle Identifier

确保 **Bundle Identifier** 与 Apple Developer Portal 中的 App ID 一致。

```
例如：com.yourcompany.aiassistant
```

### 步骤 3: 配置 Team 和 Signing

1. 在 **Team** 下拉菜单中选择你的开发团队
2. 如果是自动签名，Xcode 会自动处理 Provisioning Profile
3. 如果是手动签名，需要选择对应的 Provisioning Profile（包含 iCloud 权限的）

### 步骤 4: 添加 iCloud Capability

1. 点击 **+ Capability** 按钮（左上角）
2. 搜索并添加 **iCloud**
3. 在 iCloud 配置中，勾选 **Key-value storage**

### 步骤 5: 配置 iCloud Container（可选）

如果使用多个 App 共享数据，可以配置自定义 Container：

1. 点击 **+ Container** 按钮
2. 输入 Container ID（格式：`iCloud.$(PRODUCT_BUNDLE_IDENTIFIER)`）
3. 默认情况下，使用默认 Container 即可

### 配置完成检查清单

- [ ] App ID 在 Apple Developer Portal 中已启用 iCloud Key-value storage
- [ ] Xcode 项目中已添加 iCloud Capability
- [ ] Bundle Identifier 配置正确
- [ ] Team 和 Signing 配置正确
- [ ] Provisioning Profile 已更新并包含 iCloud 权限

---

## 代码实现说明

### 主要文件

- **`AIUAWordPackManager.h/m`** - 字数包管理器，包含 iCloud 同步逻辑

### 核心代码结构

#### 1. iCloud Store 初始化

```objective-c
@interface AIUAWordPackManager ()
@property (nonatomic, strong) NSUbiquitousKeyValueStore *iCloudStore;
@property (nonatomic, assign) BOOL iCloudSyncEnabled;
@end

- (instancetype)init {
    self = [super init];
    if (self) {
        _iCloudStore = [NSUbiquitousKeyValueStore defaultStore];
        _iCloudSyncEnabled = NO;
        // ...
    }
    return self;
}
```

#### 2. iCloud 可用性检查

```objective-c
- (BOOL)isiCloudAvailable {
    // 检查设备是否登录 Apple ID 并开启 iCloud Drive
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *ubiquityURL = [fileManager URLForUbiquityContainerIdentifier:nil];
    
    if (ubiquityURL == nil) {
        return NO;
    }
    
    // 尝试访问 iCloud Store
    @try {
        id testValue = [self.iCloudStore objectForKey:@"__test_icloud_availability__"];
        return YES;
    } @catch (NSException *exception) {
        return NO;
    }
}
```

#### 3. 启用 iCloud 同步

```objective-c
- (void)enableiCloudSync {
    if (self.iCloudSyncEnabled) {
        return;
    }
    
    // 检查 iCloud 是否可用
    if (![self isiCloudAvailable]) {
        // 自动降级到本地存储（Keychain）
        return;
    }
    
    self.iCloudSyncEnabled = YES;
    
    // 监听 iCloud 数据变化
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(iCloudStoreDidChange:)
                                                 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                               object:self.iCloudStore];
    
    // 同步 iCloud 数据
    [self.iCloudStore synchronize];
    
    // 首次启用时，从 iCloud 拉取数据
    [self syncFromiCloud];
}
```

#### 4. 从 iCloud 同步数据

```objective-c
- (void)syncFromiCloud {
    if (!self.iCloudSyncEnabled) {
        return;
    }
    
    NSDictionary *iCloudData = [self.iCloudStore dictionaryForKey:kAIUAiCloudWordPackData];
    if (!iCloudData) {
        return;
    }
    
    // 同步数据到本地 Keychain
    // ...
}
```

#### 5. 上传数据到 iCloud

```objective-c
- (void)syncToiCloud {
    if (!self.iCloudSyncEnabled) {
        return;
    }
    
    // 构建要上传的数据
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data[@"vipGiftedWords"] = @([self localIntegerForKey:kAIUAVIPGiftedWords]);
    data[@"purchases"] = purchases;
    // ...
    
    // 上传到 iCloud
    [self.iCloudStore setDictionary:data forKey:kAIUAiCloudWordPackData];
    [self.iCloudStore synchronize];
}
```

#### 6. 监听 iCloud 数据变化

```objective-c
- (void)iCloudStoreDidChange:(NSNotification *)notification {
    NSLog(@"[WordPack] iCloud数据发生变化，同步到本地");
    [self syncFromiCloud];
}
```

### 应用启动时启用 iCloud

在 `AppDelegate.m` 中：

```objective-c
- (void)applicationDidBecomeActive:(UIApplication *)application {
    // 检查 iCloud 可用性并提示用户（如果需要）
    UIViewController *topVC = [AIUAToolsManager topViewController];
    [[AIUAWordPackManager sharedManager] checkiCloudAvailabilityAndPrompt:topVC showAlert:YES];
    
    // 启用 iCloud 同步
    [[AIUAWordPackManager sharedManager] enableiCloudSync];
}
```

---

## 使用指南

### 启用 iCloud 同步

iCloud 同步会在应用启动时自动启用（在 `AppDelegate` 中调用）。

如果需要手动启用：

```objective-c
[[AIUAWordPackManager sharedManager] enableiCloudSync];
```

### 检查 iCloud 可用性

```objective-c
BOOL isAvailable = [[AIUAWordPackManager sharedManager] isiCloudAvailable];
if (isAvailable) {
    NSLog(@"iCloud 可用");
} else {
    NSLog(@"iCloud 不可用（未登录 Apple ID 或未开启 iCloud Drive）");
}
```

### 检查可用性并提示用户

```objective-c
UIViewController *viewController = self;
BOOL isAvailable = [[AIUAWordPackManager sharedManager] 
    checkiCloudAvailabilityAndPrompt:viewController 
                           showAlert:YES];
```

这会检查 iCloud 可用性，如果不可用且 `showAlert` 为 `YES`，会弹出提示引导用户到设置页面。

### 数据同步时机

数据会在以下情况自动同步到 iCloud：

- ✅ 购买字数包后
- ✅ 消耗字数后
- ✅ VIP 订阅状态变化后
- ✅ 奖励字数发放后

### 数据冲突处理

当多个设备同时修改数据时，iCloud 会按照时间戳合并数据。我们的实现策略：

1. **购买记录**：追加方式，不覆盖现有记录
2. **消耗记录**：按时间顺序消耗
3. **VIP 赠送字数**：使用最新值

---

## 注意事项

### ⚠️ 重要限制

1. **存储限制**
   - Key-Value Storage 总容量：**1 MB**
   - 单个 Key 的最大值：**1 MB**
   - 单个 App 最多：**1024 个 Key**

2. **同步延迟**
   - 数据同步不是实时的，通常需要几秒到几分钟
   - 取决于网络状况和 iCloud 服务器状态

3. **需要 Apple ID**
   - 用户必须登录 Apple ID
   - 必须开启 iCloud Drive

4. **测试环境**
   - 在模拟器中无法测试 iCloud（可以使用沙盒账户）
   - 必须在真机上测试
   - 使用不同的 Apple ID 测试跨设备同步

### ✅ 最佳实践

1. **数据大小控制**
   - 只同步必要的数据（字数包数据）
   - 避免存储大文件（使用 iCloud Drive 文档存储）

2. **错误处理**
   - 始终检查 iCloud 可用性
   - 提供本地存储降级方案（已实现）
   - 处理同步失败的情况

3. **用户体验**
   - 不要在用户设置 iCloud 前强制要求同步
   - 提供手动导出/导入功能（已实现）
   - 清晰告知用户同步状态

4. **数据安全**
   - 敏感数据存储在 Keychain 中
   - iCloud 数据自动加密传输和存储
   - 不使用 iCloud 同步敏感用户信息

### 🔒 隐私和安全

- iCloud 数据由 Apple 加密存储和传输
- 只有同一 Apple ID 下的设备可以访问
- 符合 Apple 的隐私政策要求
- 用户可以在系统设置中管理 iCloud 数据

---

## 故障排除

### 问题 1: iCloud 同步不工作

**症状**：数据无法同步到其他设备

**可能原因和解决方案**：

1. **设备未登录 Apple ID**
   - ✅ 检查：设置 → Apple ID → 确认已登录
   - ✅ 解决：登录 Apple ID

2. **未开启 iCloud Drive**
   - ✅ 检查：设置 → Apple ID → iCloud → iCloud Drive
   - ✅ 解决：开启 iCloud Drive

3. **Xcode 配置不正确**
   - ✅ 检查：Signing & Capabilities → 确认已添加 iCloud
   - ✅ 检查：确认 Key-value storage 已勾选
   - ✅ 解决：重新配置并清理项目

4. **Provisioning Profile 过期或不正确**
   - ✅ 检查：Xcode → Preferences → Accounts → Download Manual Profiles
   - ✅ 解决：更新 Provisioning Profile

5. **App ID 未启用 iCloud**
   - ✅ 检查：Apple Developer Portal → App ID → Capabilities
   - ✅ 解决：启用 iCloud Key-value storage

### 问题 2: 数据同步延迟

**症状**：数据变更后，其他设备没有立即看到

**原因**：iCloud 同步有延迟（正常现象）

**解决方案**：
- ✅ 等待几分钟后刷新
- ✅ 检查网络连接
- ✅ 手动触发同步：`[self.iCloudStore synchronize]`

### 问题 3: 数据冲突

**症状**：多个设备同时修改数据，出现不一致

**解决方案**：
- ✅ 使用时间戳确定最新数据
- ✅ 合并策略：追加而非覆盖
- ✅ 从 iCloud 同步时覆盖本地数据

### 问题 4: 测试时无法同步

**症状**：在开发/测试环境中无法测试同步

**解决方案**：

1. **使用真机测试**
   - ✅ 模拟器不支持 iCloud（可以使用沙盒账户测试）

2. **使用不同的 Apple ID**
   - ✅ 在主设备登录 Apple ID A
   - ✅ 在测试设备登录 Apple ID B
   - ✅ 无法测试跨设备同步（iCloud 基于 Apple ID）

3. **使用沙盒账户**
   - ✅ 在设置中注销主 Apple ID
   - ✅ 登录沙盒测试账户
   - ✅ 在 App Store 中使用沙盒账户测试购买

### 问题 5: 代码中提示 iCloud 不可用

**检查清单**：

- [ ] 设备已登录 Apple ID
- [ ] 已开启 iCloud Drive
- [ ] Xcode 项目中已添加 iCloud Capability
- [ ] App ID 在 Developer Portal 中已启用 iCloud
- [ ] 使用了正确的 Provisioning Profile
- [ ] 在真机上测试（非模拟器）

### 调试技巧

1. **查看日志**
   ```
   搜索关键词：[WordPack] [iCloud]
   ```

2. **检查 iCloud 数据**
   - 在代码中添加断点
   - 检查 `iCloudStore` 中的数据
   - 使用 `[self.iCloudStore synchronize]` 强制同步

3. **清理和重置**
   - 删除 App 重新安装
   - 在系统设置中重置 iCloud 数据（谨慎操作）

---

## 相关链接

- [Apple Developer - iCloud Key-Value Storage](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore)
- [Apple Developer - Configuring iCloud](https://developer.apple.com/icloud/)
- [Apple Developer - Capabilities](https://developer.apple.com/documentation/xcode/configuring-signing-and-capabilities)

---

## 更新日志

- **2025-01-XX** - 初始版本，完成 iCloud Key-Value Storage 配置文档

---

**文档维护者**：开发团队  
**最后更新**：2025-01-XX

