# AI创作喵 - Flutter版本

## 项目简介

这是将iOS原生项目（Objective-C）迁移到Flutter的跨平台版本，专注于移动端，支持iOS和Android双端运行。

AI创作喵是一款基于DeepSeek AI技术的智能写作助手应用，提供续写、改写、扩写、翻译等多种AI写作功能。

**注意**: 本项目仅保留移动端平台（iOS和Android），已移除Web、macOS、Linux、Windows平台支持。

## 主要功能

### 1. 热门模板
- 提供多种写作场景模板（社媒、校园、职场、生活、营销等）
- 模板收藏和最近使用记录
- 搜索功能，快速找到需要的模板

### 2. AI写作
- **自由创作**：根据主题和要求生成内容
- **续写**：基于现有内容继续写作
- **改写**：优化表达方式
- **扩写**：丰富内容细节
- **翻译**：多语言翻译（中文、英文、日文）

### 3. 文档管理
- 创建、编辑、删除文档
- 文档字数统计
- 按时间排序
- 支持复制和分享

### 4. 设置功能
- 会员订阅管理（周/月/年/永久）
- 字数包购买和管理
- 主题切换（浅色/深色/跟随系统）
- 多语言支持（中文/英文/日文）
- 清理缓存
- 关于和联系我们

## 技术栈

### 核心技术
- **Flutter 3.10+**: 跨平台UI框架
- **Dart**: 编程语言

### 状态管理
- **Provider**: 应用状态管理

### 网络请求
- **http**: HTTP请求
- **dio**: 高级HTTP客户端

### 本地存储
- **sqflite**: SQLite数据库
- **shared_preferences**: 键值对存储
- **path_provider**: 文件路径管理

### AI服务
- **DeepSeek API**: AI文本生成服务

### 内购支持
- **in_app_purchase**: 应用内购买

### UI组件
- **cached_network_image**: 图片缓存
- **flutter_slidable**: 滑动操作
- **pull_to_refresh**: 下拉刷新

### 工具类
- **intl**: 国际化
- **uuid**: UUID生成
- **package_info_plus**: 应用信息
- **url_launcher**: 打开链接
- **share_plus**: 分享功能

## 项目结构

```
lib/
├── config/               # 配置文件
│   └── app_config.dart   # 应用配置（API密钥、产品ID等）
├── constants/            # 常量定义
│   ├── app_colors.dart   # 颜色常量
│   └── app_styles.dart   # 样式常量
├── models/               # 数据模型
│   ├── document_model.dart         # 文档模型
│   ├── writing_record_model.dart   # 写作记录模型
│   ├── template_model.dart         # 模板模型
│   ├── word_pack_model.dart        # 字数包模型
│   └── subscription_model.dart     # 订阅模型
├── services/             # 服务层
│   ├── deepseek_service.dart   # DeepSeek AI服务
│   ├── database_service.dart   # 数据库服务
│   ├── storage_service.dart    # 本地存储服务
│   └── iap_service.dart        # 内购服务
├── providers/            # 状态管理
│   ├── app_provider.dart       # 应用全局状态
│   ├── document_provider.dart  # 文档状态
│   └── template_provider.dart  # 模板状态
├── screens/              # 页面
│   ├── home/             # 主页（TabBar）
│   ├── hot/              # 热门页面
│   ├── writer/           # 写作页面
│   ├── docs/             # 文档页面
│   └── settings/         # 设置页面
├── widgets/              # 通用组件
├── utils/                # 工具类
├── l10n/                 # 国际化文件
│   ├── app_zh.arb        # 中文
│   └── app_en.arb        # 英文
└── main.dart             # 入口文件
```

## 配置说明

### 1. DeepSeek API配置
在 `lib/config/app_config.dart` 中配置：
```dart
static const String deepseekApiKey = 'your-api-key';
```

### 2. IAP产品ID配置
根据App Store Connect中配置的产品ID修改：
```dart
// 订阅产品
static const String iapProductLifetime = 'com.xxx.xxx';
static const String iapProductYearly = 'com.xxx.xxx';
// ... 其他产品ID
```

### 3. iOS配置
- 修改 `ios/Runner/Info.plist` 添加必要的权限
- 配置Bundle ID和签名

### 4. Android配置
- 修改 `android/app/build.gradle` 配置包名和版本
- 添加必要的权限到 `android/app/src/main/AndroidManifest.xml`

## 运行项目

### 1. 安装依赖
```bash
flutter pub get
```

### 2. 运行iOS
```bash
flutter run -d ios
```

### 3. 运行Android
```bash
flutter run -d android
```

### 4. 构建发布版本
```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
# 或
flutter build appbundle --release
```

## 数据库结构

### documents表（文档）
- id: 文档ID
- title: 标题
- content: 内容
- createdAt: 创建时间
- updatedAt: 更新时间

### writing_records表（写作记录）
- id: 记录ID
- templateId: 模板ID
- templateTitle: 模板标题
- prompt: 提示词
- generatedContent: 生成的内容
- wordCount: 字数
- createdAt: 创建时间
- isCompleted: 是否完成

### templates表（模板）
- id: 模板ID
- title: 标题
- description: 描述
- category: 分类
- fields: 字段配置（JSON字符串）
- isFavorite: 是否收藏
- lastUsedAt: 最后使用时间

## 本地存储键值

使用SharedPreferences存储：
- `subscription`: 订阅信息
- `word_pack_stats`: 字数包统计
- `trial_count`: 试用次数
- `search_history`: 搜索历史
- `theme_mode`: 主题模式
- `language`: 语言设置

## 注意事项

1. **API密钥安全**: 生产环境中应使用后端服务管理API密钥
2. **内购测试**: iOS需要使用沙盒账号测试，Android需要加入测试轨道
3. **数据同步**: 当前版本未实现iCloud同步（原iOS版本有），可后续添加
4. **广告功能**: Flutter版本暂未集成广告SDK，需要时可添加admob_flutter等插件
5. **暗黑模式**: 已支持，会跟随系统设置或用户手动切换

## 与原iOS版本的差异

### 已实现的功能
✅ 热门模板展示和搜索
✅ AI写作（续写、改写、扩写、翻译）
✅ 文档管理
✅ 会员订阅系统
✅ 字数包管理
✅ 多语言支持
✅ 暗黑模式
✅ 本地数据库存储

### 未实现的功能
❌ 广告系统（开屏广告、激励视频）
❌ iCloud同步
❌ 越狱检测
❌ Keychain存储（使用SharedPreferences替代）

### 新增功能
✨ Android平台支持
✨ Material Design风格UI
✨ 更好的跨平台兼容性

## 后续优化建议

1. **性能优化**
   - 添加图片加载占位符
   - 优化列表渲染性能
   - 实现增量加载

2. **功能增强**
   - 添加AI写作流式输出
   - 实现文档导出为PDF/Word
   - 添加历史记录管理
   - 实现云端同步

3. **用户体验**
   - 添加引导页
   - 优化加载动画
   - 添加错误重试机制
   - 实现离线缓存

4. **安全性**
   - API密钥加密
   - 数据传输加密
   - 用户数据隐私保护

## 项目平台

- **支持平台**: 仅移动端
  - iOS 15.0+
  - Android 5.0+ (API Level 21+)
- **已移除平台**: Web、macOS、Linux、Windows

## 开发者信息

- 原iOS项目：Objective-C开发
- Flutter迁移：2025年完成
- 平台优化：专注移动端体验

## 许可证

Copyright © 2025 AI创作喵. All rights reserved.

