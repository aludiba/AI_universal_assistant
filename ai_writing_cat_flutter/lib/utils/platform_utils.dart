import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

/// 平台工具类 - 检测当前运行平台
class PlatformUtils {
  static bool? _isHarmonyOSCache;
  
  /// 是否为鸿蒙平台
  /// OpenHarmony TPC Flutter SDK 在运行时可以通过检查默认目标平台来判断
  /// 或者通过环境变量检查
  static bool get isHarmonyOS {
    if (_isHarmonyOSCache != null) return _isHarmonyOSCache!;
    if (kIsWeb) {
      _isHarmonyOSCache = false;
      return false;
    }
    
    try {
      // 方法1: 检查环境变量（开发环境）
      final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
      if (flutterRoot.contains('ohos') || 
          flutterRoot.contains('openharmony') ||
          flutterRoot.contains('harmony')) {
        _isHarmonyOSCache = true;
        return true;
      }
      
      // 方法2: 检查默认目标平台（运行时）
      // OpenHarmony TPC Flutter SDK 可能设置特定的默认目标平台
      // 这里我们使用一个更保守的方法：通过尝试导入平台特定插件来判断
      // 但更实用的方法是：在编译时通过检查默认目标平台
      
      // 方法3: 通过检查是否支持特定插件来判断（运行时检测）
      // 如果 in_app_purchase 不可用，可能是在鸿蒙平台
      // 但这个方法不够可靠，因为插件可能在其他平台也不可用
      
      // 临时方案：如果是在 Android 平台，且检测到是 OpenHarmony SDK，则认为是鸿蒙
      // 由于 OpenHarmony TPC Flutter SDK 可能使用 Android 作为基础平台
      // 我们需要其他方式来判断
      
      // 最保守的方法：默认返回 false，让用户通过编译时条件或环境变量明确指定
      // 但为了兼容性，我们可以尝试通过其他方式检测
      
      _isHarmonyOSCache = false;
      return false;
    } catch (e) {
      _isHarmonyOSCache = false;
      return false;
    }
  }
  
  /// 强制设置为鸿蒙平台（用于测试或明确指定）
  static void setHarmonyOS(bool value) {
    _isHarmonyOSCache = value;
  }
  
  /// 是否为 iOS 平台
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  
  /// 是否为 Android 平台（不包括鸿蒙）
  static bool get isAndroid => !kIsWeb && Platform.isAndroid && !isHarmonyOS;
  
  /// 是否为 Web 平台
  static bool get isWeb => kIsWeb;
  
  /// 是否支持内购（iOS 和 Android 支持，鸿蒙不支持）
  static bool get supportsIAP => isIOS || isAndroid;
  
  /// 是否支持 SQLite（鸿蒙可能不支持 sqflite）
  static bool get supportsSQLite => !isHarmonyOS;
}
