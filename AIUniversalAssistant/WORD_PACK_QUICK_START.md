# 字数包系统快速开始指南

## 🚀 5分钟集成指南

### 1. App Store Connect配置（5分钟）

1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 选择您的应用 → 功能 → App内购买项目
3. 点击"+"创建新的App内购买项目
4. 选择"消耗型"
5. 创建以下3个产品：

| 产品ID | 显示名称 | 价格层级 | 描述 |
|--------|---------|---------|------|
| `com.yourcompany.aiassistant.wordpack.500k` | 500,000字数包 | ¥6 | 50万字创作字数包，90天有效 |
| `com.yourcompany.aiassistant.wordpack.2m` | 2,000,000字数包 | ¥18 | 200万字创作字数包，90天有效 |
| `com.yourcompany.aiassistant.wordpack.6m` | 6,000,000字数包 | ¥38 | 600万字创作字数包，90天有效 |

6. 保存并提交审核

---

### 2. Xcode配置（2分钟）

#### 启用iCloud

1. 选择项目 → Target → Signing & Capabilities
2. 点击"+ Capability"
3. 选择"iCloud"
4. 勾选"Key-value storage"

完成！Xcode会自动配置entitlements文件。

---

### 3. 代码集成（已完成✅）

#### 已自动集成的功能

✅ **字数包管理器** - `AIUAWordPackManager`  
✅ **购买界面** - `AIUAWordPackViewController`  
✅ **iCloud同步** - 自动启用  
✅ **VIP赠送** - 自动刷新  
✅ **本地化** - 中英文双语  

#### 应用启动时自动执行

```objective-c
// AppDelegate.m - applicationDidBecomeActive
[[AIUAIAPManager sharedManager] checkSubscriptionStatus];
[[AIUAWordPackManager sharedManager] enableiCloudSync];
[[AIUAWordPackManager sharedManager] refreshVIPGiftedWords];
```

---

### 4. 使用方法

#### 查询字数

```objective-c
AIUAWordPackManager *manager = [AIUAWordPackManager sharedManager];

NSInteger vipWords = [manager vipGiftedWords];      // VIP赠送字数
NSInteger purchasedWords = [manager purchasedWords]; // 购买字数
NSInteger totalWords = [manager totalAvailableWords]; // 总字数
```

#### 购买字数包

```objective-c
// 已在 AIUAWordPackViewController 中实现
// 用户点击购买按钮 → 确认 → IAP购买 → 保存记录 → iCloud同步
```

#### 消耗字数

```objective-c
NSInteger words = generatedContent.length;

[[AIUAWordPackManager sharedManager] consumeWords:words 
                                        completion:^(BOOL success, NSInteger remaining) {
    if (success) {
        NSLog(@"消耗成功，剩余: %ld字", (long)remaining);
    } else {
        // 字数不足，显示提示
        [self showInsufficientWordsAlert];
    }
}];
```

#### 检查字数是否足够

```objective-c
NSInteger estimatedWords = 1000;

if ([[AIUAWordPackManager sharedManager] hasEnoughWords:estimatedWords]) {
    // 字数足够，开始生成
    [self startGeneration];
} else {
    // 字数不足，显示提示
    [self showInsufficientWordsAlert];
}
```

---

## 📱 用户流程

### 订阅VIP获得赠送

```
用户订阅VIP
    ↓
自动赠送50万字
    ↓
字数包页面显示"会员赠送: 500,000字"
    ↓
有效期 = VIP到期时间
```

### 购买字数包

```
进入"设置" → "创作字数包"
    ↓
查看当前字数
    - 会员赠送: X字
    - 已购买: X字
    - 可用总字数: X字
    ↓
选择字数包 (500K/2M/6M)
    ↓
点击"立即开通"
    ↓
确认购买弹窗
    ↓
IAP支付流程
    ↓
购买成功提示
    ↓
字数自动增加
```

### 使用AI写作

