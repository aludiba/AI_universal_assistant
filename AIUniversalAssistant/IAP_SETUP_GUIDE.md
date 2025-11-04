# Apple IAP (In-App Purchase) 配置指南

## 一、Xcode 项目配置

### 1. 添加 StoreKit 框架能力
1. 打开 Xcode 项目
2. 选择项目 Target
3. 点击 "Signing & Capabilities" 标签
4. 点击 "+ Capability"
5. 添加 "In-App Purchase"

### 2. 配置 Bundle Identifier
确保项目的 Bundle Identifier 与 App Store Connect 中的一致

当前 Bundle ID: `$(PRODUCT_BUNDLE_IDENTIFIER)`
示例: `com.yourcompany.aiassistant`

## 二、App Store Connect 配置

### 1. 登录 App Store Connect
访问: https://appstoreconnect.apple.com

### 2. 创建订阅群组
1. 进入 "我的 App"
2. 选择你的应用
3. 点击 "订阅" 或 "App 内购买项目"
4. 创建一个新的订阅群组
5. 群组名称: "会员订阅"

### 3. 创建订阅产品

需要创建以下4个订阅产品：

#### 产品 1: 永久会员
- **产品ID**: `com.yourcompany.aiassistant.lifetime`
- **参考名称**: 永久会员
- **订阅周期**: 非续期订阅（Non-Renewing Subscription）
- **价格**: ¥198
- **描述**: 一次购买，永久使用
- **显示名称**: 
  - 中文：永久会员
  - 英文：Lifetime Member

#### 产品 2: 年度会员
- **产品ID**: `com.yourcompany.aiassistant.yearly`
- **参考名称**: 年度会员
- **订阅周期**: 1年（自动续订）
- **价格**: ¥168
- **描述**: 约0.5毛/天
- **显示名称**: 
  - 中文：年度会员
  - 英文：Yearly Plan

#### 产品 3: 月度会员
- **产品ID**: `com.yourcompany.aiassistant.monthly`
- **参考名称**: 月度会员
- **订阅周期**: 1个月（自动续订）
- **价格**: ¥68
- **描述**: 短期创作首选
- **显示名称**: 
  - 中文：月度会员
  - 英文：Monthly Plan

#### 产品 4: 周度会员
- **产品ID**: `com.yourcompany.aiassistant.weekly`
- **参考名称**: 周度会员
- **订阅周期**: 1周（自动续订）
- **价格**: ¥38
- **描述**: 体验AI写作
- **显示名称**: 
  - 中文：周度会员
  - 英文：Weekly Plan

### 4. 配置产品详情

对于每个产品，需要配置：
1. **本地化信息** (中文和英文)
   - 显示名称
   - 描述
2. **审核信息**
   - 屏幕截图（可选）
   - 审核说明
3. **价格**
   - 选择价格级别
   - 确认各地区价格

## 三、测试配置

### 1. 创建沙盒测试账号
1. 在 App Store Connect 中
2. 进入 "用户和访问" -> "沙盒技术测试员"
3. 点击 "+" 创建新的测试账号
4. 填写测试账号信息（邮箱、密码、地区等）

### 2. 在设备上配置测试账号
1. 打开 "设置" -> "App Store"
2. 登出当前账号
3. 不要在这里登录沙盒账号！
4. 运行应用，尝试购买时会提示登录
5. 此时输入沙盒测试账号

### 3. 测试购买流程
1. 运行应用
2. 进入会员订阅页面
3. 选择一个订阅方案
4. 点击购买，系统会显示确认对话框
5. 使用沙盒账号完成购买（沙盒环境不会真实扣费）

## 四、代码说明

### 1. 产品 ID 映射
在 `AIUAIAPManager.m` 中的 `productIdentifierForType:` 方法会自动生成产品ID：

```objective-c
// 格式: com.yourcompany.aiassistant.{product_type}
// 例如: com.yourcompany.aiassistant.lifetime
```

### 2. 修改 Bundle ID 后需要做的事
如果你修改了项目的 Bundle ID，产品ID会自动更新。
但需要在 App Store Connect 中创建对应的新产品ID。

### 3. 收据验证
当前代码包含本地收据验证的框架，建议在生产环境中：
1. 将收据发送到你的服务器
2. 服务器将收据转发给 Apple 验证
3. 根据验证结果解锁内容

Apple 验证服务器：
- 生产环境: `https://buy.itunes.apple.com/verifyReceipt`
- 沙盒环境: `https://sandbox.itunes.apple.com/verifyReceipt`

## 五、常见问题

### Q1: 无法获取产品信息
**原因:**
- 产品ID不匹配
- 产品状态未设置为"准备提交"
- Bundle ID不匹配
- 网络问题

**解决方法:**
1. 检查产品ID是否正确
2. 在 App Store Connect 中确认产品状态
3. 确保网络连接正常
4. 等待几分钟，Apple 服务器可能需要同步时间

### Q2: 购买时提示"无法连接到iTunes Store"
**原因:**
- 未使用沙盒测试账号
- 设备限制问题

**解决方法:**
1. 确保使用沙盒测试账号
2. 退出设备上的Apple ID，在购买时再登录沙盒账号
3. 检查设备的"访问限制"设置

### Q3: 恢复购买没有反应
**原因:**
- 没有可恢复的购买记录
- 使用了不同的Apple ID

**解决方法:**
1. 确保使用同一个Apple ID
2. 对于非自动续订订阅（如永久会员），需要自己管理恢复逻辑
3. 检查 `paymentQueue:updatedTransactions:` 方法是否正确处理

### Q4: 审核被拒，提示无法测试购买
**原因:**
- 产品未配置完整
- 未提供测试账号

**解决方法:**
1. 在审核信息中提供沙盒测试账号
2. 确保所有产品都处于"准备提交"状态
3. 在审核说明中详细说明测试步骤

## 六、上线前检查清单

- [ ] 所有产品在 App Store Connect 中已创建
- [ ] 产品ID与代码中的匹配
- [ ] 产品已本地化（中文和英文）
- [ ] 已使用沙盒账号完整测试购买流程
- [ ] 已测试恢复购买功能
- [ ] 已添加收据验证（推荐使用服务器验证）
- [ ] 已在应用中添加"恢复购买"按钮
- [ ] 已准备审核说明和测试账号
- [ ] 已添加订阅管理链接（在设置中）
- [ ] 已添加隐私政策和用户协议

## 七、监控和维护

### 1. 监控订阅状态
使用 App Store Server Notifications 监听订阅状态变化：
- 订阅开始
- 订阅续订
- 订阅取消
- 退款

### 2. 定期检查
- 定期检查用户的订阅状态
- 处理过期订阅
- 更新本地订阅信息

### 3. 数据分析
建议追踪以下指标：
- 订阅转化率
- 各产品的订阅比例
- 订阅续订率
- 退订率
- 收入统计

## 八、相关资源

- [Apple IAP 官方文档](https://developer.apple.com/in-app-purchase/)
- [StoreKit 框架文档](https://developer.apple.com/documentation/storekit)
- [App Store Connect 帮助](https://help.apple.com/app-store-connect/)
- [收据验证指南](https://developer.apple.com/documentation/appstorereceipts)

## 九、联系支持

如果遇到问题，可以：
1. 查看 Xcode Console 中的日志（标签：[IAP]）
2. 检查 App Store Connect 中的产品配置
3. 联系 Apple Developer Support

