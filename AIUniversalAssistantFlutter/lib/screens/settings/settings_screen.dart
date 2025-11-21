import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../models/subscription_model.dart';
import '../../services/data_service.dart';
import '../../services/vip_service.dart';
import '../../services/iap_service.dart';
import '../../services/word_pack_service.dart';
import '../../utils/app_localizations_helper.dart';
import '../../l10n/app_localizations.dart';
import '../membership/membership_screen.dart';
import '../word_pack/word_pack_screen.dart';
import '../writing_records/writing_records_screen.dart';
import '../about/about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DataService _dataService = DataService();
  final VIPService _vipService = VIPService();
  final IAPService _iapService = IAPService();
  List<Map<String, dynamic>> _settingsData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoading) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    await _buildSettingsData();
  }

  Future<void> _buildSettingsData() async {
    if (!mounted) return;
    
    final isVIP = await _vipService.isVIP();
    final memberSubtitle = await _getMembershipStatusText();
    final cacheSize = await _getCacheSizeText();
    final rewardProgress = await _getRewardProgressText();

    if (!mounted) return;

    setState(() {
      _settingsData = [
        {
          'title': _translate('member_privileges'),
          'icon': Icons.star,
          'color': const Color(0xFFFFD700),
          'action': 'memberPrivileges',
          'subtitle': memberSubtitle,
        },
        {
          'title': _translate('creation_records'),
          'icon': Icons.description,
          'color': const Color(0xFF3B82F6),
          'action': 'creationRecords',
        },
        {
          'title': _translate('writing_word_packs'),
          'icon': Icons.inventory_2,
          'color': const Color(0xFF10B981),
          'action': 'wordPacks',
          'requiresVIP': true,
        },
        {
          'title': _translate('clear_cache'),
          'icon': Icons.delete_outline,
          'color': const Color(0xFFF97316),
          'action': 'clearCache',
          'subtitle': cacheSize,
        },
        {
          'title': _translate('rate_app'),
          'icon': Icons.star_outline,
          'color': const Color(0xFFEF4444),
          'action': 'rateApp',
        },
        {
          'title': _translate('share_app'),
          'icon': Icons.share,
          'color': const Color(0xFF06B6D4),
          'action': 'shareApp',
        },
        {
          'title': _translate('watch_reward_title'),
          'icon': Icons.play_circle_outline,
          'color': const Color(0xFF22C55E),
          'action': 'watchReward',
          'requiresVIP': true,
          'subtitle': rewardProgress,
        },
        {
          'title': _translate('contact_us'),
          'icon': Icons.email,
          'color': const Color(0xFFF59E0B),
          'action': 'contactUs',
        },
        {
          'title': _translate('about_us'),
          'icon': Icons.info_outline,
          'color': const Color(0xFF8B5CF6),
          'action': 'aboutUs',
        },
      ];
      _isLoading = false;
    });
  }

  String _translate(String key, [List<dynamic>? args]) {
    final locale = Localizations.localeOf(context);
    final l10n = AppLocalizations(locale);
    return l10n.translate(key, args);
  }

  Future<String> _getMembershipStatusText() async {
    final isVIP = await _vipService.isVIP();
    if (!isVIP) {
      return _translate('not_vip_member');
    }

    final subscription = await _vipService.getSubscription();
    final expiryDate = subscription.expiryDate;
    
    if (subscription.type == SubscriptionType.lifetime) {
      return '${subscription.displayName} - ${_translate('lifetime')}';
    }
    
    if (expiryDate != null) {
      final formatter = DateFormat('yyyy-MM-dd');
      return '${subscription.displayName} - ${_translate('expires_on')} ${formatter.format(expiryDate)}';
    }
    
    return subscription.displayName;
  }

  Future<String> _getCacheSizeText() async {
    final size = await _dataService.calculateCacheSize();
    return _dataService.formatCacheSize(size);
  }

  Future<String> _getRewardProgressText() async {
    // 获取今日观看次数
    // 简化处理
    return _translate('watch_reward_progress', [0, 4]);
  }

  Future<void> _handleAction(String action) async {
    switch (action) {
      case 'memberPrivileges':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const MembershipScreen()),
        );
        break;
      case 'creationRecords':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const WritingRecordsScreen(isAllRecords: true),
          ),
        );
        break;
      case 'wordPacks':
        final isVIP = await _vipService.isVIP();
        if (!isVIP) {
          _showVIPDialog();
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const WordPackScreen()),
        );
        break;
      case 'clearCache':
        _showClearCacheDialog();
        break;
      case 'rateApp':
        _rateApp();
        break;
      case 'shareApp':
        _shareApp();
        break;
      case 'watchReward':
        final isVIP = await _vipService.isVIP();
        if (!isVIP) {
          _showVIPDialog();
          return;
        }
        // TODO: 实现激励视频
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('激励视频功能待实现')),
        );
        break;
      case 'contactUs':
        // TODO: 实现联系我们
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('联系我们功能待实现')),
        );
        break;
      case 'aboutUs':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
        break;
    }
  }

  void _showVIPDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_translate('vip_unlock_required')),
        content: Text(_translate('vip_general_locked_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MembershipScreen()),
              );
            },
            child: Text(_translate('unlock_vip_features')),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearCacheDialog() async {
    final cacheSize = await _dataService.calculateCacheSize();
    if (cacheSize == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_translate('cache_already_empty'))),
        );
      }
      return;
    }

    final sizeText = _dataService.formatCacheSize(cacheSize);
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_translate('clear_cache')),
        content: Text(_translate('clear_cache_message', [sizeText])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _dataService.clearCache();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_translate('cache_cleared_success'))),
                );
                _loadData();
              }
            },
            child: Text(_translate('confirm')),
          ),
        ],
      ),
    );
  }

  Future<void> _rateApp() async {
    // TODO: 实现评分功能
    final url = Uri.parse('https://apps.apple.com/app/idYOUR_APP_ID');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_translate('cannot_open_app_store'))),
        );
      }
    }
  }

  Future<void> _shareApp() async {
    await Share.share(_translate('share_app_description'));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_translate('tab_settings')),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _settingsData.length,
        itemBuilder: (context, index) {
          final item = _settingsData[index];
          final requiresVIP = item['requiresVIP'] == true;
          
          return FutureBuilder<bool>(
            future: _vipService.isVIP(),
            builder: (context, snapshot) {
              final isVIP = snapshot.data ?? false;
              final enabled = !requiresVIP || isVIP;
              
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                  ),
                ),
                title: Text(item['title'] as String),
                subtitle: item['subtitle'] != null
                    ? Text(item['subtitle'] as String)
                    : null,
                trailing: requiresVIP && !isVIP
                    ? const Icon(Icons.lock, size: 16)
                    : const Icon(Icons.chevron_right),
                enabled: enabled,
                onTap: enabled ? () => _handleAction(item['action'] as String) : null,
              );
            },
          );
        },
      ),
    );
  }
}
