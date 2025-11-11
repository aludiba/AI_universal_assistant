# 字数包系统完整实现文档

## 📋 概述

本文档详细说明完整的字数包系统实现，包括VIP赠送、IAP购买、字数消耗和iCloud同步。

---

## 🎯 实现的5大功能

### ✅ 1. 更新购买须知文案

**原文案**:
```
- 购买字数包有效期为 90天;
- 创作时优先消耗会员每日赠送字数;
- 剩余可用字数 = 购买总字数 - 累计消耗字数;
- 1个汉字、1个字母、任意标点符号、空格均计算为一个字。
```

**新文案**:
```
- 字数包购买后90天内有效，逾期未使用将自动失效
- 使用时将优先消耗会员赠送字数，其次消耗购买字数包
- 订阅任意会员套餐可获赠50万字，有效期与会员时长一致
- 字数统计规则：1个中文字符、英文字母、数字、标点或空格均计为1字
```

**变化点**:
- 语言更自然，表达更清晰
- 强调"逾期失效"警示
- "会员每日赠送"改为"会员赠送"（更准确）
- 新增第3条：明确说明VIP赠送50万字

---

### ✅ 2. 增加订阅会员赠送50万字提示

#### UI展示

**位置**: 字数信息卡片下方

**样式**: 橙色提示卡片（gift图标）

**内容**: "订阅任意会员套餐可获赠50万字，有效期与会员时长一致"

**交互**: 点击跳转到会员订阅页面

```
┌──────────────────────────────────────┐
│ 会员赠送: 0字                        │
│ 已购买: 0字                          │
│ ──────────────────────────────────  │
│ 可用总字数: 0字                      │
└──────────────────────────────────────┘
        ↓
┌──────────────────────────────────────┐
│ 🎁 订阅任意会员套餐可获赠50万字     │
│    有效期与会员时长一致              │  ← 点击跳转
└──────────────────────────────────────┘
```

#### 赠送逻辑

```objective-c
- (void)refreshVIPGiftedWords {
    BOOL isVIP = [[AIUAIAPManager sharedManager] isVIPMember];
    
    if (isVIP) {
        NSInteger currentGiftedWords = [...];
        
        // 新订阅时赠送50万字
        if (currentGiftedWords == 0) {
            [[NSUserDefaults standardUserDefaults] setInteger:500000 
                                                       forKey:kAIUAVIPGiftedWords];
        }
        
        // 更新过期时间为VIP到期时间
        NSDate *vipExpiryDate = [[AIUAIAPManager sharedManager] subscriptionExpiryDate];
        [[NSUserDefaults standardUserDefaults] setObject:vipExpiryDate 
                                                   forKey:kAIUAVIPGiftedWordsExpiryDate];
    }
}
```

**触发时机**:
- 用户订阅VIP时自动赠送
- 应用启动时刷新（`applicationDidBecomeActive`）
- 订阅状态变化时刷新（通过通知）

---

### ✅ 3. 集成真实IAP购买逻辑

#### 字数包产品定义

```objective-c
// 产品ID
static NSString * const kProductIDWordPack500K = @"com.yourcompany.aiassistant.wordpack.500k";
static NSString * const kProductIDWordPack2M = @"com.yourcompany.aiassistant.wordpack.2m";
static NSString * const kProductIDWordPack6M = @"com.yourcompany.aiassistant.wordpack.6m";

// 字数包类型
typedef NS_ENUM(NSUInteger, AIUAWordPackType) {
    AIUAWordPackType500K = 0,   // 500,000字 - ¥6
    AIUAWordPackType2M,          // 2,000,000字 - ¥18
    AIUAWordPackType6M           // 6,000,000字 - ¥38
};
```

#### 购买流程

