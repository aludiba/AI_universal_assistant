# VIP每日赠送字数功能更新文档

## 📋 需求变更

### 旧逻辑（已废弃）
- ❌ 订阅VIP时一次性赠送50万字
- ❌ 赠送字数有效期 = VIP会员到期时间
- ❌ 字数会累计，用不完一直保留

### 新逻辑（已实现）
- ✅ VIP会员**每天**赠送50万字
- ✅ 当天未用完**不累计**到次日
- ✅ 每天零点自动重置为50万字

---

## 🎯 实现细节

### 1. 数据结构调整

#### 存储Key变化

**旧Key**:
```objective-c
kAIUAVIPGiftedWords              // VIP赠送字数（累计）
kAIUAVIPGiftedWordsExpiryDate    // 过期时间
```

**新Key**:
```objective-c
kAIUAVIPGiftedWords              // VIP每日赠送字数（当天剩余）
kAIUAVIPGiftedWordsLastRefreshDate  // ✨ 上次刷新日期
```

### 2. 核心逻辑实现

#### 查询VIP赠送字数

```objective-c
- (NSInteger)vipGiftedWords {
    // 1. 检查VIP状态
    BOOL isVIP = [[AIUAIAPManager sharedManager] isVIPMember];
    if (!isVIP) {
        return 0;
    }
    
    // 2. 检查是否需要刷新（新的一天）
    [self checkAndRefreshDailyGift];
    
    // 3. 返回今日剩余字数
    return [[NSUserDefaults standardUserDefaults] integerForKey:kAIUAVIPGiftedWords];
}
```

#### 每日刷新检查

```objective-c
- (void)checkAndRefreshDailyGift {
    NSDate *lastRefreshDate = [[NSUserDefaults standardUserDefaults] 
                                objectForKey:kAIUAVIPGiftedWordsLastRefreshDate];
    NSDate *now = [NSDate date];
    
    // 检查是否是新的一天
    if (![self isSameDay:lastRefreshDate date2:now]) {
        NSLog(@"[WordPack] 新的一天，重置VIP每日赠送字数为 500,000");
        
        // 重置为50万字
        [[NSUserDefaults standardUserDefaults] setInteger:500000 
                                                   forKey:kAIUAVIPGiftedWords];
        [[NSUserDefaults standardUserDefaults] setObject:now 
                                                   forKey:kAIUAVIPGiftedWordsLastRefreshDate];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // 同步到iCloud
        [self syncToiCloud];
    }
}
```

#### 日期比较

```objective-c
- (BOOL)isSameDay:(NSDate *)date1 date2:(NSDate *)date2 {
    if (!date1 || !date2) {
        return NO;
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    // 提取年月日
    NSDateComponents *components1 = [calendar components:NSCalendarUnitYear | 
                                                         NSCalendarUnitMonth | 
                                                         NSCalendarUnitDay
                                                 fromDate:date1];
    NSDateComponents *components2 = [calendar components:NSCalendarUnitYear | 
                                                         NSCalendarUnitMonth | 
                                                         NSCalendarUnitDay
                                                 fromDate:date2];
    
    // 比较年月日
    return components1.year == components2.year &&
           components1.month == components2.month &&
           components1.day == components2.day;
}
```

---

## 📊 工作流程

### 用户使用流程

```
第1天 (2025-11-11):
━━━━━━━━━━━━━━━━━━━━
08:00 订阅VIP
    ↓
    自动赠送: 500,000字
    ↓
10:00 使用AI创作，消耗10,000字
    ↓
    剩余赠送: 490,000字
    ↓
23:59 当天结束
    ↓
    剩余的490,000字不累计 ❌

第2天 (2025-11-12):
━━━━━━━━━━━━━━━━━━━━
00:00 新的一天开始
    ↓
    自动重置: 500,000字 ✅
    ↓
09:00 用户打开应用
    ↓
    checkAndRefreshDailyGift()
    ↓
    检测到新的一天
    ↓
    重置赠送字数为500,000字
    ↓
    同步到iCloud
```

### 自动刷新时机

**时机1**: 应用启动时
```objective-c
// AppDelegate - applicationDidBecomeActive
[[AIUAWordPackManager sharedManager] refreshVIPGiftedWords];
```

**时机2**: 查询字数时
```objective-c
// 每次调用 vipGiftedWords 都会自动检查
NSInteger words = [[AIUAWordPackManager sharedManager] vipGiftedWords];
```

**时机3**: VIP状态变化时
```objective-c
// 监听通知
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(subscriptionStatusChanged:)
                                             name:@"AIUASubscriptionStatusChanged"
                                           object:nil];
```

---

## 🌐 本地化更新

### 中文

**字数包页面**:
```
"vip_gifted_words" = "今日赠送: %@字"  // "会员赠送" → "今日赠送"
"word_pack_note_2" = "使用时将优先消耗会员每日赠送字数，其次消耗购买字数包"
"word_pack_note_3" = "订阅会员每日赠送50万字，当天未用完不累计到次日"  // ✨ 重点
```

**会员页面**:
```
"daily_word_quota" = "每日赠送字数"
"daily_word_quota_desc" = "每日赠送50万字，当天未用完不累计"  // ✨ 更新
```

