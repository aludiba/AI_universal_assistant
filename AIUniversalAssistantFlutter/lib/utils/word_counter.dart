/// 字数统计工具
/// 规则：1个中文字符、英文字母、数字、标点或空格均计为1字
class WordCounter {
  /// 统计文本字数
  static int countWords(String text) {
    if (text.isEmpty) return 0;
    // 使用runes来正确处理Unicode字符（包括emoji）
    return text.runes.length;
  }

  /// 统计输入和输出的总字数
  static int countTotalWords(String input, String output) {
    return countWords(input) + countWords(output);
  }
}

