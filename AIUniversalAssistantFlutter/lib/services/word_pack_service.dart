import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/word_pack_model.dart';
import 'vip_service.dart';

/// 字数包服务
class WordPackService extends ChangeNotifier {
  static final WordPackService _instance = WordPackService._internal();
  factory WordPackService() => _instance;
  WordPackService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _keyWordPacks = 'word_packs';
  static const String _keyVIPGift = 'vip_gift';
  static const String _keyConsumedWords = 'consumed_words';
  static const String _keyLastRefreshDate = 'last_refresh_date';

  /// 获取VIP赠送字数
  Future<int> getVIPGiftedWords() async {
    final vipService = VIPService();
    if (!await vipService.isVIP()) {
      return 0;
    }

    final lastRefreshDateStr = await _secureStorage.read(
      key: _keyLastRefreshDate,
    );
    final today = DateTime.now();
    final todayStr = _dateToString(today);

    // 如果不是今天，重置赠送字数
    if (lastRefreshDateStr != todayStr) {
      await _refreshDailyGift();
      return AppConfig.vipDailyGiftWords;
    }

    final giftJson = await _secureStorage.read(key: _keyVIPGift);
    if (giftJson == null) {
      await _refreshDailyGift();
      return AppConfig.vipDailyGiftWords;
    }

    final gift = VIPGiftRecord.fromJson(jsonDecode(giftJson));
    return gift.remainingWords;
  }

  /// 刷新VIP每日赠送
  Future<void> refreshVIPGiftedWords() async {
    final vipService = VIPService();
    if (!await vipService.isVIP()) {
      return;
    }

    await _refreshDailyGift();
  }

  Future<void> _refreshDailyGift() async {
    final today = DateTime.now();
    final gift = VIPGiftRecord(
      date: today,
      words: AppConfig.vipDailyGiftWords,
      remainingWords: AppConfig.vipDailyGiftWords,
    );

    await _secureStorage.write(
      key: _keyVIPGift,
      value: jsonEncode(gift.toJson()),
    );
    await _secureStorage.write(
      key: _keyLastRefreshDate,
      value: _dateToString(today),
    );
  }

