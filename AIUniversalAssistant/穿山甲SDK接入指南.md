# 穿山甲SDK接入指南 - 快速开始

## 🎯 当前进度
✅ 已完成穿山甲SDK 6.7.0.8 的接入和开屏广告实现（最新版本）

## 📋 接入清单

### ✅ 已完成的工作

1. **Podfile配置** ✅
   - 添加了 `pod 'Ads-CN', '~> 6.3.0.6'` 依赖
   - 位置：`/Podfile`

2. **广告管理类** ✅
   - 创建了 `AIUASplashAdManager.h/m` 开屏广告管理器
   - 位置：`AIUniversalAssistant/Ad/`
   - 功能：封装广告加载、展示、回调等逻辑

3. **SDK初始化** ✅
   - 在 `AppDelegate.m` 中添加了SDK初始化代码
   - 支持自动判断SDK是否已安装
   - 包含完整的错误处理

4. **配置文件** ✅
   - 更新了 `AIUAConfigID.h`
   - 添加了详细的配置说明和注释
   - 支持一键开关广告功能

5. **文档** ✅
   - 创建了详细的README文档
   - 位置：`AIUniversalAssistant/Ad/README.md`

### 🔧 下一步操作（需要你手动完成）

#### 步骤1: 安装SDK依赖
```bash
cd /Users/chuhongbiao/Desktop/aludiba/AI_universal_assistant/AIUniversalAssistant
pod install
```

#### 步骤2: 配置穿山甲AppID和代码位ID

打开 `AIUniversalAssistant/Config/AIUAConfigID.h`，填入你的配置：

```objective-c
// 测试阶段可以使用穿山甲提供的测试代码位
#define AIUA_APPID               @"5001121"         // 测试AppID
#define AIUA_SPLASH_AD_SLOT_ID   @"887382973"      // 测试开屏广告代码位

// 正式上线前，替换为你自己申请的ID：
// #define AIUA_APPID               @"你的AppID"
// #define AIUA_SPLASH_AD_SLOT_ID   @"你的代码位ID"
```

#### 步骤3: 运行项目
```bash
# 打开 workspace（重要：必须打开workspace，不是xcodeproj）
open AIUniversalAssistant.xcworkspace

# 或者在Xcode中：
# 1. File -> Open -> 选择 AIUniversalAssistant.xcworkspace
# 2. 选择模拟器或真机
# 3. 按 Cmd + R 运行
```

## 📱 效果预览

运行后，应用启动时会：
1. 初始化穿山甲SDK
2. 展示开屏广告（3秒超时）
3. 用户点击跳过或广告关闭后，进入主界面
4. 如果广告加载失败，直接进入主界面

## 🔍 测试验证

### 查看控制台日志

成功的日志应该是：
```
[穿山甲] 开始初始化SDK，AppID: 5001121
[穿山甲] SDK初始化成功
[穿山甲] 准备展示开屏广告
[穿山甲] 开始加载开屏广告，代码位ID: 887382973
[穿山甲] 开屏广告加载成功
[穿山甲] 开屏广告展示成功
[穿山甲] 开屏广告关闭，类型: 1
[主界面] 已展示
```

### 如果看到未集成提示

```
[穿山甲] SDK未集成，请执行 pod install 安装依赖
```

说明还没有执行 `pod install`，请先安装依赖。

## 🎨 自定义配置

### 关闭广告
```objective-c
// 在 AIUAConfigID.h 中设置
#define AIUA_AD_ENABLED  0  // 关闭广告
```

### 修改超时时间
```objective-c
// 在 AIUASplashAdManager.m 中修改
self.splashAd.tolerateTimeout = 3.0; // 单位：秒
```

### ~~调整日志级别~~（已废弃）
```objective-c
// 注意：SDK 6.7+ 版本已移除 logLevel 属性
// 日志会自动输出到Xcode控制台，无需手动配置
```

## 📚 申请正式AppID流程

### 1. 注册账号
访问：https://www.csjplatform.com/

### 2. 创建应用
- 进入「广告变现」→「流量」→「应用」
- 点击「新建应用」
- 填写应用信息（包名、名称等）
- 提交审核

### 3. 创建代码位
- 进入「广告变现」→「流量」→「代码位」
- 选择刚创建的应用
- 点击「新建代码位」
- 选择「开屏广告」
- 配置广告参数
- 获取代码位ID

### 4. 替换测试ID
将申请到的AppID和代码位ID填入 `AIUAConfigID.h`

## ⚠️ 重要提示

1. **必须使用 .xcworkspace 打开项目**
   - ❌ 不要打开 AIUniversalAssistant.xcodeproj
   - ✅ 打开 AIUniversalAssistant.xcworkspace

2. **pod install 前置条件**
   - 确保已安装 CocoaPods
   - 如果没有：`sudo gem install cocoapods`

3. **测试代码位仅供测试**
   - 测试代码位不能用于发布到App Store
   - 正式上线前必须替换为自己申请的ID

4. **合规要求**
   - 确保 Info.plist 中添加了隐私政策说明
   - 根据地区要求，可能需要用户同意才能展示广告

## 🐛 常见问题

### Q: pod install 报错
```bash
# 更新 CocoaPods
sudo gem install cocoapods
pod repo update

# 清理缓存后重试
pod cache clean --all
pod install --repo-update
```

### Q: 编译错误 "Cannot find 'BUAdSDK'"
- 确认已执行 `pod install`
- 确认打开的是 `.xcworkspace` 而不是 `.xcodeproj`
- 尝试清理项目：Cmd + Shift + K，然后重新编译

### Q: 广告不展示
- 检查网络连接
- 检查是否配置了AppID和代码位ID
- 查看控制台日志，根据错误信息排查
- 尝试使用测试代码位验证

## 📞 技术支持

- 穿山甲官方文档：https://www.csjplatform.com/supportcenter
- 开发者社区：https://forum.partner.oceanengine.com/
- 项目Issues：提交到项目的GitHub仓库

## 🎉 完成！

按照以上步骤操作后，开屏广告功能就接入完成了！

如有问题，请查看详细文档：`AIUniversalAssistant/Ad/README.md`

