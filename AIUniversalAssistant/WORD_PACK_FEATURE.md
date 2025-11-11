# 创作字数包功能实现文档

## 📋 概述

本文档详细说明了"创作字数包"购买功能的实现，用户可以购买字数包来使用AI写作功能。

---

## 🎯 功能说明

### 字数包规格和价格

根据截图要求，提供三种字数包：

| 字数包 | 字数 | 价格 |
|--------|------|------|
| 小包 | 500,000字 | ¥6 |
| 中包 | 2,000,000字 | ¥18 |
| 大包 | 6,000,000字 | ¥38 |

### 购买须知

1. **有效期**: 购买字数包有效期为 90天
2. **消耗优先级**: 创作时优先消耗会员每日赠送字数
3. **计算规则**: 剩余可用字数 = 购买总字数 - 累计消耗字数
4. **字数定义**: 1个汉字、1个字母、任意标点符号、空格均计算为一个字

---

## 🔧 技术实现

### 一、页面结构

#### 文件位置
```
AIUniversalAssistant/Settings/Controller/
├── AIUAWordPackViewController.h
└── AIUAWordPackViewController.m
```

#### 页面组成

```
┌─────────────────────────────────┐
│  [<] 写作字数包    [消耗记录]    │  导航栏
├─────────────────────────────────┤
│ 字数包剩余可用字数: 0字          │  当前字数显示
├─────────────────────────────────┤
│ 💰 购买字数包                    │  标题
│                                 │
│ ┌───────────────────────────┐  │
│ │ ✓ 500,000字      ¥6       │  │  字数包选项1（已选中）
│ └───────────────────────────┘  │
│                                 │
│ ┌───────────────────────────┐  │
│ │ ○ 2,000,000字    ¥18      │  │  字数包选项2
│ └───────────────────────────┘  │
│                                 │
│ ┌───────────────────────────┐  │
│ │ ○ 6,000,000字    ¥38      │  │  字数包选项3
│ └───────────────────────────┘  │
│                                 │
│    ┌─────────────────┐         │
│    │   立即开通      │         │  购买按钮
│    └─────────────────┘         │
│                                 │
│ 💰 购买须知                     │  说明标题
│                                 │
│ • 购买字数包有效期为 90天;      │
│ • 创作时优先消耗会员每日赠送... │
│ • 剩余可用字数 = ...            │
│ • 1个汉字、1个字母...           │
│                                 │
└─────────────────────────────────┘
```

---

### 二、核心实现

#### 1. 字数包枚举定义

```objective-c
typedef NS_ENUM(NSUInteger, AIUAWordPackType) {
    AIUAWordPackType500K = 0,   // 500,000字 - ¥6
    AIUAWordPackType2M,          // 2,000,000字 - ¥18
    AIUAWordPackType6M           // 6,000,000字 - ¥38
};
```

#### 2. 页面元素创建

##### 当前字数显示
```objective-c
- (void)setupRemainingWordsView {
    self.remainingWordsLabel = [[UILabel alloc] init];
    self.remainingWordsLabel.font = AIUAUIFontSystem(14);
    self.remainingWordsLabel.textColor = [UIColor grayColor];
    [self updateRemainingWordsLabel];
    // ... 布局约束
}

- (void)updateRemainingWordsLabel {
    self.remainingWordsLabel.text = 
        [NSString stringWithFormat:L(@"remaining_words"), 
         [self formatNumber:self.remainingWords]];
}
```

**显示效果**: "字数包剩余可用字数: 0字"

##### 字数包选项卡片

```objective-c
- (UIView *)createPackOptionView:(NSDictionary *)option {
    UIView *containerView = [[UIView alloc] init];
    
    // 样式
    containerView.backgroundColor = [UIColor whiteColor];
    containerView.layer.cornerRadius = 8;
    containerView.layer.borderWidth = 1;
    containerView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    // 选中图标（✓ 或 ○）
    UIImageView *checkIcon = [[UIImageView alloc] init];
    checkIcon.image = [UIImage systemImageNamed:@"checkmark.circle.fill"];
    
    // 字数标签
    UILabel *wordsLabel = [[UILabel alloc] init];
    wordsLabel.text = @"500,000字";
    
    // 价格标签
    UILabel *priceLabel = [[UILabel alloc] init];
    priceLabel.text = @"¥6";
    priceLabel.textColor = [UIColor systemGreenColor];
    
    // ... 布局和手势
    return containerView;
}
```

