# iCloud不可用时的替代方案

## 📋 概述

当设备未登录Apple ID或未开启iCloud Drive时，应用会自动降级到本地存储，并提供手动导出/导入功能作为跨设备同步的替代方案。

---

## 🔄 自动降级机制

### 工作原理

1. **iCloud可用性检测**
   - 应用启动时自动检测iCloud是否可用
   - 如果不可用，自动使用本地存储（**Keychain钥匙串**）

2. **数据存储策略**
   - ✅ **iCloud可用**：数据存储在Keychain + 同步到iCloud
   - ✅ **iCloud不可用**：数据仅存储在Keychain（钥匙串）
   - ✅ **功能不受影响**：所有功能正常工作，只是无法跨设备同步
   - ✅ **数据安全**：Keychain提供加密存储，比NSUserDefaults更安全

### 代码实现

**文件**: `AIUAWordPackManager.m`

```objective-c
// 检测iCloud是否可用
- (BOOL)isiCloudAvailable {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *ubiquityURL = [fileManager URLForUbiquityContainerIdentifier:nil];
    
    if (ubiquityURL == nil) {
        // 设备未登录Apple ID或未开启iCloud Drive
        return NO;
    }
    
    return YES;
}

// 启用iCloud同步（带自动降级）
- (void)enableiCloudSync {
    if (![self isiCloudAvailable]) {
        NSLog(@"[WordPack] iCloud不可用，使用Keychain本地存储");
        // 自动降级到Keychain存储，无需用户操作
        return;
    }
    
    // iCloud可用，启用同步
    self.iCloudSyncEnabled = YES;
    // ... 配置iCloud同步
}

// 本地存储辅助方法（使用Keychain）
- (void)setLocalInteger:(NSInteger)value forKey:(NSString *)key {
    [self.keychainManager setInteger:value forKey:key];
}

- (NSInteger)localIntegerForKey:(NSString *)key {
    return [self.keychainManager integerForKey:key];
}
```

---

## 📤 手动导出/导入功能

### 使用场景

当iCloud不可用时，用户可以通过手动导出/导入功能：
- ✅ 备份字数包数据
- ✅ 在新设备上恢复数据
- ✅ 跨设备手动同步数据

### 导出数据

**方法**: `exportWordPackData`

**返回**: JSON格式的字符串

**包含的数据**:
- VIP赠送字数
- VIP赠送字数刷新日期
- 购买记录（字数包）
- 消耗记录

**示例代码**:

```objective-c
NSString *jsonData = [[AIUAWordPackManager sharedManager] exportWordPackData];
if (jsonData) {
    // 保存到文件或分享给用户
    NSLog(@"导出成功: %@", jsonData);
} else {
    NSLog(@"导出失败");
}
```

**导出的JSON格式**:

```json
{
  "version": 1,
  "exportTime": 1734567890,
  "vipGiftedWords": 500000,
  "vipGiftedWordsLastRefreshDate": 1734567890,
  "purchases": [
    {
      "productID": "com.yourcompany.aiassistant.wordpack.500k",
      "words": 500000,
      "remainingWords": 450000,
      "purchaseDate": 1734567890,
      "expiryDate": 1737237890
    }
  ],
  "consumedWords": 50000
}
```

### 导入数据

**方法**: `importWordPackData:completion:`

**参数**: JSON格式的字符串

**示例代码**:

```objective-c
NSString *jsonString = @"..."; // 从文件读取或用户输入

[[AIUAWordPackManager sharedManager] importWordPackData:jsonString completion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"导入成功");
        // 刷新UI显示
    } else {
        NSLog(@"导入失败: %@", error.localizedDescription);
    }
}];
```

---

## 🎯 用户体验流程

### 场景1：iCloud可用

```
用户打开应用
    ↓
检测iCloud可用
    ↓
启用iCloud同步
    ↓
数据自动同步到iCloud
    ↓
其他设备自动同步
```

### 场景2：iCloud不可用

```
用户打开应用
    ↓
检测iCloud不可用
    ↓
自动降级到本地存储
    ↓
数据保存在本地（NSUserDefaults）
    ↓
功能正常使用
    ↓
用户可以通过导出/导入手动同步
```

### 场景3：手动跨设备同步

```
设备A（iCloud不可用）
    ↓
导出数据 → JSON文件
    ↓
通过AirDrop/邮件/其他方式传输
    ↓
设备B（iCloud不可用）
    ↓
导入JSON文件
    ↓
数据恢复成功
```

---

## 💡 实现建议

### 1. 在设置页面添加导出/导入功能

**建议UI**:
- 导出按钮：生成JSON文件，支持分享
- 导入按钮：从文件选择器选择JSON文件导入
- 显示iCloud状态：显示当前是否使用iCloud同步

### 2. 导出功能实现示例

