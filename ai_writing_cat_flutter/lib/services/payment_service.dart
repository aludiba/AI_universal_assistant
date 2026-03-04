import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alipay_kit/alipay_kit.dart';
import 'package:fluwx/fluwx.dart' as fluwx;
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/subscription_model.dart';
import '../models/word_pack_model.dart';
import 'data_manager.dart';

enum PayChannel { alipay, wechat }

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final DataManager _dataManager = DataManager();
  final fluwx.Fluwx _fluwx = fluwx.Fluwx();
  bool _inited = false;

  Uri get _billingBase => Uri.parse('${AppConfig.billingBaseUrl}${AppConfig.billingApiPath}');

  Future<void> init() async {
    if (_inited) return;
    if (Platform.isAndroid && AppConfig.wechatAppId.isNotEmpty) {
      await _fluwx.registerApi(
        appId: AppConfig.wechatAppId,
        doOnAndroid: true,
        doOnIOS: false,
      );
    }
    _inited = true;
  }

  Future<bool> purchaseProduct({
    required String sku,
    required PayChannel channel,
  }) async {
    if (!Platform.isAndroid) {
      throw Exception('当前仅支持 Android 微信/支付宝支付');
    }
    await init();
    final userId = await _dataManager.getOrCreateClientUserId();
    final order = await _createOrder(
      userId: userId,
      sku: sku,
      channel: channel,
    );

    if (channel == PayChannel.alipay) {
      await _payByAlipay(order['payPayload'] as Map<String, dynamic>);
    } else {
      await _payByWechat(order['payPayload'] as Map<String, dynamic>);
    }

    final paid = await _waitOrderPaid(
      userId: userId,
      orderId: order['orderId'] as String,
    );
    if (!paid) return false;
    await syncBillingState();
    return true;
  }

  Future<void> syncBillingState() async {
    final userId = await _dataManager.getOrCreateClientUserId();
    final uri = _billingBase.replace(path: '${_billingBase.path}/state/$userId');
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode != 200) {
      throw Exception('同步权益失败: HTTP ${response.statusCode}');
    }
    final payload = _decodeJson(response.body) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>;
    final membership = data['membership'] as Map<String, dynamic>?;
    final wallet = data['wallet'] as Map<String, dynamic>? ?? <String, dynamic>{};

    if (membership == null) {
      await _dataManager.clearSubscription();
    } else {
      await _dataManager.saveSubscription(_mapSubscription(membership));
    }

    await _dataManager.saveWordPackStats(WordPackStats(
      vipGiftWords: (wallet['vipGiftWords'] as num?)?.toInt() ?? 0,
      purchasedWords: (wallet['purchasedWords'] as num?)?.toInt() ?? 0,
      rewardWords: (wallet['rewardWords'] as num?)?.toInt() ?? 0,
      consumedWords: (wallet['consumedWords'] as num?)?.toInt() ?? 0,
    ));
  }

  Future<Map<String, dynamic>> _createOrder({
    required String userId,
    required String sku,
    required PayChannel channel,
  }) async {
    final uri = _billingBase.replace(path: '${_billingBase.path}/order');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: _encodeJson({
        'userId': userId,
        'sku': sku,
        'channel': channel.name,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('创建订单失败: HTTP ${response.statusCode} ${response.body}');
    }
    final payload = _decodeJson(response.body) as Map<String, dynamic>;
    if (payload['ok'] != true) {
      throw Exception('创建订单失败: ${payload['error'] ?? 'unknown'}');
    }
    return payload['data'] as Map<String, dynamic>;
  }

  Future<void> _payByAlipay(Map<String, dynamic> payload) async {
    final orderString = '${payload['orderString'] ?? ''}';
    if (orderString.isEmpty) {
      throw Exception('支付宝下单参数为空');
    }
    final future = AlipayKitPlatform.instance.payResp().first.timeout(
      const Duration(minutes: 2),
      onTimeout: () => throw Exception('支付宝支付结果超时'),
    );
    await AlipayKitPlatform.instance.pay(orderInfo: orderString);
    final resp = await future;
    if (!resp.isSuccessful) {
      throw Exception('支付宝支付失败: ${resp.resultStatus ?? -1}');
    }
  }

  Future<void> _payByWechat(Map<String, dynamic> payload) async {
    if (AppConfig.wechatAppId.isEmpty) {
      throw Exception('请先在 AppConfig.wechatAppId 配置微信 AppID');
    }
    final completer = Completer<fluwx.WeChatPaymentResponse>();
    final cancelable = _fluwx.addSubscriber((event) {
      if (event is fluwx.WeChatPaymentResponse && !completer.isCompleted) {
        completer.complete(event);
      }
    });

    try {
      final started = await _fluwx.pay(
        which: fluwx.Payment(
          appId: '${payload['appId'] ?? ''}',
          partnerId: '${payload['partnerId'] ?? ''}',
          prepayId: '${payload['prepayId'] ?? ''}',
          packageValue: '${payload['packageValue'] ?? ''}',
          nonceStr: '${payload['nonceStr'] ?? ''}',
          timestamp: (payload['timestamp'] as num?)?.toInt() ?? 0,
          sign: '${payload['sign'] ?? ''}',
          signType: '${payload['signType'] ?? 'RSA'}',
        ),
      );
      if (!started) {
        throw Exception('微信支付拉起失败');
      }
      final resp = await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw Exception('微信支付结果超时'),
      );
      if (!resp.isSuccessful) {
        throw Exception('微信支付失败: ${resp.errCode ?? -1} ${resp.errStr ?? ''}');
      }
    } finally {
      cancelable.cancel();
    }
  }

  Future<bool> _waitOrderPaid({
    required String userId,
    required String orderId,
  }) async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      final status = await _queryOrderStatus(userId: userId, orderId: orderId);
      if (status == 'PAID') return true;
      if (status == 'FAILED' || status == 'CLOSED' || status == 'EXPIRED') return false;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return false;
  }

  Future<String> _queryOrderStatus({
    required String userId,
    required String orderId,
  }) async {
    final uri = _billingBase.replace(
      path: '${_billingBase.path}/order/$orderId',
      queryParameters: {'userId': userId},
    );
    final response = await http.get(uri, headers: _headers());
    if (response.statusCode != 200) return 'UNKNOWN';
    final payload = _decodeJson(response.body) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>?;
    return '${data?['status'] ?? 'UNKNOWN'}';
  }

  SubscriptionModel _mapSubscription(Map<String, dynamic> m) {
    final productId = '${m['productId'] ?? ''}';
    return SubscriptionModel(
      productId: productId,
      type: _mapSubscriptionType(productId),
      purchaseDate: m['purchaseDate'] != null ? DateTime.tryParse('${m['purchaseDate']}') : null,
      expiryDate: m['expiryDate'] != null ? DateTime.tryParse('${m['expiryDate']}') : null,
      isActive: m['isActive'] == true,
      isLifetime: m['isLifetime'] == true,
    );
  }

  SubscriptionType _mapSubscriptionType(String productId) {
    if (productId.contains('weekly')) return SubscriptionType.weekly;
    if (productId.contains('monthly')) return SubscriptionType.monthly;
    if (productId.contains('yearly')) return SubscriptionType.yearly;
    if (productId.contains('lifetime')) return SubscriptionType.lifetime;
    return SubscriptionType.none;
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (AppConfig.billingAppToken.isNotEmpty) {
      headers['x-aiua-app-token'] = AppConfig.billingAppToken;
    }
    return headers;
  }

  String _encodeJson(Map<String, dynamic> value) {
    return jsonEncode(value);
  }

  dynamic _decodeJson(String body) {
    return body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
  }
}
