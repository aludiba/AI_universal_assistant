# AI创作喵 - Android版

基于Kotlin开发的AI写作助手Android应用，与iOS版功能完全一致。

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

- **语言**: Kotlin
- **架构**: MVVM
- **数据库**: Room
- **网络**: Retrofit + OkHttp
- **异步**: Kotlin Coroutines
- **UI**: Material Design + ViewBinding
- **事件总线**: EventBus

## 项目结构

```
app/src/main/
├── java/com/aiwriting/assistant/
│   ├── AIWritingApplication.kt          # Application类
│   ├── data/
│   │   ├── model/                       # 数据模型
│   │   ├── local/                       # 本地数据库
│   │   └── repository/                  # 数据仓库层
│   ├── ui/
│   │   ├── splash/                      # 启动页
│   │   ├── main/                        # 主页面
│   │   ├── hot/                         # 热门页面
│   │   ├── writer/                      # 写作页面
│   │   ├── docs/                        # 文档页面
│   │   └── settings/                    # 设置页面
│   └── utils/                           # 工具类
├── res/                                 # 资源文件
└── assets/                              # 静态资源

```

## 开发环境

- Android Studio Hedgehog | 2023.1.1+
- Gradle 8.2+
- Kotlin 1.9.20+
- Min SDK: 24 (Android 7.0)
- Target SDK: 34 (Android 14)

## 构建说明

1. 克隆项目
```bash
git clone [repository_url]
cd AIUniversalAssistantAndroid
```

2. 打开Android Studio，导入项目

3. 同步Gradle依赖
```bash
./gradlew build
```

4. 运行应用
```bash
./gradlew installDebug
```

## 配置说明

### AI API配置
在 `AIService.kt` 中配置DeepSeek API密钥：
```kotlin
private const val API_KEY = "YOUR_DEEPSEEK_API_KEY"
```

### 广告配置（可选）
如需接入广告，请在相应位置配置广告SDK。

## 与iOS版本的一致性

本Android版本与iOS版本在以下方面保持一致：
- UI设计和交互逻辑
- 功能特性
- 数据结构
- 字数消耗规则（输入+输出）
- 缓存管理机制
- 会员和字数包系统

## 许可证

Copyright © 2025 AI创作喵. All rights reserved.