### 英文

**字数包页面**:
```
"vip_gifted_words" = "Today's Gift: %@ words"
"word_pack_note_2" = "VIP daily gifted words will be consumed first, followed by purchased word packs"
"word_pack_note_3" = "VIP members receive 500,000 words daily, unused words do not roll over to the next day"
```

**会员页面**:
```
"daily_word_quota" = "Daily Word Gift"
"daily_word_quota_desc" = "500,000 words daily, no rollover to next day"
```

---

## 💡 优势对比

### 旧逻辑的问题

❌ **累计问题**: 用户可能长期不用，累计大量字数  
❌ **过期复杂**: 需要跟踪VIP到期时间  
❌ **同步冲突**: 多设备可能累计字数不一致  

### 新逻辑的优势

✅ **公平性**: 每天50万字，活跃用户和非活跃用户一样  
✅ **简单明确**: 每天重置，易于理解  
✅ **防止滥用**: 不能无限累计  
✅ **激励使用**: 鼓励用户每天使用  
✅ **同步简单**: 只需同步当天剩余字数和刷新日期  

---

## 📱 用户体验

### 场景1：每日使用

```
周一 08:00 - 打开应用
    ↓
    今日赠送: 500,000字 ✅
    ↓
周一 10:00 - 创作5万字
    ↓
    今日赠送: 450,000字
    ↓
周二 08:00 - 打开应用
    ↓
    自动重置为: 500,000字 ✅
    （昨天剩余的45万字不累计）
```

### 场景2：周末不使用

```
周五 20:00 - 使用30万字
    ↓
    今日赠送: 200,000字
    ↓
周末 - 不使用应用
    ↓
周一 08:00 - 打开应用
    ↓
    自动重置为: 500,000字 ✅
    （周五剩余的20万字已失效）
```

### 场景3：跨设备使用

```
设备A (上午):
    今日赠送: 500,000字
    使用50,000字
    剩余: 450,000字
    → 同步到iCloud
    
设备B (下午):
    从iCloud同步
    今日赠送: 450,000字 ✅
    （显示正确的剩余量）
```

---

## 🔧 技术实现

### 日期存储

```objective-c
// 保存上次刷新日期
NSDate *now = [NSDate date];
[[NSUserDefaults standardUserDefaults] setObject:now 
                                           forKey:kAIUAVIPGiftedWordsLastRefreshDate];
```

### 日期比较

```objective-c
// 使用NSCalendar比较年月日
NSCalendar *calendar = [NSCalendar currentCalendar];
NSDateComponents *comp1 = [calendar components:NSCalendarUnitYear|Month|Day fromDate:date1];
NSDateComponents *comp2 = [calendar components:NSCalendarUnitYear|Month|Day fromDate:date2];

BOOL isSameDay = (comp1.year == comp2.year && 
                  comp1.month == comp2.month && 
                  comp1.day == comp2.day);
```

### 自动刷新

```objective-c
// 每次查询时都会自动检查
- (NSInteger)vipGiftedWords {
    [self checkAndRefreshDailyGift];  // 自动检查新的一天
    return [[NSUserDefaults standardUserDefaults] integerForKey:kAIUAVIPGiftedWords];
}
```

---

## 📊 数据同步

### iCloud数据结构

```objective-c
NSDictionary *iCloudData = @{
    // VIP每日赠送字数（当天剩余）
    @"vipGiftedWords": @450000,
    
    // 上次刷新日期（用于跨设备同步）
    @"vipGiftedWordsLastRefreshDate": @"2025-11-11 08:00:00",
    
    // 购买记录
    @"purchases": @[...],
    
    // 累计消耗
    @"consumedWords": @50000
};
```

### 跨设备同步逻辑

```
设备A (早上8点):
    - 新的一天，重置为500,000字
    - 上传到iCloud: {words: 500000, date: 2025-11-11}
    
设备A (中午12点):
    - 使用了100,000字
    - 上传到iCloud: {words: 400000, date: 2025-11-11}
    
设备B (下午3点):
    - 从iCloud下载
    - 检查日期: 2025-11-11（同一天）
    - 显示: 400,000字 ✅（不重置，使用同步的值）
    
设备B (第二天早上):
    - 检查日期: 2025-11-12（新的一天）
    - 重置为: 500,000字 ✅
    - 上传到iCloud
```

---

## 🎨 UI显示变化

### 字数包页面

**旧UI**:
```
会员赠送: 500,000字
```

**新UI**:
```
今日赠送: 500,000字  ← 强调"今日"
```

### 会员订阅页面

**会员权益第2项**:

**旧文案**:
```
📝 赠送创作字数
   每日赠送50万字用于AI创作
```

**新文案**:
```
📝 每日赠送字数
   每日赠送50万字，当天未用完不累计  ← 明确说明
```

---

## 📝 修改文件清单

### ✅ AIUAWordPackManager.m