  /// 获取购买的字数包
  Future<List<WordPackRecord>> getPurchasedWordPacks() async {
    final packsJson = await _secureStorage.read(key: _keyWordPacks);
    if (packsJson == null) {
      return [];
    }

    final List<dynamic> packsList = jsonDecode(packsJson);
    final List<WordPackRecord> packs = packsList
        .map((json) => WordPackRecord.fromJson(json))
        .where((pack) => !pack.isExpired)
        .toList();

    // 按购买时间排序（最早的优先）
    packs.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));

    return packs;
  }

  /// 购买字数包
  Future<void> purchaseWordPack({
    required WordPackType type,
    required int words,
  }) async {
    final expiryDate = DateTime.now().add(
      Duration(days: AppConfig.wordPackValidDays),
    );

    final pack = WordPackRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      words: words,
      purchaseDate: DateTime.now(),
      expiryDate: expiryDate,
      remainingWords: words,
      isExpired: false,
    );

    final packs = await getPurchasedWordPacks();
    packs.add(pack);

    await _saveWordPacks(packs);
  }

  /// 消耗字数
  Future<WordConsumeResult> consumeWords(int words) async {
    if (words <= 0) {
      return WordConsumeResult(success: true, remainingWords: await totalAvailableWords());
    }

    // 优先消耗VIP赠送字数
    int vipGifted = await getVIPGiftedWords();
    int remaining = words;

    if (vipGifted > 0) {
      final consumed = vipGifted >= remaining ? remaining : vipGifted;
      vipGifted -= consumed;
      remaining -= consumed;

      // 更新VIP赠送字数
      final today = DateTime.now();
      final gift = VIPGiftRecord(
        date: today,
        words: AppConfig.vipDailyGiftWords,
        remainingWords: vipGifted,
      );
      await _secureStorage.write(
        key: _keyVIPGift,
        value: jsonEncode(gift.toJson()),
      );
    }

    // 如果还有剩余，消耗购买的字数包
    if (remaining > 0) {
      final packs = await getPurchasedWordPacks();
      for (var pack in packs) {
        if (pack.remainingWords > 0) {
          final consumed = pack.remainingWords >= remaining
              ? remaining
              : pack.remainingWords;
          pack = WordPackRecord(
            id: pack.id,
            type: pack.type,
            words: pack.words,
            purchaseDate: pack.purchaseDate,
            expiryDate: pack.expiryDate,
            remainingWords: pack.remainingWords - consumed,
            isExpired: pack.isExpired,
          );
          remaining -= consumed;

          if (remaining <= 0) break;
        }
      }

      // 更新字数包
      await _saveWordPacks(packs);
    }

    // 记录总消耗
    final consumed = await _getConsumedWords();
    await _saveConsumedWords(consumed + words);

    final totalRemaining = await totalAvailableWords();
    return WordConsumeResult(
      success: remaining <= 0,
      remainingWords: totalRemaining,
    );
  }

  /// 获取总可用字数
  Future<int> totalAvailableWords() async {
    final vipGifted = await getVIPGiftedWords();
    final packs = await getPurchasedWordPacks();
    final purchased = packs.fold<int>(
      0,
      (sum, pack) => sum + pack.remainingWords,
    );
    return vipGifted + purchased;
  }

  /// 检查字数是否足够
  Future<bool> hasEnoughWords(int words) async {
    return await totalAvailableWords() >= words;
  }

  /// 统计文本字数
  /// 规则：1个中文字符、英文字母、数字、标点或空格均计为1字
  static int countWordsInText(String text) {
    if (text.isEmpty) return 0;
    return text.runes.length;
  }

  /// 奖励字数（激励视频等）
  Future<void> awardBonusWords(int words, {int validDays = 90}) async {
    final expiryDate = DateTime.now().add(Duration(days: validDays));
    final pack = WordPackRecord(
      id: 'bonus_${DateTime.now().millisecondsSinceEpoch}',
      type: WordPackType.pack500K, // 使用最小的类型
      words: words,
      purchaseDate: DateTime.now(),
      expiryDate: expiryDate,
      remainingWords: words,
      isExpired: false,
    );

    final packs = await getPurchasedWordPacks();
    packs.add(pack);
    await _saveWordPacks(packs);
  }

  Future<void> _saveWordPacks(List<WordPackRecord> packs) async {
    final packsJson = jsonEncode(
      packs.map((p) => p.toJson()).toList(),
    );
    await _secureStorage.write(key: _keyWordPacks, value: packsJson);
  }

  Future<int> _getConsumedWords() async {
    final consumedStr = await _secureStorage.read(key: _keyConsumedWords);
    return int.tryParse(consumedStr ?? '0') ?? 0;
  }

  Future<void> _saveConsumedWords(int words) async {
    await _secureStorage.write(
      key: _keyConsumedWords,
      value: words.toString(),
    );
  }

  String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 导出数据
  Future<String?> exportData() async {
    try {
      final packs = await getPurchasedWordPacks();
      final vipGift = await _secureStorage.read(key: _keyVIPGift);
      final consumed = await _getConsumedWords();

      final data = {
        'wordPacks': packs.map((p) => p.toJson()).toList(),
        'vipGift': vipGift != null ? jsonDecode(vipGift) : null,
        'consumedWords': consumed,
        'exportDate': DateTime.now().toIso8601String(),
      };

      return jsonEncode(data);
    } catch (e) {
      return null;
    }
  }

  /// 导入数据
  Future<bool> importData(String jsonString) async {
    try {
      final data = jsonDecode(jsonString);
      final packsList = data['wordPacks'] as List<dynamic>;
      final packs = packsList
          .map((json) => WordPackRecord.fromJson(json))
          .toList();

      await _saveWordPacks(packs);

      if (data['vipGift'] != null) {
        await _secureStorage.write(
          key: _keyVIPGift,
          value: jsonEncode(data['vipGift']),
        );
      }

      if (data['consumedWords'] != null) {
        await _saveConsumedWords(data['consumedWords'] as int);
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// 字数消耗结果
class WordConsumeResult {
  final bool success;
  final int remainingWords;

  WordConsumeResult({
    required this.success,
    required this.remainingWords,
  });
}

