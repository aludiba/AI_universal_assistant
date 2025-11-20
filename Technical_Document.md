# AI万能助手 (AIUniversalAssistant) 技术文档

## 1. 项目简介
**AI万能助手** 是一款基于 iOS 平台的 AI 辅助写作工具，旨在通过人工智能技术帮助用户进行高效创作。应用集成了模版写作、自由创作、文档管理、智能改写/扩写/翻译等功能，并配备了完善的 VIP 订阅会员系统和字数包消耗系统。

## 2. 技术栈与开发环境

### 2.1 核心技术
*   **开发语言**: Objective-C
*   **最低支持版本**: iOS 15.0+
*   **架构模式**: MVC (Model-View-Controller)
*   **UI 框架**: UIKit (纯代码布局，主要使用 Masonry)
*   **网络层**: NSURLSession + Network.framework (用于网络状态监测)
*   **数据存储**: 
    *   `NSUserDefaults`: 用户偏好设置
    *   `Keychain`: 敏感数据（如 VIP 状态备份）加密存储
    *   `iCloud Key-Value Store`: 跨设备数据（如字数包余额）同步
    *   `plist`: 本地数据持久化（历史记录、搜索记录、写作草稿等）

### 2.2 第三方库 (CocoaPods)
*   **Masonry**: 自动布局库，简化 Auto Layout 代码。
*   **MBProgressHUD**: 提示框与加载进度指示器。
*   **MJRefresh**: 下拉刷新与上拉加载控件。
*   **SDWebImage**: 异步图片加载与缓存。
*   **Ads-CN (BytedanceUnionAd)**: 穿山甲广告 SDK (v6.7.0.8)，用于展示开屏广告和激励视频广告。

### 2.3 开发工具
*   **IDE**: Xcode 13+
*   **依赖管理**: CocoaPods

## 3. 项目架构与目录结构

项目采用标准的 MVC 架构，目录结构清晰，主要模块划分如下：

### 3.1 根目录
*   **`AppDelegate` / `SceneDelegate`**: 应用生命周期管理，负责 SDK 初始化（如穿山甲广告）、IAP 启动检查、跟视图控制器设置等。
*   **`AIUATabBarController`**: 主 TabBar 控制器，管理应用的主要功能入口（热门、写作、文档、设置）。

### 3.2 主要模块 (`AIUniversalAssistant` 目录下)

#### 3.2.1 `Common` (公共组件)
*   **`AIUADataManager`**: 核心数据管理类。负责缓存计算、清理、本地数据（历史、收藏）的增删改查及持久化。
*   **`AIUASuperViewController`**: 所有视图控制器的基类，封装了通用的导航栏设置、背景色等。
*   **`AIUASuperTableViewCell` / `AIUASuperCollectionViewCell`**: 列表 Cell 基类。
*   **`UITextView+AIUAPlaceholder`**: `UITextView` 分类，实现了动态计算高度和避免遮挡的 Placeholder 功能。

#### 3.2.2 `Ad` (广告模块)
*   **`AIUASplashViewController`**: **(核心重构)** 独立的开屏广告视图控制器。
    *   负责在应用启动时加载穿山甲开屏广告。
    *   集成网络状态监测 (`Network.framework`)，无网状态下快速通过。
    *   管理广告展示、点击跳转及关闭后的主界面切换逻辑。
*   **`AIUASplashAdManager`**: 旧版开屏管理类（逐步废弃，逻辑迁移至 `AIUASplashViewController`）。
*   **`AIUARewardAdManager`**: 激励视频广告管理。

#### 3.2.3 `Hot` (热门/首页)
*   **`AIUAHotViewController`**: 首页推荐，展示热门模板和分类。
*   **`AIUASearchViewController`**: 搜索功能，支持搜索历史记录。
*   **`AIUAWritingInputViewController`**: 写作输入页面，处理用户 Prompt 输入。

#### 3.2.4 `Writer` (写作)
*   **`AIUAWriterViewController`**: 写作主页，分类展示各种写作场景（职场、校园、营销等）。
*   **`AIUAWritingDetailViewController`**: 写作详情页，执行 AI 写作生成，展示结果，处理字数消耗逻辑。
*   **`AIUAWritingRecordsViewController`**: 写作历史记录列表。

#### 3.2.5 `Docs` (文档)
*   **`AIUADocumentsViewController`**: 文档列表页，管理用户保存的文档。
*   **`AIUADocDetailViewController`**: 文档编辑详情页，支持对现有文档进行 AI 改写、续写、润色等操作。