```objective-c
// 在设置页面
- (void)exportWordPackData {
    NSString *jsonData = [[AIUAWordPackManager sharedManager] exportWordPackData];
    
    if (jsonData) {
        // 保存到文件
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths firstObject];
        NSString *filePath = [documentsPath stringByAppendingPathComponent:@"wordpack_backup.json"];
        
        [jsonData writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        // 分享文件
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] 
            initWithActivityItems:@[[NSURL fileURLWithPath:filePath]] 
            applicationActivities:nil];
        [self presentViewController:activityVC animated:YES completion:nil];
    }
}
```

### 3. 导入功能实现示例

```objective-c
// 在设置页面
- (void)importWordPackData {
    // 使用UIDocumentPickerViewController选择文件
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] 
        initWithDocumentTypes:@[@"public.json"] 
        inMode:UIDocumentPickerModeImport];
    documentPicker.delegate = self;
    [self presentViewController:documentPicker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *fileURL = urls.firstObject;
    
    // 读取JSON文件
    NSString *jsonString = [NSString stringWithContentsOfURL:fileURL 
        encoding:NSUTF8StringEncoding error:nil];
    
    if (jsonString) {
        [[AIUAWordPackManager sharedManager] importWordPackData:jsonString completion:^(BOOL success, NSError *error) {
            if (success) {
                [self showAlert:@"导入成功"];
                // 刷新UI
            } else {
                [self showAlert:[NSString stringWithFormat:@"导入失败: %@", error.localizedDescription]];
            }
        }];
    }
}
```

---

## 📊 数据存储对比

| 特性 | iCloud同步 | Keychain本地存储 | 手动导出/导入 |
|------|-----------|-----------------|--------------|
| **可用性** | 需要Apple ID + iCloud Drive | 始终可用 | 始终可用 |
| **自动同步** | ✅ 是 | ❌ 否 | ❌ 否 |
| **跨设备** | ✅ 是 | ❌ 否 | ✅ 是（手动） |
| **数据安全** | ✅ 加密 | ✅ **Keychain加密** | ⚠️ 用户负责 |
| **存储位置** | iCloud + Keychain | Keychain | JSON文件 |
| **使用便捷性** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

### Keychain优势

- ✅ **加密存储**：数据在Keychain中自动加密
- ✅ **系统级安全**：由iOS系统管理，安全性高
- ✅ **持久化**：即使应用卸载，数据也可能保留（取决于配置）
- ✅ **性能**：读写速度快

---

## ✅ 优势总结

### 自动降级机制

1. ✅ **无缝体验**：iCloud不可用时自动使用本地存储
2. ✅ **功能完整**：所有功能正常工作
3. ✅ **无需用户操作**：自动处理，用户无感知

### 手动导出/导入

1. ✅ **灵活备份**：用户可以随时备份数据
2. ✅ **跨设备同步**：即使iCloud不可用也能同步
3. ✅ **数据恢复**：支持从备份恢复数据

---

## 🎯 最佳实践

### 1. 检测并提示用户

```objective-c
- (void)checkiCloudStatus {
    BOOL iCloudAvailable = [[AIUAWordPackManager sharedManager] isiCloudAvailable];
    
    if (!iCloudAvailable) {
        // 可选：提示用户iCloud不可用，建议开启
        // 但不要强制，因为用户可能不想使用iCloud
    }
}
```

### 2. 在设置页面显示状态

```objective-c
// 显示iCloud同步状态
if ([[AIUAWordPackManager sharedManager] isiCloudAvailable]) {
    statusLabel.text = @"iCloud同步已启用";
    statusLabel.textColor = [UIColor greenColor];
} else {
    statusLabel.text = @"iCloud不可用，使用本地存储";
    statusLabel.textColor = [UIColor orangeColor];
    // 显示导出/导入按钮
}
```

### 3. 定期提醒备份

```objective-c
// 如果iCloud不可用，定期提醒用户导出备份
if (![[AIUAWordPackManager sharedManager] isiCloudAvailable]) {
    NSDate *lastBackupDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastBackupDate"];
    if (!lastBackupDate || [lastBackupDate timeIntervalSinceNow] < -7 * 24 * 60 * 60) {
        // 7天未备份，提醒用户
        [self remindUserToBackup];
    }
}
```

---

## 📝 总结

### ✅ 已实现的功能

1. ✅ **iCloud可用性检测**：`isiCloudAvailable`
2. ✅ **自动降级机制**：iCloud不可用时自动使用本地存储
3. ✅ **数据导出功能**：`exportWordPackData`
4. ✅ **数据导入功能**：`importWordPackData:completion:`

### 🎯 用户体验

- ✅ **iCloud可用**：自动同步，最佳体验
- ✅ **iCloud不可用**：自动降级，功能正常
- ✅ **手动同步**：导出/导入功能，灵活备份

**无论用户是否使用iCloud，应用都能正常工作！** 🎉