**卡片布局**:
```
┌─────────────────────────────────┐
│ [✓] 500,000字          ¥6      │
└─────────────────────────────────┘
  ↑     ↑                 ↑
图标   字数              价格
```

##### 选中状态更新

```objective-c
- (void)updatePackOptionsUI {
    for (UIView *optionView in self.packOptionViews) {
        BOOL isSelected = (optionView.tag == self.selectedPackType);
        
        // 更新边框颜色
        if (isSelected) {
            optionView.layer.borderColor = [UIColor systemGreenColor].CGColor;
            optionView.layer.borderWidth = 2;
        } else {
            optionView.layer.borderColor = [UIColor lightGrayColor].CGColor;
            optionView.layer.borderWidth = 1;
        }
        
        // 更新图标
        UIImageView *checkIcon = [optionView viewWithTag:100];
        if (isSelected) {
            checkIcon.image = [UIImage systemImageNamed:@"checkmark.circle.fill"];
            checkIcon.tintColor = [UIColor systemGreenColor];
        } else {
            checkIcon.image = [UIImage systemImageNamed:@"circle"];
            checkIcon.tintColor = [UIColor lightGrayColor];
        }
    }
}
```

**视觉效果**:
- **已选中**: 绿色边框(2px) + ✓绿色圆形图标
- **未选中**: 灰色边框(1px) + ○灰色圆形图标

##### 购买按钮

```objective-c
- (void)setupPurchaseButton {
    self.purchaseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.purchaseButton setTitle:L(@"activate_now") forState:UIControlStateNormal];
    [self.purchaseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.purchaseButton.titleLabel.font = AIUAUIFontBold(16);
    self.purchaseButton.backgroundColor = [UIColor systemGreenColor];
    self.purchaseButton.layer.cornerRadius = 8;
    // ... 约束: 高度 48pt
}
```

**样式**: 绿色背景、白色文字、圆角8、高度48

##### 购买须知

```objective-c
- (void)setupPurchaseNotes {
    // 标题: "💰 购买须知"
    
    NSArray *notes = @[
        L(@"word_pack_validity"),      // 购买字数包有效期为 90天;
        L(@"word_pack_priority"),      // 创作时优先消耗会员每日赠送字数;
        L(@"word_pack_calculation"),   // 剩余可用字数 = 购买总字数 - 累计消耗字数;
        L(@"word_pack_definition")     // 1个汉字、1个字母、任意标点符号、空格均计算为一个字。
    ];
    
    // 每条须知前添加 "•" 符号
    for (NSString *note in notes) {
        UILabel *noteLabel = [[UILabel alloc] init];
        noteLabel.text = [NSString stringWithFormat:@"• %@", note];
        noteLabel.numberOfLines = 0;
        // ...
    }
}
```

---

### 三、交互流程

#### 1. 选择字数包

```
用户点击卡片
   ↓
packOptionTapped:
   ↓
更新 selectedPackType
   ↓
updatePackOptionsUI
   ├─ 当前选中: 绿色边框 + ✓图标
   └─ 其他选项: 灰色边框 + ○图标
```

#### 2. 购买流程

```
用户点击"立即开通"
   ↓
purchaseButtonTapped
   ↓
显示确认弹窗
   ├─ 标题: "确认购买"
   ├─ 消息: "确认购买 500,000 字数包，金额 ¥6？"
   ├─ 按钮: [取消] [确定]
   ↓
用户点击"确定"
   ↓
performPurchase
   ├─ 显示加载HUD: "处理中..."
   ├─ 调用IAP购买逻辑（TODO）
   ├─ 购买成功
   │   ├─ 更新剩余字数
   │   ├─ 保存到本地
   │   └─ 显示成功提示
   └─ 购买失败
       └─ 显示错误提示
```

#### 3. 查看消耗记录

```
用户点击导航栏"消耗记录"
   ↓
showConsumptionRecord
   ↓
跳转到消耗记录页面（TODO）
```

---

### 四、数据持久化

#### 本地存储

使用 `NSUserDefaults` 存储剩余字数：

```objective-c
// 加载
- (NSInteger)loadRemainingWords {
    return [[NSUserDefaults standardUserDefaults] 
            integerForKey:@"kAIUARemainingWords"];
}

// 保存
- (void)saveRemainingWords:(NSInteger)words {
    [[NSUserDefaults standardUserDefaults] 
        setInteger:words forKey:@"kAIUARemainingWords"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
```

#### 数据结构

```
kAIUARemainingWords (NSInteger)
   ↓
剩余可用字数
```

---

### 五、辅助方法

#### 1. 数字格式化

