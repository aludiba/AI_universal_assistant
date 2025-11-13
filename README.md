# AI万能助手

AI万能助手-你创作的好帮手！

## 📋 项目概述

本项目是一个功能完整的iOS AI写作助手应用，集成了AI写作、文档管理、VIP订阅、字数包购买、iCloud同步等核心功能。

## 🎯 核心功能

### 1. AI写作功能
- **模板创作**：提供丰富的写作模板
- **即时写作**：自由输入创作内容
- **文档编辑**：续写、改写、扩写、翻译

### 2. VIP会员系统
- **订阅类型**：永久会员、年度、月度、周度
- **权限控制**：所有AI功能需要VIP权限
- **跨设备恢复**：自动从Apple ID恢复订阅

### 3. 字数包系统
- **购买方案**：500K/2M/6M三种字数包
- **VIP赠送**：订阅会员每日赠送50万字
- **消耗逻辑**：优先消耗VIP赠送，其次消耗购买包
- **iCloud同步**：跨设备自动同步字数数据

### 4. 开屏广告
- **穿山甲SDK**：集成穿山甲SDK 6.7.0.8
- **自动展示**：应用启动时自动展示
- **可配置**：支持一键开关

### 5. 缓存管理
- **实时显示**：设置页面显示当前缓存大小
- **一键清理**：清除最近使用、搜索历史、创作记录
- **智能保留**：收藏内容不会被清除
- **自动刷新**：清理后相关页面自动更新

## 🔧 技术架构

### 核心技术栈
- **开发语言**：Objective-C
- **最低iOS版本**：iOS 15.0+
- **依赖管理**：CocoaPods
- **UI框架**：UIKit + Masonry
- **网络请求**：NSURLSession
- **数据存储**：NSUserDefaults + Keychain + iCloud

### 主要第三方库
- **Ads-CN** (6.7.0.8)：穿山甲广告SDK
- **MBProgressHUD**：加载提示
- **MJRefresh**：下拉刷新
- **SDWebImage**：图片加载
- **Masonry**：自动布局

## 📦 快速开始

### 1. 环境要求
- Xcode 13+
- CocoaPods
- iOS 15.0+ 设备或模拟器

### 2. 安装依赖
```bash
cd AIUniversalAssistant
pod install
```

### 3. 打开项目
```bash
# 必须打开 .xcworkspace，不要打开 .xcodeproj
open AIUniversalAssistant.xcworkspace
```

### 4. 配置信息

#### 穿山甲广告配置
编辑 `AIUniversalAssistant/Config/AIUAConfigID.h`：
```objective-c
#define AIUA_APPID               @"你的AppID"
#define AIUA_SPLASH_AD_SLOT_ID   @"你的代码位ID"
#define AIUA_AD_ENABLED         1  // 1:开启 0:关闭
```

#### IAP产品配置
在 App Store Connect 中创建以下产品：
- `com.yourcompany.aiassistant.lifetime` - 永久会员
- `com.yourcompany.aiassistant.yearly` - 年度会员
- `com.yourcompany.aiassistant.monthly` - 月度会员
- `com.yourcompany.aiassistant.weekly` - 周度会员

#### 字数包产品配置
在 App Store Connect 中创建消耗型产品：
- `com.yourcompany.aiassistant.wordpack.500k` - 500K字数包
- `com.yourcompany.aiassistant.wordpack.2m` - 2M字数包
- `com.yourcompany.aiassistant.wordpack.6m` - 6M字数包

### 5. 运行项目
在Xcode中按 `Cmd + R` 运行

## 📱 功能模块

### IAP内购系统
- **文件位置**：`AIUniversalAssistant/Utils/AIUAIAPManager.h/m`
- **功能**：订阅购买、恢复购买、收据验证、订阅状态管理
- **安全**：越狱检测、本地收据验证、Bundle ID验证

### VIP权限系统
- **文件位置**：`AIUniversalAssistant/Utils/AIUAVIPManager.h/m`
- **功能**：权限检查、VIP提示弹窗、导航到会员页面
- **集成**：所有AI功能入口已集成权限检查

### 字数包系统
- **文件位置**：`AIUniversalAssistant/Utils/AIUAWordPackManager.h/m`
- **功能**：字数查询、购买、消耗、过期管理
- **同步**：iCloud Key-Value Store自动同步

### 开屏广告
- **文件位置**：`AIUniversalAssistant/Ad/AIUASplashAdManager.h/m`
- **功能**：广告加载、展示、回调处理
- **配置**：支持一键开关，超时自动进入主界面

### 数据管理与缓存
- **文件位置**：`AIUniversalAssistant/Common/AIUADataManager.h/m`
- **功能**：
  - 数据加载与保存（收藏、最近使用、搜索历史、写作记录）
  - 缓存大小计算与格式化
  - 缓存清理（保留收藏，清除其他）
  - 通知机制（清理后自动刷新相关页面）

## 🔐 数据存储

### 本地存储
- **NSUserDefaults**：订阅状态、字数包数据、用户偏好
- **Keychain**：敏感数据加密存储（iCloud不可用时）

### 云端同步
- **iCloud Key-Value Store**：字数包数据跨设备同步
- **自动降级**：iCloud不可用时自动使用Keychain存储
- **手动导出/导入**：支持JSON格式的数据备份

## 👤 用户身份与账号系统

### 当前方案：Apple ID + iCloud

**✅ 已实现的跨设备能力：**
- **订阅信息**：通过Apple IAP绑定到Apple ID，自动跨设备恢复
- **字数包数据**：通过iCloud Key-Value Store自动同步
- **用户身份**：Apple ID作为唯一标识

**✅ 优势：**
- 无需后端服务器，零成本
- 用户无需注册登录，体验流畅
- 数据安全由Apple保障
- 自动同步，用户无感知

