import 'package:flutter/material.dart';
import '../screens/writer/writer_screen.dart';

/// AI写作页面状态管理
class WritingProvider with ChangeNotifier {
  WritingType? _type;
  String? _initialContent;
  
  // 输入状态
  final TextEditingController promptController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController resultController = TextEditingController();
  
  // UI状态
  bool _isGenerating = false;
  String _selectedStyle = '通用';
  String _selectedLanguage = '中文';
  
  final List<String> styles = ['通用', '新闻', '学术', '公务', '小说', '作文'];
  final List<String> languages = ['中文', '英文', '日文'];
  
  WritingType? get type => _type;
  String? get initialContent => _initialContent;
  bool get isGenerating => _isGenerating;
  String get selectedStyle => _selectedStyle;
  String get selectedLanguage => _selectedLanguage;
  String get resultText => resultController.text;
  bool get hasResult => resultController.text.isNotEmpty;
  
  /// 初始化写作页面
  void initWriting(WritingType type, {String? initialContent}) {
    _type = type;
    _initialContent = initialContent;
    
    if (initialContent != null) {
      contentController.text = initialContent;
    }
    
    notifyListeners();
  }
  
  /// 设置风格
  void setStyle(String style) {
    if (_selectedStyle != style) {
      _selectedStyle = style;
      notifyListeners();
    }
  }
  
  /// 设置语言
  void setLanguage(String language) {
    if (_selectedLanguage != language) {
      _selectedLanguage = language;
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
    _type = null;
    _initialContent = null;
    promptController.clear();
    contentController.clear();
    resultController.clear();
    _isGenerating = false;
    _selectedStyle = '通用';
    _selectedLanguage = '中文';
    notifyListeners();
  }
  
  @override
  void dispose() {
    promptController.dispose();
    contentController.dispose();
    resultController.dispose();
    super.dispose();
  }
}