```
用户使用AI写作功能
    ↓
系统自动消耗字数
    - 优先消耗VIP赠送
    - 其次消耗购买字数包
    ↓
字数不足时
    ↓
显示提示弹窗
    - 购买字数包
    - 开通会员
```

---

## 🧪 测试清单

### 沙盒测试账号

1. 前往 App Store Connect
2. 用户和访问 → 沙盒测试员
3. 创建测试账号

### 测试场景

#### ✅ VIP赠送测试
- [ ] 订阅VIP后检查是否赠送50万字
- [ ] 检查赠送字数过期时间
- [ ] VIP到期后检查赠送字数是否失效

#### ✅ 字数包购买测试
- [ ] 选择500K字数包并购买
- [ ] 检查购买后字数是否增加
- [ ] 检查是否设置90天过期时间

#### ✅ 字数消耗测试
- [ ] 生成内容后检查字数是否减少
- [ ] 检查是否优先消耗VIP赠送
- [ ] 字数不足时是否显示提示

#### ✅ iCloud同步测试
- [ ] 设备A购买字数包
- [ ] 设备B检查是否自动同步
- [ ] 字数是否一致

---

## 🐛 常见问题

### Q: 购买字数包后没有增加字数？

**A**: 
1. 检查IAP购买是否成功
2. 查看控制台日志 `[WordPack]` 相关输出
3. 确认产品ID是否正确配置

### Q: iCloud同步不工作？

**A**:
1. 确认已在Xcode中启用iCloud Key-value storage
2. 检查设备是否登录同一Apple ID
3. 确认iCloud同步已启用（会在应用激活时自动启用）

### Q: VIP赠送字数没有生效？

**A**:
1. 确认用户是VIP会员
2. 检查VIP过期时间
3. 调用 `refreshVIPGiftedWords` 手动刷新

### Q: 字数消耗不准确？

**A**:
1. 检查是否正确调用 `consumeWords:`
2. 确认字数统计规则（1个字符=1字）
3. 查看消耗日志确认消耗流程

---

## 📊 监控和日志

### 关键日志

所有字数包相关日志都以 `[WordPack]` 开头：

```
[WordPack] setupPurchaseOptions 开始
[WordPack] 创建了 3 个字数包选项
[WordPack] VIP赠送字数: 500000
[WordPack] 购买字数（未过期）: 500000
[WordPack] 总可用字数: 1000000
[WordPack] 尝试消耗 1000 字
[WordPack] 从VIP赠送消耗 1000 字，剩余 499000 字
[WordPack] ✓ 消耗完成，累计消耗: 1000 字
[WordPack] iCloud同步完成
```

### 数据监控

```objective-c
// 查看当前状态
NSLog(@"VIP赠送: %ld", (long)[[AIUAWordPackManager sharedManager] vipGiftedWords]);
NSLog(@"购买字数: %ld", (long)[[AIUAWordPackManager sharedManager] purchasedWords]);
NSLog(@"总字数: %ld", (long)[[AIUAWordPackManager sharedManager] totalAvailableWords]);
NSLog(@"已消耗: %ld", (long)[[AIUAWordPackManager sharedManager] consumedWords]);
```

---

## 🔗 相关文档

- **WORD_PACK_SYSTEM_COMPLETE.md** - 完整系统实现文档
- **WORD_PACK_FEATURE.md** - 功能需求文档
- **IAP_SETUP_GUIDE.md** - IAP配置指南
- **VIP_PERMISSION_SYSTEM.md** - VIP权限系统

---

## 🎉 完成

恭喜！您已经完成了字数包系统的集成。

**核心功能**:
✅ VIP赠送50万字  
✅ 字数包IAP购买  
✅ 跨设备iCloud同步  
✅ 优先级字数消耗  
✅ 90天过期管理  

**下一步**:
1. 在App Store Connect配置产品
2. 创建沙盒测试账号
3. 测试购买和同步功能
4. 集成到具体写作场景

开始使用吧！🚀