```objective-c
- (NSString *)formatNumber:(NSInteger)number {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.groupingSeparator = @",";
    formatter.usesGroupingSeparator = YES;
    return [formatter stringFromNumber:@(number)];
}
```

**效果**:
- `500000` → `"500,000"`
- `2000000` → `"2,000,000"`
- `6000000` → `"6,000,000"`

#### 2. 获取字数包信息

```objective-c
- (NSInteger)getWordsForPackType:(AIUAWordPackType)type {
    switch (type) {
        case AIUAWordPackType500K: return 500000;
        case AIUAWordPackType2M:   return 2000000;
        case AIUAWordPackType6M:   return 6000000;
    }
}

- (NSString *)getPriceForPackType:(AIUAWordPackType)type {
    switch (type) {
        case AIUAWordPackType500K: return @"6";
        case AIUAWordPackType2M:   return @"18";
        case AIUAWordPackType6M:   return @"38";
    }
}
```

---

## 🌐 本地化支持

### 中文（zh-Hans）

```
"word_pack_title" = "写作字数包";
"consumption_record" = "消耗记录";
"remaining_words" = "字数包剩余可用字数: %@字";
"purchase_word_pack" = "购买字数包";
"purchase_notes" = "购买须知";
"word_pack_validity" = "购买字数包有效期为 90天;";
"word_pack_priority" = "创作时优先消耗会员每日赠送字数;";
"word_pack_calculation" = "剩余可用字数 = 购买总字数 - 累计消耗字数;";
"word_pack_definition" = "1个汉字、1个字母、任意标点符号、空格均计算为一个字。";
"confirm_purchase_word_pack" = "确认购买 %@ 字数包，金额 ¥%@？";
"word_pack_purchase_success" = "购买成功！已获得 %@ 字";
```

### 英文（en）

```
"word_pack_title" = "Writing Word Packs";
"consumption_record" = "Consumption Record";
"remaining_words" = "Remaining words: %@ words";
"purchase_word_pack" = "Purchase Word Pack";
"purchase_notes" = "Purchase Notes";
"word_pack_validity" = "Purchased word packs are valid for 90 days;";
"word_pack_priority" = "When creating, priority is given to consuming words gifted daily to members;";
"word_pack_calculation" = "Remaining available words = Total purchased words - Accumulated consumed words;";
"word_pack_definition" = "1 Chinese character, 1 letter, any punctuation mark, and spaces are all counted as one word.";
"confirm_purchase_word_pack" = "Confirm purchase of %@ word pack for ¥%@?";
"word_pack_purchase_success" = "Purchase successful! You've received %@ words";
```

---

## 📱 设置页面入口

### 集成方式

在 `AIUASettingsViewController.m` 中：

```objective-c
// 1. 导入头文件
#import "AIUAWordPackViewController.h"

// 2. 实现跳转方法
- (void)showWordPacks {
    AIUAWordPackViewController *vc = [[AIUAWordPackViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}
```

### 设置列表中的位置

```
会员特权
创作记录
创作字数包  ← 这里
联系我们
关于我们
```

---

## 🔄 待实现功能

### 1. IAP购买集成

**当前状态**: 使用模拟购买（延迟1.5秒后成功）

**需要实现**:

```objective-c
- (void)performPurchase {
    // TODO: 集成 AIUAIAPManager
    // 1. 定义字数包产品ID
    //    - com.yourcompany.aiassistant.wordpack.500k
    //    - com.yourcompany.aiassistant.wordpack.2m
    //    - com.yourcompany.aiassistant.wordpack.6m
    
    // 2. 调用购买
    NSString *productID = [self getProductIDForPackType:self.selectedPackType];
    [[AIUAIAPManager sharedManager] purchaseProduct:productID 
                                         completion:^(BOOL success, NSError *error) {
        if (success) {
            // 购买成功，更新字数
            [self updateWordsAfterPurchase];
        } else {
            // 购买失败，显示错误
            [self showPurchaseError:error];
        }
    }];
}
```

### 2. 消耗记录页面

**功能需求**:
- 显示所有字数消耗记录
- 包括时间、消耗字数、剩余字数
- 按时间倒序排列

**建议实现**:
```
创建 AIUAConsumptionRecordViewController
   ├─ 使用 UITableView 展示记录
   ├─ 每条记录显示
   │   ├─ 日期时间
   │   ├─ 消耗场景（创作类型）
   │   ├─ 消耗字数
   │   └─ 剩余字数
   └─ 数据持久化到 Plist 或数据库
```

