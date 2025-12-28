import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../config/app_config.dart';
import '../../constants/app_styles.dart';

/// 会员页面
class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('会员特权'),
        actions: [
          TextButton(
            onPressed: () => _restorePurchases(context),
            child: const Text('恢复购买'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppStyles.paddingMedium),
        children: [
          // 会员权益
          _buildBenefitsSection(),
          
          const SizedBox(height: AppStyles.paddingLarge),
          
          // 订阅选项
          _buildSubscriptionOptions(context),
          
          const SizedBox(height: AppStyles.paddingLarge),
          
          // 购买按钮
          _buildPurchaseButton(context),
          
          const SizedBox(height: AppStyles.paddingMedium),
          
          // 说明文字
          _buildNotice(),
        ],
      ),
    );
  }
  
  Widget _buildBenefitsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '会员权益',
              style: AppStyles.titleMedium,
            ),
            const SizedBox(height: AppStyles.paddingMedium),
            _buildBenefitItem(
              Icons.auto_awesome,
              '解锁全部模板',
              '访问所有写作模板和场景',
            ),
            _buildBenefitItem(
              Icons.text_fields,
              '订阅赠送50万字',
              '一次性赠送用于AI创作',
            ),
            _buildBenefitItem(
              Icons.edit,
              'AI辅助写作',
              '续写、改写、扩写、翻译',
            ),
            _buildBenefitItem(
              Icons.devices,
              '多端同步',
              '一次购买，多设备使用',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppStyles.paddingSmall),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: AppStyles.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: AppStyles.bodyMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubscriptionOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择订阅方案',
          style: AppStyles.titleMedium,
        ),
        const SizedBox(height: AppStyles.paddingMedium),
        _buildSubscriptionCard(
          context,
          title: '永久会员',
          description: '一次购买，永久使用',
          price: '¥198',
          productId: AppConfig.iapProductLifetime,
          isRecommended: true,
        ),
        _buildSubscriptionCard(
          context,
          title: '年度会员',
          description: '约0.5元/天',
          price: '¥168/年',
          productId: AppConfig.iapProductYearly,
        ),
        _buildSubscriptionCard(
          context,
          title: '月度会员',
          description: '短期创作首选',
          price: '¥28/月',
          productId: AppConfig.iapProductMonthly,
        ),
        _buildSubscriptionCard(
          context,
          title: '周度会员',
          description: '体验AI写作',
          price: '¥8/周',
          productId: AppConfig.iapProductWeekly,
        ),
      ],
    );
  }
  
  Widget _buildSubscriptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required String price,
    required String productId,
    bool isRecommended = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppStyles.paddingMedium),
      child: InkWell(
        onTap: () {
          // TODO: 选择该方案
        },
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
                      title,
                      style: AppStyles.titleMedium,
                    ),
                    Text(
                      description,
                      style: AppStyles.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: AppStyles.titleMedium.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPurchaseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _purchase(context),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('立即开通'),
      ),
    );
  }
  
  Widget _buildNotice() {
    return Text(
      '• 订阅后一次性赠送50万字\n'
      '• 自动续费，可随时取消\n'
      '• 购买前请阅读用户协议和自动续费服务协议',
      style: AppStyles.bodySmall.copyWith(
        color: Colors.grey[600],
      ),
    );
  }
  
  void _purchase(BuildContext context) {
    final appProvider = context.read<AppProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认购买'),
        content: const Text('确定要购买会员吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // TODO: 实现实际的购买逻辑
                await appProvider.purchaseProduct(AppConfig.iapProductLifetime);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('购买成功！')),
                  );
                  Navigator.pop(context);
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
  
  void _restorePurchases(BuildContext context) async {
    final appProvider = context.read<AppProvider>();
    
    try {
      await appProvider.restorePurchases();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('恢复成功')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败: $e')),
        );
      }
    }
  }
}

