import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../config/app_config.dart';
import '../../constants/app_styles.dart';

/// 字数包页面
class WordPackScreen extends StatelessWidget {
  const WordPackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创作字数包'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        children: [
          // 字数统计卡片
          _buildStatsCard(context),
          
          const SizedBox(height: AppStyles.paddingLarge),
          
          // 字数包列表
          _buildWordPacksList(context),
          
          const SizedBox(height: AppStyles.paddingLarge),
          
          // 购买须知
          _buildNoticeCard(),
        ],
      ),
    );
  }
  
  Widget _buildStatsCard(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final stats = provider.wordPackStats;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '字数统计',
                  style: AppStyles.titleMedium,
                ),
                const SizedBox(height: AppStyles.paddingMedium),
                _buildStatRow(
                  '订阅赠送',
                  _formatNumber(stats?.vipGiftWords ?? 0),
                  Colors.orange,
                ),
                _buildStatRow(
                  '已购买',
                  _formatNumber(stats?.purchasedWords ?? 0),
                  Colors.blue,
                ),
                _buildStatRow(
                  '奖励获得',
                  _formatNumber(stats?.rewardWords ?? 0),
                  Colors.green,
                ),
                const Divider(),
                _buildStatRow(
                  '可用总字数',
                  _formatNumber(stats?.remainingWords ?? 0),
                  Colors.red,
                  isTotal: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatRow(String label, String value, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '$value 字',
            style: AppStyles.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 20 : 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWordPacksList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '购买字数包',
          style: AppStyles.titleMedium,
        ),
        const SizedBox(height: AppStyles.paddingMedium),
        _buildWordPackCard(
          context,
          words: 500000,
          price: 6,
          productId: AppConfig.iapWordPack500k,
        ),
        _buildWordPackCard(
          context,
          words: 2000000,
          price: 18,
          productId: AppConfig.iapWordPack2m,
          isRecommended: true,
        ),
        _buildWordPackCard(
          context,
          words: 6000000,
          price: 45,
          productId: AppConfig.iapWordPack6m,
        ),
      ],
    );
  }
  
  Widget _buildWordPackCard(
    BuildContext context, {
    required int words,
    required int price,
    required String productId,
    bool isRecommended = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppStyles.paddingMedium),
      child: InkWell(
        onTap: () => _purchaseWordPack(context, productId, words, price),
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.paddingMedium),
          child: Row(
            children: [
              if (isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '推荐',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(width: AppStyles.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatNumber(words)} 字',
                      style: AppStyles.titleMedium,
                    ),
                    Text(
                      '有效期90天',
                      style: AppStyles.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _purchaseWordPack(context, productId, words, price),
                child: Text('¥$price'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNoticeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '购买须知',
              style: AppStyles.bodyLarge,
            ),
            const SizedBox(height: AppStyles.paddingSmall),
            Text(
              '• 字数包购买后90天内有效，逾期未使用将自动失效\n'
              '• 使用时将优先消耗会员订阅赠送字数，其次消耗购买字数包\n'
              '• 订阅会员后一次性赠送50万字\n'
              '• 字数统计规则：输入+输出字数，1个字符计为1字',
              style: AppStyles.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _purchaseWordPack(BuildContext context, String productId, int words, int price) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认购买'),
        content: Text('确定要购买 ${_formatNumber(words)} 字数包，需支付 ¥$price？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final appProvider = context.read<AppProvider>();
              
              try {
                await appProvider.purchaseProduct(productId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('购买成功！已获得 ${_formatNumber(words)} 字')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('购买失败: $e')),
                  );
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  String _formatNumber(int number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }
}