```objective-c
// 1. 用户点击购买按钮
- (void)purchaseButtonTapped {
    // 显示确认弹窗
    // 用户确认后调用 performPurchase
}

// 2. 执行购买
- (void)performPurchase {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = L(@"processing");
    
    // 调用WordPackManager购买
    [[AIUAWordPackManager sharedManager] purchaseWordPack:self.selectedPackType 
                                                completion:^(BOOL success, NSError *error) {
        [hud hideAnimated:YES];
        
        if (success) {
            // 显示成功提示
            // 刷新字数显示
        } else {
            // 显示错误提示
        }
    }];
}

// 3. WordPackManager调用IAP
- (void)purchaseWordPack:(AIUAWordPackType)type completion:(void(^)(BOOL, NSError*))completion {
    NSString *productID = [self productIDForPackType:type];
    
    // 调用AIUAIAPManager购买
    [[AIUAIAPManager sharedManager] purchaseProduct:productID completion:^(BOOL success, NSError *error) {
        if (success) {
            // 添加购买记录
            [self addPurchaseRecord:words forProductID:productID];
            
            // 同步到iCloud
            [self syncToiCloud];
            
            // 发送通知
            [[NSNotificationCenter defaultCenter] postNotificationName:AIUAWordPackPurchasedNotification
                                                                object:nil];
        }
        
        completion(success, error);
    }];
}
```

#### 购买记录结构

```objective-c
NSDictionary *purchase = @{
    @"productID": @"com.yourcompany.aiassistant.wordpack.500k",
    @"words": @500000,              // 购买的字数
    @"remainingWords": @500000,     // 剩余字数
    @"purchaseDate": [NSDate date], // 购买时间
    @"expiryDate": expiryDate       // 过期时间（90天后）
};
```

#### App Store Connect配置

**步骤**:
1. 登录 App Store Connect
2. 进入应用 → 功能 → App内购买项目
3. 创建3个消耗型项目：
   - 产品ID: `com.yourcompany.aiassistant.wordpack.500k`
   - 显示名称: "500,000字数包"
   - 价格: ¥6
   - 重复以上步骤创建2M和6M字数包

---

### ✅ 4. 通过iCloud记录字数包到云端

#### iCloud数据结构

```objective-c
// iCloud Key
static NSString * const kAIUAiCloudWordPackData = @"AIUAWordPackData";

// 数据结构
NSDictionary *iCloudData = @{
    @"vipGiftedWords": @500000,           // VIP赠送字数
    @"vipGiftedWordsExpiryDate": date,    // VIP赠送过期时间
    @"purchases": @[...],                  // 购买记录数组
    @"consumedWords": @123456              // 累计消耗字数
};
```

#### 同步流程

```
应用启动
    ↓
enableiCloudSync
    ├─ 监听iCloud变化通知
    ├─ 调用 [iCloudStore synchronize]
    └─ 首次同步：syncFromiCloud
        ↓
本地数据 ← iCloud数据
    ↓
用户购买字数包
    ↓
本地保存 + syncToiCloud
    ↓
iCloud数据 ← 本地数据
    ↓
其他设备检测到iCloud变化
    ↓
自动 syncFromiCloud
    ↓
实现跨设备同步
```

#### 核心代码

```objective-c
// 启用同步
- (void)enableiCloudSync {
    self.iCloudSyncEnabled = YES;
    self.iCloudStore = [NSUbiquitousKeyValueStore defaultStore];
    
    // 监听变化
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(iCloudStoreDidChange:)
                                                 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                               object:self.iCloudStore];
    
    [self.iCloudStore synchronize];
    [self syncFromiCloud];
}

// 上传到iCloud
- (void)syncToiCloud {
    NSDictionary *data = @{
        @"vipGiftedWords": @(...),
        @"vipGiftedWordsExpiryDate": ...,
        @"purchases": ...,
        @"consumedWords": @(...)
    };
    
    [self.iCloudStore setDictionary:data forKey:kAIUAiCloudWordPackData];
    [self.iCloudStore synchronize];
}

// 从iCloud下载
- (void)syncFromiCloud {
    NSDictionary *iCloudData = [self.iCloudStore dictionaryForKey:kAIUAiCloudWordPackData];
    
    // 同步到本地
    [[NSUserDefaults standardUserDefaults] setInteger:[iCloudData[@"vipGiftedWords"] integerValue]
                                               forKey:kAIUAVIPGiftedWords];
    // ... 同步其他数据
    [[NSUserDefaults standardUserDefaults] synchronize];
}
```

