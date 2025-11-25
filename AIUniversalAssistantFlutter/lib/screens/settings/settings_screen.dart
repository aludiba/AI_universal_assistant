import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/data_provider.dart';
import '../../providers/vip_provider.dart';
import '../../utils/extensions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  String _cacheSize = '0 KB';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final cacheSize = await dataProvider.calculateCacheSize();
    
    setState(() {
      _version = packageInfo.version;
      _cacheSize = cacheSize.formatFileSize();
    });
  }

  Future<void> _clearCache() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final cacheSize = await dataProvider.calculateCacheSize();
    
    if (cacheSize == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('当前没有缓存数据，无需清理')),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理缓存'),
        content: Text('将清除最近使用记录和搜索历史，共 $_cacheSize。收藏内容不会被清除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await dataProvider.clearCache();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('缓存清理成功')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // VIP状态卡片
          Consumer<VIPProvider>(
            builder: (context, vipProvider, child) {
              return Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vipProvider.isVIP
                            ? '${vipProvider.subscription.type.displayName}'
                            : '未开通会员',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: 跳转到会员页面
                          },
                          child: const Text('开通会员'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // 设置选项
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '通用',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  title: const Text('清理缓存'),
                  trailing: Text(
                    _cacheSize,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: _clearCache,
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('关于我们'),
                  trailing: Text(
                    _version,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    // TODO: 跳转到关于页面
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

