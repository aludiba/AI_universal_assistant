# 穿山甲SDK开屏广告接入文档

## 概述
本文档介绍如何在 AIUniversalAssistant 项目中使用穿山甲SDK实现开屏广告功能。

## SDK版本
- **穿山甲SDK版本**: Ads-CN 6.7.0.8（国内版本，最新）
- **最低iOS版本**: iOS 15.0+
- **集成方式**: CocoaPods

## ⚠️ API变更说明（6.7+ 版本）
新版本SDK简化了配置API：
- ✅ 保留：`configuration.appID`
- ❌ 移除：`configuration.appName`（不再需要）
- ❌ 移除：`configuration.logLevel`（自动输出日志）

## 接入步骤

### 1. 注册穿山甲账号并创建应用

1. 访问穿山甲广告平台：https://www.csjplatform.com/
2. 注册开发者账号并完成企业认证
3. 在「广告变现」→「流量」→「应用」中创建新应用
4. 记录下生成的 **AppID**

### 2. 创建开屏广告位

1. 在「广告变现」→「流量」→「代码位」中创建开屏广告位
2. 选择「开屏广告」类型
3. 记录下生成的 **代码位ID**

### 3. 安装SDK依赖

项目已在 Podfile 中配置好依赖，只需执行：

```bash
cd /Users/chuhongbiao/Desktop/aludiba/AI_universal_assistant/AIUniversalAssistant
pod install
```

### 4. 配置AppID和代码位ID

打开 `AIUAConfigID.h` 文件，填入你的配置信息：

```objective-c
// 穿山甲广告SDK配置
#define AIUA_APPID               @"你的AppID"              // 穿山甲应用ID（必填）
#define AIUA_SPLASH_AD_SLOT_ID   @"你的开屏广告代码位ID"   // 开屏广告代码位ID（必填）
```

### 5. 配置Info.plist

在项目的 `Info.plist` 中添加以下权限（如果尚未添加）：

```xml
<!-- 允许HTTP请求 -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>

<!-- 应用跟踪透明度授权（iOS 14+） -->
<key>NSUserTrackingUsageDescription</key>
<string>为了向您提供更好的广告体验，请允许应用跟踪您的活动</string>
```

## 使用说明

### 广告展示流程

1. **应用启动时自动展示**：在 `AppDelegate` 的 `application:didFinishLaunchingWithOptions:` 方法中自动判断并展示开屏广告
2. **广告加载成功**：自动展示开屏广告
3. **广告关闭或失败**：自动进入主界面

### 开关广告

如果不想展示广告，可以在 `AIUAConfigID.h` 中设置：

```objective-c
#define AIUA_AD_ENABLED  0  // 0: 关闭广告  1: 开启广告
```

### 代码文件说明

#### 1. AIUASplashAdManager.h/m
开屏广告管理器，封装了穿山甲开屏广告的加载和展示逻辑。

**主要方法**：
```objective-c
// 加载并展示开屏广告
- (void)loadAndShowSplashAdInWindow:(UIWindow *)window
                             loaded:(AIUASplashAdLoadedBlock)loadedBlock
                             closed:(AIUASplashAdClosedBlock)closedBlock
                             failed:(AIUASplashAdFailedBlock)failedBlock;
```

#### 2. AppDelegate.m
在应用启动时初始化穿山甲SDK并展示开屏广告。

**关键方法**：
- `initPangleSDK`：初始化穿山甲SDK
- `showSplashAd`：展示开屏广告
- `showMainWindow`：展示主界面

## 测试步骤

### 1. 使用测试代码位

在测试阶段，可以使用穿山甲提供的测试代码位：

```objective-c
// 测试用代码位ID（仅供测试，请勿发布到线上）
#define AIUA_APPID               @"5001121"
#define AIUA_SPLASH_AD_SLOT_ID   @"887382973"
```

### 2. 运行测试

```bash
# 1. 安装依赖
pod install

# 2. 打开workspace（不要打开xcodeproj）
open AIUniversalAssistant.xcworkspace

# 3. 运行到模拟器或真机测试
# 按 Cmd + R 运行
```

### 3. 查看日志

在Xcode控制台可以看到穿山甲SDK的日志输出：

```
[穿山甲] 开始初始化SDK，AppID: xxx
[穿山甲] SDK初始化成功
[穿山甲] 准备展示开屏广告
[穿山甲] 开始加载开屏广告，代码位ID: xxx
[穿山甲] 开屏广告加载成功
[穿山甲] 开屏广告已展示
[穿山甲] 开屏广告关闭，类型: xx
[主界面] 已展示
```

## 注意事项

### 1. 合规要求
- ✅ 开屏广告必须提供显著、有效的"跳过/关闭"按钮
- ✅ 限制点击跳转的区域，避免误触（SDK已处理）
- ✅ 根据用户隐私政策，获取必要的授权

### 2. 广告策略
- 建议开屏广告展示频率不要过高，避免影响用户体验
- 可以根据用户付费状态、启动次数等条件控制广告展示
- 建议设置合理的超时时间（当前为3秒）

### 3. 性能优化
- SDK初始化是异步的，不会阻塞主线程
- 广告加载失败时会自动进入主界面，不影响应用正常使用
- 使用单例模式管理广告，避免内存泄漏

### 4. 发布到线上
发布前请确保：
- ✅ 替换为正式的AppID和代码位ID
- ✅ 将日志级别改为 `BUAdSDKLogLevelError`
- ✅ 完成广告合规审核
- ✅ 在穿山甲平台完成应用审核

## 常见问题

### Q1: pod install 失败
**解决方案**：
```bash
# 更新 CocoaPods
sudo gem install cocoapods
pod repo update
pod install --repo-update
```

### Q2: 广告不展示
**检查清单**：
1. 确认 `AIUA_AD_ENABLED` 为 1
2. 确认 `AIUA_APPID` 和 `AIUA_SPLASH_AD_SLOT_ID` 已正确配置
3. 查看控制台日志，确认SDK初始化是否成功
4. 确认网络连接正常
5. 测试阶段使用穿山甲提供的测试代码位

### Q3: 编译错误
**解决方案**：
```bash
# 清理项目
Cmd + Shift + K

# 重新安装依赖
pod deintegrate
pod install

# 重新编译
Cmd + B
```

### Q4: 真机运行崩溃
**检查清单**：
1. 确认 Info.plist 中已添加必要的权限
2. 确认证书配置正确
3. 查看崩溃日志定位问题

## 技术支持

- 穿山甲官方文档：https://www.csjplatform.com/supportcenter
- 穿山甲开发者社区：https://forum.partner.oceanengine.com/
- iOS SDK文档：https://www.csjplatform.com/supportcenter/5001

## 更新记录

- **2025/11/09**: 
  - 初始版本，实现开屏广告功能
  - 更新到穿山甲SDK 6.7.0.8（最新版本）
  - 适配新版本API（移除 appName 和 logLevel 配置）

