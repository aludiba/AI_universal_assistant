# Android Studio 修改 Flutter/Dart SDK 路径指南

## 问题说明
当前 IDE 使用的是鸿蒙版 Flutter (Dart 2.19.6)，需要切换到标准 Flutter (Dart 3.10.0)。

## 修改方法

### 方法一：通过 Android Studio 设置界面（推荐）

#### 步骤 1：打开设置
- **macOS**: `Android Studio` > `Preferences` (或按 `Cmd + ,`)
- **Windows/Linux**: `File` > `Settings` (或按 `Ctrl + Alt + S`)

#### 步骤 2：配置 Flutter SDK 路径
1. 在左侧导航栏，展开 `Languages & Frameworks`
2. 选择 `Flutter`
3. 在右侧的 `Flutter SDK path` 字段中，点击文件夹图标或直接输入路径：
   ```
   /Users/apple/flutter
   ```
4. 点击 `Apply` 应用更改

#### 步骤 3：配置 Dart SDK 路径（可选，通常会自动检测）
1. 在左侧导航栏，展开 `Languages & Frameworks`
2. 选择 `Dart`
3. 在右侧的 `Dart SDK path` 字段中，输入或浏览选择：
   ```
   /Users/apple/flutter/bin/cache/dart-sdk
   ```
4. 点击 `Apply` 和 `OK` 保存

### 方法二：通过项目级配置

#### 在项目设置中指定 Flutter SDK
1. 打开项目后，点击 `File` > `Project Structure` (macOS: `Cmd + ;`)
2. 在左侧选择 `Project`
3. 在 `SDK` 下拉菜单中选择或添加 Flutter SDK
4. 点击 `Apply` 和 `OK`

### 方法三：修改环境变量（全局配置）

#### macOS (zsh)
编辑 `~/.zshrc` 文件：
```bash
# 注释掉或删除鸿蒙Flutter的PATH
# export PATH=/Users/apple/Desktop/openharmony-sig/bin:$PATH

# 添加标准Flutter到PATH（确保在前面）
export PATH="$HOME/flutter/bin:$PATH"

# 可选：取消FLUTTER_GIT_URL设置，让Flutter使用官方源
unset FLUTTER_GIT_URL
```

然后执行：
```bash
source ~/.zshrc
```

#### 验证配置
在终端中运行：
```bash
flutter --version
dart --version
```

应该显示：
- Flutter 3.38.2 (或更新版本)
- Dart 3.10.0 (或更新版本)

### 方法四：在 Android Studio 中直接指定

#### 通过 Terminal 设置
1. 在 Android Studio 中打开 Terminal
2. 运行以下命令设置当前会话的 PATH：
   ```bash
   export PATH="$HOME/flutter/bin:$PATH"
   unset FLUTTER_GIT_URL
   ```
3. 验证：
   ```bash
   flutter --version
   ```

## 验证配置是否生效

### 1. 检查 Flutter 版本
在 Android Studio 的 Terminal 中运行：
```bash
flutter --version
```
应该显示标准 Flutter 版本（不是 ohos 版本）

### 2. 检查 Dart 版本
```bash
dart --version
```
应该显示 Dart 3.x.x

### 3. 在项目中运行 pub get
```bash
cd AIUniversalAssistantFlutter
flutter pub get
```
应该能成功下载依赖，不再报 SDK 版本错误

## 常见问题

### Q: 修改后 IDE 仍然使用旧路径？
A: 
1. 重启 Android Studio
2. 检查 `File` > `Invalidate Caches / Restart` > `Invalidate and Restart`
3. 确认环境变量已正确设置

### Q: 如何同时保留两个 Flutter 版本？
A: 
1. 保持环境变量指向标准 Flutter
2. 需要鸿蒙 Flutter 时，在终端中临时设置：
   ```bash
   export PATH="/Users/apple/Desktop/openharmony-sig/bin:$PATH"
   export FLUTTER_GIT_URL=https://gitee.com/openharmony-sig/flutter_flutter.git
   ```

### Q: pubspec.yaml 需要修改吗？
A: 
- 如果使用标准 Flutter (Dart 3.10+)，可以保持 `sdk: '>=3.0.0 <4.0.0'`
- 如果使用鸿蒙 Flutter (Dart 2.19.6)，需要改为 `sdk: '>=2.19.0 <4.0.0'` 并降级依赖版本

## 推荐配置

**建议使用标准 Flutter (Dart 3.10.0)**，因为：
1. 支持最新的 Dart 语言特性
2. 依赖库版本更新，功能更完善
3. 社区支持更好
4. 与主流 Flutter 项目兼容

## 快速切换脚本

创建 `~/switch_flutter.sh`：
```bash
#!/bin/bash
if [ "$1" == "ohos" ]; then
    export PATH="/Users/apple/Desktop/openharmony-sig/bin:$PATH"
    export FLUTTER_GIT_URL=https://gitee.com/openharmony-sig/flutter_flutter.git
    echo "切换到鸿蒙 Flutter"
else
    export PATH="$HOME/flutter/bin:$PATH"
    unset FLUTTER_GIT_URL
    echo "切换到标准 Flutter"
fi
flutter --version
```

使用方法：
```bash
chmod +x ~/switch_flutter.sh
source ~/switch_flutter.sh        # 切换到标准Flutter
source ~/switch_flutter.sh ohos   # 切换到鸿蒙Flutter
```

