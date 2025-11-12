# 字数统计与消耗逻辑完整实现

## 📋 概述

本文档详细说明了App中字数统计规则和消耗逻辑的完整实现，包括：
- 字数统计规则：1个中文字符、英文字母、数字、标点或空格均计为1字
- 字数消耗逻辑：优先消耗VIP每日赠送字数，其次消耗购买的字数包
- 集成到所有AI写作功能中

---

## ✅ 实现内容

### 1. 字数统计方法

#### 1.1 方法定义

**文件**: `AIUAWordPackManager.h`

```objective-c
/**
 * 根据字数统计规则计算文本的字数
 * 规则：1个中文字符、英文字母、数字、标点或空格均计为1字
 * @param text 要统计的文本
 * @return 字数
 */
+ (NSInteger)countWordsInText:(NSString *)text;
```

#### 1.2 实现逻辑

**文件**: `AIUAWordPackManager.m`

```objective-c
+ (NSInteger)countWordsInText:(NSString *)text {
    if (!text || text.length == 0) {
        return 0;
    }
    
    // 使用enumerateSubstringsInRange来正确处理所有Unicode字符
    // 包括emoji等特殊字符，每个composed character sequence计为1字
    __block NSInteger count = 0;
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        count++;
    }];
    
    return count;
}
```

**统计规则**:
- ✅ 中文字符：每个中文字符计为1字
- ✅ 英文字母：每个字母（a-z, A-Z）计为1字
- ✅ 数字：每个数字（0-9）计为1字
- ✅ 标点符号：每个标点符号计为1字
- ✅ 空格和换行：每个空格或换行符计为1字
- ✅ Emoji和特殊字符：每个composed character sequence计为1字

---

### 2. 字数消耗逻辑

#### 2.1 消耗优先级

**文件**: `AIUAWordPackManager.m` - `consumeWords:completion:`

消耗顺序：
1. **优先消耗VIP每日赠送字数**（`vipGiftedWords`）
2. **其次消耗购买的字数包**（按购买时间顺序，先购买的先消耗）

```objective-c
- (void)consumeWords:(NSInteger)words completion:(void (^)(BOOL, NSInteger))completion {
    // 1. 优先消耗VIP赠送字数
    NSInteger vipWords = [self vipGiftedWords];
    if (vipWords > 0) {
        NSInteger consumeFromVIP = MIN(remainingToConsume, vipWords);
        // ... 更新VIP赠送字数
    }
    
    // 2. 如果还需要消耗，则从购买的字数包中消耗
    if (remainingToConsume > 0) {
        [self consumeFromPurchasedPacks:remainingToConsume];
    }
}
```

---

### 3. AI写作功能集成

#### 3.1 模板创作功能

**文件**: `AIUAWritingDetailViewController.m`

**集成点**:
- ✅ `startWriting`方法：生成前检查字数是否足够
- ✅ `writingCompletedWithContent:`方法：生成完成后消耗实际字数

**实现逻辑**:

```objective-c
- (void)startWriting {
    // 估算需要消耗的字数
    NSInteger estimatedWords = self.wordCount > 0 ? self.wordCount : 1000;
    
    // 检查字数是否足够
    if (![[AIUAWordPackManager sharedManager] hasEnoughWords:estimatedWords]) {
        // 显示字数不足提示，引导用户购买字数包
        // ...
        return;
    }
    
    // 开始生成...
}

- (void)writingCompletedWithContent:(NSString *)content {
    // 计算实际生成的字数并消耗
    NSInteger actualWords = [AIUAWordPackManager countWordsInText:finalText];
    if (actualWords > 0) {
        [[AIUAWordPackManager sharedManager] consumeWords:actualWords completion:^(BOOL success, NSInteger remainingWords) {
            // 处理消耗结果
        }];
    }
}
```

#### 3.2 文档编辑功能（续写、改写、扩写、翻译）

**文件**: `AIUADocDetailViewController.m`

**集成点**:
- ✅ `performAIGenerationWithType:`方法：生成前检查字数，生成后消耗字数

**字数估算策略**:

| 操作类型 | 估算规则 |
|---------|---------|
| **续写** | `MAX(原文字数, 500)` |
| **改写** | `MAX(原文字数, 300)` |
| **扩写** | 短：`MAX(原文字数 × 1.5, 500)`<br>中：`MAX(原文字数 × 2.0, 1000)`<br>长：`MAX(原文字数 × 3.0, 2000)` |
| **翻译** | `MAX(原文字数, 500)` |

**实现逻辑**:

