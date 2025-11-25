# AI创作喵 - Flutter跨平台版

基于Flutter开发的AI写作助手跨平台应用，支持Android和iOS双端，与原生版本功能完全一致。

## 功能特性

### 核心功能
- **热门模板**: 提供多种热门写作模板，快速开始创作
- **AI写作**: 智能生成各类文本内容
- **文档管理**: 创建、编辑、保存文档
- **续写/改写/扩写/翻译**: 多种AI辅助功能

### 会员系统
- 周度/月度/年度/永久会员
- 每日赠送50万字（VIP）
- 字数包购买系统

### 数据管理
- 收藏功能
- 最近使用记录
- 搜索历史
- 缓存管理

## 技术栈

- **框架**: Flutter 3.0+
- **语言**: Dart 3.0+
- **状态管理**: Provider
- **本地存储**: SharedPreferences
- **网络请求**: Dio + Http
- **UI组件**: Material Design

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── models/                      # 数据模型
│   ├── writing_category.dart
│   ├── hot_category.dart
│   ├── writing_record.dart
│   ├── document.dart
│   ├── word_pack.dart
│   └── subscription.dart
├── services/                    # 服务层
│   ├── storage_service.dart    # 本地存储服务
│   ├── ai_service.dart         # AI服务
│   └── data_service.dart       # 数据服务
├── providers/                   # 状态管理
│   ├── data_provider.dart      # 数据Provider
│   ├── vip_provider.dart       # 会员Provider
│   └── word_pack_provider.dart # 字数包Provider
├── screens/                     # 页面
│   ├── splash_screen.dart      # 启动页
│   ├── main_screen.dart        # 主页面
│   ├── hot/                    # 热门页面
│   ├── writer/                 # 写作页面
│   ├── docs/                   # 文档页面
│   └── settings/               # 设置页面
└── utils/                       # 工具类
    ├── app_colors.dart         # 颜色定义
    └── extensions.dart         # 扩展函数
```

## 开发环境

- Flutter SDK: 3.0.0+
- Dart SDK: 3.0.0+
- Android Studio / VS Code
- Xcode (iOS开发)

## 快速开始

### 1. 安装依赖

```bash
cd AIUniversalAssistantFlutter2
flutter pub get
```

### 2. 运行应用

**Android:**
```bash
flutter run
```

**iOS:**
```bash
flutter run -d ios
```

### 3. 构建发布版本

**Android APK:**
```bash
flutter build apk --release
```

**iOS IPA:**
```bash
flutter build ios --release
```

## 配置说明

### AI API配置
在 `lib/services/ai_service.dart` 中配置DeepSeek API密钥：
```dart
static const String apiKey = 'YOUR_DEEPSEEK_API_KEY';
```

## 核心功能实现

### 状态管理
使用Provider进行状态管理：
- `DataProvider`: 管理数据加载、收藏、最近使用等
- `VIPProvider`: 管理会员状态和订阅
- `WordPackProvider`: 管理字数包和字数消耗

### 数据持久化
- 使用SharedPreferences存储用户偏好设置
- 支持收藏、最近使用、搜索历史等数据持久化

### 字数消耗规则
- 计算规则：输入字数 + 输出字数
- 优先消耗VIP每日赠送字数
- 其次消耗购买的字数包
- 字数包90天有效期

### 缓存管理
- 计算缓存大小（最近使用 + 搜索历史）
- 清理缓存不删除收藏内容
- 清理后自动刷新相关页面

## 与原生版本的一致性

### UI一致性
- ✅ 底部Tab导航结构
- ✅ 页面布局和交互
- ✅ 颜色主题
- ✅ Material Design风格

### 功能一致性
- ✅ 热门模板
- ✅ 写作分类
- ✅ 文档管理
- ✅ 收藏和最近使用
- ✅ 搜索历史
- ✅ 缓存管理
- ✅ 字数包系统
- ✅ 会员系统

### 数据一致性
- ✅ 字数消耗规则（输入+输出）
- ✅ VIP每日赠送50万字
- ✅ 字数包90天有效期
- ✅ 缓存清理不删除收藏

## 跨平台特性

### Android支持
- Material Design组件
- 原生Android性能
- 支持Android 5.0+

### iOS支持
- Cupertino风格组件
- 原生iOS性能
- 支持iOS 11.0+

### 代码复用
- 100% Dart代码
- 单一代码库
- 平台特定适配

## 性能优化

- 使用`const`构造函数减少重建
- 懒加载数据
- 图片缓存
- 列表性能优化

## 待完善功能

1. **详情页面**
   - 写作详情页面
   - 文档详情页面
   - 搜索页面
   - 会员页面
   - 字数包页面

2. **AI集成**
   - 接入真实的DeepSeek API
   - 实现流式文本生成
   - 完整的AI功能

3. **支付集成**
   - Google Play内购（Android）
   - App Store内购（iOS）
   - 字数包购买流程

4. **数据同步**
   - iCloud同步（iOS）
   - Google Drive同步（Android）

## 许可证

Copyright © 2025 AI创作喵. All rights reserved.

## 联系方式

如有问题或建议，请联系开发团队。

