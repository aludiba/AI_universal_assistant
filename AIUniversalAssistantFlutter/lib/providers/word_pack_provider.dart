import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/word_pack.dart';
import '../services/storage_service.dart';

class WordPackProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  static const int vipDailyGiftWords = 500000; // 50万字
  static const int wordPackValidDays = 90;

  List<WordPackRecord> _wordPacks = [];
  VIPGiftRecord? _vipGift;

  List<WordPackRecord> get wordPacks => _wordPacks;
  VIPGiftRecord? get vipGift => _vipGift;

  /// 获取VIP赠送字数
  Future<int> getVIPGiftedWords(bool isVIP) async {
    if (!isVIP) return 0;

    final today = _getTodayString();
    final lastRefreshDate = await _storageService.getLastRefreshDate();

    // 如果不是今天，重置赠送字数
    if (lastRefreshDate != today) {
      await _refreshDailyGift();
      return vipDailyGiftWords;
    }

    final giftJson = await _storageService.getVIPGift();
    if (giftJson == null) {
      await _refreshDailyGift();
      return vipDailyGiftWords;
    }

    try {
      _vipGift = VIPGiftRecord.fromJson(jsonDecode(giftJson));
      return _vipGift!.remainingWords;
    } catch (e) {
      await _refreshDailyGift();
      return vipDailyGiftWords;
    }
  }

  /// 刷新VIP每日赠送
  Future<void> _refreshDailyGift() async {
    _vipGift = VIPGiftRecord(
      date: DateTime.now(),
      words: vipDailyGiftWords,
      remainingWords: vipDailyGiftWords,
    );
    await _storageService.saveVIPGift(jsonEncode(_vipGift!.toJson()));
    await _storageService.saveLastRefreshDate(_getTodayString());
    notifyListeners();
  }

  /// 获取购买的字数包
  Future<List<WordPackRecord>> getPurchasedWordPacks() async {
    final json = await _storageService.getWordPacks();
    if (json == null) return [];

    try {
      final List<dynamic> packsList = jsonDecode(json);
      _wordPacks = packsList
          .map((item) => WordPackRecord.fromJson(item))
          .where((pack) => !pack.isExpired && pack.remainingWords > 0)
          .toList();
      _wordPacks.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
      return _wordPacks;
    } catch (e) {
      return [];
    }
  }

  /// 消耗字数
  Future<WordConsumeResult> consumeWords(int words, bool isVIP) async {
    if (words <= 0) {
      return WordConsumeResult(
        success: true,
        remainingWords: await totalAvailableWords(isVIP),
      );
    }

    int remaining = words;

    // 优先消耗VIP赠送字数
    int vipGifted = await getVIPGiftedWords(isVIP);
    if (vipGifted > 0) {
      final consumed = vipGifted >= remaining ? remaining : vipGifted;
      vipGifted -= consumed;
      remaining -= consumed;

      // 更新VIP赠送字数
      _vipGift = VIPGiftRecord(
        date: DateTime.now(),
        words: vipDailyGiftWords,
        remainingWords: vipGifted,
      );
      await _storageService.saveVIPGift(jsonEncode(_vipGift!.toJson()));
    }

    // 如果还有剩余，消耗购买的字数包
    if (remaining > 0) {
      final packs = await getPurchasedWordPacks();
      for (int i = 0; i < packs.length; i++) {
        if (packs[i].remainingWords > 0) {
          final consumed = packs[i].remainingWords >= remaining
              ? remaining
              : packs[i].remainingWords;
          packs[i] = packs[i].copyWith(
            remainingWords: packs[i].remainingWords - consumed,
          );
          remaining -= consumed;
          if (remaining <= 0) break;
        }
      }
      await _saveWordPacks(packs);
    }

    // 记录总消耗
    final totalConsumed = await _storageService.getConsumedWords() + words;
    await _storageService.saveConsumedWords(totalConsumed);

    final totalRemaining = await totalAvailableWords(isVIP);
    notifyListeners();
    
    return WordConsumeResult(
      success: remaining <= 0,
      remainingWords: totalRemaining,
    );
  }

  /// 获取总可用字数
  Future<int> totalAvailableWords(bool isVIP) async {
    final vipGifted = await getVIPGiftedWords(isVIP);
    final packs = await getPurchasedWordPacks();
    final purchased = packs.fold<int>(0, (sum, pack) => sum + pack.remainingWords);
    return vipGifted + purchased;
  }

  /// 检查字数是否足够
  Future<bool> hasEnoughWords(int words, bool isVIP) async {
    return await totalAvailableWords(isVIP) >= words;
  }

  Future<void> _saveWordPacks(List<WordPackRecord> packs) async {
    final json = jsonEncode(packs.map((p) => p.toJson()).toList());
    await _storageService.saveWordPacks(json);
    _wordPacks = packs;
  }

  String _getTodayString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }
}