#### Xcode配置

**步骤**:
1. 选择项目 → Target → Signing & Capabilities
2. 点击 "+ Capability"
3. 添加 "iCloud"
4. 勾选 "Key-value storage"
5. Xcode会自动配置entitlements文件

---

### ✅ 5. 实现完整字数消耗逻辑

#### 消耗优先级

```
1. VIP赠送字数（优先）
    ↓
2. 购买字数包（按购买时间顺序）
    ↓
3. 字数不足 → 提示购买
```

#### 核心实现

```objective-c
- (void)consumeWords:(NSInteger)words completion:(void(^)(BOOL, NSInteger))completion {
    // 1. 检查字数是否足够
    if (![self hasEnoughWords:words]) {
        completion(NO, [self totalAvailableWords]);
        return;
    }
    
    NSInteger remainingToConsume = words;
    
    // 2. 优先从VIP赠送字数中消耗
    NSInteger vipWords = [self vipGiftedWords];
    if (vipWords > 0) {
        NSInteger consumeFromVIP = MIN(remainingToConsume, vipWords);
        NSInteger newVIPWords = vipWords - consumeFromVIP;
        
        [[NSUserDefaults standardUserDefaults] setInteger:newVIPWords 
                                                   forKey:kAIUAVIPGiftedWords];
        remainingToConsume -= consumeFromVIP;
    }
    
    // 3. 如果还需要消耗，从购买字数包中消耗
    if (remainingToConsume > 0) {
        [self consumeFromPurchasedPacks:remainingToConsume];
    }
    
    // 4. 更新累计消耗字数
    NSInteger totalConsumed = [[NSUserDefaults standardUserDefaults] integerForKey:kAIUAConsumedWords];
    totalConsumed += words;
    [[NSUserDefaults standardUserDefaults] setInteger:totalConsumed forKey:kAIUAConsumedWords];
    
    // 5. 同步到iCloud
    [self syncToiCloud];
    
    // 6. 发送通知
    [[NSNotificationCenter defaultCenter] postNotificationName:AIUAWordConsumedNotification
                                                        object:nil];
    
    completion(YES, [self totalAvailableWords]);
}

- (void)consumeFromPurchasedPacks:(NSInteger)words {
    NSMutableArray *purchases = [...];
    NSInteger remainingToConsume = words;
    
    // 按购买时间排序（先购买的先消耗）
    [purchases sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"purchaseDate" ascending:YES]]];
    
    for (NSMutableDictionary *purchase in purchases) {
        if (remainingToConsume <= 0) break;
        
        // 检查过期
        if ([now compare:purchase[@"expiryDate"]] == NSOrderedDescending) {
            continue;
        }
        
        NSInteger remainingWords = [purchase[@"remainingWords"] integerValue];
        if (remainingWords > 0) {
            NSInteger consumeFromThis = MIN(remainingToConsume, remainingWords);
            purchase[@"remainingWords"] = @(remainingWords - consumeFromThis);
            remainingToConsume -= consumeFromThis;
        }
    }
    
    // 保存更新
    [[NSUserDefaults standardUserDefaults] setObject:purchases forKey:kAIUAWordPackPurchases];
}
```

#### 集成到AI写作

**方法1: 在写作控制器中调用**

```objective-c
// 在生成完成后
- (void)onGenerationComplete:(NSString *)content {
    NSInteger wordCount = content.length;
    
    [[AIUAWordPackManager sharedManager] consumeWords:wordCount 
                                            completion:^(BOOL success, NSInteger remaining) {
        if (success) {
            NSLog(@"字数消耗成功，剩余: %ld", (long)remaining);
        } else {
            // 字数不足，显示提示
            [self showInsufficientWordsAlert];
        }
    }];
}
```

**方法2: 在生成前检查**

```objective-c
- (void)startGeneration {
    // 估算需要的字数
    NSInteger estimatedWords = 1000;
    
    if (![[AIUAWordPackManager sharedManager] hasEnoughWords:estimatedWords]) {
        // 显示字数不足提示
        [self showInsufficientWordsAlert];
        return;
    }
    
    // 继续生成
    [self performGeneration];
}
```

