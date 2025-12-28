import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/app_provider.dart';
import '../../constants/app_styles.dart';
import 'membership_screen.dart';
import 'word_pack_screen.dart';

/// 设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // VIP信息卡片
          _buildVIPCard(context),
          
          const SizedBox(height: AppStyles.paddingMedium),
          
          // 功能列表
          _buildSection(
            context,
            title: '会员与字数',
            children: [
              _buildListTile(
                context,
                icon: Icons.card_membership,
                title: '会员特权',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MembershipScreen(),
                    ),
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.auto_awesome,
                title: '创作字数包',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WordPackScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          
          _buildSection(
            context,
            title: '应用设置',
            children: [
              _buildThemeTile(context),
              _buildLanguageTile(context),
              _buildListTile(
                context,
                icon: Icons.cleaning_services,
                title: '清理缓存',
                onTap: () => _clearCache(context),
              ),
            ],
          ),
          
          _buildSection(
            context,
            title: '关于',
            children: [
              _buildListTile(
                context,
                icon: Icons.star_outline,
                title: '前往评分',
                onTap: () {
                  // TODO: 打开应用商店评分
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('感谢您的支持！')),
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.share,
                title: '分享应用',
                onTap: () {
                  // TODO: 分享应用
                },
              ),
              _buildListTile(
                context,
                icon: Icons.contact_support,
                title: '联系我们',
                onTap: () {
                  _showContactDialog(context);
                },
              ),
              _buildListTile(
                context,
                icon: Icons.info_outline,
                title: '关于我们',
                onTap: () => _showAboutDialog(context),
              ),
              _buildListTile(
                context,
                icon: Icons.article,
                title: '用户协议',
                onTap: () {
                  // TODO: 显示用户协议
                },
              ),
              _buildListTile(
                context,
                icon: Icons.privacy_tip,
                title: '隐私政策',
                onTap: () {
                  // TODO: 显示隐私政策
                },
              ),
            ],
          ),
          
          // 版本信息
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '1.0.0';
              return Padding(
                padding: const EdgeInsets.all(AppStyles.paddingLarge),
                child: Center(
                  child: Text(
                    'v$version',
                    style: AppStyles.bodySmall.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildVIPCard(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final isVip = provider.isVip;
        final subscription = provider.subscription;
        
        return Container(
          margin: const EdgeInsets.all(AppStyles.paddingMedium),
          padding: const EdgeInsets.all(AppStyles.paddingLarge),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isVip
                  ? [Colors.amber[700]!, Colors.amber[500]!]
                  : [Colors.grey[400]!, Colors.grey[300]!],
            ),
            borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
          ),
          child: Row(
            children: [
              Icon(
                isVip ? Icons.workspace_premium : Icons.person_outline,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(width: AppStyles.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVip ? 'VIP会员' : '普通用户',
                      style: AppStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isVip && subscription != null
                          ? subscription.isLifetime
                              ? '永久有效'
                              : '剩余${subscription.remainingDays}天'
                          : '开通会员享受更多特权',
                      style: AppStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isVip)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MembershipScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.amber[700],
                  ),
                  child: const Text('开通'),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppStyles.paddingLarge,
            AppStyles.paddingMedium,
            AppStyles.paddingLarge,
            AppStyles.paddingSmall,
          ),
          child: Text(
            title,
            style: AppStyles.bodyMedium.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
  
  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing,
              style: AppStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
      onTap: onTap,
    );
  }
  
  Widget _buildThemeTile(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        String themeName = '跟随系统';
        switch (provider.themeMode) {
          case ThemeMode.light:
            themeName = '浅色';
            break;
          case ThemeMode.dark:
            themeName = '深色';
            break;
          default:
            themeName = '跟随系统';
        }
        
        return ListTile(
          leading: const Icon(Icons.brightness_6),
          title: const Text('主题模式'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                themeName,
                style: AppStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
          onTap: () => _showThemeDialog(context, provider),
        );
      },
    );
  }
  
  Widget _buildLanguageTile(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        String languageName = '简体中文';
        if (provider.locale?.languageCode == 'en') {
          languageName = 'English';
        } else if (provider.locale?.languageCode == 'ja') {
          languageName = '日本語';
        }
        
        return ListTile(
          leading: const Icon(Icons.language),
          title: const Text('语言'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                languageName,
                style: AppStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
          onTap: () => _showLanguageDialog(context, provider),
        );
      },
    );
  }
  
  void _showThemeDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: provider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  provider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('浅色'),
              value: ThemeMode.light,
              groupValue: provider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  provider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('深色'),
              value: ThemeMode.dark,
              groupValue: provider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  provider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showLanguageDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择语言'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('简体中文'),
              onTap: () {
                provider.setLocale(const Locale('zh'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              onTap: () {
                provider.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('日本語'),
              onTap: () {
                provider.setLocale(const Locale('ja'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理缓存'),
        content: const Text('确定要清理缓存吗？将清除搜索历史和临时数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 清理缓存
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('缓存清理成功')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('联系我们'),
        content: const Text('如有任何问题或建议，请发送邮件至：\nsupport@aiwritingcat.com'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    
    if (context.mounted) {
      showAboutDialog(
        context: context,
        applicationName: 'AI创作喵',
        applicationVersion: packageInfo.version,
        applicationIcon: const FlutterLogo(size: 48),
        children: [
          const Text('AI创作喵是一款基于AI技术的智能写作助手。'),
          const SizedBox(height: 8),
          const Text('© 2025 AI创作喵 保留所有权利'),
        ],
      );
    }
  }
}

