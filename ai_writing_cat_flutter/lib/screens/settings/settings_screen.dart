import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/hot_provider.dart';
import '../../router/app_router.dart';
import '../../services/data_manager.dart';

enum _SettingsAction {
  memberPrivileges,
  creationRecords,
  wordPacks,
  clearCache,
  rateApp,
  shareApp,
  contactUs,
  aboutUs,
}

class _SettingsItem {
  const _SettingsItem({
    required this.title,
    required this.icon,
    required this.iconBgColor,
    required this.action,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final Color iconBgColor;
  final _SettingsAction action;
  final String? subtitle;
}

/// 设置页面（对齐 iOS：单列表卡片样式、8 个功能项）
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DataManager _dataManager = DataManager();

  String _cacheSizeText = '...';
  bool _cacheLoading = false;
  bool _isClearingCache = false;

  // 监听数据变化时自动刷新缓存大小
  DocumentProvider? _docProvider;
  HotProvider? _hotProvider;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 绑定 DocumentProvider 监听
    final newDocProvider = Provider.of<DocumentProvider>(context, listen: false);
    if (_docProvider != newDocProvider) {
      _docProvider?.removeListener(_loadCacheSize);
      _docProvider = newDocProvider;
      _docProvider!.addListener(_loadCacheSize);
    }
    // 绑定 HotProvider 监听
    final newHotProvider = Provider.of<HotProvider>(context, listen: false);
    if (_hotProvider != newHotProvider) {
      _hotProvider?.removeListener(_loadCacheSize);
      _hotProvider = newHotProvider;
      _hotProvider!.addListener(_loadCacheSize);
    }
  }

  @override
  void dispose() {
    _docProvider?.removeListener(_loadCacheSize);
    _hotProvider?.removeListener(_loadCacheSize);
    super.dispose();
  }

  Future<void> _loadCacheSize() async {
    if (_cacheLoading) return;
    setState(() => _cacheLoading = true);
    try {
      final cacheSize = await _dataManager.calculateCacheSize();
      final text = _dataManager.formatCacheSize(cacheSize);
      if (mounted) setState(() => _cacheSizeText = text);
    } catch (_) {
      if (mounted) setState(() => _cacheSizeText = '--');
    } finally {
      if (mounted) setState(() => _cacheLoading = false);
    }
  }

  String _membershipStatusText(AppProvider appProvider, AppLocalizations l10n) {
    final sub = appProvider.subscription;
    if (!appProvider.isVip) return l10n.normalUser;
    if (sub == null) return l10n.vipMember;
    if (sub.isLifetime) return '${l10n.vipMember} - ${l10n.permanentValid}';
    if (sub.expiryDate != null) {
      final dateText = DateFormat('yyyy-MM-dd', l10n.localeName).format(sub.expiryDate!);
      return '${l10n.vipMember} - $dateText';
    }
    return l10n.vipMember;
  }

  List<_SettingsItem> _buildItems(AppProvider appProvider, AppLocalizations l10n) {
    return [
      _SettingsItem(
        title: l10n.memberPrivileges,
        icon: Icons.workspace_premium,
        iconBgColor: const Color(0xFFFFD700),
        action: _SettingsAction.memberPrivileges,
        subtitle: _membershipStatusText(appProvider, l10n),
      ),
      _SettingsItem(
        title: l10n.writingRecords,
        icon: Icons.description,
        iconBgColor: const Color(0xFF3B82F6),
        action: _SettingsAction.creationRecords,
      ),
      _SettingsItem(
        title: l10n.writingWordPacks,
        icon: Icons.inventory_2,
        iconBgColor: const Color(0xFF10B981),
        action: _SettingsAction.wordPacks,
      ),
      _SettingsItem(
        title: l10n.clearCache,
        icon: Icons.delete,
        iconBgColor: const Color(0xFFF97316),
        action: _SettingsAction.clearCache,
        subtitle: _cacheSizeText,
      ),
      _SettingsItem(
        title: l10n.rateApp,
        icon: Icons.star,
        iconBgColor: const Color(0xFFEF4444),
        action: _SettingsAction.rateApp,
      ),
      _SettingsItem(
        title: l10n.shareApp,
        icon: Icons.ios_share,
        iconBgColor: const Color(0xFF06B6D4),
        action: _SettingsAction.shareApp,
      ),
      _SettingsItem(
        title: l10n.contactUs,
        icon: Icons.email,
        iconBgColor: const Color(0xFFF59E0B),
        action: _SettingsAction.contactUs,
      ),
      _SettingsItem(
        title: l10n.aboutUs,
        icon: Icons.info,
        iconBgColor: const Color(0xFF8B5CF6),
        action: _SettingsAction.aboutUs,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<AppProvider>();
    final items = _buildItems(provider, l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabSettings),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildSettingsCell(context, items[index]),
      ),
    );
  }

  Widget _buildSettingsCell(BuildContext context, _SettingsItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Material(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleAction(item.action),
          child: SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.iconBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: item.subtitle == null || item.subtitle!.isEmpty
                        ? Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.getTextPrimary(context),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.getTextPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.getTextSecondary(context),
                                ),
                              ),
                            ],
                          ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
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

  Future<void> _handleAction(_SettingsAction action) async {
    switch (action) {
      case _SettingsAction.memberPrivileges:
        context.pushNamed(AppRoute.membership.name);
        return;
      case _SettingsAction.creationRecords:
        context.pushNamed(AppRoute.writingRecords.name, extra: null);
        return;
      case _SettingsAction.wordPacks:
        context.pushNamed(AppRoute.wordPack.name);
        return;
      case _SettingsAction.clearCache:
        _showClearCacheDialog();
        return;
      case _SettingsAction.rateApp:
        await _rateApp();
        return;
      case _SettingsAction.shareApp:
        await _shareApp();
        return;
      case _SettingsAction.contactUs:
        _showContactDialog(context);
        return;
      case _SettingsAction.aboutUs:
        context.pushNamed(AppRoute.about.name);
        return;
    }
  }

  Future<void> _rateApp() async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.parse('https://apps.apple.com/app/id6755778624');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failure)),
      );
    }
  }

  Future<void> _shareApp() async {
    final l10n = AppLocalizations.of(context)!;
    final shareText = '${l10n.appName}\n\n${l10n.aboutDescription(l10n.appName)}\n\n'
        'https://apps.apple.com/app/id6755778624';
    await Share.share(shareText);
  }

  void _showClearCacheDialog() {
    if (_isClearingCache) return;
    final l10n = AppLocalizations.of(context)!;
    final message = '${l10n.clearCacheConfirm}\n\n$_cacheSizeText';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearCache),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _clearCache();
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    if (_isClearingCache) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isClearingCache = true);
    try {
      final result = await _dataManager.clearCache();
      if (!mounted) return;
      if (result['success'] == true) {
        // 刷新内存中的文档列表和最近使用列表
        await Future.wait([
          Provider.of<DocumentProvider>(context, listen: false).loadDocuments(),
          Provider.of<HotProvider>(context, listen: false).refreshRecentUsed(),
        ]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cacheCleared)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((result['errorMessage'] as String?) ?? l10n.failure)),
        );
      }
      await _loadCacheSize();
    } finally {
      if (mounted) setState(() => _isClearingCache = false);
    }
  }

  void _showContactDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.contactUs),
        content: Text(l10n.contactDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

}