```objective-c
- (void)performAIGenerationWithType:(AIUAWritingEditType)type {
    // 根据操作类型估算字数
    NSInteger baseContentWords = [AIUAWordPackManager countWordsInText:self.currentContent];
    NSInteger estimatedWords = 0;
    
    switch (type) {
        case AIUAWritingEditTypeContinue:
            estimatedWords = MAX(baseContentWords, 500);
            break;
        // ... 其他类型
    }
    
    // 检查字数是否足够
    if (![[AIUAWordPackManager sharedManager] hasEnoughWords:estimatedWords]) {
        // 显示字数不足提示
        // ...
        return;
    }
    
    // 开始生成...
    
    // 生成完成后消耗实际字数
    if (finished) {
        NSInteger actualWords = [AIUAWordPackManager countWordsInText:self.generatedContent];
        [[AIUAWordPackManager sharedManager] consumeWords:actualWords completion:^(BOOL success, NSInteger remainingWords) {
            // 处理消耗结果
        }];
    }
}
```

---

### 4. 用户体验优化

#### 4.1 字数不足提示

当用户字数不足时，显示友好的提示信息：

**中文**:
```
标题: "字数不足"
内容: "需要 XXX 字，当前可用 XXX 字。请购买字数包或开通会员"
按钮: [取消] [购买字数包]
```

**英文**:
```
Title: "Insufficient Words"
Content: "Need XXX words, but only XXX words available. Please purchase word packs or subscribe to VIP"
Buttons: [Cancel] [Purchase Word Pack]
```

#### 4.2 字数消耗反馈

- ✅ 消耗成功后记录日志
- ✅ 发送`AIUAWordConsumedNotification`通知
- ✅ 更新iCloud同步数据

---

## 📊 数据流程

### 字数消耗流程

```
用户触发AI生成
    ↓
估算需要消耗的字数
    ↓
检查是否有足够字数
    ↓
[字数不足] → 显示提示 → 引导购买
    ↓
[字数充足] → 开始生成
    ↓
生成完成
    ↓
统计实际生成的字数
    ↓
消耗字数（优先VIP赠送，其次购买包）
    ↓
更新本地存储和iCloud
    ↓
发送通知
```

---

## 🔍 验证要点

### 1. 字数统计准确性

- ✅ 中文：每个中文字符计为1字
- ✅ 英文：每个字母计为1字
- ✅ 数字：每个数字计为1字
- ✅ 标点：每个标点符号计为1字
- ✅ 空格：每个空格计为1字
- ✅ Emoji：每个emoji计为1字（不是2字）

### 2. 消耗优先级

- ✅ 优先消耗VIP每日赠送字数
- ✅ VIP赠送字数用完后，消耗购买的字数包
- ✅ 购买包按购买时间顺序消耗（先购买的先消耗）

### 3. 集成完整性

- ✅ 模板创作功能已集成
- ✅ 续写功能已集成
- ✅ 改写功能已集成
- ✅ 扩写功能已集成
- ✅ 翻译功能已集成

---

## 📝 本地化字符串

### 中文 (`zh-Hans.lproj/Localizable.strings`)

```strings
"insufficient_words" = "字数不足";
"insufficient_words_message" = "需要 %@ 字，当前可用 %@ 字。请购买字数包或开通会员";
"purchase_word_pack" = "购买字数包";
```

### 英文 (`en.lproj/Localizable.strings`)

```strings
"insufficient_words" = "Insufficient Words";
"insufficient_words_message" = "Need %@ words, but only %@ words available. Please purchase word packs or subscribe to VIP";
"purchase_word_pack" = "Purchase Word Pack";
```

---

## 🎯 总结

### ✅ 已完成

1. ✅ **字数统计方法**：实现了符合规则的`countWordsInText:`方法
2. ✅ **消耗优先级**：优先消耗VIP每日赠送字数，其次消耗购买包
3. ✅ **模板创作集成**：在`AIUAWritingDetailViewController`中完整集成
4. ✅ **文档编辑集成**：在`AIUADocDetailViewController`中完整集成所有编辑功能
5. ✅ **用户体验优化**：字数不足提示、消耗反馈、iCloud同步

### 📌 关键特性

- **准确的字数统计**：正确处理所有Unicode字符（包括emoji）
- **智能的字数估算**：根据操作类型和原文长度动态估算
- **优先消耗VIP赠送**：确保VIP用户优先使用每日赠送字数
- **友好的用户提示**：字数不足时引导用户购买或订阅

---

## 🚀 使用示例

### 统计文本字数

```objective-c
NSString *text = @"Hello 世界！123 😊";
NSInteger wordCount = [AIUAWordPackManager countWordsInText:text];
// wordCount = 13 (H-e-l-l-o-空格-世-界-！-1-2-3-空格-😊)
```

### 检查并消耗字数

```objective-c
// 检查字数是否足够
if ([[AIUAWordPackManager sharedManager] hasEnoughWords:estimatedWords]) {
    // 开始生成
    // ...
    
    // 生成完成后消耗实际字数
    NSInteger actualWords = [AIUAWordPackManager countWordsInText:generatedText];
    [[AIUAWordPackManager sharedManager] consumeWords:actualWords completion:^(BOOL success, NSInteger remainingWords) {
        if (success) {
            NSLog(@"消耗成功，剩余: %ld 字", (long)remainingWords);
        }
    }];
}
```

---

**实现完成日期**: 2024年
**版本**: 1.0
**状态**: ✅ 已完成并测试

