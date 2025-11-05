# IAP 内购功能 - 快速开始指南

## 🚀 5分钟快速上手

### 第1步：启用 In-App Purchase（1分钟）

1. 打开 Xcode 项目
2. 选择项目 Target
3. 点击 **"Signing & Capabilities"** 标签
4. 点击 **"+ Capability"**
5. 搜索并添加 **"In-App Purchase"**

✅ 完成！

---

### 第2步：在 App Store Connect 创建产品（3分钟）

1. 访问 [App Store Connect](https://appstoreconnect.apple.com)
2. 选择你的应用 → **"App 内购买项目"**
3. 点击 **"+"** 创建订阅群组
4. 创建以下 4 个产品：

#### 产品 1: 永久会员
- Product ID: `com.yourcompany.aiassistant.lifetime`
- 类型: 非续期订阅
- 价格: ¥198

#### 产品 2: 年度会员
- Product ID: `com.yourcompany.aiassistant.yearly`
- 类型: 自动续订订阅（1年）
- 价格: ¥168

#### 产品 3: 月度会员
- Product ID: `com.yourcompany.aiassistant.monthly`
- 类型: 自动续订订阅（1月）
- 价格: ¥68

#### 产品 4: 周度会员
- Product ID: `com.yourcompany.aiassistant.weekly`
- 类型: 自动续订订阅（1周）
- 价格: ¥38

⚠️ **重要**: 将 `com.yourcompany.aiassistant` 替换为你的实际 Bundle ID

✅ 完成！

---

### 第3步：创建沙盒测试账号（1分钟）

1. 在 App Store Connect 中
2. 进入 **"用户和访问"** → **"沙盒技术测试员"**
3. 点击 **"+"** 创建测试账号
4. 填写邮箱、密码、地区等信息

✅ 完成！

---

### 第4步：测试购买（马上开始）

1. **退出设备上的 Apple ID**
   - 设置 → App Store → 登出
   
2. **运行应用**
   ```bash
   # 在 Xcode 中点击运行
   ```

3. **进入会员页面**
   - 设置 → 会员特权
   
4. **选择套餐并购买**
   - 系统会提示登录
   - 输入沙盒测试账号
   - 确认购买（**沙盒环境不会真实扣费**）

5. **测试恢复购买**
   - 点击"恢复订阅"按钮
   - 验证是否恢复成功

✅ 完成！

---

## 📱 验证功能

### 检查订阅状态

在应用中查看：
- **设置** → **会员特权**
- 应显示订阅状态和到期时间

### 查看日志

在 Xcode Console 中查找 `[IAP]` 标签的日志：

```
[IAP] 开始请求产品信息
[IAP] 成功获取 4 个产品
[IAP] 发起购买请求: com.yourcompany.aiassistant.yearly
[IAP] 购买成功
[IAP] 解锁内容
[IAP] 本地收据验证结果: 通过
```

---

## 🔍 常见问题快速解决

### ❌ 问题1: 无法获取产品信息

**解决方法**:
1. 检查 Product ID 是否正确
2. 确认产品状态为"准备提交"
3. 等待几分钟（Apple 服务器同步需要时间）
4. 检查网络连接

### ❌ 问题2: 购买时提示"无法连接到iTunes Store"

**解决方法**:
1. 确保已退出设备上的 Apple ID
2. 在购买时才登录沙盒账号
3. 检查设备的"访问限制"设置

### ❌ 问题3: 恢复购买没有反应

**解决方法**:
1. 确保使用同一个沙盒账号
2. 先完成一次购买，再测试恢复
3. 查看日志确认问题

---

## 📚 更多文档

### 详细配置指南
查看 **`IAP_SETUP_GUIDE.md`** 了解：
- 详细的配置步骤
- 服务器验证实现
- 审核注意事项
- 监控和维护

### 实现总结
查看 **`IAP_IMPLEMENTATION_SUMMARY.md`** 了解：
- 完整的功能列表
- API 使用方法
- 代码集成位置
- 测试说明

---

## 💡 快速使用代码

### 检查用户是否是VIP

```objective-c
#import "AIUAIAPManager.h"

if ([AIUAIAPManager sharedManager].isVIPMember) {
    NSLog(@"用户是VIP会员");
} else {
    NSLog(@"用户未开通会员");
}
```

### 显示订阅页面

```objective-c
#import "AIUAMembershipViewController.h"

AIUAMembershipViewController *vc = [[AIUAMembershipViewController alloc] init];
vc.hidesBottomBarWhenPushed = YES;
[self.navigationController pushViewController:vc animated:YES];
```

### 监听订阅状态变化

```objective-c
// 注册监听
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(subscriptionChanged:)
                                             name:@"AIUASubscriptionStatusChanged"
                                           object:nil];

// 处理变化
- (void)subscriptionChanged:(NSNotification *)notification {
    NSLog(@"订阅状态已更改");
    // 更新UI或解锁功能
}
```

---

## 🎯 下一步

完成测试后：

1. ✅ 确保所有功能正常
2. ✅ 查看 **上线前检查清单**（`IAP_IMPLEMENTATION_SUMMARY.md`）
3. ✅ 实现服务器端验证（推荐，参考 `IAP_SETUP_GUIDE.md`）
4. ✅ 提交 App Store 审核

---

## 🆘 需要帮助？

遇到问题？查看：
1. 项目日志（搜索 `[IAP]` 标签）
2. `IAP_SETUP_GUIDE.md` 中的"常见问题"章节
3. [Apple 官方文档](https://developer.apple.com/in-app-purchase/)

---

**祝你的应用成功上线！🎉**