### 3. 字数消耗逻辑

**集成点**: AI生成内容后

```objective-c
// 在 AIUADeepSeekWriter 或相关写作控制器中
- (void)onGenerationComplete:(NSString *)content {
    // 计算字数
    NSInteger wordCount = content.length;
    
    // 扣除字数
    [[AIUAWordPackManager sharedManager] consumeWords:wordCount 
                                            completion:^(BOOL success, NSInteger remaining) {
        if (success) {
            NSLog(@"字数消耗成功，剩余: %ld", (long)remaining);
        } else {
            // 字数不足
            [self showInsufficientWordsAlert];
        }
    }];
}
```

### 4. 过期管理

**需要实现**:
- 记录每次购买的时间戳
- 检查是否超过90天
- 定期清理过期字数

**建议数据结构**:
```json
{
  "purchases": [
    {
      "id": "UUID",
      "words": 500000,
      "purchaseDate": "2025-11-11",
      "expiryDate": "2026-02-09",
      "remainingWords": 450000
    }
  ]
}
```

### 5. 优先级消耗逻辑

根据购买须知"创作时优先消耗会员每日赠送字数"：

```objective-c
- (void)consumeWords:(NSInteger)words {
    // 1. 先扣除会员每日赠送字数
    NSInteger vipDailyWords = [self getVIPDailyWords];
    if (vipDailyWords > 0) {
        NSInteger consumed = MIN(words, vipDailyWords);
        [self consumeVIPDailyWords:consumed];
        words -= consumed;
    }
    
    // 2. 再扣除购买的字数包
    if (words > 0) {
        [self consumeWordPackWords:words];
    }
}
```

---

## 📊 测试建议

### 1. UI测试

**测试场景**:
- ✅ 页面加载，显示当前剩余字数
- ✅ 点击不同字数包选项，选中状态正确切换
- ✅ 选中状态的视觉效果（边框颜色、图标）
- ✅ 购买按钮点击，显示确认弹窗
- ✅ 滚动查看所有内容（购买须知）
- ✅ 点击"消耗记录"，跳转到相应页面

### 2. 购买流程测试

**测试场景**:
- ✅ 模拟购买成功，字数正确增加
- ✅ 购买后，剩余字数显示更新
- ✅ 购买成功提示显示
- ⏳ IAP真实购买流程（待集成）

### 3. 数据持久化测试

**测试场景**:
- ✅ 购买字数后，杀掉应用重新打开，字数保留
- ✅ 多次购买，字数累加
- ⏳ 字数消耗后，正确扣除

### 4. 边界情况测试

**测试场景**:
- ⏳ 字数不足时的提示
- ⏳ 购买失败的错误处理
- ⏳ 网络异常的处理
- ⏳ 重复购买的处理

---

## 🎨 UI优化建议

### 1. 视觉增强

**推荐优化**:
- 添加字数包卡片的阴影效果
- 选中卡片时添加轻微的缩放动画
- 购买按钮添加渐变色背景
- 添加骨架屏占位效果

### 2. 交互优化

**推荐优化**:
- 点击卡片时添加轻微震动反馈
- 购买成功时添加庆祝动画（如五彩纸屑）
- 剩余字数不足时的警告提示
- 添加下拉刷新功能

### 3. 信息展示

**推荐优化**:
- 显示每种字数包的平均单价（如"¥0.00001/字"）
- 显示"最划算"标签在最大字数包上
- 添加字数包有效期倒计时
- 显示历史购买统计

---

## 🎉 总结

### 实现特点

✅ **完整的UI实现** - 参照截图完整实现所有界面元素  
✅ **三种字数包** - 500K/2M/6M，价格¥6/¥18/¥38  
✅ **选择交互** - 点击卡片切换选中状态  
✅ **购买流程** - 确认弹窗 → 购买 → 成功提示  
✅ **数据持久化** - 剩余字数保存到本地  
✅ **本地化支持** - 中英文双语  
✅ **购买须知** - 完整展示四条购买说明  
✅ **数字格式化** - 大数字使用千分位分隔符  
✅ **无 Linter 错误** - 代码质量有保证  

### 待完成功能

⏳ **IAP购买集成** - 需要集成真实的Apple内购  
⏳ **消耗记录页面** - 显示字数消耗历史  
⏳ **字数消耗逻辑** - AI生成时自动扣除字数  
⏳ **过期管理** - 90天有效期检查和清理  
⏳ **优先级消耗** - 先消耗会员赠送字数  

**基础功能已完整实现！** 🚀