**修改内容**:
1. 常量名称：`kVIPGiftWords` → `kVIPDailyGiftWords`
2. 新增Key：`kAIUAVIPGiftedWordsLastRefreshDate`
3. 新增方法：`checkAndRefreshDailyGift`
4. 新增方法：`isSameDay:date2:`
5. 修改方法：`vipGiftedWords` - 添加每日检查
6. 修改方法：`refreshVIPGiftedWords` - 改为每日重置逻辑
7. 修改方法：`syncFromiCloud` - 同步lastRefreshDate
8. 修改方法：`syncToiCloud` - 上传lastRefreshDate

### ✅ 本地化文件

**zh-Hans.lproj/Localizable.strings**:
```
"vip_gifted_words" = "今日赠送: %@字"  // 新增"今日"
"word_pack_note_2" = "使用时将优先消耗会员每日赠送字数..."
"word_pack_note_3" = "订阅会员每日赠送50万字，当天未用完不累计到次日"
"daily_word_quota" = "每日赠送字数"
"daily_word_quota_desc" = "每日赠送50万字，当天未用完不累计"
```

**en.lproj/Localizable.strings**:
```
"vip_gifted_words" = "Today's Gift: %@ words"
"word_pack_note_2" = "VIP daily gifted words will be consumed first..."
"word_pack_note_3" = "VIP members receive 500,000 words daily, unused words do not roll over to the next day"
"daily_word_quota" = "Daily Word Gift"
"daily_word_quota_desc" = "500,000 words daily, no rollover to next day"
```

---

## 🧪 测试场景

### 测试1：每日重置

**步骤**:
```
1. 订阅VIP
   → 显示"今日赠送: 500,000字" ✓
   
2. 使用200,000字
   → 显示"今日赠送: 300,000字" ✓
   
3. 修改系统日期到次日
   
4. 重新打开应用
   → 显示"今日赠送: 500,000字" ✓
   （昨天剩余的30万字不累计）
```

### 测试2：当天多次使用

**步骤**:
```
早上 08:00:
   今日赠送: 500,000字
   使用: 100,000字
   剩余: 400,000字
   
中午 12:00:
   今日赠送: 400,000字（保持）
   使用: 100,000字
   剩余: 300,000字
   
晚上 20:00:
   今日赠送: 300,000字（保持）
   使用: 100,000字
   剩余: 200,000字 ✓
```

### 测试3：跨设备同步

**步骤**:
```
设备A (上午):
   新的一天，重置为500,000字
   使用100,000字
   剩余400,000字
   上传iCloud
   
设备B (下午):
   从iCloud下载
   检查日期：同一天
   显示: 400,000字 ✓
   （不重置，因为已经是同一天）
```

### 测试4：VIP到期

**步骤**:
```
1. VIP状态，今日赠送: 300,000字
   
2. VIP到期
   
3. 刷新页面
   → 今日赠送: 0字 ✓
   （VIP到期后无赠送）
```

---

## 💡 业务逻辑说明

### 为什么每日重置？

**商业价值**:
- ✅ 鼓励用户每天使用应用（提高DAU）
- ✅ 防止用户囤积字数后取消订阅
- ✅ 公平对待活跃用户和非活跃用户
- ✅ 简化计费和管理逻辑

**用户价值**:
- ✅ 每天都有新的配额，不用担心用完
- ✅ 规则简单明了，易于理解
- ✅ 激励每天使用，养成习惯

### 消耗优先级

```
AI生成内容
    ↓
优先级1: VIP每日赠送（先消耗，鼓励使用）
    ↓
优先级2: 购买字数包（后消耗，节省开支）
    ↓
字数不足: 引导购买或续费VIP
```

---

## 📊 数据监控

### 关键指标

```objective-c
// 查看每日赠送使用情况
NSInteger dailyGift = [[AIUAWordPackManager sharedManager] vipGiftedWords];
NSInteger used = 500000 - dailyGift;

NSLog(@"今日已使用赠送字数: %ld", (long)used);
NSLog(@"今日剩余赠送字数: %ld", (long)dailyGift);
```

### 日志示例

```
[WordPack] 检测到VIP用户，检查每日赠送字数
[WordPack] 新的一天，重置VIP每日赠送字数为 500000
[WordPack] VIP今日剩余赠送字数: 500000
[WordPack] 从VIP赠送消耗 10000 字，剩余 490000 字
[WordPack] VIP今日剩余赠送字数: 490000
```

---

## 🎉 总结

### 核心变更

✅ **每日重置** - 从一次性赠送改为每日赠送  
✅ **不累计** - 当天未用完自动清零  
✅ **自动刷新** - 新的一天自动重置为50万字  
✅ **文案更新** - 所有相关文案已更新  
✅ **会员页提示** - 已在会员权益中说明  

### 技术实现

✅ **日期检查** - `isSameDay:date2:` 方法  
✅ **自动重置** - `checkAndRefreshDailyGift` 方法  
✅ **iCloud同步** - 同步刷新日期  
✅ **无缝集成** - 所有现有功能正常工作  

### 验证结果

✅ **代码质量**: 无linter错误  
✅ **功能完整**: 每日重置逻辑完整  
✅ **本地化**: 中英文文案已更新  
✅ **同步支持**: iCloud跨设备同步  

**VIP每日赠送功能已完全实现！** 🎉✨