#### 字数不足提示

```objective-c
- (void)showInsufficientWordsAlert {
    UIAlertController *alert = [UIAlertController 
        alertControllerWithTitle:L(@"insufficient_words")
        message:L(@"insufficient_words_message")
        preferredStyle:UIAlertControllerStyleAlert];
    
    // "购买字数包"按钮
    UIAlertAction *purchaseAction = [UIAlertAction 
        actionWithTitle:L(@"purchase_word_pack")
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *action) {
            // 跳转到字数包页面
            AIUAWordPackViewController *vc = [[AIUAWordPackViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }];
    
    // "开通会员"按钮
    UIAlertAction *vipAction = [UIAlertAction 
        actionWithTitle:L(@"activate_membership")
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction *action) {
            // 跳转到会员页面
            AIUAMembershipViewController *vc = [[AIUAMembershipViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }];
    
    UIAlertAction *cancelAction = [UIAlertAction 
        actionWithTitle:L(@"cancel")
        style:UIAlertActionStyleCancel
        handler:nil];
    
    [alert addAction:purchaseAction];
    [alert addAction:vipAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}
```

---

## 📊 数据流程图

### 字数包生命周期

```
VIP订阅
    ↓
赠送50万字
    ├─ 保存到本地 (NSUserDefaults)
    ├─ 记录过期时间 (VIP到期时间)
    └─ 同步到iCloud
        ↓
用户使用AI写作
    ↓
检查字数是否足够
    ├─ 是 → 生成内容
    │        ↓
    │     消耗字数
    │        ├─ 优先消耗VIP赠送
    │        ├─ 其次消耗购买字数
    │        ├─ 更新本地数据
    │        └─ 同步到iCloud
    │
    └─ 否 → 提示购买字数包或开通VIP
              ↓
         用户购买字数包
              ├─ IAP购买流程
              ├─ 添加购买记录
              ├─ 设置90天过期
              └─ 同步到iCloud
```

### 跨设备同步

```
设备A
    ↓
购买字数包
    ↓
本地保存 + iCloud上传
    ↓
iCloud存储
    ↓
设备B检测到变化
    ↓
自动下载到本地
    ↓
设备B显示最新字数
```

---

## 📂 文件清单

### 新增文件

✅ **AIUAWordPackManager.h** - 字数包管理器头文件
✅ **AIUAWordPackManager.m** - 字数包管理器实现

### 修改文件

✅ **AIUAWordPackViewController.m** - 完全重写，集成管理器
✅ **AppDelegate.m** - 添加iCloud同步初始化
✅ **zh-Hans.lproj/Localizable.strings** - 更新本地化
✅ **en.lproj/Localizable.strings** - 更新本地化

---

## 🎯 关键类说明

### AIUAWordPackManager

**职责**: 统一管理所有字数包相关逻辑

**核心方法**:
```objective-c
// 查询
- (NSInteger)vipGiftedWords;
- (NSInteger)purchasedWords;
- (NSInteger)totalAvailableWords;

// 购买
- (void)purchaseWordPack:(AIUAWordPackType)type completion:(void(^)(BOOL, NSError*))completion;

// VIP赠送
- (void)refreshVIPGiftedWords;

// 消耗
- (void)consumeWords:(NSInteger)words completion:(void(^)(BOOL, NSInteger))completion;

// iCloud
- (void)enableiCloudSync;
- (void)syncFromiCloud;
- (void)syncToiCloud;
```

### AIUAWordPackViewController

**职责**: 字数包购买界面

**功能**:
- 显示VIP赠送字数、购买字数、总字数
- 显示VIP赠送提示卡片
- 提供3种字数包选项
- 集成真实IAP购买
- 监听字数包变化并更新UI

---

## 🔔 通知机制

### 字数包购买通知

