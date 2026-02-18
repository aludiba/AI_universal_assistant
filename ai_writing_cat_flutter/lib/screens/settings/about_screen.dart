import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../router/app_router.dart';

/// 关于我们页面（模仿 iOS AIUAAboutViewController）
/// Logo 暂用占位图标，用户协议和隐私政策复用 iOS 的 HTML
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutUs),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo 占位（与 iOS 一致：100x100 圆角，无图标时蓝色底+文字）
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.app_version(_version),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 32),
            _buildCard(
              context,
              title: l10n.app_intro_title,
              content: l10n.app_intro_content,
            ),
            const SizedBox(height: 16),
            _buildCard(
              context,
              title: l10n.main_features_title,
              content: l10n.main_features_content,
            ),
            const SizedBox(height: 24),
            _buildLinkButton(
              context,
              title: l10n.userAgreement,
              onTap: () => context.pushNamed(
                AppRoute.policyWebView.name,
                extra: PolicyWebViewArgs(
                  title: l10n.userAgreement,
                  assetPath: 'assets/html/用户协议.html',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildLinkButton(
              context,
              title: l10n.privacyPolicy,
              onTap: () => context.pushNamed(
                AppRoute.policyWebView.name,
                extra: PolicyWebViewArgs(
                  title: l10n.privacyPolicy,
                  assetPath: 'assets/html/隐私政策.html',
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n.copyright_text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.getTextSecondary(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 用于路由传递 WebView 参数
class PolicyWebViewArgs {
  const PolicyWebViewArgs({
    required this.title,
    required this.assetPath,
  });

  final String title;
  final String assetPath;
}
