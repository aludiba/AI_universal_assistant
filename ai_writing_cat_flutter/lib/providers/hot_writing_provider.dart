import 'package:flutter/material.dart';
import '../models/hot_item_model.dart';

/// 热门模板写作页面状态管理
class HotWritingProvider with ChangeNotifier {
  HotItemModel? _item;
  
  // 输入状态
  final TextEditingController promptController = TextEditingController();
  final TextEditingController resultController = TextEditingController();
  
  // UI状态
  bool _isGenerating = false;
  
  HotItemModel? get item => _item;
  bool get isGenerating => _isGenerating;
  String get resultText => resultController.text;
  bool get hasResult => resultController.text.isNotEmpty;
  
  /// 初始化热门模板写作页面
  void initWriting(HotItemModel item) {
    _item = item;
    promptController.clear();
    resultController.clear();
    _isGenerating = false;
    notifyListeners();
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
    promptController.clear();
    resultController.clear();
    _isGenerating = false;
    notifyListeners();
  }
  
  @override
  void dispose() {
    promptController.dispose();
    resultController.dispose();
    super.dispose();
  }
}

