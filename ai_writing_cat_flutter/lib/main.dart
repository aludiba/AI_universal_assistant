import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, FlutterError, FlutterErrorDetails;
import 'dart:ui' show PlatformDispatcher;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'providers/app_provider.dart';
import 'providers/document_provider.dart';
import 'providers/template_provider.dart';
import 'providers/hot_provider.dart';
import 'providers/writing_provider.dart';
import 'providers/hot_writing_provider.dart';
import 'providers/hot_search_provider.dart';
import 'router/app_router.dart';
import 'constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 全局错误处理（简化，避免 Stack Overflow）
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      try {
        debugPrint('=== Flutter Error ===');
        debugPrint('Exception: ${details.exception}');
        if (details.stack != null) {
          debugPrint('Stack: ${details.stack}');
        }
        debugPrint('===================');
      } catch (e) {
        // 如果打印错误信息本身出错，避免无限递归
        debugPrint('Error in error handler: $e');
      }
    }
    FlutterError.presentError(details);
  };
  
  // 处理异步错误
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('=== Platform Error ===');
    debugPrint('Error: $error');
    debugPrint('Stack: $stack');
    debugPrint('====================');
    return true;
  };
  
  debugPrint('🚀 应用开始启动...');
  
  try {
    // 初始化应用提供者
    debugPrint('📦 初始化 AppProvider...');
    final appProvider = AppProvider();
    await appProvider.init();
    debugPrint('✅ AppProvider 初始化完成');
    
    debugPrint('🎨 创建 Provider 树...');
    runApp(
      ProviderScope(
        child: legacy_provider.MultiProvider(
          providers: [
            legacy_provider.ChangeNotifierProvider.value(value: appProvider),
            legacy_provider.ChangeNotifierProvider(create: (_) => DocumentProvider()),
            legacy_provider.ChangeNotifierProvider(create: (_) => TemplateProvider()..init()),
            legacy_provider.ChangeNotifierProvider(create: (_) => HotProvider()..init(locale: appProvider.locale)),
            legacy_provider.ChangeNotifierProvider(create: (_) => WritingProvider()),
            legacy_provider.ChangeNotifierProvider(create: (_) => HotWritingProvider()),
            legacy_provider.ChangeNotifierProvider(create: (_) => HotSearchProvider()),
          ],
          child: const MyApp(),
        ),
      ),
    );
    debugPrint('✅ 应用启动完成');
  } catch (e, stackTrace) {
    debugPrint('❌ 应用启动失败: $e');
    debugPrint('Stack: $stackTrace');
    // 即使启动失败，也尝试显示一个简单的错误界面
    try {
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      '应用启动失败',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString().length > 100 
                        ? '${e.toString().substring(0, 100)}...' 
                        : e.toString(),
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } catch (errorError) {
      // 如果显示错误界面也失败，至少打印错误
      debugPrint('无法显示错误界面: $errorError');
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
  
  /// 构建浅色主题
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.cardBackground,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// 构建深色主题
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        surface: AppColors.cardBackgroundDark,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackgroundDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondaryBackgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
            ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return legacy_provider.Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        return MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
          debugShowCheckedModeBanner: false,

          // 主题配置
          theme: widget._buildLightTheme(),
          darkTheme: widget._buildDarkTheme(),
          themeMode: appProvider.themeMode,

          // 国际化配置
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: appProvider.locale,

          // 路由
          routerConfig: _router,
        );
      },
    );
  }
}
