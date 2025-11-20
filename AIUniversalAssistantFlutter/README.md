# AI Universal Assistant - Flutter版本

AI写作助手跨平台应用（iOS & Android）

## 功能特性

- ✅ AI辅助写作（基于DeepSeek API）
- ✅ VIP会员订阅系统（IAP）
- ✅ 字数包系统（购买、消耗、VIP赠送）
- ✅ 文档管理（创建、编辑、删除）
- ✅ 创作记录管理
- ✅ 模板搜索和收藏
- ✅ 云同步（Firebase/iCloud）
- ✅ 本地化支持（中英文）
- ✅ 激励视频广告

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── config/                   # 配置文件
├── models/                   # 数据模型
├── services/                 # 服务层
│   ├── ai_service.dart       # AI写作服务
│   ├── iap_service.dart      # 内购服务
│   ├── word_pack_service.dart # 字数包服务
│   ├── vip_service.dart      # VIP服务
│   ├── data_service.dart     # 数据管理服务
│   └── sync_service.dart     # 云同步服务
├── providers/                # 状态管理
├── screens/                  # 页面
│   ├── splash/              # 启动页
│   ├── main_tab/            # 主TabBar
│   ├── hot/                 # 热门模块
│   ├── writer/              # 写作模块
│   ├── docs/                # 文档模块
│   └── settings/            # 设置模块
├── widgets/                  # 通用组件
├── utils/                    # 工具类
└── l10n/                     # 本地化文件
```

## 开始使用

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 配置

在 `lib/config/app_config.dart` 中配置：
- DeepSeek API Key
- IAP产品ID
- 广告配置（如需要）

### 3. 运行

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

## 平台特定配置

### iOS

在 `ios/Runner/Info.plist` 中配置：
- iCloud权限
- 广告ID（如需要）

### Android

在 `android/app/build.gradle` 中配置：
- 应用签名
- 广告SDK（如需要）

## 许可证

Copyright © 2025 AI Universal Assistant
保留所有权利