### 是否需要独立账号系统？

**❌ 当前不需要，原因：**

1. **Apple ID已提供身份识别**
   - 订阅信息绑定到Apple ID
   - 可以通过Apple ID恢复购买
   - 无需额外的用户标识

2. **iCloud已实现数据同步**
   - 字数包数据自动同步
   - 用户偏好可以同步（如需要）
   - 无需服务器存储

3. **没有后端支持**
   - 独立账号系统需要服务器存储用户数据
   - 需要登录、注册、密码找回等功能
   - 增加开发成本和维护成本

**✅ 什么情况下需要账号系统？**

只有在以下场景才考虑独立账号系统：

1. **需要跨平台同步**（iOS + Android + Web）
   - Apple ID无法在Android使用
   - 需要统一的数据平台

2. **需要社交功能**
   - 用户间分享、评论、关注
   - 需要用户资料、头像等

3. **需要数据统计和分析**
   - 用户行为分析
   - 内容推荐算法
   - 需要服务器端数据处理

4. **需要内容管理**
   - 用户生成内容需要服务器存储
   - 需要内容审核、管理
   - 需要版本控制、协作功能

5. **需要更精细的用户管理**
   - 用户等级、积分系统
   - 邀请奖励、推广系统
   - 需要复杂的用户关系

### 当前架构建议

**保持现状，无需账号系统：**

```
用户身份识别：Apple ID
    ↓
订阅管理：Apple IAP（自动跨设备）
    ↓
数据同步：iCloud（自动跨设备）
    ↓
数据备份：Keychain（本地加密存储）
```

**如果未来需要扩展：**

1. **先考虑扩展iCloud同步**
   - 使用iCloud Documents同步文档
   - 使用CloudKit同步更多数据
   - 仍然无需后端

2. **再考虑轻量级后端**
   - 使用Firebase、Supabase等BaaS服务
   - 最小化开发成本
   - 渐进式迁移

3. **最后考虑完整后端**
   - 只有在明确需要复杂功能时
   - 评估ROI和开发成本

## 🌐 本地化支持

项目支持中英文双语：
- `zh-Hans.lproj/Localizable.strings` - 简体中文
- `en.lproj/Localizable.strings` - 英文

## 🧪 测试

### 沙盒测试账号
1. 在 App Store Connect 创建沙盒测试账号
2. 设备上退出Apple ID
3. 运行应用，购买时登录沙盒账号

### 测试检查清单
- [ ] VIP订阅购买流程
- [ ] 恢复购买功能
- [ ] 字数包购买流程
- [ ] 字数消耗逻辑
- [ ] iCloud跨设备同步
- [ ] 开屏广告展示
- [ ] 权限检查功能

## 📊 项目结构

```
AIUniversalAssistant/
├── AIUniversalAssistant/
│   ├── Ad/                    # 广告模块
│   ├── Common/                # 通用组件
│   ├── Config/                # 配置文件
│   ├── DeepSeekV/             # AI接口
│   ├── Docs/                  # 文档管理
│   ├── Hot/                   # 热门模板
│   ├── Settings/              # 设置页面
│   ├── Utils/                 # 工具类
│   └── Writer/                # 写作功能
├── Pods/                      # 第三方依赖
└── AIUniversalAssistant.xcworkspace
```

## ⚠️ 注意事项

### 开发环境
- 必须使用 `.xcworkspace` 打开项目
- 运行前先执行 `pod install`
- 真机测试需要配置证书

### 上线前检查
- [ ] 替换测试代码位为正式代码位
- [ ] 确认所有产品ID已创建
- [ ] 测试所有购买流程
- [ ] 配置App Store ID（评分和分享功能）
- [ ] 添加隐私政策和使用协议

### 安全建议
- 生产环境建议实现服务器端收据验证
- 定期检查订阅状态
- 监控异常购买行为

## 📚 相关文档

### 配置指南
- **IAP配置**：参考 `IAP_SETUP_GUIDE.md`（已合并）
- **iCloud配置**：在Xcode中启用iCloud Key-value storage
- **广告配置**：在穿山甲平台申请AppID和代码位

### 功能说明
- **VIP权限**：所有AI功能需要VIP权限
- **字数消耗**：优先消耗VIP赠送，其次消耗购买包
- **数据同步**：iCloud可用时自动同步，不可用时使用Keychain

## 🐛 常见问题

### Q: 无法获取产品信息？
A: 检查产品ID是否正确，确认产品状态为"准备提交"，等待几分钟让Apple服务器同步。

### Q: 广告不展示？
A: 检查AppID和代码位ID配置，确认网络连接正常，查看控制台日志。

### Q: iCloud同步不工作？
A: 确认设备已登录Apple ID，已开启iCloud Drive，Xcode中已启用iCloud capability。

### Q: 字数包购买失败？
A: 检查产品ID配置，确认IAP已启用，使用沙盒账号测试。

## 📞 技术支持

- **Apple IAP文档**：https://developer.apple.com/in-app-purchase/
- **穿山甲文档**：https://www.csjplatform.com/supportcenter
- **项目Issues**：提交到项目仓库

## 📝 更新日志

### 2025-11-13
- ✅ 添加清理缓存功能
- ✅ 显示缓存大小（最近使用、搜索历史、创作记录）
- ✅ 清理后自动刷新相关页面
- ✅ 收藏内容不会被清除

### 2025-11-09
- ✅ 完成VIP订阅系统
- ✅ 完成字数包系统
- ✅ 集成穿山甲开屏广告
- ✅ 实现iCloud数据同步
- ✅ 添加越狱检测和安全验证

## 📄 许可证

本项目为私有项目，保留所有权利。

---

**AI万能助手** - 让AI成为你的创作好帮手！🚀
