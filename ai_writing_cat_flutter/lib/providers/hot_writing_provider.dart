import 'package:flutter/material.dart';
import '../models/hot_item_model.dart';

/// 热门模板写作页面状态管理
class HotWritingProvider with ChangeNotifier {
  HotItemModel? _item;

  // 输入状态
  final TextEditingController themeController = TextEditingController();
  final TextEditingController requirementController = TextEditingController();
  final TextEditingController resultController = TextEditingController();

  // 最大字数：0=不限，100/300/600/1000
  int _selectedWordCount = 0;
  static const List<int> wordCountOptions = [0, 100, 300, 600, 1000];

  // UI状态
  bool _isGenerating = false;

  HotItemModel? get item => _item;
  bool get isGenerating => _isGenerating;
  int get selectedWordCount => _selectedWordCount;
  String get resultText => resultController.text;
  bool get hasResult => resultController.text.isNotEmpty;

  /// 初始化热门模板写作页面
  void initWriting(HotItemModel item) {
    _item = item;
    themeController.text = item.title;
    requirementController.clear();
    resultController.clear();
    _selectedWordCount = 0;
    _isGenerating = false;
    notifyListeners();
  }

  /// 设置选中的字数
  void setSelectedWordCount(int count) {
    if (wordCountOptions.contains(count)) {
      _selectedWordCount = count;
      notifyListeners();
    }
  }

  /// 开始生成
  void startGenerating() {
    _isGenerating = true;
    resultController.clear();
    notifyListeners();
  }

  /// 设置生成结果
  void setResult(String result) {
    resultController.text = result;
    notifyListeners();
  }

  /// 完成生成
  void finishGenerating() {
    _isGenerating = false;
    notifyListeners();
  }

  /// 清空结果
  void clearResult() {
    resultController.clear();
    notifyListeners();
  }

  /// 重置状态
  void reset() {
    _item = null;
    themeController.clear();
    requirementController.clear();
    resultController.clear();
    _selectedWordCount = 0;
    _isGenerating = false;
    notifyListeners();
  }

  @override
  void dispose() {
    themeController.dispose();
    requirementController.dispose();
    resultController.dispose();
    super.dispose();
  }
}