```objective-c
NSString * const AIUAWordPackPurchasedNotification = @"AIUAWordPackPurchasedNotification";

// 发送
[[NSNotificationCenter defaultCenter] postNotificationName:AIUAWordPackPurchasedNotification
                                                    object:nil
                                                  userInfo:@{@"words": @(words)}];

// 监听
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(wordPackPurchased:)
                                             name:AIUAWordPackPurchasedNotification
                                           object:nil];
```

### 字数消耗通知

```objective-c
NSString * const AIUAWordConsumedNotification = @"AIUAWordConsumedNotification";

// 用途：实时更新UI显示的剩余字数
```

### VIP状态变化通知

```objective-c
// AIUASubscriptionStatusChanged (已存在)
// 用途：VIP订阅状态变化时自动刷新赠送字数
```

---

## 🧪 测试建议

### 1. VIP赠送测试

**步骤**:
1. 未订阅VIP时，检查赠送字数为0
2. 订阅VIP后，检查赠送字数为500,000
3. VIP到期后，检查赠送字数失效

**预期结果**:
- ✅ VIP订阅后立即获得50万字
- ✅ 赠送字数过期时间 = VIP过期时间
- ✅ VIP到期后赠送字数失效

### 2. 字数包购买测试

**步骤**:
1. 选择500K字数包
2. 点击购买
3. 完成IAP流程

**预期结果**:
- ✅ 购买成功后字数增加
- ✅ 购买记录保存到本地
- ✅ 数据同步到iCloud
- ✅ 设置90天过期时间

### 3. 字数消耗测试

**步骤**:
1. VIP赠送字数: 500,000
2. 购买字数: 500,000
3. 消耗600,000字

**预期结果**:
- ✅ 先消耗VIP赠送500,000字
- ✅ 再消耗购买字数100,000字
- ✅ VIP赠送剩余: 0
- ✅ 购买字数剩余: 400,000

### 4. iCloud同步测试

**步骤**:
1. 设备A购买字数包
2. 设备B登录同一Apple ID
3. 等待iCloud同步

**预期结果**:
- ✅ 设备B自动显示最新字数
- ✅ 无需手动操作
- ✅ 数据一致

### 5. 过期管理测试

**步骤**:
1. 修改系统时间到91天后
2. 检查字数包状态

**预期结果**:
- ✅ 过期字数包不再计入总字数
- ✅ 消耗时跳过过期字数包

---

## 📝 TODO待完成

### 高优先级

⏳ **集成到具体写作场景**
- 在AIUAWritingDetailViewController中添加字数消耗
- 在AIUADocDetailViewController中添加字数消耗
- 在生成前检查字数是否足够

⏳ **字数消耗记录页面**
- 创建AIUAConsumptionRecordViewController
- 显示消耗历史
- 按时间倒序排列

### 中优先级

⏳ **优化用户体验**
- 生成前显示预估消耗字数
- 添加字数不足预警（剩余<10%时提示）
- 字数包即将过期提醒

⏳ **数据统计**
- 统计总消耗字数
- 统计各功能消耗字数
- 统计平均每日消耗

### 低优先级

⏳ **高级功能**
- 字数包转赠功能
- 字数包分享功能
- 消耗字数排行榜

---

## 🎉 总结

### 已完成功能

✅ **文案更新** - 购买须知更清晰自然  
✅ **VIP赠送** - 订阅会员送50万字  
✅ **真实IAP** - 集成Apple内购  
✅ **iCloud同步** - 跨设备数据同步  
✅ **字数消耗** - 完整消耗逻辑和优先级  

### 技术亮点

🌟 **统一管理** - AIUAWordPackManager集中管理  
🌟 **iCloud同步** - 自动跨设备同步  
🌟 **优先级消耗** - VIP赠送 → 购买字数  
🌟 **过期管理** - 90天自动失效  
🌟 **通知机制** - 实时更新UI  
🌟 **完整日志** - 详细调试信息  

### 架构优势

- ✅ **解耦设计**: 字数包逻辑与UI分离
- ✅ **易于扩展**: 新增字数包类型只需配置
- ✅ **可测试性**: 核心逻辑独立可测试
- ✅ **可维护性**: 清晰的代码结构和文档

**字数包系统核心功能已完整实现！** 🚀