#### 3.2.6 `Settings` (设置)
*   **`AIUASettingsViewController`**: 设置主页，包含清理缓存、会员入口、关于我们等。
*   **`AIUAMembershipViewController`**: 会员订阅页面，展示 VIP 权益和 IAP 商品。
*   **`AIUAWordPackViewController`**: 字数包购买页面。

#### 3.2.7 `DeepSeekV` (AI 引擎)
*   **`AIUADeepSeekWriter`**: 封装 DeepSeek API 或相关大模型接口，负责与服务端进行 AI 文本生成交互。

#### 3.2.8 `Utils` (工具类)
*   **`AIUAIAPManager`**: 内购管理的核心类。
    *   处理商品请求、购买流程、恢复购买。
    *   负责本地收据验证和交易状态更新。
*   **`AIUAWordPackManager`**: 字数包管理类。
    *   管理本地和 iCloud 的字数余额。
    *   实现 "优先消耗 VIP 赠送字数，后消耗购买字数" 的逻辑。
*   **`AIUAVIPManager`**: VIP 权限管理，判断用户当前会员状态。
*   **`AIUAKeychainManager`**: 钥匙串操作封装，用于安全存储。

## 4. 核心功能实现细节

### 4.1 缓存管理系统
*   **功能**: 计算并清理应用产生的临时文件，保留用户收藏的重要数据。
*   **实现**:
    *   通过 `AIUADataManager` 遍历沙盒中的 `AIUARecentUsed.plist` (最近使用), `SearchHistory.plist` (搜索历史), `AIUAWritings.plist` (写作记录)。
    *   计算文件大小总和并在设置页显示。
    *   清理时删除文件并发送 `AIUACacheClearedNotification` 通知，各 UI 模块收到通知后自动刷新界面。
    *   **保护机制**: 收藏夹数据存储在独立文件或通过字段标识，清理操作不影响收藏内容。

### 4.2 字数包消耗系统
*   **规则**: `消耗字数 = 输入字数 (Prompt) + 输出字数 (AI 生成)`。
*   **逻辑**: 每次写作完成时，系统调用 `AIUAWordPackManager`扣除余额。
*   **同步**: 余额变动实时写入本地 `NSUserDefaults` 并尝试推送到 `NSUbiquitousKeyValueStore` (iCloud)，实现多设备同步。

### 4.3 开屏广告 (Splash Ad)
*   **重构方案**: 模仿 `SeaHorseTheater` 项目，将开屏逻辑从 `AppDelegate` 剥离到 `AIUASplashViewController`。
*   **流程**:
    1.  App 启动，`AppDelegate` 判断是否需要展示广告。
    2.  若需要，将 `rootViewController` 设置为 `AIUASplashViewController`。
    3.  `AIUASplashViewController` 启动网络监测，有网则加载穿山甲广告，无网或超时则直接调用 `enterMainUI` 切换回 `AIUATabBarController`。
    4.  广告点击或关闭后，平滑过渡到主界面。

### 4.4 VIP 会员与内购 (IAP)
*   **无需账号系统**: 利用 Apple ID 机制。订阅状态绑定 Apple ID，通过 `restoreCompletedTransactions` 恢复资格。
*   **安全性**: 关键 IAP 状态本地加密存储于 Keychain，防止删包重装后数据丢失（针对非消耗品和订阅）。

## 5. 配置说明

### 5.1 广告配置
在 `AIUAConfigID.h` 中配置：
```objective-c
#define AIUA_APPID               @"YOUR_APP_ID"
#define AIUA_SPLASH_AD_SLOT_ID   @"YOUR_SLOT_ID"
#define AIUA_AD_ENABLED          1 // 1开启，0关闭
```

### 5.2 隐私权限
`Info.plist` 中需配置：
*   `NSAppTransportSecurity`: 允许任意网络加载 (广告 SDK 需求)。
*   `NSUserTrackingUsageDescription`: IDFA 权限请求（用于广告精准投放）。

## 6. 注意事项
1.  **Placeholder 显示**: `UITextView` 的 Placeholder 已经过特殊适配，支持多行显示且不被遮挡，修改字体或边距时需同步调整 `UITextView+AIUAPlaceholder.m` 中的计算逻辑。
2.  **崩溃防护**: 在 `AIUADataManager` 保存数据时已加入类型检查和判空保护，防止因数据结构异常导致的 Crash。

