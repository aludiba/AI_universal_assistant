import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/app_provider.dart';
import '../../constants/app_styles.dart';
import '../../l10n/app_localizations.dart';
import 'membership_screen.dart';
import 'word_pack_screen.dart';

/// 设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabSettings),
      ),
      body: ListView(
        children: [
          // VIP信息卡片
          _buildVIPCard(context),
          
          const SizedBox(height: AppStyles.paddingMedium),
          
          // 功能列表
          _buildSection(
            context,
            title: l10n.membershipAndWords,
            children: [
              _buildListTile(
                context,
                icon: Icons.card_membership,
                title: l10n.memberPrivileges,
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
                title: l10n.writingWordPacks,
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
            title: l10n.appSettings,
            children: [
              _buildThemeTile(context),
              _buildLanguageTile(context),
              _buildListTile(
                context,
                icon: Icons.cleaning_services,
                title: l10n.clearCache,
                onTap: () => _clearCache(context),
              ),
            ],
          ),
          
          _buildSection(
            context,
            title: l10n.aboutSection,
            children: [
              _buildListTile(
                context,
                icon: Icons.star_outline,
                title: l10n.rateApp,
                onTap: () {
                  // TODO: 打开应用商店评分
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.thanksForSupport)),
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.share,
                title: l10n.shareApp,
                onTap: () {
                  // TODO: 分享应用
                },
              ),
              _buildListTile(
                context,
                icon: Icons.contact_support,
                title: l10n.contactUs,
                onTap: () {
                  _showContactDialog(context);
                },
              ),
              _buildListTile(
                context,
                icon: Icons.info_outline,
                title: l10n.aboutUs,
                onTap: () => _showAboutDialog(context),
              ),
              _buildListTile(
                context,
                icon: Icons.article,
                title: l10n.userAgreement,
                onTap: () {
                  // TODO: 显示用户协议
                },
              ),
              _buildListTile(
                context,
                icon: Icons.privacy_tip,
                title: l10n.privacyPolicy,
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
        final l10n = AppLocalizations.of(context)!;
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
                      isVip ? l10n.vipMember : l10n.normalUser,
                      style: AppStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isVip && subscription != null
                          ? subscription.isLifetime
                              ? l10n.permanentValid
                              : l10n.remainingDays(subscription.remainingDays)
                          : l10n.vipBenefitsHint,
                      style: AppStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
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
                  child: Text(l10n.openMembership),
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
        final l10n = AppLocalizations.of(context)!;
        String themeName = l10n.themeSystem;
        switch (provider.themeMode) {
          case ThemeMode.light:
            themeName = l10n.themeLight;
            break;
          case ThemeMode.dark:
            themeName = l10n.themeDark;
            break;
          default:
            themeName = l10n.themeSystem;
        }
        
        return ListTile(
          leading: const Icon(Icons.brightness_6),
          title: Text(l10n.themeMode),
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
        final l10n = AppLocalizations.of(context)!;
        String languageName = l10n.simplifiedChinese;
        if (provider.locale?.languageCode == 'en') {
          languageName = l10n.english;
        } else if (provider.locale?.languageCode == 'ja') {
          languageName = l10n.japanese;
        }
        
        return ListTile(
          leading: const Icon(Icons.language),
          title: Text(l10n.language),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text(l10n.themeSystem),
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
              title: Text(l10n.themeLight),
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
              title: Text(l10n.themeDark),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.simplifiedChinese),
              onTap: () {
                provider.setLocale(const Locale('zh'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(l10n.english),
              onTap: () {
                provider.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(l10n.japanese),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearCache),
        content: Text(l10n.clearCacheConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              // TODO: 清理缓存
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.cacheCleared)),
              );
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
  
  void _showContactDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.contactUs),
        content: Text(l10n.contactDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      final year = DateTime.now().year.toString();
      showAboutDialog(
        context: context,
        applicationName: l10n.appName,
        applicationVersion: packageInfo.version,
        applicationIcon: const FlutterLogo(size: 48),
        children: [
          Text(l10n.aboutDescription(l10n.appName)),
          const SizedBox(height: 8),
          Text(l10n.copyright(year, l10n.appName)),
        ],
      );
    }
  }
}

