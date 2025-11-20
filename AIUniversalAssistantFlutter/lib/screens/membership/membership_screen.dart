import 'package:flutter/material.dart';
import '../../services/iap_service.dart';
import '../../services/vip_service.dart';
import '../../utils/app_localizations_helper.dart';
import '../../models/subscription_model.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('member_privileges')),
      ),
      body: const Center(
        child: Text('会员订阅页面 - 待完善'),
      ),
    );
  }
}

